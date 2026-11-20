# Guía de Laboratorio — W18
## ERP Django · Espiral 6 · Semana 18 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W18 de 24 |
| **Espiral** | E6 — Celery e Integraciones |
| **Sprint Scrum** | Sprint 5 — Review + Retrospectiva |
| **Hito** | **★ M6: Celery activo + correo recibido + alertas + Beat programado** |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 4 — Funcionalidades Avanzadas |
| **Hilo conductor** | "W17 enseñó al ERP a enviar correos. W18 lo hace autónomo: trabaja mientras nadie lo mira." |

---

## Respuesta a la tarea de investigación de W17

> **¿Qué es `CELERY_BEAT_SCHEDULE`?**
> Es un diccionario en `settings.py` que define las tareas programadas.
> Cada entrada especifica: qué tarea ejecutar, con qué argumentos y
> con qué frecuencia (timedelta o crontab).
>
> ```python
> CELERY_BEAT_SCHEDULE = {
>     'nombre-tarea': {
>         'task':     'app.tasks.nombre_funcion',
>         'schedule': timedelta(hours=1),   # cada hora
>         'args':     (umbral,),
>     },
> }
> ```
>
> **¿Por qué Beat debe correr como proceso SEPARADO?**
>
> | Escenario | Problema |
> |---|---|
> | `worker -B` (combinado) | Si el worker se cae, el scheduler también se cae |
> | Beat separado | Si el worker se cae, el Beat sigue enviando tareas a la cola |
>
> En producción: siempre dos procesos independientes.
> En desarrollo: `worker -B` es aceptable por comodidad.
>
> **¿Riesgo de usar SendGrid real en CI/CD?**
> Sí: cada ejecución del pipeline enviaría correos reales a las
> direcciones de los datos de prueba, podría agotar el límite
> gratuito (100/día), generar costos inesperados y marcar los
> correos como spam si se repiten. Por eso usamos `locmem.EmailBackend`
> que captura todo en `mail.outbox` sin salir del proceso.

---

## Objetivos de la sesión

Al terminar W18, el estudiante será capaz de:

1. Agregar la tarea `reporte_ventas_diario` con agregación SQL
2. Crear el template HTML del reporte de ventas
3. Configurar `CELERY_BEAT_SCHEDULE` con `crontab` y `timedelta`
4. Agregar el servicio `celery_beat` a `docker-compose.yml`
5. Ejecutar Beat y verificar las tareas programadas
6. Ejecutar el Sprint 5 Review y declarar el Hito M6
7. Completar la ficha Schmelkes E6

---

## Stack tecnológico de W18

| Herramienta | Novedad en W18 | Descripción |
|---|---|---|
| `celery.schedules.crontab` | ✅ Nuevo | Programa tareas en horas exactas (como cron de Unix) |
| `CELERY_BEAT_SCHEDULE` | ✅ Nuevo | Diccionario de tareas periódicas en `settings.py` |
| Celery Beat (proceso) | ✅ Nuevo | Proceso que envía tareas programadas al broker |
| `annotate` + `Sum(F())` | ✅ Nuevo | Agregación SQL para totales de ventas |
| `django.utils.timezone.now()` | ya usado | Fecha/hora actual en zona horaria configurada |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar W17 | 10 min |
| Parte 1 | Template `reporte_ventas.html` + `.txt` | 20 min |
| Parte 2 | Tarea `reporte_ventas_diario` en `ventas/tasks.py` | 25 min |
| Parte 3 | `CELERY_BEAT_SCHEDULE` en `settings.py` | 15 min |
| Parte 4 | Agregar `celery_beat` en `docker-compose.yml` | 10 min |
| Parte 5 | Arrancar Beat + verificar ejecución | 15 min |
| Parte 6 | Tests W18 (8 pruebas) | 20 min |
| **Commit parcial** | Punto de control seguro | 5 min |
| Parte 7 | Sprint 5 Review ante el asesor | 20 min |
| Parte 8 | Sprint 5 Retrospectiva + Ficha Schmelkes E6 | 20 min |
| Cierre | Commit final [M6] · `finalizar_sesion.bat` · hilo → W19 | 10 min |
| Buffer | | 10 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W17?
   → Instalé django-anymail, actualicé las tareas Celery para
     enviar correos reales con SendGrid y garanticé idempotencia
     con el campo correo_enviado.

2. ¿Qué haré en W18?
   → Agregaré la tarea de reporte diario de ventas, configuraré
     Celery Beat para tareas programadas y cerraré el Sprint 5
     con el Hito M6.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 163 tests … OK`

---

## PARTE 1 — Template HTML del Reporte de Ventas (20 min)

### 1.1 Crear `templates/emails/reporte_ventas.html`

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de ventas — {{ fecha }}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: Arial, Helvetica, sans-serif;
            font-size: 14px;
            background: #F5F7FA;
            color: #1A1A2E;
        }
        .wrapper {
            max-width: 640px;
            margin: 24px auto;
            background: #FFFFFF;
            border-radius: 12px;
            overflow: hidden;
        }
        .header {
            background: #0A2342;
            padding: 26px 32px;
            border-bottom: 4px solid #B8860B;
        }
        .header-title {
            color: #D4AF37;
            font-size: 20px;
            font-weight: bold;
        }
        .header-sub {
            color: rgba(255,255,255,.72);
            font-size: 13px;
            margin-top: 4px;
        }
        .body { padding: 26px 32px; }
        /* KPI cards */
        .kpi-grid {
            display: table;
            width: 100%;
            border-collapse: separate;
            border-spacing: 8px;
            margin-bottom: 24px;
        }
        .kpi-row { display: table-row; }
        .kpi-card {
            display: table-cell;
            background: #E8F0FB;
            border-radius: 8px;
            padding: 14px 16px;
            text-align: center;
            width: 50%;
        }
        .kpi-valor {
            font-size: 22px;
            font-weight: bold;
            color: #0A2342;
        }
        .kpi-label {
            font-size: 12px;
            color: #5A6A7E;
            text-transform: uppercase;
            letter-spacing: .05em;
            margin-top: 3px;
        }
        .kpi-card.gold .kpi-valor { color: #B8860B; }
        /* Tabla top productos */
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 16px 0;
        }
        th {
            background: #0A2342;
            color: #FFFFFF;
            padding: 10px 14px;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: .05em;
            text-align: left;
        }
        th.num { text-align: right; }
        td {
            padding: 9px 14px;
            border-bottom: 1px solid #E8F0FB;
            font-size: 13px;
        }
        td.num { text-align: right; }
        .sin-ventas {
            background: #FDF8E8;
            border: 1px solid #B8860B;
            border-radius: 8px;
            padding: 16px;
            text-align: center;
            color: #5A6A7E;
            font-size: 14px;
            margin: 16px 0;
        }
        .footer {
            background: #F5F7FA;
            border-top: 1px solid #C8D8EC;
            padding: 14px 32px;
            font-size: 11px;
            color: #5A6A7E;
            text-align: center;
        }
    </style>
</head>
<body>
<div class="wrapper">

    <!-- ENCABEZADO -->
    <div class="header">
        <div class="header-title">📊 Reporte de ventas del día</div>
        <div class="header-sub">
            {{ config.nombre_empresa }} · {{ fecha }}
        </div>
    </div>

    <!-- CUERPO -->
    <div class="body">

        <!-- KPIs -->
        <div class="kpi-grid">
            <div class="kpi-row">
                <div class="kpi-card">
                    <div class="kpi-valor">{{ total_pedidos }}</div>
                    <div class="kpi-label">Pedidos pagados hoy</div>
                </div>
                <div class="kpi-card gold">
                    <div class="kpi-valor">${{ total_facturado }}</div>
                    <div class="kpi-label">Total facturado</div>
                </div>
            </div>
        </div>

        {% if top_productos %}
        <p style="font-weight:600;color:#0A2342;margin-bottom:8px;">
            Top {{ top_productos|length }} productos del día
        </p>
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Producto</th>
                    <th class="num">Unidades vendidas</th>
                    <th class="num">Ingreso ($)</th>
                </tr>
            </thead>
            <tbody>
                {% for prod in top_productos %}
                <tr>
                    <td>{{ forloop.counter }}</td>
                    <td>{{ prod.nombre }}</td>
                    <td class="num">{{ prod.unidades }}</td>
                    <td class="num">${{ prod.ingreso }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
        {% else %}
        <div class="sin-ventas">
            Sin ventas registradas hoy. ¡Hay oportunidad de mejorar! 🎯
        </div>
        {% endif %}

        <p style="color:#5A6A7E;font-size:12px;margin-top:12px;">
            Panel de administración:
            <a href="{{ url_admin }}" style="color:#0A2342;">
                {{ url_admin }}
            </a>
        </p>
    </div>

    <div class="footer">
        <p>Generado automáticamente por ERP Django a las 8:00 AM</p>
        <p>{{ config.nombre_empresa }}</p>
    </div>

</div>
</body>
</html>
```

---

### 1.2 Crear `templates/emails/reporte_ventas.txt`

```
📊 REPORTE DE VENTAS DEL DÍA — {{ fecha }}
{{ config.nombre_empresa }}
═══════════════════════════════════════════

RESUMEN:
  Pedidos pagados hoy: {{ total_pedidos }}
  Total facturado:     ${{ total_facturado }}

{% if top_productos %}
TOP PRODUCTOS:
{% for prod in top_productos %}
  {{ forloop.counter }}. {{ prod.nombre }}
     Unidades: {{ prod.unidades }} | Ingreso: ${{ prod.ingreso }}
{% endfor %}
{% else %}
Sin ventas registradas hoy.
{% endif %}

Panel de administración: {{ url_admin }}

───────────────────────────────────────────
Generado automáticamente a las 8:00 AM
ERP Django · {{ config.nombre_empresa }}
```

---

## PARTE 2 — Tarea `reporte_ventas_diario` (25 min)

### 2.1 ¿Qué es `annotate` + `Sum(F())`?

```python
# Sin annotate — N+1 queries en Python:
for pedido in Pedido.objects.filter(hoy):
    total += pedido.total   # @property: 1 query por pedido

# Con annotate — 1 sola query SQL con SUM():
from django.db.models import Sum, F, ExpressionWrapper, DecimalField

DetalleVenta.objects.filter(
    venta__fecha__date=hoy
).values('producto__nombre').annotate(
    unidades=Sum('cantidad'),
    ingreso=Sum(
        ExpressionWrapper(
            F('cantidad') * F('precio_unitario'),
            output_field=DecimalField()
        )
    )
).order_by('-ingreso')[:5]
```

`F('campo')` referencia un campo de la BD sin traerlo a Python,
permitiendo que la multiplicación ocurra directamente en SQL.

---

### 2.2 Agregar `reporte_ventas_diario` a `ventas/tasks.py`

Agregar al final del archivo `ventas/tasks.py` (después de `_enviar_alerta_stock`):

```python
# ventas/tasks.py — agregar al final del archivo

@shared_task(
    bind=True,
    max_retries=2,
    name='ventas.reporte_ventas_diario',
)
def reporte_ventas_diario(self) -> dict:
    """Genera y envía el reporte diario de ventas al administrador.

    Se ejecuta automáticamente a las 8:00 AM todos los días
    mediante Celery Beat (configurado en CELERY_BEAT_SCHEDULE).

    Cálculos realizados en SQL (no en Python) para máxima eficiencia:
        - Total de pedidos pagados hoy
        - Total facturado (suma de total_pagado)
        - Top 5 productos por ingreso del día

    Returns:
        dict con total_pedidos, total_facturado y top_productos.
    """
    from decimal import Decimal

    from django.db.models import (
        DecimalField, ExpressionWrapper, F, Sum,
    )
    from django.utils import timezone

    from configuracion.models import ConfiguracionERP   # import local
    from ventas.models        import DetalleVenta, Pedido  # import local

    hoy    = timezone.localdate()
    config = ConfiguracionERP.get_instance()

    # ── 1. KPIs del día ───────────────────────────────────────────────
    pedidos_hoy = Pedido.objects.filter(
        fecha_pedido__date=hoy,
        estado='pagado'
    )
    total_pedidos   = pedidos_hoy.count()
    total_facturado = pedidos_hoy.aggregate(
        total=Sum('total_pagado')
    )['total'] or Decimal('0.00')

    # ── 2. Top 5 productos por ingreso del día ─────────────────────────
    top_productos = list(
        DetalleVenta.objects
        .filter(venta__fecha__date=hoy)
        .values(nombre=F('producto__nombre'))
        .annotate(
            unidades=Sum('cantidad'),
            ingreso=Sum(
                ExpressionWrapper(
                    F('cantidad') * F('precio_unitario'),
                    output_field=DecimalField(max_digits=12, decimal_places=2)
                )
            )
        )
        .order_by('-ingreso')[:5]
    )

    logger.info(
        f'[reporte_diario] {hoy}: {total_pedidos} pedidos, '
        f'${total_facturado} facturados, '
        f'{len(top_productos)} productos top.'
    )

    # ── 3. Enviar correo al admin si está configurado ──────────────────
    if settings.ADMINS:
        _enviar_reporte_ventas(
            hoy, total_pedidos, total_facturado, top_productos, config
        )

    return {
        'fecha':           str(hoy),
        'total_pedidos':   total_pedidos,
        'total_facturado': str(total_facturado),
        'top_productos':   top_productos,
    }


def _enviar_reporte_ventas(
    fecha, total_pedidos, total_facturado, top_productos, config
) -> None:
    """Envía el reporte diario al primer administrador configurado.

    Args:
        fecha:           Objeto date del día reportado.
        total_pedidos:   Número de pedidos pagados.
        total_facturado: Decimal con la suma total.
        top_productos:   Lista de dicts con nombre, unidades, ingreso.
        config:          Instancia de ConfiguracionERP.
    """
    url_admin = (
        'https://erp-django-utec.onrender.com/admin/ventas/venta/'
    )
    fecha_str = fecha.strftime('%d/%m/%Y')

    contexto = {
        'fecha':           fecha_str,
        'config':          config,
        'total_pedidos':   total_pedidos,
        'total_facturado': total_facturado,
        'top_productos':   top_productos,
        'url_admin':       url_admin,
    }

    asunto      = f'Reporte de ventas del {fecha_str} — {config.nombre_empresa}'
    texto_plano = render_to_string('emails/reporte_ventas.txt',  contexto)
    html_body   = render_to_string('emails/reporte_ventas.html', contexto)

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
        logger.info(f'[reporte_diario] Reporte enviado a {admin_correo}.')
    except Exception as exc:
        logger.error(f'[reporte_diario] Error al enviar reporte: {exc}')
```

---

## PARTE 3 — `CELERY_BEAT_SCHEDULE` en `settings.py` (15 min)

### 3.1 Agregar al final de `core/settings.py`

```python
# core/settings.py — agregar después de CELERY_TASK_ALWAYS_EAGER:

# ── CELERY BEAT — Tareas programadas ──────────────────────────────────────
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {

    # Verificar stock bajo cada hora
    'verificar-stock-bajo-cada-hora': {
        'task':     'ventas.verificar_stock_bajo',
        'schedule': timedelta(hours=1),
        'args':     (5,),   # umbral = 5 unidades
        'options':  {'queue': 'erp_django'},
    },

    # Reporte de ventas diario a las 8:00 AM (hora México)
    'reporte-ventas-diario-8am': {
        'task':     'ventas.reporte_ventas_diario',
        'schedule': crontab(hour=8, minute=0),
        'options':  {'queue': 'erp_django'},
    },

}

# Necesario para que Beat use la zona horaria de Django (no UTC)
CELERY_BEAT_TIMEZONE = TIME_ZONE   # 'America/Mexico_City'
```

> **`crontab(hour=8, minute=0)`** equivale a la expresión cron `0 8 * * *`:
> ejecutar exactamente a las 8:00 AM todos los días.
>
> **`timedelta(hours=1)`** equivale a `crontab(minute=0)` pero
> más legible cuando se trata de intervalos, no de horas exactas.

---

### 3.2 Agregar el import de `timedelta` al inicio de `settings.py`

```python
# core/settings.py — verificar que existe al inicio:
from datetime import timedelta   # ← agregar si no está

# (ya debería estar si se instaló dj-database-url en W03)
```

### 3.3 Verificar

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

---

## PARTE 4 — Agregar `celery_beat` a `docker-compose.yml` (10 min)

### 4.1 Agregar el servicio de Beat

Abrir `docker-compose.yml` y agregar el nuevo servicio después de `celery_worker`:

```yaml
  # ── Celery Beat — Scheduler de tareas programadas — W18 ────────────
  celery_beat:
    build: .
    restart: unless-stopped
    # Beat NUNCA debe tener múltiples réplicas (un solo scheduler)
    command: celery -A core beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
    volumes:
      - .:/app
    depends_on:
      redis:
        condition: service_healthy
      db:
        condition: service_healthy
    environment:
      DJANGO_SETTINGS_MODULE: core.settings_prod
      SECRET_KEY:             dev-clave-docker-no-usar-en-produccion
      DATABASE_URL:           postgres://erp_user:erp_pass_local@db:5432/erp_db
      REDIS_URL:              redis://redis:6379/0
```

> **Nota de producción:** `celery beat` nunca debe tener más de
> **una instancia corriendo simultáneamente**. Si se despliega con
> múltiples réplicas, las tareas se programarían duplicadas.
> En Render.com, configurar el Beat como un servicio independiente
> con `numInstances: 1` en `render.yaml`.

---

## PARTE 5 — Arrancar Beat y Verificar (15 min)

### 5.1 Iniciar todos los procesos

Necesitas **4 terminales** simultáneas:

```
Terminal 1 (Django):
    cd C:\Temp_Workspace_ERP
    call env_erp\Scripts\activate
    python manage.py runserver

Terminal 2 (Worker):
    cd C:\Temp_Workspace_ERP
    call env_erp\Scripts\activate
    celery -A core worker -l info -Q erp_django

Terminal 3 (Beat):
    cd C:\Temp_Workspace_ERP
    call env_erp\Scripts\activate
    celery -A core beat -l info

Terminal 4 (Flower — opcional):
    cd C:\Temp_Workspace_ERP
    call env_erp\Scripts\activate
    celery -A core flower --port=5555
```

**Alternativa en desarrollo (solo 2 terminales):**

```cmd
:: Terminal 2 (worker + beat combinados — solo para desarrollo)
celery -A core worker -B -l info -Q erp_django
```

### 5.2 Salida esperada del proceso Beat

```
celery beat v5.3.6 (emerald-rush) is starting.
__    -    ... __   -        _
Configuration ->
    . broker -> redis://localhost:6379/0
    . loader -> celery.loaders.app.AppLoader
    . scheduler -> celery.beat.PersistentScheduler
    . db -> celerybeat-schedule.db
    . logfile -> [stderr]@%INFO
    . maxinterval -> 5.00 minutes (300s)

[2025-01-15 08:00:00,000: INFO/MainProcess]
    Scheduler: Sending due task reporte-ventas-diario-8am
    (ventas.reporte_ventas_diario)
[2025-01-15 09:00:00,000: INFO/MainProcess]
    Scheduler: Sending due task verificar-stock-bajo-cada-hora
    (ventas.verificar_stock_bajo)
```

### 5.3 Forzar ejecución inmediata para verificar (desarrollo)

Para no esperar hasta las 8:00 AM:

```cmd
python manage.py shell
```

```python
from ventas.tasks import reporte_ventas_diario, verificar_stock_bajo

# Ejecutar sincrónicamente (sin worker)
r1 = reporte_ventas_diario.apply()
print('Reporte:', r1.get())

r2 = verificar_stock_bajo.apply(args=(3,))
print('Stock bajo:', r2.get())
```

### 5.4 Verificar en Flower

```
[ ] http://localhost:5555 → Workers: [celery@PC online]
[ ] Pestaña "Tasks" → ventas.reporte_ventas_diario: SUCCESS
[ ] Pestaña "Tasks" → ventas.verificar_stock_bajo: SUCCESS
[ ] Correo de reporte visible en la terminal de Django (backend consola)
```

---

## PARTE 6 — Tests W18 (20 min)

### 6.1 Crear `tests/test_w18_beat.py`

```python
"""Suite de pruebas W18 — Celery Beat y tarea de reporte diario.

Verifica la configuración del schedule, la ejecución de la tarea
y el envío del correo de reporte.

Ejecutar con:
    python manage.py test tests.test_w18_beat --verbosity=2

Resultado esperado:
    Ran 8 tests in X.XXXs
    OK
"""
from decimal import Decimal
from datetime import timedelta

from django.conf import settings
from django.core import mail
from django.test import TestCase, override_settings
from django.utils import timezone

from clientes.models      import Cliente
from configuracion.models import ConfiguracionERP
from productos.models     import Categoria, Producto
from ventas.models        import DetalleVenta, Pedido, Venta
from ventas.tasks         import reporte_ventas_diario, verificar_stock_bajo

EMAIL_SETTINGS = {
    'EMAIL_BACKEND':               'django.core.mail.backends.locmem.EmailBackend',
    'CELERY_TASK_ALWAYS_EAGER':    True,
    'CELERY_TASK_EAGER_PROPAGATES': True,
    'ADMINS':           [('Admin Test', 'admin@test.com')],
    'DEFAULT_FROM_EMAIL': 'test@erp.com',
}


class BeatScheduleConfigTest(TestCase):
    """Verifica la configuración de CELERY_BEAT_SCHEDULE."""

    def test_beat_schedule_tiene_verificar_stock(self):
        """El schedule debe incluir verificar_stock_bajo."""
        schedule = settings.CELERY_BEAT_SCHEDULE
        tareas   = [v['task'] for v in schedule.values()]
        self.assertIn('ventas.verificar_stock_bajo', tareas)

    def test_beat_schedule_tiene_reporte_diario(self):
        """El schedule debe incluir reporte_ventas_diario."""
        schedule = settings.CELERY_BEAT_SCHEDULE
        tareas   = [v['task'] for v in schedule.values()]
        self.assertIn('ventas.reporte_ventas_diario', tareas)

    def test_reporte_usa_crontab(self):
        """El reporte diario debe usar crontab (no timedelta)."""
        from celery.schedules import crontab
        schedule = settings.CELERY_BEAT_SCHEDULE
        for nombre, config in schedule.items():
            if config['task'] == 'ventas.reporte_ventas_diario':
                self.assertIsInstance(
                    config['schedule'], crontab,
                    "reporte_ventas_diario debe usar crontab, no timedelta"
                )
                break

    def test_verificar_stock_usa_timedelta(self):
        """verificar_stock_bajo debe usar timedelta (intervalo)."""
        schedule = settings.CELERY_BEAT_SCHEDULE
        for nombre, config in schedule.items():
            if config['task'] == 'ventas.verificar_stock_bajo':
                self.assertIsInstance(
                    config['schedule'], timedelta,
                    "verificar_stock_bajo debe usar timedelta"
                )
                break


@override_settings(**EMAIL_SETTINGS)
class ReporteVentasTest(TestCase):
    """Tests de la tarea reporte_ventas_diario."""

    def setUp(self):
        mail.outbox = []
        ConfiguracionERP.get_instance()
        cat      = Categoria.objects.create(nombre='Cat Rep')
        self.prod = Producto.objects.create(
            nombre='Producto Reporte', precio=Decimal('500.00'),
            stock=10, categoria=cat
        )
        cli        = Cliente.objects.create(
            nombre='Cliente Rep', correo='rep@test.com'
        )
        # Crear una venta de HOY
        venta = Venta.objects.create(cliente=cli)
        DetalleVenta.objects.create(
            venta=venta, producto=self.prod,
            cantidad=3, precio_unitario=Decimal('500.00')
        )
        # Crear un pedido pagado de HOY
        Pedido.objects.create(
            numero_pedido = 'PED-REP-001',
            cliente       = cli,
            estado        = 'pagado',
            total_pagado  = Decimal('1500.00'),
        )

    def test_reporte_envia_correo_al_admin(self):
        """La tarea debe enviar correo al administrador."""
        reporte_ventas_diario.delay()
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn('admin@test.com', mail.outbox[0].to)

    def test_reporte_asunto_contiene_fecha(self):
        """El asunto debe contener la fecha del reporte."""
        reporte_ventas_diario.delay()
        fecha_str = timezone.localdate().strftime('%d/%m/%Y')
        self.assertIn(fecha_str, mail.outbox[0].subject)

    def test_reporte_sin_ventas_hoy_envia_correo(self):
        """Aunque no haya ventas, el reporte debe enviarse."""
        # Eliminar ventas y pedidos creados en setUp
        Pedido.objects.all().delete()
        DetalleVenta.objects.all().delete()

        reporte_ventas_diario.delay()

        self.assertEqual(len(mail.outbox), 1)
        # Verificar que menciona 0 pedidos en el texto plano
        cuerpo = mail.outbox[0].body
        self.assertIn('0', cuerpo)

    def test_reporte_devuelve_dict_con_totales(self):
        """La tarea debe devolver un dict con total_pedidos y facturado."""
        resultado = reporte_ventas_diario.delay().get()
        self.assertIn('total_pedidos',   resultado)
        self.assertIn('total_facturado', resultado)
        self.assertIn('top_productos',   resultado)
        self.assertGreaterEqual(resultado['total_pedidos'], 0)
```

### 6.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w18_beat --verbosity=2
```

**Resultado esperado:**
```
test_beat_schedule_tiene_reporte_diario ... ok
test_beat_schedule_tiene_verificar_stock ... ok
test_reporte_asunto_contiene_fecha ... ok
test_reporte_devuelve_dict_con_totales ... ok
test_reporte_envia_correo_al_admin ... ok
test_reporte_sin_ventas_hoy_envia_correo ... ok
test_reporte_usa_crontab ... ok
test_verificar_stock_usa_timedelta ... ok

Ran 8 tests in X.XXXs
OK
```

### 6.3 Suite acumulada — Hito M6

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 171 tests in X.XXXs · OK` (163 + 8)

### COMMIT PARCIAL

```cmd
git add .
git commit -m "Sprint 5 W18: Beat + reporte_diario + crontab + 171 tests OK [pre-M6]"
```

---

## PARTE 7 — Sprint 5 Review ante el asesor (20 min)

### Guión de demo (≤ 10 min en vivo)

```
1. Mostrar los 3 procesos activos:
   → Terminal 1: Django runserver (servidor web)
   → Terminal 2: Celery worker (ejecuta tareas)
   → Terminal 3: Celery Beat (programa tareas)
   → Flower en http://localhost:5555

2. Demostrar envío de correo de confirmación:
   → Completar una compra con tarjeta 4242
   → En terminal del worker: "[correo_confirmacion] Correo enviado a..."
   → En terminal de Django: correo impreso (backend consola)

3. Demostrar reporte de ventas:
   → python manage.py shell
   → from ventas.tasks import reporte_ventas_diario
   → reporte_ventas_diario.apply().get()
   → Correo de reporte impreso en terminal con KPIs del día

4. Demostrar verificación de stock:
   → from ventas.tasks import verificar_stock_bajo
   → verificar_stock_bajo.apply(args=(100,)).get()  # umbral alto para forzar alerta
   → Correo de alerta impreso en terminal

5. Mostrar Flower:
   → Workers online + 3 tareas ejecutadas en el historial

6. Mostrar los tests:
   → python manage.py test tests --verbosity=0
   → Ran 171 tests … OK

7. Declarar Sprint Goal y Hito M6 verificados:
   "Celery activo + correo recibido + alerta de stock +
    Beat programado (8:00 AM diario + cada hora)"
   → Estado: ✅ HITO M6 ALCANZADO
```

### Tabla de verificación M6

| Criterio | Estado |
|---|---|
| `celery -A core worker` → procesa tareas | ✅ |
| `celery -A core beat` → scheduler activo | ✅ |
| Pago confirmado → correo de confirmación < 30 s | ✅ |
| Stock bajo → alerta al admin | ✅ |
| Reporte diario a las 8:00 AM (crontab) | ✅ |
| Verificación de stock cada hora (timedelta) | ✅ |
| Flower dashboard → workers + tareas visibles | ✅ |
| 171 tests acumulados OK | ✅ |

---

## PARTE 8 — Sprint 5 Retrospectiva + Ficha Schmelkes E6 (20 min)

### 8.1 Crear `sprint5_retrospective.md`

```markdown
# Sprint 5 Retrospective — ERP Django
## Semanas W16–W18 · Espiral 6: Celery e Integraciones

**Fecha:** ___/___/_____

## ¿Qué funcionó bien? (Keep)
1. El campo correo_enviado en Pedido resolvió elegantemente el
   problema de duplicados sin necesidad de un sistema externo de idempotencia.
2. @override_settings(EMAIL_BACKEND=locmem) hizo los tests de correo
   triviales: mail.outbox captura todo sin enviar nada.
3. Separar beat de worker como procesos independientes es la
   arquitectura correcta desde el inicio.

## ¿Qué mejorar? (Improve)
1. Documentar mejor el procedimiento de arranque de los 4 procesos.
2. Agregar health check a los servicios Celery en docker-compose.

## Acción de mejora (Kaizen) para Sprint 6
> "En el Sprint 6 (Dashboard), pre-calcularé los KPIs con annotate
>  desde el principio, sin iterar en Python."

## Velocidad del Sprint 5

| HU | Pts plan. | Pts ent. |
|---|---|---|
| HU-E6-01 Infraestructura Celery+Redis | 3 | 3 |
| HU-E6-02 Tareas sin bloquear HTTP | 2 | 2 |
| HU-E6-03 Correo confirmación post-pago | 5 | 5 |
| HU-E6-04 Alerta stock bajo | 3 | 3 |
| HU-E6-05 Reporte diario 8 AM | 3 | 3 |
| HU-E6-06 Monitorear con Flower | 2 | 2 |
| **Total** | **18** | **18** |

**Velocidad Sprint 5:** 18 puntos
**Velocidad acumulada (S0–S5):** 123 puntos
```

---

### 8.2 Crear `fichas/espiral_06_async.md`

```markdown
# Ficha de Sistematización — Espiral 6
## ERP Django · Espiral E6: Celery e Integraciones

| Campo | Contenido |
|---|---|
| **Número de espiral** | 6 |
| **Nombre del ciclo** | Celery e Integraciones |
| **Semanas** | W16 – W18 |
| **Fecha de inicio** | ___/___/_____ |
| **Fecha de cierre** | ___/___/_____ |
| **Responsable** | [Nombre del estudiante] |
| **Asesor** | MC. Román Fernando López González |

## 1. Objetivo del ciclo
Implementar procesamiento asíncrono con Celery y Redis para:
correos transaccionales de confirmación de pedido, alertas de
stock bajo y reportes diarios automáticos vía Celery Beat.

## 2. Tareas realizadas

| # | Tarea | Estado | Semana |
|---|---|---|---|
| 1 | pip install celery redis flower | ✅ | W16 |
| 2 | core/celery.py + core/__init__.py | ✅ | W16 |
| 3 | CELERY_* en settings.py | ✅ | W16 |
| 4 | docker-compose: worker + flower | ✅ | W16 |
| 5 | ventas/tasks.py (2 tareas placeholder) | ✅ | W16 |
| 6 | pip install django-anymail | ✅ | W17 |
| 7 | Template confirmacion_pedido.html + .txt | ✅ | W17 |
| 8 | Template alerta_stock.html + .txt | ✅ | W17 |
| 9 | enviar_confirmacion_pedido: correo real + idempotencia | ✅ | W17 |
| 10 | verificar_stock_bajo: alerta al admin | ✅ | W17 |
| 11 | Template reporte_ventas.html + .txt | ✅ | W18 |
| 12 | reporte_ventas_diario con annotate + Sum(F()) | ✅ | W18 |
| 13 | CELERY_BEAT_SCHEDULE (crontab + timedelta) | ✅ | W18 |
| 14 | docker-compose: celery_beat | ✅ | W18 |

## 3. Evidencias
- Worker activo: `celery -A core worker` → tasks registradas
- Beat activo: `celery -A core beat` → schedule configurado
- Flower: http://localhost:5555 → workers online
- Tests: Ran 171 tests → OK
- Correo confirmación: enviado tras pago (idempotente)
- Alerta stock: enviada cuando stock < umbral
- Reporte: programado crontab(hour=8, minute=0)

## 4. Criterios de aceptación

| Criterio | Estado |
|---|---|
| Worker procesa enviar_confirmacion_pedido | ✅ |
| correo_enviado=True previene duplicados | ✅ |
| Alerta de stock enviada al admin | ✅ |
| reporte_ventas_diario en BEAT_SCHEDULE | ✅ |
| verificar_stock_bajo en BEAT_SCHEDULE | ✅ |
| 171 tests OK | ✅ |

## 5. Problemas encontrados
(completar durante la sesión)

## 6. Lecciones aprendidas
1.
2.
3.

## 7. Tiempo total invertido

| Categoría | Horas |
|---|---|
| Diseño | |
| Implementación | |
| Pruebas | |
| Documentación | |
| **Total Espiral 6** | |
```

---

## CIERRE — Commit Final [M6] y Respaldo (10 min)

### Actualizar `sprint5_planning.md`

```markdown
## Sprint 5 — Estado final W18

| HU | Estado | Pts |
|---|---|---|
| HU-E6-01 a HU-E6-06 | ✅ Completadas | 18/18 |

## Hito M6 — ALCANZADO ✅
- Worker: celery -A core worker → tareas procesadas
- Beat: celery -A core beat → schedule activo
- Correo: enviar_confirmacion_pedido → enviado post-pago
- Alerta: verificar_stock_bajo → correo al admin
- Reporte: crontab(8,0) → 8:00 AM diario
- Tests: Ran 171 tests → OK
- Fecha: ___/___/_____
```

### Commit final de la Espiral 6

```cmd
git add .
git status

:: Verificar que incluye:
::   ventas/tasks.py (con reporte_ventas_diario)
::   templates/emails/reporte_ventas.html + .txt
::   core/settings.py (CELERY_BEAT_SCHEDULE)
::   docker-compose.yml (celery_beat service)
::   tests/test_w18_beat.py
::   sprint5_retrospective.md
::   sprint5_planning.md (actualizado)
::   fichas/espiral_06_async.md

git commit -m "Sprint 5 CIERRE [M6]: Beat + reporte_diario + 171 tests OK + Ficha E6"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
:: Detener todos los procesos (Ctrl+C × 3 si hay 3 terminales)
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W18 — HITO M6

### Técnico

```
TAREA REPORTE DIARIO
[ ] ventas/tasks.py: reporte_ventas_diario(@shared_task)
[ ] Usa annotate + Sum(F('cantidad') * F('precio_unitario'))
[ ] Filtra pedidos de HOY con fecha_pedido__date=timezone.localdate()
[ ] Top 5 productos por ingreso del día
[ ] Envía correo a ADMINS[0] si está configurado
[ ] Devuelve dict con total_pedidos, total_facturado, top_productos

TEMPLATES
[ ] templates/emails/reporte_ventas.html con KPI grid y tabla top productos
[ ] templates/emails/reporte_ventas.txt (versión texto plano)
[ ] Ambos usan contexto con: fecha, config, total_pedidos,
    total_facturado, top_productos, url_admin

CELERY BEAT
[ ] CELERY_BEAT_SCHEDULE en settings.py
[ ] verificar_stock_bajo: timedelta(hours=1) con args=(5,)
[ ] reporte_ventas_diario: crontab(hour=8, minute=0)
[ ] CELERY_BEAT_TIMEZONE = TIME_ZONE
[ ] from datetime import timedelta al inicio de settings.py
[ ] from celery.schedules import crontab en settings.py

DOCKER COMPOSE
[ ] Servicio celery_beat agregado con correct command
[ ] depends_on redis + db
[ ] Solo UNA instancia (nunca escalar beat)

PROCESOS (verificación manual)
[ ] celery -A core beat -l info → muestra el schedule configurado
[ ] celery -A core worker -l info → ventas.reporte_ventas_diario registrada
[ ] reporte_ventas_diario.apply().get() → dict con totales
[ ] Flower → ambas tareas visibles en historial

TESTS
[ ] test tests.test_w18_beat → 8/8 OK
[ ] test tests → 171/171 OK acumulados
[ ] test_beat_schedule_tiene_* → nombres exactos en BEAT_SCHEDULE
[ ] test_reporte_usa_crontab → isinstance(..., crontab)
[ ] test_reporte_envia_correo → mail.outbox tiene 1 mensaje
[ ] test_reporte_sin_ventas → outbox tiene 1 mensaje (total=0)

SCRUM / SCHMELKES
[ ] sprint5_planning.md: 18/18 puntos entregados
[ ] sprint5_retrospective.md: 3 secciones + Kaizen + velocidad
[ ] fichas/espiral_06_async.md: 14 tareas completadas, criterios OK
[ ] Commit de cierre con etiqueta [M6]
[ ] git push → GitHub actualizado
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Arquitectura de Celery al cerrar Espiral 6

```
┌─────────────────────────────────────────────────────────────────┐
│ Django + Gunicorn (proceso web)                                 │
│                                                                 │
│  POST /catalogo/webhook/                                        │
│      → pedido.estado = 'pagado'                                 │
│      → enviar_confirmacion_pedido.delay(pk) ──────────────┐    │
│                                                           │    │
│  GET /catalogo/pago-exitoso/                              │    │
│      → _guardar_carrito({})                               │    │
│      → enviar_confirmacion_pedido.delay(pk) ──────────────┤    │
└───────────────────────────────────────────────────────────┼────┘
                                                            │
                ┌───────────────────────────────────────────▼────┐
                │ Redis (Broker — cola erp_django)                │
                │  Mensajes pendientes:                           │
                │  [enviar_confirmacion, reporte_diario, ...]     │
                └─────────┬───────────────────┬──────────────────┘
                           │                   │
          ┌────────────────▼──┐     ┌──────────▼────────────────┐
          │ Celery Worker     │     │ Celery Beat               │
          │ (lee la cola)     │     │ (programa tareas)         │
          │                   │     │                           │
          │ Ejecuta:          │     │ Cada hora:                │
          │ · enviar_conf...  │     │   verificar_stock_bajo.   │
          │ · verificar_stock │     │   delay(5)                │
          │ · reporte_diario  │     │                           │
          └──────────────────┘     │ 8:00 AM cada día:         │
                   │                │   reporte_ventas_diario.  │
                   ▼                │   delay()                 │
          Correo enviado ✉️         └───────────────────────────┘
          Stock alertado ⚠️
          Reporte generado 📊

Flower (:5555): monitorea workers + historial de tareas
```

---

## HILO CONDUCTOR → W19

**¿Qué cierra W18 / Espiral 6?**
La automatización completa del ERP: correos transaccionales, alertas
y reportes ejecutándose de forma autónoma. 171 tests verifican
cada pieza de la integración. Hito M6 declarado.

**¿Qué abre W19 / Espiral 7 / Sprint 6?**
Con todas las operaciones automatizadas, el siguiente paso es
**visualizar los datos**: un dashboard de KPIs con gráficas
en tiempo real usando Chart.js y consultas optimizadas con `annotate`.

**¿Qué necesita W19 de W18?**

| Artefacto de W18 | Uso en W19 |
|---|---|
| `reporte_ventas_diario` con `annotate` | El dashboard usa las mismas queries SQL pero en tiempo real |
| `Pedido.objects.filter(estado='pagado')` | El KPI de ventas del día usa este mismo filtro |
| Redis ya corriendo | W19 usará `cache.set/get` con Redis para cachear el dashboard |
| 171 tests pasando | W19 agrega tests de las vistas del dashboard |

**Tarea de investigación para W19:**
> Lee la documentación de Django sobre caché:
> `https://docs.djangoproject.com/en/4.2/topics/cache/`
>
> ¿Cómo se configura Redis como backend de caché en Django?
> ¿Qué diferencia hay entre `cache.set(key, value, timeout=300)`
> y el decorador `@cache_page(300)`?
> ¿Cuándo conviene cachear el resultado de una vista completa vs.
> cachear solo los datos de una consulta?

**Pregunta de reflexión:**
> "El `reporte_ventas_diario` usa `annotate` con `Sum(F(...))`.
> Si el administrador quiere ver este reporte en tiempo real
> desde el dashboard (no solo por correo), ¿debería llamarse
> a la tarea Celery o ejecutarse directamente en la vista?
> ¿Qué trade-off hay entre las dos opciones?"

---

## Referencia rápida de comandos W18

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO (terminal 1)
python manage.py check
python manage.py runserver

:: CELERY WORKER (terminal 2)
celery -A core worker -l info -Q erp_django

:: CELERY BEAT (terminal 3) — proceso separado
celery -A core beat -l info

:: ALTERNATIVA DESARROLLO (worker + beat juntos, terminal 2)
celery -A core worker -B -l info -Q erp_django

:: FLOWER (terminal 4)
celery -A core flower --port=5555

:: SHELL — ejecutar tareas inmediatamente para probar
python manage.py shell
>>> from ventas.tasks import reporte_ventas_diario, verificar_stock_bajo
>>> reporte_ventas_diario.apply().get()
>>> verificar_stock_bajo.apply(args=(100,)).get()

:: TESTS
python manage.py test tests.test_w18_beat --verbosity=2
python manage.py test tests --verbosity=0   (171 tests)

:: GIT
git add .
git commit -m "Sprint 5 CIERRE [M6]: descripción"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W18 · ERP Django*
*Espiral 6 Cierre · Sprint 5 Review + Retrospectiva · Hito M6*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*