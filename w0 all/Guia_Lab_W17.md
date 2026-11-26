# Guía de Laboratorio — W17
## ERP Django · Espiral 6 · Semana 17 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W17 de 24 |
| **Espiral** | E6 — Celery e Integraciones |
| **Sprint Scrum** | Sprint 5 — Desarrollo |
| **Hito** | Sin hito propio · Avance hacia M6 (W18) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 4 — Funcionalidades Avanzadas |
| **Hilo conductor** | "W16 creó la tubería. W17 hace fluir el agua: correos reales con SendGrid." |

---

## Respuesta a la tarea de investigación de W16

> **¿Qué es un `Dynamic Template` de SendGrid?**
> Es una plantilla HTML almacenada en SendGrid que acepta variables
> dinámicas (Handlebars). Permite diseñar correos visualmente en el
> dashboard de SendGrid sin necesitar código Python.
> Para el ERP académico usamos templates Django locales (más controlables),
> que es equivalente pero sin depender del dashboard externo.
>
> **¿`django-anymail` o SDK directo de SendGrid?**
>
> | Aspecto | `django-anymail` | SDK directo `sendgrid-python` |
> |---|---|---|
> | API | `send_mail()`, `EmailMessage` de Django | `sg.client.mail.send(message)` |
> | Portabilidad | Cambiar a Mailgun/Postmark con 1 línea | Reescribir toda la integración |
> | Tests | `mail.outbox` de Django | Mocking manual del SDK |
> | Aprendizaje | Reutiliza lo que Django ya enseña | API específica de Stripe |
>
> Usaremos **`django-anymail`** porque aprovecha la API estándar de
> Django y hace los tests triviales con `mail.outbox`.
>
> **¿Dos correos de confirmación para el mismo pedido?**
> Sí, es posible: `pago_exitoso()` llama `.delay()` Y el webhook
> también lo llama. La solución es el campo `correo_enviado` en `Pedido`:
> la tarea verifica si ya se envió y aborta si es así. Este campo
> también sirve como registro de auditoría.

---

## Objetivos de la sesión

Al terminar W17, el estudiante será capaz de:

1. Instalar y configurar `django-anymail` con el backend de SendGrid
2. Agregar el campo `correo_enviado` al modelo `Pedido` para garantizar
   idempotencia en el envío de correos
3. Crear templates HTML de correo compatibles con clientes de email
4. Actualizar la tarea `enviar_confirmacion_pedido` para enviar correo real
5. Actualizar `verificar_stock_bajo` para alertar al administrador
6. Escribir tests que verifican el contenido del correo con `mail.outbox`

---

## Stack tecnológico de W17

| Herramienta | Novedad en W17 | Descripción |
|---|---|---|
| `django-anymail` | ✅ Nuevo | Backends de correo para servicios transaccionales (SendGrid, etc.) |
| `EmailMultiAlternatives` | ✅ Nuevo | Correo con versión texto y HTML simultáneas |
| `render_to_string()` | ya usado (W12 PDF) | Renderiza template sin `request` — OK en tareas Celery |
| `mail.outbox` | ✅ Nuevo | Lista de correos enviados en tests con locmem backend |
| `correo_enviado` | ✅ Nuevo | Campo `BooleanField` en `Pedido` para idempotencia |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar W16 | 10 min |
| Parte 1 | Instalar `django-anymail` + configurar email | 15 min |
| Parte 2 | Campo `correo_enviado` en `Pedido` + migración | 15 min |
| Parte 3 | Templates HTML de correo | 25 min |
| Parte 4 | Actualizar `enviar_confirmacion_pedido` | 25 min |
| Parte 5 | Actualizar `verificar_stock_bajo` | 15 min |
| Parte 6 | Tests W17 (8 pruebas con `mail.outbox`) | 25 min |
| Cierre | Commit · `finalizar_sesion.bat` · hilo → W18 | 10 min |
| Buffer | | 20 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W16?
   → Instalé Celery+Redis+Flower, creé las tareas placeholder
     en ventas/tasks.py y las conecté al flujo de pago.

2. ¿Qué haré en W17?
   → Reemplazaré los placeholders con envío real de correo
     usando django-anymail y SendGrid.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 155 tests … OK`

---

## PARTE 1 — Instalar `django-anymail` y Configurar Email (15 min)

### 1.1 Instalar el paquete

```cmd
pip install "django-anymail[sendgrid]==10.3"
pip freeze > requirements.txt
```

Verificar:
```cmd
python -c "import anymail; print('anymail OK')"
```

### 1.2 Obtener API Key de SendGrid

1. Ir a `https://app.sendgrid.com` → crear cuenta gratuita
   (100 correos/día en el plan gratuito)
2. Configuración → API Keys → Create API Key
3. Nombre: `erp-django-utec`
4. Permisos: **Mail Send** (solo los necesarios)
5. Copiar la clave: `SG.xxxxxxxxxxxxx`

### 1.3 Agregar variables al `.env`

```bash
# .env — agregar:
SENDGRID_API_KEY=SG.TU_API_KEY_AQUI
DEFAULT_FROM_EMAIL=noreply@tu-dominio.com
ADMIN_EMAIL=tu-correo-admin@gmail.com
```

### 1.4 Configurar en `core/settings.py`

Agregar al final del archivo, antes de `JAZZMIN_SETTINGS`:

```python
# core/settings.py — configuración de correo electrónico

# ── CORREO ELECTRÓNICO ────────────────────────────────────────────────────
# En desarrollo: usar el backend de consola (imprime en terminal)
# En producción: anymail con SendGrid
EMAIL_BACKEND = env(
    'EMAIL_BACKEND',
    default='django.core.mail.backends.console.EmailBackend'
)

# Dirección del remitente visible en los correos
DEFAULT_FROM_EMAIL = env(
    'DEFAULT_FROM_EMAIL',
    default='ERP Django <noreply@erp-django.com>'
)

# Nombre del asunto con prefijo del sistema
EMAIL_SUBJECT_PREFIX = '[ERP Django] '

# Administradores que reciben alertas del sistema
ADMINS = [
    ('Admin ERP', env('ADMIN_EMAIL', default='admin@erp-django.com')),
]

# Configuración de django-anymail (SendGrid)
SENDGRID_API_KEY = env('SENDGRID_API_KEY', default='')
ANYMAIL = {
    'SENDGRID_API_KEY': SENDGRID_API_KEY,
    # Reintentar envíos fallidos automáticamente
    'SEND_DEFAULTS': {
        'esp_extra': {'ip_pool_name': 'transactional'},
    },
}
```

### 1.5 Actualizar `core/settings_prod.py`

En producción, usar el backend real de SendGrid:

```python
# core/settings_prod.py — agregar:

# En producción: usar SendGrid via anymail
EMAIL_BACKEND = 'anymail.backends.sendgrid.EmailBackend'
```

### 1.6 Agregar `anymail` a `INSTALLED_APPS`

```python
# core/settings.py — en INSTALLED_APPS, después de rest_framework:
'anymail',    # ← agregar
```

### 1.7 Verificar

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

**Prueba rápida con el backend de consola:**
```cmd
python manage.py shell
>>> from django.core.mail import send_mail
>>> send_mail('Test', 'Mensaje de prueba', None, ['test@test.com'])
```
Debe imprimirse el correo en la terminal (backend de consola).

---

## PARTE 2 — Campo `correo_enviado` en `Pedido` + Migración (15 min)

### 2.1 ¿Por qué necesitamos `correo_enviado`?

```
Escenario sin correo_enviado:
  1. Pago confirmado → webhook dispara tarea
  2. pago_exitoso() también dispara la misma tarea
  3. La tarea se ejecuta DOS veces
  4. Cliente recibe DOS correos de confirmación ← ❌ mala experiencia

Escenario con correo_enviado:
  1. Primera ejecución: correo_enviado=False → enviar + marcar True
  2. Segunda ejecución: correo_enviado=True → skip (return early)
  3. Cliente recibe UN correo ← ✅
```

---

### 2.2 Agregar el campo al modelo `Pedido`

Abrir `ventas/models.py` y agregar en la clase `Pedido`:

```python
# ventas/models.py — en Pedido, después de items_snapshot:

    correo_enviado = models.BooleanField(
        default=False,
        verbose_name='Correo de confirmación enviado',
        help_text='True cuando se envió el correo de confirmación al cliente.'
    )
```

### 2.3 Crear y aplicar la migración

```cmd
python manage.py makemigrations ventas --name correo_enviado_pedido
python manage.py migrate
```

**Resultado esperado:**
```
Migrations for 'ventas':
  ventas/migrations/0004_correo_enviado_pedido.py
    - Add field correo_enviado to pedido
Applying ventas.0004_correo_enviado_pedido... OK
```

```cmd
python manage.py showmigrations ventas
```

```
ventas
 [X] 0001_initial
 [X] 0002_validators_pedido
 [X] 0003_items_snapshot_pedido
 [X] 0004_correo_enviado_pedido
```

---

## PARTE 3 — Templates HTML de Correo (25 min)

### 3.1 Crear carpeta de templates de correo

```cmd
mkdir templates\emails
```

### 3.2 `templates/emails/confirmacion_pedido.html`

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Confirmación de pedido {{ pedido.numero_pedido }}</title>
    <style>
        /* CSS inline — mayor compatibilidad con clientes de correo */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: Arial, Helvetica, sans-serif;
            font-size: 15px;
            background: #F5F7FA;
            color: #1A1A2E;
        }
        .wrapper {
            max-width: 600px;
            margin: 24px auto;
            background: #FFFFFF;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 2px 16px rgba(10,35,66,.1);
        }
        /* Encabezado */
        .header {
            background: #0A2342;
            padding: 28px 32px;
            border-bottom: 4px solid #B8860B;
        }
        .header-title {
            color: #D4AF37;
            font-size: 22px;
            font-weight: bold;
            letter-spacing: .03em;
        }
        .header-sub {
            color: rgba(255,255,255,.7);
            font-size: 13px;
            margin-top: 4px;
        }
        /* Cuerpo */
        .body { padding: 28px 32px; }
        .greeting {
            font-size: 17px;
            margin-bottom: 16px;
            color: #0A2342;
        }
        /* Caja del pedido */
        .pedido-box {
            background: #E8F0FB;
            border-left: 5px solid #0A2342;
            border-radius: 0 8px 8px 0;
            padding: 16px 20px;
            margin: 20px 0;
        }
        .pedido-num {
            font-size: 20px;
            font-weight: bold;
            color: #0A2342;
        }
        .pedido-total {
            font-size: 18px;
            font-weight: bold;
            color: #B8860B;
            margin-top: 4px;
        }
        /* Tabla de productos */
        .productos-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        .productos-table th {
            background: #0A2342;
            color: #FFFFFF;
            padding: 10px 14px;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: .05em;
            text-align: left;
        }
        .productos-table th.num { text-align: right; }
        .productos-table td {
            padding: 9px 14px;
            border-bottom: 1px solid #E8F0FB;
            font-size: 14px;
        }
        .productos-table td.num { text-align: right; }
        .productos-table tr:last-child td { border-bottom: none; }
        .total-row td {
            background: #FDF8E8;
            border-top: 2px solid #B8860B;
            font-weight: bold;
            font-size: 15px;
            padding: 12px 14px;
        }
        .total-valor { color: #B8860B; text-align: right; }
        /* CTA */
        .cta-section { text-align: center; margin: 24px 0; }
        .cta-btn {
            display: inline-block;
            background: #B8860B;
            color: #FFFFFF;
            padding: 12px 28px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: bold;
            font-size: 15px;
        }
        /* Pie */
        .footer {
            background: #F5F7FA;
            border-top: 1px solid #C8D8EC;
            padding: 16px 32px;
            font-size: 12px;
            color: #5A6A7E;
            text-align: center;
        }
    </style>
</head>
<body>
<div class="wrapper">

    <!-- ENCABEZADO -->
    <div class="header">
        <div class="header-title">✅ ¡Pago confirmado!</div>
        <div class="header-sub">{{ config.nombre_empresa }}</div>
    </div>

    <!-- CUERPO -->
    <div class="body">
        <p class="greeting">
            Hola, <strong>{{ pedido.cliente.nombre }}</strong>:
        </p>
        <p style="color:#5A6A7E;margin-bottom:16px;">
            Gracias por tu compra. Tu pedido ha sido confirmado
            y está siendo procesado.
        </p>

        <!-- Número y total del pedido -->
        <div class="pedido-box">
            <div class="pedido-num">
                Pedido {{ pedido.numero_pedido }}
            </div>
            <div class="pedido-total">
                Total pagado: ${{ pedido.total_pagado }}
            </div>
            <div style="color:#5A6A7E;font-size:13px;margin-top:6px;">
                Fecha: {{ pedido.fecha_pedido|date:"d/m/Y H:i" }}
            </div>
        </div>

        <!-- Tabla de productos del snapshot -->
        {% if items %}
        <table class="productos-table">
            <thead>
                <tr>
                    <th>Producto</th>
                    <th class="num">Precio</th>
                    <th class="num">Cant.</th>
                    <th class="num">Subtotal</th>
                </tr>
            </thead>
            <tbody>
                {% for item in items %}
                <tr>
                    <td>{{ item.nombre }}</td>
                    <td class="num">${{ item.precio }}</td>
                    <td class="num">{{ item.cantidad }}</td>
                    <td class="num">
                        ${% widthratio item.cantidad 1 item.precio %}
                    </td>
                </tr>
                {% endfor %}
            </tbody>
            <tfoot>
                <tr class="total-row">
                    <td colspan="3">Total:</td>
                    <td class="total-valor">${{ pedido.total_pagado }}</td>
                </tr>
            </tfoot>
        </table>
        {% endif %}

        <!-- Botón CTA -->
        <div class="cta-section">
            <a href="{{ url_pedido }}" class="cta-btn">
                Ver detalle del pedido
            </a>
        </div>

        <p style="color:#5A6A7E;font-size:13px;margin-top:8px;">
            Si tienes preguntas, responde a este correo.<br>
            Equipo de {{ config.nombre_empresa }}
        </p>
    </div>

    <!-- PIE -->
    <div class="footer">
        <p>{{ config.nombre_empresa }}
           {% if config.rfc %}· RFC: {{ config.rfc }}{% endif %}</p>
        <p style="margin-top:4px;">
            Este correo fue generado automáticamente. No responder directamente.
        </p>
    </div>

</div>
</body>
</html>
```

---

### 3.3 `templates/emails/alerta_stock.html`

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Alerta: Stock bajo en {{ total_productos }} producto(s)</title>
    <style>
        body {
            font-family: Arial, Helvetica, sans-serif;
            font-size: 15px;
            background: #F5F7FA;
            color: #1A1A2E;
        }
        .wrapper {
            max-width: 600px;
            margin: 24px auto;
            background: #FFFFFF;
            border-radius: 12px;
            overflow: hidden;
        }
        .header {
            background: #C0392B;
            padding: 24px 32px;
            border-bottom: 4px solid #B8860B;
        }
        .header-title { color: #FFFFFF; font-size: 20px; font-weight: bold; }
        .header-sub   { color: rgba(255,255,255,.8); font-size: 13px; margin-top: 4px; }
        .body { padding: 24px 32px; }
        .alert-box {
            background: #FDEDEC;
            border-left: 5px solid #C0392B;
            border-radius: 0 8px 8px 0;
            padding: 14px 18px;
            margin: 16px 0;
            font-weight: bold;
            color: #C0392B;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 16px 0;
        }
        th {
            background: #0A2342;
            color: #FFFFFF;
            padding: 10px 14px;
            font-size: 12px;
            text-transform: uppercase;
            text-align: left;
        }
        td {
            padding: 9px 14px;
            border-bottom: 1px solid #E8F0FB;
            font-size: 14px;
        }
        .stock-critico { color: #C0392B; font-weight: bold; }
        .footer {
            background: #F5F7FA;
            border-top: 1px solid #C8D8EC;
            padding: 14px 32px;
            font-size: 12px;
            color: #5A6A7E;
            text-align: center;
        }
    </style>
</head>
<body>
<div class="wrapper">

    <div class="header">
        <div class="header-title">⚠️ Alerta: Stock bajo</div>
        <div class="header-sub">
            {{ total_productos }} producto(s) requieren reposición
        </div>
    </div>

    <div class="body">
        <p style="margin-bottom:12px;">
            El siguiente reporte fue generado automáticamente el
            <strong>{{ fecha }}</strong>.
        </p>

        <div class="alert-box">
            {{ total_productos }} producto(s) con stock &lt; {{ umbral }} unidades
        </div>

        <table>
            <thead>
                <tr>
                    <th>Producto</th>
                    <th style="text-align:right;">Stock actual</th>
                    <th>Categoría</th>
                </tr>
            </thead>
            <tbody>
                {% for prod in productos_bajos %}
                <tr>
                    <td>{{ prod.nombre }}</td>
                    <td style="text-align:right;" class="stock-critico">
                        {{ prod.stock }}
                    </td>
                    <td>{{ prod.categoria__nombre }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>

        <p style="color:#5A6A7E;font-size:13px;margin-top:8px;">
            Accede al panel de administración para reponer el stock:
            <a href="{{ url_admin }}" style="color:#0A2342;">
                {{ url_admin }}
            </a>
        </p>
    </div>

    <div class="footer">
        <p>Generado por ERP Django · Sistema de alertas automáticas</p>
    </div>

</div>
</body>
</html>
```

---

### 3.4 Versión texto plano (fallback)

Crear `templates/emails/confirmacion_pedido.txt`:

```
¡Pago confirmado! — {{ config.nombre_empresa }}

Hola, {{ pedido.cliente.nombre }}:

Tu pedido ha sido confirmado.

PEDIDO: {{ pedido.numero_pedido }}
TOTAL:  ${{ pedido.total_pagado }}
FECHA:  {{ pedido.fecha_pedido|date:"d/m/Y H:i" }}

{% for item in items %}
- {{ item.nombre }} × {{ item.cantidad }} = ${{ item.precio }}
{% endfor %}

Ver tu pedido: {{ url_pedido }}

Gracias por tu compra.
{{ config.nombre_empresa }}
```

Crear `templates/emails/alerta_stock.txt`:

```
⚠️ ALERTA DE STOCK BAJO — ERP Django
Fecha: {{ fecha }}

{{ total_productos }} producto(s) con stock < {{ umbral }} unidades:

{% for prod in productos_bajos %}
- {{ prod.nombre }}: {{ prod.stock }} unidades
{% endfor %}

Administración: {{ url_admin }}
```

---

## PARTE 4 — Actualizar `enviar_confirmacion_pedido` (25 min)

### 4.1 Reemplazar `ventas/tasks.py` completamente

```python
# ventas/tasks.py
"""Tareas asíncronas de la app ventas — W17.

W17 implementa el envío real de correos con django-anymail + SendGrid.

Idempotencia:
    Pedido.correo_enviado=True previene envíos duplicados si la tarea
    se llama más de una vez para el mismo pedido.
"""
import logging
from decimal import Decimal

from celery import shared_task
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils import timezone

logger = logging.getLogger(__name__)


@shared_task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,
    name='ventas.enviar_confirmacion_pedido',
)
def enviar_confirmacion_pedido(self, pedido_id: int) -> dict:
    """Envía el correo de confirmación de pedido al cliente.

    Garantías:
        - Idempotente: si correo_enviado=True, aborta sin error.
        - Retry automático hasta 3 veces en caso de fallo de SendGrid.

    Args:
        pedido_id: ID del Pedido confirmado.

    Returns:
        dict con estado, pedido_id y correo del destinatario.
    """
    from configuracion.models import ConfiguracionERP  # import local
    from ventas.models        import Pedido             # import local

    try:
        pedido = Pedido.objects.select_related('cliente').get(pk=pedido_id)
    except Pedido.DoesNotExist:
        logger.error(
            f'[correo_confirmacion] Pedido {pedido_id} no existe.'
        )
        return {'estado': 'error', 'razon': 'Pedido no encontrado'}

    # ── Verificación de idempotencia ────────────────────────────────────
    if pedido.correo_enviado:
        logger.info(
            f'[correo_confirmacion] Pedido {pedido.numero_pedido}: '
            f'correo ya enviado anteriormente — skip.'
        )
        return {
            'estado':    'skip',
            'pedido_id': pedido_id,
            'razon':     'correo ya enviado',
        }

    config = ConfiguracionERP.get_instance()

    # ── Construir contexto del correo ───────────────────────────────────
    items = pedido.items_snapshot or []
    url_pedido = (
        f"https://erp-django-utec.onrender.com"
        f"/ventas/{pedido.pk}/"
    )

    contexto = {
        'pedido':     pedido,
        'config':     config,
        'items':      items,
        'url_pedido': url_pedido,
    }

    # ── Renderizar templates ────────────────────────────────────────────
    # render_to_string sin request (las tareas Celery no tienen request)
    asunto     = (
        f'Confirmación de pedido {pedido.numero_pedido} '
        f'— {config.nombre_empresa}'
    )
    texto_plano = render_to_string(
        'emails/confirmacion_pedido.txt', contexto
    )
    html_body   = render_to_string(
        'emails/confirmacion_pedido.html', contexto
    )

    # ── Construir el correo ────────────────────────────────────────────
    correo_destino = pedido.cliente.correo
    correo_origen  = settings.DEFAULT_FROM_EMAIL

    mensaje = EmailMultiAlternatives(
        subject      = asunto,
        body         = texto_plano,      # versión texto plano (fallback)
        from_email   = correo_origen,
        to           = [correo_destino],
    )
    mensaje.attach_alternative(html_body, 'text/html')

    # ── Enviar y manejar errores ───────────────────────────────────────
    try:
        mensaje.send()
        logger.info(
            f'[correo_confirmacion] Correo enviado a {correo_destino} '
            f'para pedido {pedido.numero_pedido}.'
        )

        # Marcar como enviado para evitar duplicados
        pedido.correo_enviado = True
        pedido.save(update_fields=['correo_enviado'])

        return {
            'estado':    'ok',
            'pedido_id': pedido_id,
            'correo':    correo_destino,
        }

    except Exception as exc:
        logger.error(
            f'[correo_confirmacion] Error al enviar correo para pedido '
            f'{pedido.numero_pedido}: {exc}'
        )
        # Reintento automático con Celery (hasta max_retries=3)
        raise self.retry(exc=exc, countdown=60 * (self.request.retries + 1))


@shared_task(
    bind=True,
    max_retries=1,
    name='ventas.verificar_stock_bajo',
)
def verificar_stock_bajo(self, umbral: int = 5) -> dict:
    """Verifica productos con stock bajo y envía alerta al admin.

    W17: Si hay productos bajo el umbral, envía correo a ADMINS[0].

    Args:
        umbral: cantidad mínima antes de alertar (default: 5).

    Returns:
        dict con conteo y lista de productos con stock bajo.
    """
    from productos.models import Producto   # import local

    productos_bajos = list(
        Producto.objects
        .select_related('categoria')
        .filter(activo=True, stock__lt=umbral)
        .values('pk', 'nombre', 'stock', 'categoria__nombre')
        .order_by('stock')
    )

    if not productos_bajos:
        logger.info(
            f'[stock_bajo] Todos los productos tienen stock ≥ {umbral}. OK.'
        )
        return {'umbral': umbral, 'total': 0, 'productos_bajos': []}

    logger.warning(
        f'[stock_bajo] {len(productos_bajos)} producto(s) con stock < {umbral}.'
    )

    # Enviar alerta por correo si hay administradores configurados
    if settings.ADMINS:
        _enviar_alerta_stock(productos_bajos, umbral)

    return {
        'umbral':          umbral,
        'total':           len(productos_bajos),
        'productos_bajos': productos_bajos,
    }


def _enviar_alerta_stock(productos_bajos: list, umbral: int) -> None:
    """Envía el correo de alerta de stock al primer administrador.

    Args:
        productos_bajos: lista de dicts con nombre, stock y categoría.
        umbral:          umbral mínimo configurado.
    """
    from configuracion.models import ConfiguracionERP   # import local

    config = ConfiguracionERP.get_instance()
    fecha  = timezone.now().strftime('%d/%m/%Y %H:%M')

    url_admin = (
        'https://erp-django-utec.onrender.com/admin/productos/producto/'
    )

    contexto = {
        'productos_bajos':  productos_bajos,
        'total_productos':  len(productos_bajos),
        'umbral':           umbral,
        'fecha':            fecha,
        'url_admin':        url_admin,
        'config':           config,
    }

    asunto      = (
        f'[ALERTA] {len(productos_bajos)} producto(s) con stock < {umbral}'
    )
    texto_plano = render_to_string('emails/alerta_stock.txt',  contexto)
    html_body   = render_to_string('emails/alerta_stock.html', contexto)

    admin_nombre, admin_correo = settings.ADMINS[0]

    mensaje = EmailMultiAlternatives(
        subject    = asunto,
        body       = texto_plano,
        from_email = settings.DEFAULT_FROM_EMAIL,
        to         = [admin_correo],
    )
    mensaje.attach_alternative(html_body, 'text/html')

    try:
        mensaje.send()
        logger.info(
            f'[stock_bajo] Alerta enviada a {admin_correo}. '
            f'{len(productos_bajos)} productos.'
        )
    except Exception as exc:
        logger.error(f'[stock_bajo] Error al enviar alerta: {exc}')
```

---

## PARTE 5 — Verificar con el backend de consola (15 min)

### 5.1 Prueba con el shell de Django (sin worker real)

```cmd
python manage.py shell
```

```python
from django.test.utils import override_settings

with override_settings(
    CELERY_TASK_ALWAYS_EAGER=True,
    EMAIL_BACKEND='django.core.mail.backends.console.EmailBackend'
):
    from ventas.tasks import enviar_confirmacion_pedido
    from ventas.models import Pedido

    # Tomar un pedido existente
    pedido = Pedido.objects.filter(estado='pagado').first()
    if pedido:
        resultado = enviar_confirmacion_pedido.delay(pedido.pk)
        print('Resultado:', resultado.get())
    else:
        print('No hay pedidos pagados. Crea uno en /catalogo/checkout/')
```

**Resultado esperado en la terminal:**
```
Content-Type: text/plain; charset="utf-8"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Subject: Confirmación de pedido PED-2025-0001 — Mi Empresa ERP
From: ERP Django <noreply@erp-django.com>
To: cliente@test.com

¡Pago confirmado! — Mi Empresa ERP
...

[correo_confirmacion] Correo enviado a cliente@test.com para PED-2025-0001.
```

---

### 5.2 Actualizar `.env.example`

```bash
# .env.example — agregar:
SENDGRID_API_KEY=SG.TU_CLAVE_AQUI
DEFAULT_FROM_EMAIL=ERP Django <noreply@tu-dominio.com>
ADMIN_EMAIL=admin@tu-dominio.com
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
```

---

## PARTE 6 — Tests W17 (25 min)

### 6.1 Crear `tests/test_w17_correo.py`

```python
"""Suite de pruebas W17 — Correos transaccionales con django-anymail.

Usa el backend locmem (en memoria) para capturar correos sin enviarlos.
Los correos enviados se almacenan en django.core.mail.outbox.

Ejecutar con:
    python manage.py test tests.test_w17_correo --verbosity=2

Resultado esperado:
    Ran 8 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.core import mail
from django.test import TestCase, override_settings

from clientes.models      import Cliente
from configuracion.models import ConfiguracionERP
from productos.models     import Categoria, Producto
from ventas.models        import Pedido
from ventas.tasks         import (
    enviar_confirmacion_pedido,
    verificar_stock_bajo,
)

# Configuración común para todos los tests de correo
EMAIL_SETTINGS = {
    'EMAIL_BACKEND': 'django.core.mail.backends.locmem.EmailBackend',
    'CELERY_TASK_ALWAYS_EAGER': True,
    'CELERY_TASK_EAGER_PROPAGATES': True,
    'ADMINS': [('Admin Test', 'admin@test.com')],
    'DEFAULT_FROM_EMAIL': 'test@erp.com',
}


def _crear_pedido_pagado(correo_enviado=False) -> Pedido:
    """Crea un Pedido en estado 'pagado' para los tests."""
    ConfiguracionERP.get_instance()
    cat  = Categoria.objects.create(nombre=f'Cat-{Pedido.objects.count()}')
    prod = Producto.objects.create(
        nombre='Producto Test', precio=Decimal('100.00'),
        stock=5, categoria=cat
    )
    cli  = Cliente.objects.create(
        nombre='Cliente Test',
        correo=f'cliente{Pedido.objects.count()}@test.com'
    )
    return Pedido.objects.create(
        numero_pedido  = f'PED-TEST-{Pedido.objects.count():03d}',
        cliente        = cli,
        estado         = 'pagado',
        total_pagado   = Decimal('116.00'),
        correo_enviado = correo_enviado,
        items_snapshot = [
            {
                'producto_id': prod.pk,
                'nombre':      prod.nombre,
                'cantidad':    2,
                'precio':      str(prod.precio),
            }
        ],
    )


@override_settings(**EMAIL_SETTINGS)
class EnviarConfirmacionTest(TestCase):
    """Tests del envío del correo de confirmación de pedido."""

    def setUp(self):
        mail.outbox = []   # limpiar la bandeja de prueba antes de cada test

    def test_correo_enviado_a_cliente(self):
        """El correo debe enviarse al correo del cliente."""
        pedido = _crear_pedido_pagado()
        enviar_confirmacion_pedido.delay(pedido.pk)

        self.assertEqual(len(mail.outbox), 1)
        self.assertIn(pedido.cliente.correo, mail.outbox[0].to)

    def test_correo_asunto_contiene_numero_pedido(self):
        """El asunto debe incluir el número de pedido."""
        pedido = _crear_pedido_pagado()
        enviar_confirmacion_pedido.delay(pedido.pk)

        self.assertIn(pedido.numero_pedido, mail.outbox[0].subject)

    def test_correo_cuerpo_html_contiene_total(self):
        """El cuerpo HTML debe contener el total pagado."""
        pedido = _crear_pedido_pagado()
        enviar_confirmacion_pedido.delay(pedido.pk)

        mensaje = mail.outbox[0]
        # Verificar que hay alternativa HTML
        alternativas = [
            body for body, mime in mensaje.alternatives
            if mime == 'text/html'
        ]
        self.assertEqual(len(alternativas), 1)
        self.assertIn(str(pedido.total_pagado), alternativas[0])

    def test_correo_marca_correo_enviado_true(self):
        """Tras el envío, Pedido.correo_enviado debe ser True."""
        pedido = _crear_pedido_pagado()
        self.assertFalse(pedido.correo_enviado)

        enviar_confirmacion_pedido.delay(pedido.pk)

        pedido.refresh_from_db()
        self.assertTrue(pedido.correo_enviado)

    def test_correo_no_duplicado_si_ya_enviado(self):
        """Si correo_enviado=True, la tarea NO debe enviar otro correo."""
        pedido = _crear_pedido_pagado(correo_enviado=True)

        enviar_confirmacion_pedido.delay(pedido.pk)

        # mail.outbox debe estar vacío (no se envió correo)
        self.assertEqual(len(mail.outbox), 0)

    def test_tarea_devuelve_skip_si_ya_enviado(self):
        """La tarea debe devolver estado 'skip' si ya se envió."""
        pedido = _crear_pedido_pagado(correo_enviado=True)
        resultado = enviar_confirmacion_pedido.delay(pedido.pk).get()
        self.assertEqual(resultado['estado'], 'skip')


@override_settings(**EMAIL_SETTINGS)
class AlertaStockTest(TestCase):
    """Tests del correo de alerta de stock bajo."""

    def setUp(self):
        mail.outbox = []
        ConfiguracionERP.get_instance()

    def test_alerta_enviada_si_hay_stock_bajo(self):
        """Si hay productos con stock < umbral, se envía alerta al admin."""
        cat  = Categoria.objects.create(nombre='Cat Alert')
        Producto.objects.create(
            nombre='Stock Bajo', precio=Decimal('50.00'),
            stock=2, categoria=cat
        )

        verificar_stock_bajo.delay(umbral=5)

        self.assertEqual(len(mail.outbox), 1)
        self.assertIn('admin@test.com', mail.outbox[0].to)

    def test_alerta_contiene_nombre_producto(self):
        """El correo de alerta debe mencionar el producto con stock bajo."""
        cat  = Categoria.objects.create(nombre='Cat Alert2')
        Producto.objects.create(
            nombre='Teclado Escaso', precio=Decimal('200.00'),
            stock=1, categoria=cat
        )

        verificar_stock_bajo.delay(umbral=5)

        self.assertEqual(len(mail.outbox), 1)
        # Verificar en el texto plano O en el HTML
        cuerpo = mail.outbox[0].body
        self.assertIn('Teclado Escaso', cuerpo)

    def test_no_alerta_si_todo_ok(self):
        """Si todos los productos tienen stock >= umbral, no se envía correo."""
        cat  = Categoria.objects.create(nombre='Cat OK')
        Producto.objects.create(
            nombre='Bien surtido', precio=Decimal('100.00'),
            stock=20, categoria=cat
        )

        verificar_stock_bajo.delay(umbral=5)

        self.assertEqual(len(mail.outbox), 0)
```

### 6.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w17_correo --verbosity=2
```

**Resultado esperado:**
```
test_alerta_contiene_nombre_producto ... ok
test_alerta_enviada_si_hay_stock_bajo ... ok
test_correo_asunto_contiene_numero_pedido ... ok
test_correo_cuerpo_html_contiene_total ... ok
test_correo_enviado_a_cliente ... ok
test_correo_marca_correo_enviado_true ... ok
test_correo_no_duplicado_si_ya_enviado ... ok
test_no_alerta_si_todo_ok ... ok
test_tarea_devuelve_skip_si_ya_enviado ... ok

Ran 8 tests in X.XXXs
OK
```

### 6.3 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 163 tests in X.XXXs · OK` (155 + 8)

---

## CIERRE — Commit y Respaldo (10 min)

### Actualizar `sprint5_planning.md`

```markdown
## Sprint Backlog — actualización W17

| Tarea | Estado |
|---|---|
| pip install celery redis flower | ✅ W16 |
| core/celery.py + tareas placeholder | ✅ W16 |
| pip install django-anymail | ✅ W17 |
| EMAIL_BACKEND configurado (console dev / anymail prod) | ✅ W17 |
| correo_enviado en Pedido + migración 0004 | ✅ W17 |
| Template confirmacion_pedido.html + .txt | ✅ W17 |
| Template alerta_stock.html + .txt | ✅ W17 |
| enviar_confirmacion_pedido: correo real + idempotencia | ✅ W17 |
| verificar_stock_bajo: alerta al admin | ✅ W17 |
| 8 tests con mail.outbox | ✅ W17 |
| Celery Beat + tareas programadas | ⏳ W18 |
```

### Commit de cierre W17

```cmd
git add .
git status

:: Verificar que incluye:
::   ventas/tasks.py (reemplazado con lógica real)
::   ventas/models.py (con correo_enviado)
::   ventas/migrations/0004_correo_enviado_pedido.py
::   templates/emails/confirmacion_pedido.html + .txt
::   templates/emails/alerta_stock.html + .txt
::   core/settings.py (EMAIL_BACKEND + ANYMAIL + ADMINS)
::   core/settings_prod.py (EMAIL_BACKEND anymail)
::   tests/test_w17_correo.py
::   sprint5_planning.md

git commit -m "Sprint 5 W17: SendGrid + correos reales + idempotencia + 163 tests OK"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W17

### Técnico

```
INSTALACIÓN Y CONFIG
[ ] pip install django-anymail[sendgrid] → sin errores
[ ] 'anymail' en INSTALLED_APPS
[ ] EMAIL_BACKEND en settings.py (console para dev)
[ ] EMAIL_BACKEND = anymail.sendgrid en settings_prod.py
[ ] ANYMAIL = {'SENDGRID_API_KEY': SENDGRID_API_KEY}
[ ] DEFAULT_FROM_EMAIL con nombre y correo
[ ] ADMINS con al menos un admin
[ ] python manage.py check → 0 issues

MODELO Y MIGRACIÓN
[ ] Pedido.correo_enviado = BooleanField(default=False)
[ ] migrations/0004_correo_enviado_pedido.py creada y aplicada
[ ] showmigrations ventas → [X] 0004

TEMPLATES DE CORREO
[ ] templates/emails/confirmacion_pedido.html con CSS inline
[ ] templates/emails/confirmacion_pedido.txt (fallback texto)
[ ] templates/emails/alerta_stock.html
[ ] templates/emails/alerta_stock.txt
[ ] Todos los templates usan context sin request

TAREAS ACTUALIZADAS
[ ] enviar_confirmacion_pedido: verificación correo_enviado al inicio
[ ] enviar_confirmacion_pedido: EmailMultiAlternatives (texto + HTML)
[ ] enviar_confirmacion_pedido: pedido.correo_enviado=True tras envío
[ ] enviar_confirmacion_pedido: self.retry() en caso de excepción
[ ] verificar_stock_bajo: _enviar_alerta_stock si productos_bajos
[ ] Todos los imports de modelos son locales (dentro de la función)

TESTS (8 tests con locmem backend)
[ ] test tests.test_w17_correo → 8/8 OK
[ ] test tests → 163/163 OK acumulados
[ ] @override_settings(EMAIL_BACKEND='...locmem...', CELERY_TASK_ALWAYS_EAGER=True)
[ ] mail.outbox = [] en setUp()
[ ] test correo enviado al cliente → len(mail.outbox) == 1
[ ] test asunto contiene numero_pedido
[ ] test HTML contiene total_pagado
[ ] test correo_enviado=True tras envío
[ ] test NO duplicado si correo_enviado=True → outbox vacío
[ ] test alerta stock → outbox tiene 1 mensaje a admin
[ ] test sin stock bajo → outbox vacío

GIT
[ ] sprint5_planning.md actualizado
[ ] Commit con mensaje descriptivo
[ ] git push → GitHub con templates/emails/
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Flujo completo del correo transaccional (W17)

```
Pago confirmado (webhook payment_intent.succeeded)
    │
    ├─ Pedido.estado = 'pagado'
    └─ enviar_confirmacion_pedido.delay(pedido_id)
                │
                │  Redis (cola erp_django)
                │  Mensaje: {task: '...', args: [42]}
                │
                ▼
    Celery Worker (proceso separado)
        │
        ├─ enviar_confirmacion_pedido(pedido_id=42)
        │       │
        │       ├─ Pedido.get(pk=42)
        │       ├─ if pedido.correo_enviado: return 'skip' ✅ (idempotente)
        │       │
        │       ├─ render_to_string('emails/confirmacion_pedido.txt', ctx)
        │       ├─ render_to_string('emails/confirmacion_pedido.html', ctx)
        │       │
        │       ├─ EmailMultiAlternatives(
        │       │       subject='Confirmación PED-2025-0042',
        │       │       body=texto_plano,
        │       │       to=['cliente@email.com']
        │       │   )
        │       ├─ mensaje.attach_alternative(html, 'text/html')
        │       ├─ mensaje.send()
        │       │       │
        │       │       ▼ (en prod: anymail → SendGrid API → cliente)
        │       │       ▼ (en dev:  console backend → terminal)
        │       │       ▼ (en test: locmem → mail.outbox[0])
        │       │
        │       └─ pedido.correo_enviado = True → save()
        │
        └─ return {'estado': 'ok', 'correo': 'cliente@email.com'}

mail.outbox en tests:
    >>> mail.outbox[0].to         → ['cliente@test.com']
    >>> mail.outbox[0].subject    → 'Confirmación de pedido PED-TEST-001...'
    >>> mail.outbox[0].alternatives[0][1]  → 'text/html'
```

---

## HILO CONDUCTOR → W18

**¿Qué entrega W17?**
Las tareas Celery envían correos reales con SendGrid: confirmación
de pedido al cliente (con idempotencia) y alerta de stock bajo al
administrador. 163 tests verifican el comportamiento con `mail.outbox`.

**¿Qué abre W18 / Hito M6?**
Las tareas de W17 se ejecutan solo cuando un evento ocurre (pago
confirmado, solicitud manual). W18 agrega **Celery Beat** para
ejecutar `verificar_stock_bajo` cada hora y `reporte_ventas_diario`
cada mañana a las 8:00 AM automáticamente.

**¿Qué necesita W18 de W17?**

| Artefacto de W17 | Uso en W18 |
|---|---|
| `verificar_stock_bajo` task | W18 la programa en `CELERY_BEAT_SCHEDULE` |
| `ventas/tasks.py` con estructura base | W18 agrega `reporte_ventas_diario` task |
| `docker-compose.yml` con worker | W18 agrega servicio `celery_beat` separado |
| 163 tests pasando | W18 agrega tests de la programación horaria |

**Tarea de investigación para W18:**
> Lee la documentación de Celery Beat:
> `https://docs.celeryq.dev/en/stable/userguide/periodic-tasks.html`
>
> ¿Qué es `CELERY_BEAT_SCHEDULE` y cómo se define una tarea
> que se ejecuta cada hora?
> ¿Por qué el beat scheduler debe correr como proceso SEPARADO
> del worker? ¿Qué pasa si corren ambos juntos con `celery -A core worker -B`?

**Pregunta de reflexión:**
> "En W17 usamos `mail.outbox` para los tests y el backend de consola
> para desarrollo. ¿Por qué no es recomendable usar el backend real
> de SendGrid en los tests, incluso con una cuenta de sandbox?
> ¿Qué riesgo correría si los tests se ejecutan en CI/CD?"

---

## Referencia rápida de comandos W17

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py makemigrations ventas --name correo_enviado_pedido
python manage.py migrate
python manage.py runserver

:: CELERY WORKER (terminal 2 — con Redis corriendo)
celery -A core worker -l info -Q erp_django

:: PRUEBA DE CORREO EN SHELL (backend consola)
python manage.py shell
>>> from django.test.utils import override_settings
>>> with override_settings(CELERY_TASK_ALWAYS_EAGER=True):
...     from ventas.tasks import enviar_confirmacion_pedido
...     from ventas.models import Pedido
...     p = Pedido.objects.filter(estado='pagado').first()
...     if p: enviar_confirmacion_pedido.delay(p.pk)

:: TESTS
python manage.py test tests.test_w17_correo --verbosity=2
python manage.py test tests --verbosity=0   (163 tests)

:: GIT
git add .
git commit -m "Sprint 5 W17: SendGrid + correos reales + 163 tests OK"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W17 · ERP Django*
*Espiral 6 · Sprint 5 Desarrollo · SendGrid + django-anymail + Correos Reales*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*