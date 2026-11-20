# Guía de Laboratorio — W15
## ERP Django · Espiral 5 · Semana 15 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|S
| **Semana** | W15 de 24 |
| **Espiral** | E5 — E-commerce y Pagos |
| **Sprint Scrum** | Sprint 4 — Review + Retrospectiva |
| **Hito** | **★ M5: Pago de prueba en Stripe sandbox + pedido cambia a "pagado" + stock decrementado** |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 4 — Funcionalidades Avanzadas |
| **Hilo conductor** | "W14 cobró el pago. W15 lo confirma: el webhook cierra el ciclo de venta automáticamente." |

---

## Respuesta a la tarea de investigación de W14

> **¿Qué es `stripe.Webhook.construct_event()`?**
>
> Es la función que verifica que un webhook recibido realmente proviene
> de Stripe. Compara la firma del header `Stripe-Signature` con el
> payload usando el `STRIPE_WEBHOOK_SECRET`.
>
> ```python
> event = stripe.Webhook.construct_event(
>     payload    = request.body,            # bytes crudos del cuerpo HTTP
>     sig_header = request.META['HTTP_STRIPE_SIGNATURE'],
>     secret     = settings.STRIPE_WEBHOOK_SECRET
> )
> ```
>
> **¿Por qué es crítico verificar la firma?**
> Sin verificación, cualquier atacante puede enviar una petición POST
> a `/catalogo/webhook/` fingiendo ser Stripe, con un evento falso
> de `payment_intent.succeeded` para marcar un pedido como pagado
> sin haber pagado realmente.
>
> **¿Qué sucede si no hay firma válida?**
> `construct_event()` lanza `stripe.error.SignatureVerificationError`.
> La vista debe devolver HTTP 400 (Bad Request) para que Stripe sepa
> que el evento no fue procesado y no lo reintente.
>
> **¿Por qué el pedido queda en `pendiente` si el usuario cierra el navegador?**
> El `PaymentIntent` sigue activo en Stripe. Cuando Stripe confirma el pago
> (independientemente del cliente), envía el webhook `payment_intent.succeeded`.
> W15 procesa ese webhook y actualiza el pedido a `pagado` automáticamente,
> incluso si el usuario nunca llegó a `pago_exitoso`. Este es el patrón
> correcto: el webhook es la fuente de verdad del estado del pago.

---

## Objetivos de la sesión

Al terminar W15, el estudiante será capaz de:

1. Agregar `items_snapshot` al modelo `Pedido` y actualizar el checkout
2. Implementar el endpoint de webhook con verificación de firma Stripe
3. Procesar eventos `payment_intent.succeeded` y `payment_intent.payment_failed`
4. Decrementar el stock de productos usando expresiones `F()` para evitar
   race conditions
5. Probar el webhook con la CLI de Stripe en modo local
6. Ejecutar el Sprint 4 Review y declarar el Hito M5

---

## Stack tecnológico de W15

| Herramienta | Novedad en W15 | Descripción |
|---|---|---|
| `JSONField` (Django) | ✅ Nuevo | Campo para almacenar el snapshot del carrito en el Pedido |
| `@csrf_exempt` | ✅ Nuevo | Excluye el endpoint de webhook del middleware CSRF |
| `@require_POST` | ✅ Nuevo | Rechaza peticiones que no sean POST con HTTP 405 |
| `stripe.Webhook.construct_event` | ✅ Nuevo | Verifica firma criptográfica del webhook |
| Expresión `F()` Django | ✅ Nuevo | Actualización atómica del stock sin race conditions |
| Stripe CLI | ✅ Nuevo | Herramienta para reenviar webhooks de Stripe en local |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar W14 | 10 min |
| Parte 1 | `items_snapshot` en `Pedido` + migración + actualizar checkout | 20 min |
| Parte 2 | Endpoint webhook (`/catalogo/webhook/`) | 30 min |
| Parte 3 | Lógica de descuento de stock con `F()` | 15 min |
| Parte 4 | URLs + prueba con Stripe CLI | 15 min |
| Parte 5 | Tests W15 (8 pruebas con mock) | 20 min |
| **Commit parcial** | Punto de control seguro | 5 min |
| Parte 6 | Sprint 4 Review ante el asesor | 20 min |
| Parte 7 | Sprint 4 Retrospectiva + Ficha Schmelkes E5 | 20 min |
| Cierre | Commit final [M5] · `finalizar_sesion.bat` · hilo → W16 | 10 min |
| Buffer | | 15 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W14?
   → Implementé el checkout con Stripe: creación de PaymentIntent,
     template con Stripe.js Card Element y vistas de éxito/error.

2. ¿Qué haré en W15?
   → Implementaré el endpoint webhook que recibe confirmaciones de
     Stripe, actualiza el estado del pedido y descuenta el stock.
     Cerraré el Sprint 4 con M5.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 139 tests … OK`

---

## PARTE 1 — `items_snapshot` en `Pedido` + Migración (20 min)

### 1.1 ¿Por qué necesitamos `items_snapshot`?

```
Flujo sin items_snapshot:
  1. Usuario agrega al carrito → sesión
  2. POST checkout → Pedido creado + carrito en sesión
  3. pago_exitoso() → carrito ELIMINADO de la sesión
  4. Webhook fires → ¿cómo saber qué productos descuentar?
  5. ❌ Sin información de los items → imposible decrementar stock

Flujo con items_snapshot:
  1. POST checkout → Pedido creado + items_snapshot = copia del carrito
  2. pago_exitoso() → carrito eliminado de sesión (items_snapshot intacto en BD)
  3. Webhook fires → lee Pedido.items_snapshot → decrementa stock ✅
```

---

### 1.2 Agregar `items_snapshot` al modelo `Pedido`

Abrir `ventas/models.py` y agregar el campo a la clase `Pedido`:

```python
# ventas/models.py — en la clase Pedido, agregar después de total_pagado:

    items_snapshot = models.JSONField(
        default=list,
        blank=True,
        verbose_name='Snapshot de items del carrito',
        help_text=(
            'Copia del carrito al momento de crear el pedido. '
            'Estructura: [{"producto_id": 1, "nombre": "...", '
            '"cantidad": 2, "precio": "500.00"}]'
        )
    )
```

La clase `Pedido` queda con este campo adicional al final de los atributos,
antes de `class Meta`.

---

### 1.3 Crear la migración

```cmd
python manage.py makemigrations ventas --name items_snapshot_pedido
```

**Resultado esperado:**
```
Migrations for 'ventas':
  ventas/migrations/0003_items_snapshot_pedido.py
    - Add field items_snapshot to pedido
```

```cmd
python manage.py migrate
```

```cmd
python manage.py showmigrations ventas
```

**Resultado esperado:**
```
ventas
 [X] 0001_initial
 [X] 0002_validators_pedido
 [X] 0003_items_snapshot_pedido
```

---

### 1.4 Actualizar `checkout()` en `catalogo/views.py`

En la función `checkout()`, después de crear el `Pedido` y antes de
crear el `PaymentIntent`, guardar el snapshot del carrito:

```python
# catalogo/views.py — en la función checkout(), sección POST:
# Reemplazar la línea de creación del Pedido:

            # ── 2. Crear el Pedido con snapshot del carrito ────────────
            numero = generar_numero_pedido()

            # Construir el snapshot: lista de dicts serializables
            snapshot = [
                {
                    'producto_id': int(prod_id),
                    'nombre':      datos['nombre'],
                    'cantidad':    int(datos['cantidad']),
                    'precio':      datos['precio'],   # ya es str
                }
                for prod_id, datos in carrito.items()
            ]

            pedido = Pedido.objects.create(
                numero_pedido  = numero,
                cliente        = cliente,
                estado         = 'pendiente',
                total_pagado   = totales['total'],
                items_snapshot = snapshot,           # ← nuevo
            )
```

---

### 1.5 Verificar

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

---

## PARTE 2 — Endpoint Webhook (30 min)

### 2.1 ¿Por qué `@csrf_exempt` en el webhook?

```
Django CSRF: el cliente debe enviar un token único en cada POST.
→ Funciona para formularios web porque el servidor genera el token
  y el navegador lo envía.

Stripe webhook: es un servidor externo que hace POST a nuestro endpoint.
→ Stripe NO puede obtener un token CSRF de Django.
→ Sin @csrf_exempt → Django rechaza todos los webhooks → HTTP 403.
→ La seguridad la provee la verificación de firma (construct_event).
```

---

### 2.2 Crear `catalogo/webhook_views.py`

Separar el webhook en su propio archivo para mantener `views.py` legible:

```python
# catalogo/webhook_views.py
"""Endpoint de webhook para recibir eventos de Stripe — W15.

Verificación de seguridad:
    Stripe firma cada evento con STRIPE_WEBHOOK_SECRET.
    stripe.Webhook.construct_event() verifica la firma.
    Si la firma es inválida → 400 (Stripe no reintenta).
    Si la firma es válida → procesar el evento → 200.

Eventos manejados:
    payment_intent.succeeded     → Pedido.estado = 'pagado'
                                    Descontar stock de productos
    payment_intent.payment_failed → Pedido.estado = 'cancelado'
"""
import logging

import stripe
from django.conf import settings
from django.db.models import F
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from productos.models import Producto
from ventas.models    import Pedido

logger = logging.getLogger(__name__)


@csrf_exempt
@require_POST
def stripe_webhook(request) -> HttpResponse:
    """Recibe y procesa eventos de Stripe.

    Flujo:
        1. Leer payload crudo (bytes) y header de firma.
        2. Verificar firma con STRIPE_WEBHOOK_SECRET.
        3. Despachar al handler del tipo de evento.
        4. Retornar 200 (éxito) o 400 (firma inválida).

    Args:
        request: HttpRequest con cuerpo raw y header Stripe-Signature.

    Returns:
        HttpResponse: 200 si el evento fue procesado correctamente,
                      400 si la firma es inválida o el payload es inválido.
    """
    payload    = request.body
    sig_header = request.META.get('HTTP_STRIPE_SIGNATURE', '')

    # ── 1. Verificar firma ─────────────────────────────────────────────────
    try:
        event = stripe.Webhook.construct_event(
            payload    = payload,
            sig_header = sig_header,
            secret     = settings.STRIPE_WEBHOOK_SECRET,
        )
    except ValueError:
        # Payload malformado (no es JSON válido)
        logger.warning('Webhook: payload inválido recibido.')
        return HttpResponse('Payload inválido.', status=400)
    except stripe.error.SignatureVerificationError:
        # Firma inválida — posible intento de falsificación
        logger.warning('Webhook: firma inválida — posible ataque.')
        return HttpResponse('Firma inválida.', status=400)

    # stripe >= 15 devuelve StripeObject, que ya NO es un dict
    # (no tiene .get()). Lo convertimos a dict nativo de Python.
    if hasattr(event, 'to_dict'):
        event = event.to_dict()

    # ── 2. Despachar por tipo de evento ────────────────────────────────────
    tipo = event['type']
    logger.info(f'Webhook recibido: {tipo}')

    if tipo == 'payment_intent.succeeded':
        _manejar_pago_exitoso(event['data']['object'])

    elif tipo == 'payment_intent.payment_failed':
        _manejar_pago_fallido(event['data']['object'])

    else:
        logger.debug(f'Evento ignorado: {tipo}')

    # Siempre retornar 200 para eventos que no necesitamos
    # (Stripe reintentará si recibe 4xx o 5xx)
    return HttpResponse(status=200)


# ── HANDLERS INTERNOS ──────────────────────────────────────────────────────

def _manejar_pago_exitoso(payment_intent: dict) -> None:
    """Procesa un pago confirmado por Stripe.

    Actualiza el Pedido a 'pagado' y descuenta el stock de productos.

    Args:
        payment_intent: objeto PaymentIntent del evento de Stripe.
    """
    pedido_id = _extraer_pedido_id(payment_intent)
    if pedido_id is None:
        return

    try:
        pedido = Pedido.objects.get(pk=pedido_id)
    except Pedido.DoesNotExist:
        logger.error(f'Webhook: Pedido {pedido_id} no encontrado en BD.')
        return

    # Actualizar estado del pedido
    if pedido.estado != 'pagado':
        pedido.estado = 'pagado'
        pedido.save(update_fields=['estado'])
        logger.info(
            f'Pedido {pedido.numero_pedido} actualizado a "pagado".'
        )

        # Descontar stock de cada producto del snapshot
        _descontar_stock(pedido)
    else:
        logger.info(
            f'Pedido {pedido.numero_pedido} ya estaba pagado — '
            f'idempotente, sin cambios.'
        )


def _manejar_pago_fallido(payment_intent: dict) -> None:
    """Procesa un pago fallido o rechazado.

    Actualiza el Pedido a 'cancelado'.

    Args:
        payment_intent: objeto PaymentIntent del evento de Stripe.
    """
    pedido_id = _extraer_pedido_id(payment_intent)
    if pedido_id is None:
        return

    try:
        pedido = Pedido.objects.get(pk=pedido_id)
    except Pedido.DoesNotExist:
        logger.error(f'Webhook: Pedido {pedido_id} no encontrado.')
        return

    if pedido.estado == 'pendiente':
        pedido.estado = 'cancelado'
        pedido.save(update_fields=['estado'])
        logger.info(
            f'Pedido {pedido.numero_pedido} cancelado por pago fallido.'
        )


def _extraer_pedido_id(payment_intent: dict) -> int | None:
    """Extrae el pedido_id del metadata del PaymentIntent.

    Args:
        payment_intent: objeto PaymentIntent de Stripe.

    Returns:
        int con el ID del pedido, o None si no está en el metadata.
    """
    metadata  = payment_intent.get('metadata', {})
    pedido_id = metadata.get('pedido_id')

    if not pedido_id:
        logger.warning(
            f'Webhook: PaymentIntent sin pedido_id en metadata. '
            f'ID de PaymentIntent: {payment_intent.get("id")}'
        )
        return None

    try:
        return int(pedido_id)
    except (ValueError, TypeError):
        logger.error(f'Webhook: pedido_id inválido: {pedido_id!r}')
        return None


def _descontar_stock(pedido: 'Pedido') -> None:
    """Descuenta el stock de los productos del pedido.

    Usa expresiones F() para actualizar el stock de forma atómica,
    evitando race conditions cuando múltiples webhooks llegan
    simultáneamente.

    Args:
        pedido: instancia de Pedido con items_snapshot cargado.
    """
    items = pedido.items_snapshot or []

    for item in items:
        producto_id = item.get('producto_id')
        cantidad    = int(item.get('cantidad', 0))

        if not producto_id or cantidad <= 0:
            continue

        # F('stock') - cantidad: actualización atómica en la BD
        # Evita leer el stock actual en Python (race condition)
        filas_actualizadas = Producto.objects.filter(
            pk=producto_id,
            stock__gte=cantidad    # solo si hay stock suficiente
        ).update(
            stock=F('stock') - cantidad
        )

        if filas_actualizadas:
            logger.info(
                f'Stock decrementado: Producto {producto_id} '
                f'- {cantidad} unidades.'
            )
        else:
            logger.warning(
                f'Producto {producto_id}: stock insuficiente para '
                f'decrementar {cantidad} unidades.'
            )
```

> ⚠️ **Importante — `event.to_dict()` (stripe 16.x)**
>
> Desde stripe-python 15, `construct_event()` devuelve un `StripeObject`
> que **ya no hereda de `dict`**: no tiene `.get()`. Sin la conversión,
> `payment_intent.get('metadata', {})` lanza
> `AttributeError: 'get' is a dict method, but a PaymentIntent is not a dict`
> → Django responde **HTTP 500** → el pedido se queda en `pendiente`
> y el stock no se descuenta.
>
> Los tests con `mock` no detectan el error si simulan el evento con un
> `dict` normal; por eso en 4.1 se agrega un test con un `StripeObject` real.

---

### 2.3 ¿Qué es la expresión `F()` y por qué es necesaria?

```python
# ❌ SIN F() — race condition posible:
producto = Producto.objects.get(pk=1)
producto.stock -= 2      # Python lee el valor actual
producto.save()          # si otro webhook llega simultáneamente,
                         # ambos leen stock=10 y lo dejan en 8
                         # en lugar de 6

# ✅ CON F() — actualización atómica en la BD:
Producto.objects.filter(pk=1).update(
    stock=F('stock') - 2   # La BD ejecuta: UPDATE SET stock = stock - 2
)                           # Es atómico: no importa cuántos webhooks lleguen
```

---

## PARTE 3 — URLs del Webhook (15 min)

### 3.1 Actualizar `catalogo/urls.py`

```python
# catalogo/urls.py — agregar la URL del webhook:
from django.urls import path

from . import views
from .webhook_views import stripe_webhook

app_name = 'catalogo'

urlpatterns = [
    # Catálogo público
    path('', views.CatalogoView.as_view(), name='catalogo'),

    # Carrito (W13)
    path('carrito/',                              views.ver_carrito,        name='carrito'),
    path('carrito/agregar/<int:producto_id>/',    views.agregar_al_carrito, name='agregar'),
    path('carrito/remover/<int:producto_id>/',    views.remover_del_carrito,name='remover'),
    path('carrito/actualizar/<int:producto_id>/', views.actualizar_cantidad, name='actualizar'),
    path('carrito/vaciar/',                       views.vaciar_carrito,     name='vaciar'),

    # Checkout con Stripe (W14)
    path('checkout/',                   views.checkout,    name='checkout'),
    path('pago-exitoso/<int:pedido_id>/', views.pago_exitoso, name='pago_exitoso'),
    path('pago-error/',                 views.pago_error,  name='pago_error'),

    # Webhook de Stripe (W15)
    path('webhook/', stripe_webhook, name='webhook'),
]
```

---

### 3.2 Probar con Stripe CLI (modo local)

La CLI de Stripe reenvía los eventos de Stripe a tu servidor local.
Sin ella, Stripe no puede hacer POST a `localhost`.

**Instalar Stripe CLI:**

```cmd
:: Windows: descargar el .exe desde https://stripe.com/docs/stripe-cli
:: Agregar al PATH o ejecutar desde la carpeta de descarga
stripe version
```

**Escuchar y reenviar webhooks:**

```cmd
:: En una terminal separada (con el servidor Django activo):
stripe listen --forward-to http://127.0.0.1:8000/catalogo/webhook/
```

**Resultado esperado:**
```
> Ready! Your webhook signing secret is whsec_xxxxxxxxxxxxx
> (^C to quit)
```

Copiar `whsec_xxxxxxxxxxxxx` y pegarlo en `.env`:
```bash
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
```

**Prueba de extremo a extremo:**

```
1. En otra terminal: python manage.py runserver
2. Stripe CLI escuchando en una tercera terminal
3. Ir a /catalogo/ → agregar producto → checkout
4. Ingresar tarjeta 4242 4242 4242 4242 · 12/26 · 123
5. Confirmar pago
6. En la terminal de Stripe CLI debe aparecer:
   2025-01-15 18:30:01 --> payment_intent.succeeded [evt_xxx]
   2025-01-15 18:30:01 <-- [200] POST http://127.0.0.1:8000/catalogo/webhook/
7. Verificar en /admin/ que el Pedido cambió a 'pagado'
8. Verificar que el stock del producto decrementó
```

---

### 3.3 Configurar webhook en Render.com (producción)

0. **Obtener TU URL de Render:** Render → tu servicio → URL bajo el nombre.
   Si el nombre ya estaba ocupado, Render agrega un sufijo
   (ej. `https://erp-django-utec-web.onrender.com`). **No copies la URL de
   otro compañero ni la de esta guía.**
   Prueba: abrir `https://TU-URL.onrender.com/catalogo/webhook/` en el
   navegador → debe responder **405** (solo acepta POST). Si responde
   **404**, la URL está mal.
1. Ir a `dashboard.stripe.com` y **activar Modo de prueba / Sandbox**
   (el mismo entorno de tus claves `sk_test_` / `pk_test_`).
   Un endpoint creado en modo *live* nunca recibe eventos de prueba.
2. Desarrolladores → Webhooks → **Agregar endpoint**
3. URL del endpoint: `https://TU-URL.onrender.com/catalogo/webhook/`
   (con `https`, con `/catalogo/` y con `/` final)
4. Seleccionar eventos:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
5. Clic en **Agregar endpoint**
6. En la página del webhook → copiar **Signing secret** (`whsec_...`)
7. Agregarlo a las variables de entorno de Render y guardar (redeploy):
   `STRIPE_WEBHOOK_SECRET = whsec_xxxxxxxxxxxxxxxx`

> ⚠️ El `whsec_` de `stripe listen` (3.2) **solo sirve en local**.
> En Render usa el *Signing secret* del endpoint del Dashboard.

**Verificación:** realizar un pago con `4242 4242 4242 4242` → Stripe →
Webhooks → tu endpoint → *Entregas de eventos* → debe mostrar **200**.
Si un evento falló, corrige y usa **Reenviar**: no hace falta volver a pagar.

| Respuesta en Stripe | Causa | Solución |
|---|---|---|
| **404** (`x-render-routing: no-server`) | La URL no es tu servicio | Copiar la URL exacta desde Render |
| **400** "Firma inválida" | `STRIPE_WEBHOOK_SECRET` incorrecto (p. ej. el de la CLI) | Copiar el *Signing secret* del endpoint |
| **500** "Server Error" | Error en el código (ver nota `to_dict()` en 2.2) | Revisar *Logs* de Render |
| Timeout | Render free estaba dormido | Stripe reintenta solo o usar **Reenviar** |
| Sin entregas | Endpoint creado en modo *live* | Crearlo en modo de prueba / Sandbox |

---

## PARTE 4 — Tests W15 (20 min)

### 4.1 Crear `tests/test_w15_webhooks.py`

```python
"""Suite de pruebas W15 — Webhook de Stripe y lógica de pedidos.

Usa unittest.mock.patch para simular stripe.Webhook.construct_event
sin requerir claves reales ni conexión a Stripe.

Ejecutar con:
    python manage.py test tests.test_w15_webhooks --verbosity=2

Resultado esperado:
    Ran 8 tests in X.XXXs
    OK
"""
import json
from decimal import Decimal
from unittest.mock import MagicMock, patch

from django.test import TestCase
from django.urls import reverse

from clientes.models    import Cliente
from configuracion.models import ConfiguracionERP
from productos.models   import Categoria, Producto
from ventas.models      import Pedido


def _crear_evento(tipo: str, pedido_id: int) -> dict:
    """Construye un evento Stripe simulado para tests."""
    return {
        'type': tipo,
        'data': {
            'object': {
                'id':       f'pi_test_{pedido_id}',
                'amount':   116000,
                'currency': 'mxn',
                'status':   'succeeded' if 'succeeded' in tipo else 'failed',
                'metadata': {'pedido_id': str(pedido_id)},
            }
        }
    }


def _crear_pedido_con_snapshot(cliente, producto, cantidad=2) -> Pedido:
    """Crea un Pedido con items_snapshot para los tests."""
    return Pedido.objects.create(
        numero_pedido  = 'PED-2025-TEST',
        cliente        = cliente,
        estado         = 'pendiente',
        total_pagado   = Decimal('1000.00'),
        items_snapshot = [
            {
                'producto_id': producto.pk,
                'nombre':      producto.nombre,
                'cantidad':    cantidad,
                'precio':      str(producto.precio),
            }
        ]
    )


class WebhookSegurityTest(TestCase):
    """Tests de seguridad del endpoint webhook."""

    def test_get_rechazado_con_405(self):
        """El webhook solo acepta POST → GET devuelve 405."""
        r = self.client.get(reverse('catalogo:webhook'))
        self.assertEqual(r.status_code, 405)

    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_firma_invalida_devuelve_400(self, mock_construct):
        """Firma inválida → 400 Bad Request."""
        import stripe
        mock_construct.side_effect = stripe.error.SignatureVerificationError(
            'Test error', 'sig_header'
        )
        r = self.client.post(
            reverse('catalogo:webhook'),
            data=b'{"fake": "payload"}',
            content_type='application/json',
            HTTP_STRIPE_SIGNATURE='t=fake,v1=invalid'
        )
        self.assertEqual(r.status_code, 400)

    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_payload_invalido_devuelve_400(self, mock_construct):
        """Payload malformado → 400 Bad Request."""
        mock_construct.side_effect = ValueError('JSON inválido')
        r = self.client.post(
            reverse('catalogo:webhook'),
            data=b'no es json',
            content_type='application/json',
            HTTP_STRIPE_SIGNATURE='t=123,v1=abc'
        )
        self.assertEqual(r.status_code, 400)


class WebhookPagoExitosoTest(TestCase):
    """Tests del manejo de payment_intent.succeeded."""

    def setUp(self):
        ConfiguracionERP.get_instance()
        cat         = Categoria.objects.create(nombre='Cat')
        self.prod   = Producto.objects.create(
            nombre='P', precio=Decimal('500.00'), stock=10, categoria=cat
        )
        self.cli    = Cliente.objects.create(nombre='C', correo='c@t.com')
        self.pedido = _crear_pedido_con_snapshot(
            self.cli, self.prod, cantidad=2
        )

    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_payment_succeeded_actualiza_estado(self, mock_construct):
        """payment_intent.succeeded → Pedido.estado cambia a 'pagado'."""
        mock_construct.return_value = _crear_evento(
            'payment_intent.succeeded', self.pedido.pk
        )
        r = self.client.post(
            reverse('catalogo:webhook'),
            data=b'{}',
            content_type='application/json',
            HTTP_STRIPE_SIGNATURE='t=123,v1=ok'
        )
        self.assertEqual(r.status_code, 200)
        self.pedido.refresh_from_db()
        self.assertEqual(self.pedido.estado, 'pagado')

    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_payment_succeeded_descuenta_stock(self, mock_construct):
        """payment_intent.succeeded → stock decrementado en 2 unidades."""
        stock_inicial = self.prod.stock   # 10
        mock_construct.return_value = _crear_evento(
            'payment_intent.succeeded', self.pedido.pk
        )
        self.client.post(
            reverse('catalogo:webhook'),
            data=b'{}',
            content_type='application/json',
            HTTP_STRIPE_SIGNATURE='t=123,v1=ok'
        )
        self.prod.refresh_from_db()
        self.assertEqual(self.prod.stock, stock_inicial - 2)

    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_payment_succeeded_idempotente(self, mock_construct):
        """Segundo webhook del mismo pago → estado no cambia (idempotente)."""
        self.pedido.estado = 'pagado'
        self.pedido.save()
        stock_antes = self.prod.stock

        mock_construct.return_value = _crear_evento(
            'payment_intent.succeeded', self.pedido.pk
        )
        self.client.post(
            reverse('catalogo:webhook'),
            data=b'{}',
            content_type='application/json',
            HTTP_STRIPE_SIGNATURE='t=123,v1=ok'
        )
        self.prod.refresh_from_db()
        # El stock no debe cambiar porque ya estaba pagado
        self.assertEqual(self.prod.stock, stock_antes)


class WebhookPagoFallidoTest(TestCase):
    """Tests del manejo de payment_intent.payment_failed."""

    def setUp(self):
        cat         = Categoria.objects.create(nombre='Cat')
        prod        = Producto.objects.create(
            nombre='P', precio=Decimal('100.00'), stock=5, categoria=cat
        )
        cli         = Cliente.objects.create(nombre='C', correo='c2@t.com')
        self.pedido = _crear_pedido_con_snapshot(cli, prod)

    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_payment_failed_cancela_pedido(self, mock_construct):
        """payment_intent.payment_failed → Pedido.estado = 'cancelado'."""
        mock_construct.return_value = _crear_evento(
            'payment_intent.payment_failed', self.pedido.pk
        )
        r = self.client.post(
            reverse('catalogo:webhook'),
            data=b'{}',
            content_type='application/json',
            HTTP_STRIPE_SIGNATURE='t=123,v1=ok'
        )
        self.assertEqual(r.status_code, 200)
        self.pedido.refresh_from_db()
        self.assertEqual(self.pedido.estado, 'cancelado')


class WebhookStripeObjectTest(TestCase):
    """Regresión: con stripe >= 15 el evento real es un StripeObject
    (no un dict). Antes provocaba HTTP 500 en producción."""

    def setUp(self):
        cat         = Categoria.objects.create(nombre='Cat')
        self.prod   = Producto.objects.create(
            nombre='P', precio=Decimal('500.00'), stock=10, categoria=cat
        )
        cli         = Cliente.objects.create(nombre='C', correo='c3@t.com')
        self.pedido = _crear_pedido_con_snapshot(cli, self.prod, cantidad=2)

    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_evento_stripe_object_real(self, mock_construct):
        """StripeObject real → 200, pedido 'pagado' y stock descontado."""
        import stripe
        datos = _crear_evento('payment_intent.succeeded', self.pedido.pk)
        datos['data']['object']['object'] = 'payment_intent'
        datos.update({'id': 'evt_test', 'object': 'event'})
        mock_construct.return_value = stripe.Event.construct_from(datos, 'sk_test')

        r = self.client.post(
            reverse('catalogo:webhook'),
            data=b'{}',
            content_type='application/json',
            HTTP_STRIPE_SIGNATURE='t=123,v1=ok'
        )
        self.assertEqual(r.status_code, 200)
        self.pedido.refresh_from_db()
        self.prod.refresh_from_db()
        self.assertEqual(self.pedido.estado, 'pagado')
        self.assertEqual(self.prod.stock, 8)
```

### 4.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w15_webhooks --verbosity=2
```

**Resultado esperado:**
```
test_firma_invalida_devuelve_400 ... ok
test_get_rechazado_con_405 ... ok
test_payload_invalido_devuelve_400 ... ok
test_payment_failed_cancela_pedido ... ok
test_payment_succeeded_actualiza_estado ... ok
test_payment_succeeded_descuenta_stock ... ok
test_payment_succeeded_idempotente ... ok
test_evento_stripe_object_real ... ok

Ran 8 tests in X.XXXs
OK
```

### 4.3 Suite acumulada — Hito M5

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 147 tests in X.XXXs · OK` (139 + 8)

### COMMIT PARCIAL

```cmd
git add .
git commit -m "Sprint 4 W15: webhook Stripe + stock F() + 147 tests OK [pre-M5]"
```

---

## PARTE 5 — Sprint 4 Review ante el asesor (20 min)

### Guión de demo (≤ 10 min en vivo)

```
1. Mostrar el catálogo público (sin login):
   → /catalogo/ → tarjetas de productos con imágenes y precios
   → Filtrar por categoría → solo muestra los correctos

2. Demostrar el ciclo de compra completo:
   → Agregar 2 productos al carrito
   → /catalogo/carrito/ → items + total + IVA
   → Login → /catalogo/checkout/ → Click "Proceder"
   → Card Element aparece
   → Ingresar 4242 4242 4242 4242 · 12/26 · 123
   → "Confirmar pago" → procesando... → ✅ Pago exitoso

3. Verificar el webhook (con Stripe CLI activo):
   → En la terminal de Stripe CLI:
     --> payment_intent.succeeded [evt_xxx]
     <-- [200] POST .../catalogo/webhook/
   → En /admin/ → Pedidos → el pedido cambió de "pendiente" a "pagado"
   → Stock del producto decrementó

4. Demostrar el manejo de pago rechazado:
   → Nueva compra con tarjeta 4000 0000 0000 9995 (fondos insuficientes)
   → Error mostrado en el Card Element
   → Pedido queda en "cancelado" (vía webhook payment_failed)

5. Mostrar los tests:
   → python manage.py test tests --verbosity=0
   → Ran 147 tests … OK

6. Declarar Sprint Goal y Hito M5 verificados:
   → "Pago de prueba en Stripe sandbox completado"
   → "Pedido cambia de 'pendiente' a 'pagado' automáticamente"
   → "Stock decrementado correctamente"
   → Estado: ✅ HITO M5 ALCANZADO
```

### Tabla de verificación M5

| Criterio | Estado |
|---|---|
| GET /catalogo/ sin auth → catálogo visible | ✅ |
| Filtros por nombre, categoría, precio | ✅ |
| Carrito: agregar, remover, actualizar, vaciar | ✅ |
| POST /catalogo/checkout/ → Pedido + PaymentIntent | ✅ |
| Tarjeta 4242 → pago exitoso → pago_exitoso.html | ✅ |
| Webhook recibido → Pedido.estado = 'pagado' | ✅ |
| Stock decrementado con expresión F() | ✅ |
| Firma inválida → webhook devuelve 400 | ✅ |
| 147 tests acumulados OK | ✅ |

---

## PARTE 6 — Sprint 4 Retrospectiva + Ficha Schmelkes E5 (20 min)

### 6.1 Crear `sprint4_retrospective.md`

```markdown
# Sprint 4 Retrospective — ERP Django
## Semanas W13–W15 · Espiral 5: E-commerce y Pagos

**Fecha:** ___/___/_____

## ¿Qué funcionó bien? (Keep)
1. items_snapshot en el Pedido resolvió elegantemente el problema
   de recuperar los items del carrito después de que la sesión
   fue limpiada.
2. La expresión F() garantizó que el stock nunca quede en negativo
   con múltiples webhooks simultáneos.
3. unittest.mock.patch permitió testear el webhook sin claves reales.

## ¿Qué mejorar? (Improve)
1. El template de checkout podría mostrar un loader más visible
   durante el procesamiento de pago.
2. Documentar el flujo de webhooks en el diagrama de arquitectura.

## Acción de mejora (Kaizen) para Sprint 5
> "En el Sprint 5 (Celery), crearé primero el test que verifica
>  que el correo se envía ANTES de implementar la tarea asíncrona."

## Velocidad del Sprint 4

| HU | Pts plan. | Pts ent. |
|---|---|---|
| HU-E5-01 Catálogo sin registro | 2 | 2 |
| HU-E5-02 Filtrar por categoría/precio | 3 | 3 |
| HU-E5-03 Agregar al carrito | 3 | 3 |
| HU-E5-04 Ver contenido del carrito | 2 | 2 |
| HU-E5-05 Checkout con datos del cliente | 3 | 3 |
| HU-E5-06 Pago con Stripe sandbox | 5 | 5 |
| HU-E5-07 Confirmar pago vía webhook | 5 | 5 |
| HU-E5-08 Descontar stock al confirmar | 3 | 3 |
| **Total** | **26** | **26** |

**Velocidad Sprint 4:** 26 puntos
**Velocidad acumulada (S0–S4):** 105 puntos
```

---

### 6.2 Crear `fichas/espiral_05_ecommerce.md`

```markdown
# Ficha de Sistematización — Espiral 5
## ERP Django · Espiral E5: E-commerce y Pagos

| Campo | Contenido |
|---|---|
| **Número de espiral** | 5 |
| **Nombre del ciclo** | E-commerce y Pagos |
| **Semanas** | W13 – W15 |
| **Fecha de inicio** | ___/___/_____ |
| **Fecha de cierre** | ___/___/_____ |
| **Responsable** | [Nombre del estudiante] |
| **Asesor** | MC. Román Fernando López González |

## 1. Objetivo del ciclo
Implementar el canal de e-commerce completo: catálogo público filtrable,
carrito de compras en sesión, proceso de pago con Stripe y confirmación
automática vía webhook con descuento de stock.

## 2. Tareas realizadas

| # | Tarea | Estado | Semana |
|---|---|---|---|
| 1 | App catalogo + django-filter | ✅ | W13 |
| 2 | CatalogoView pública con filtros | ✅ | W13 |
| 3 | Carrito en sesión (5 vistas) | ✅ | W13 |
| 4 | Context processor carrito_info | ✅ | W13 |
| 5 | Templates catálogo + carrito | ✅ | W13 |
| 6 | pip install stripe | ✅ | W14 |
| 7 | CheckoutView con PaymentIntent | ✅ | W14 |
| 8 | Template checkout.html con Stripe.js | ✅ | W14 |
| 9 | pago_exitoso + pago_error | ✅ | W14 |
| 10 | items_snapshot en Pedido + migración 0003 | ✅ | W15 |
| 11 | Webhook endpoint con verificación de firma | ✅ | W15 |
| 12 | Descuento de stock con F() | ✅ | W15 |
| 13 | Tests con mock (Stripe + webhook) | ✅ | W15 |

## 3. Evidencias
- URL catálogo: https://erp-django-utec.onrender.com/catalogo/
- Webhook Stripe configurado en dashboard
- Tests: Ran 147 tests → OK
- Pedido 'pendiente' → 'pagado' via webhook verificado en /admin/
- Stock decrementado verificado en /admin/productos/

## 4. Criterios de aceptación

| Criterio | Estado |
|---|---|
| GET /catalogo/ sin auth → 200 | ✅ |
| Filtro por nombre/categoría/precio | ✅ |
| Agregar/remover/actualizar carrito | ✅ |
| Tarjeta 4242 → pago exitoso | ✅ |
| Webhook payment_intent.succeeded → Pedido 'pagado' | ✅ |
| Stock decrementado con F() (atómico) | ✅ |
| Firma inválida → 400 | ✅ |
| 147 tests OK | ✅ |

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
| **Total Espiral 5** | |
```

---

## CIERRE — Commit Final [M5] y Respaldo (10 min)

### Actualizar `sprint4_planning.md`

```markdown
## Sprint 4 — Estado final W15

| HU | Estado | Pts |
|---|---|---|
| HU-E5-01 a HU-E5-08 | ✅ Completadas | 26/26 |

## Hito M5 — ALCANZADO ✅
- Catálogo: /catalogo/ → 200 sin auth con filtros
- Carrito: agregar/remover/actualizar/vaciar funcional
- Stripe: tarjeta 4242 → pago exitoso → pedido 'pagado'
- Webhook: payment_intent.succeeded → stock decrementado
- Tests: Ran 147 tests → OK
- Fecha: ___/___/_____
```

### Commit final de la Espiral 5

```cmd
git add .
git status

:: Verificar que incluye:
::   ventas/migrations/0003_items_snapshot_pedido.py
::   ventas/models.py (con items_snapshot)
::   catalogo/views.py (checkout actualizado con snapshot)
::   catalogo/webhook_views.py (nuevo)
::   catalogo/urls.py (con webhook)
::   tests/test_w15_webhooks.py
::   sprint4_retrospective.md
::   sprint4_planning.md (actualizado)
::   fichas/espiral_05_ecommerce.md

git commit -m "Sprint 4 CIERRE [M5]: webhook + stock F() + 147 tests OK + Ficha E5"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W15 — HITO M5

### Técnico

```
MODELO Y MIGRACIÓN
[ ] ventas/models.py: Pedido.items_snapshot = JSONField(default=list)
[ ] ventas/migrations/0003_items_snapshot_pedido.py creada y aplicada
[ ] showmigrations ventas → [X] 0003
[ ] checkout() en views.py: construye snapshot y lo pasa a Pedido.create()

WEBHOOK ENDPOINT
[ ] catalogo/webhook_views.py: stripe_webhook con @csrf_exempt y @require_POST
[ ] @csrf_exempt: Stripe no puede enviar token CSRF
[ ] payload = request.body (bytes crudos, NO request.POST)
[ ] sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')
[ ] ValueError → 400
[ ] SignatureVerificationError → 400
[ ] payment_intent.succeeded → Pedido.estado='pagado' + stock decrementado
[ ] payment_intent.payment_failed → Pedido.estado='cancelado'
[ ] Webhook idempotente: segundo evento no cambia estado ya procesado

STOCK CON F()
[ ] _descontar_stock() usa F('stock') - cantidad (no leer en Python)
[ ] filter(stock__gte=cantidad) para no decrementar si no hay stock
[ ] Log de warning si stock insuficiente

URLS
[ ] path('webhook/', stripe_webhook) en catalogo/urls.py
[ ] python manage.py check → 0 issues

STRIPE CLI (verificación local)
[ ] stripe listen --forward-to .../catalogo/webhook/ → whsec_xxx
[ ] STRIPE_WEBHOOK_SECRET=whsec_xxx en .env
[ ] Flujo completo: 4242 → succeeded → Pedido 'pagado' → stock decrementado

PRODUCCIÓN (Render)
[ ] URL propia de Render verificada (GET /catalogo/webhook/ → 405, no 404)
[ ] Webhook creado en Stripe en MODO DE PRUEBA / Sandbox con TU URL
[ ] STRIPE_WEBHOOK_SECRET = Signing secret del Dashboard (no el de la CLI)
[ ] Entregas de eventos en Stripe → 200 · Pedido 'pagado' · stock decrementado

TESTS
[ ] event.to_dict() después de construct_event() (stripe 16.x)
[ ] test tests.test_w15_webhooks → 8/8 OK (incluye test StripeObject real)
[ ] test tests → 147/147 OK acumulados
[ ] test firma inválida → 400
[ ] test GET rechazado → 405
[ ] test succeeded → estado 'pagado'
[ ] test succeeded → stock decrementado
[ ] test idempotente → stock NO decrementado dos veces
[ ] test failed → estado 'cancelado'

SCRUM / SCHMELKES
[ ] sprint4_planning.md: 26/26 puntos entregados
[ ] sprint4_retrospective.md: 3 secciones + Kaizen + velocidad
[ ] fichas/espiral_05_ecommerce.md: todos los campos completados
[ ] Commit de cierre con etiqueta [M5]
[ ] git push → GitHub actualizado
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Flujo completo del webhook (W15)

```
Stripe servers
    │
    │ POST https://erp.onrender.com/catalogo/webhook/
    │ Headers: Stripe-Signature: t=123,v1=abc...
    │ Body: {"type":"payment_intent.succeeded","data":{...}}
    │
    ▼
stripe_webhook(request)
    │
    ├─ stripe.Webhook.construct_event(body, sig, secret)
    │       ├─ ValueError → 400 (payload malformado)
    │       └─ SignatureVerificationError → 400 (posible ataque)
    │
    ├─ event['type'] == 'payment_intent.succeeded'
    │       ↓
    │   _manejar_pago_exitoso(payment_intent)
    │       │
    │       ├─ pedido_id = metadata['pedido_id']
    │       ├─ Pedido.objects.get(pk=pedido_id)
    │       ├─ pedido.estado = 'pagado' → save(update_fields=['estado'])
    │       └─ _descontar_stock(pedido)
    │               │
    │               └─ for item in pedido.items_snapshot:
    │                       Producto.objects.filter(
    │                           pk=item['producto_id'],
    │                           stock__gte=item['cantidad']
    │                       ).update(stock=F('stock') - item['cantidad'])
    │
    └─ HttpResponse(status=200)
            → Stripe recibe 200 → no reintenta el evento ✅

En /admin/:
    Pedido PED-2025-0005: estado = pagado ✅
    Producto "Laptop": stock 10 → 8 ✅
```

---

## HILO CONDUCTOR → W16

**¿Qué cierra W15 / Espiral 5?**
El ciclo completo de e-commerce: catálogo → carrito → pago → confirmación
automática via webhook → stock actualizado. 147 tests garantizan
cada parte del flujo. Hito M5 declarado.

**¿Qué abre W16 / Espiral 6 / Sprint 5?**
Con el e-commerce funcionando, las operaciones pesadas (enviar correos,
generar reportes, alertar sobre stock bajo) deben ejecutarse de forma
**asíncrona** para no bloquear las peticiones HTTP. W16 instala Celery
con Redis como broker.

**¿Qué necesita W16 de W15?**

| Artefacto de W15 | Uso en W16 |
|---|---|
| `pago_exitoso()` que vacía el carrito | W16 agrega `enviar_confirmacion_pedido.delay(pedido.pk)` aquí |
| `Pedido.estado = 'pagado'` en el webhook | W16 dispara la tarea de correo desde el webhook en lugar de la vista |
| `docker-compose.yml` (W03) | W16 agrega el servicio Redis y Celery worker |
| 147 tests pasando | W16 agrega tests de tareas asíncronas |

**Tarea de investigación para W16:**
> Lee la documentación de Celery con Django:
> `https://docs.celeryq.dev/en/stable/django/first-steps-with-django.html`
>
> ¿Qué es un `broker` en Celery? ¿Por qué usamos Redis como broker
> en lugar de una base de datos PostgreSQL? ¿Qué diferencia hay
> entre `task.delay()` y `task.apply_async()`?

**Pregunta de reflexión:**
> "En W15, el webhook actualiza el stock con `F('stock') - cantidad`.
> ¿Qué pasaría si el mismo webhook llega DOS veces a Stripe
> (por un timeout de red)? ¿Cómo garantiza el código actual
> que el stock solo se descuenta una vez?"

---

## NOTAS — Observaciones de verificación en producción (10/11/2026)

Al probar W15 en Render con Stripe en **modo de prueba**, el pago aparecía
en Stripe como *"Se efectuó correctamente"*, pero en Django el pedido seguía
en **"Pendiente de pago"** y el inventario no disminuía. Se encontraron
dos causas, una tras otra:

**Observación 1 — URL del webhook incorrecta (Stripe recibía 404).**
La versión anterior de 3.3 indicaba una URL fija
(`https://erp-django-utec.onrender.com/...`). Esa URL no corresponde a
ningún servicio (`x-render-routing: no-server`): Render agrega un sufijo
cuando el nombre está ocupado. El evento nunca llegaba a Django.
*Corrección:* 3.3 ahora indica usar la URL propia de cada servicio,
verificarla con un GET (405) y crear el endpoint en modo de prueba /
Sandbox con el *Signing secret* del Dashboard.

**Observación 2 — HTTP 500 al procesar el evento (stripe 16.1.0).**
Con la URL correcta, Stripe recibía **500 Server Error**. La firma sí era
válida (si no, sería 400). La causa: en stripe-python ≥ 15, el evento
es un `StripeObject` que no hereda de `dict`, y
`payment_intent.get('metadata', {})` lanzaba `AttributeError`.
Los tests no lo detectaban porque simulaban el evento con un `dict` normal.
*Corrección:* `event = event.to_dict()` después de `construct_event()`
(2.2) y nuevo test `WebhookStripeObjectTest` con un `StripeObject` real
(4.1). Sin la corrección, el test falla; con ella, pasa.

**Notas aclaratorias:**
- En la línea de tiempo de Stripe, *"Pago autorizado"* es un paso normal
  (autorizado → efectuado). No requiere configuración adicional:
  el `PaymentIntent` usa captura automática.
- Para los pagos que fallaron antes de la corrección, después del
  redeploy usar **Reenviar** en Stripe → Webhooks → Entregas de eventos.
  El pedido pasa a `pagado` y se descuenta el stock sin volver a pagar.
- **Lección:** un *mock* debe parecerse al objeto real. Si la librería
  cambia de versión, los tests con `dict` simples pueden pasar aunque
  producción falle.

---

## Referencia rápida de comandos W15

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py makemigrations ventas --name items_snapshot_pedido
python manage.py showmigrations ventas
python manage.py migrate
python manage.py runserver

:: STRIPE CLI (en terminal separada)
stripe login
stripe listen --forward-to http://127.0.0.1:8000/catalogo/webhook/

:: TESTS
python manage.py test tests.test_w15_webhooks --verbosity=2
python manage.py test tests --verbosity=0   (147 tests)

:: GIT
git add .
git commit -m "Sprint 4 CIERRE [M5]: descripción"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W15 · ERP Django*
*Espiral 5 Cierre · Sprint 4 Review + Retrospectiva · Hito M5*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*