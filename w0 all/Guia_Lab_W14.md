# Guía de Laboratorio — W14
## ERP Django · Espiral 5 · Semana 14 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W14 de 24 |
| **Espiral** | E5 — E-commerce y Pagos |
| **Sprint Scrum** | Sprint 4 — Desarrollo |
| **Hito** | Sin hito propio · Avance hacia M5 (W15) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 4 — Funcionalidades Avanzadas |
| **Hilo conductor** | "W13 llenó el carrito. W14 cobra: checkout real con Stripe sandbox." |

---

## Respuesta a la tarea de investigación de W13

> **¿Qué es un `PaymentIntent` y qué estados puede tener?**
>
> Un `PaymentIntent` es el objeto central en la API de Stripe que
> representa una intención de cobrar dinero a un cliente. Encapsula
> el monto, la moneda y el estado del proceso de pago.
>
> | Estado | Significado |
> |---|---|
> | `requires_payment_method` | Esperando que el cliente proporcione tarjeta |
> | `requires_confirmation` | Datos proporcionados, esperando confirmación |
> | `requires_action` | Requiere autenticación 3D Secure |
> | `processing` | Stripe está procesando el pago |
> | `succeeded` | Pago completado exitosamente ✅ |
> | `canceled` | Cancelado — no se puede reactivar |
> | `payment_failed` | Pago rechazado |
>
> **Tarjetas de prueba Stripe:**
>
> | Tarjeta | Resultado |
> |---|---|
> | `4242 4242 4242 4242` | Pago exitoso |
> | `4000 0000 0000 9995` | Fondos insuficientes (rechazado) |
> | `4000 0025 0000 3155` | Requiere autenticación 3D Secure |
>
> Para todas las tarjetas de prueba: vencimiento cualquier fecha futura,
> CVC cualquier número de 3 dígitos, CP cualquier código de 5 dígitos.
>
> **¿Carrito persistente más allá de la sesión?**
> Tres opciones:
> 1. **Base de datos:** modelo `CarritoItem(user, producto, cantidad)` —
>    persiste indefinidamente, sincronizable entre dispositivos.
> 2. **Cookie firmada:** `set_signed_cookie('carrito', data, max_age=604800)` —
>    persiste 7 días sin BD, pero limita el tamaño.
> 3. **Sesión con `SESSION_COOKIE_AGE`** (actual) — persiste hasta expirar
>    la cookie, por defecto 2 semanas si `ACCOUNT_SESSION_REMEMBER=True`.

---

## Objetivos de la sesión

Al terminar W14, el estudiante será capaz de:

1. Instalar y configurar `stripe-python` con claves de sandbox desde `.env`
2. Implementar `CheckoutView` que crea un `Pedido` y un `PaymentIntent`
3. Renderizar el formulario de pago con Stripe.js y el Card Element
4. Manejar el resultado del pago (éxito, error, 3D Secure)
5. Vincular usuarios de Django con el modelo `Cliente` del ERP
6. Escribir tests con `unittest.mock.patch` para simular llamadas a Stripe

---

## Stack tecnológico de W14

| Herramienta | Novedad en W14 | Descripción |
|---|---|---|
| `stripe` 16.1.0 (Python) | ✅ Nuevo | SDK de Stripe para crear PaymentIntents desde el backend |
| Stripe.js | ✅ Nuevo | Librería JS para mostrar el formulario de tarjeta de forma segura |
| Card Element | ✅ Nuevo | Componente Stripe para capturar datos de tarjeta (no pasan por nuestro servidor) |
| `unittest.mock.patch` | ✅ Nuevo | Reemplaza `stripe.PaymentIntent.create` en tests |
| `idempotency_key` | ✅ Nuevo | Previene cargos duplicados si la petición se reintenta |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar W13 | 10 min |
| Parte 1 | Instalar `stripe` + configurar claves | 10 min |
| Parte 2 | Lógica de checkout: `_calcular_totales()` + `_obtener_cliente()` | 15 min |
| Parte 3 | `CheckoutView` + `pago_exitoso` + `pago_error` | 25 min |
| Parte 4 | Template `checkout.html` con Stripe.js | 25 min |
| Parte 5 | Templates `pago_exitoso.html` + `pago_error.html` | 15 min |
| Parte 6 | Actualizar `catalogo/urls.py` | 10 min |
| Parte 7 | Tests W14 (8 pruebas con mock) | 20 min |
| Cierre | Commit · `finalizar_sesion.bat` · hilo → W15 | 10 min |
| Buffer | | 20 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W13?
   → Creé el catálogo público filtrable con django-filter
     y el carrito de compras con sesiones Django.

2. ¿Qué haré en W14?
   → Implementaré el checkout con Stripe sandbox:
     checkout.html con Card Element, creación de PaymentIntent
     y manejo de éxito/error del pago.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 131 tests … OK`

---

## PARTE 1 — Instalar Stripe y Configurar Claves (10 min)

### 1.1 Instalar el SDK de Stripe

```cmd
pip install "stripe==16.1.0"
pip freeze > requirements.txt
```

Salida esperada: `Successfully installed stripe-16.1.0`

Verificar:
```cmd
python -c "import stripe; print('stripe', stripe.VERSION)"
```

Debe mostrar `stripe 16.1.0`, y `requirements.txt` debe incluir la línea `stripe==16.1.0`.

### 1.2 Obtener claves de sandbox de Stripe

1. Ir a `https://dashboard.stripe.com` → crear cuenta gratuita
2. Activar el **modo de prueba** (toggle en la esquina superior derecha)
3. Ir a **Desarrolladores** → **Claves de API**
4. Copiar:
   - **Clave publicable:** `pk_test_51...`
   - **Clave secreta:** `sk_test_51...`

### 1.3 Agregar claves al `.env`

```bash
# .env — agregar (nunca subir al repositorio)
STRIPE_SECRET_KEY=sk_test_51XXXXXXXXXXXXXXXXXXXXXXXXXX
STRIPE_PUBLISHABLE_KEY=pk_test_51XXXXXXXXXXXXXXXXXXXXXXXXXX
STRIPE_WEBHOOK_SECRET=whsec_XXXXXXXXXX   # se obtiene en W15
```

### 1.4 Agregar configuración en `core/settings.py`

```python
# core/settings.py — agregar al final (antes de JAZZMIN_SETTINGS):

# ── STRIPE (Pasarela de pago) ──────────────────────────────────────────────
STRIPE_SECRET_KEY     = env('STRIPE_SECRET_KEY',     default='sk_test_placeholder')
STRIPE_PUBLISHABLE_KEY = env('STRIPE_PUBLISHABLE_KEY', default='pk_test_placeholder')
STRIPE_WEBHOOK_SECRET = env('STRIPE_WEBHOOK_SECRET', default='whsec_placeholder')
```

### 1.5 Actualizar `.env.example`

```bash
# .env.example — agregar:
STRIPE_SECRET_KEY=sk_test_TU_CLAVE_SECRETA_AQUI
STRIPE_PUBLISHABLE_KEY=pk_test_TU_CLAVE_PUBLICABLE_AQUI
STRIPE_WEBHOOK_SECRET=whsec_TU_WEBHOOK_SECRET_AQUI
```

---

## PARTE 2 — Funciones Auxiliares del Checkout (15 min)

### 2.1 ¿Por qué separar la lógica en funciones auxiliares?

```
CheckoutView sin separación → función de 80 líneas difícil de testear
CheckoutView con separación → cada función tiene UNA responsabilidad:
    _calcular_totales()   → matemática del IVA
    _obtener_cliente()    → vincular User con Cliente del ERP
    _generar_numero()     → crear número de pedido único
    armar_items()         → subtotal por producto (precio × cantidad)
    checkout()            → orquestar todo
```

---

### 2.2 Crear `catalogo/checkout_utils.py`

```python
# catalogo/checkout_utils.py
"""Funciones auxiliares para el proceso de checkout — W14.

Separadas de views.py para facilitar las pruebas unitarias.
"""
from decimal import Decimal, ROUND_HALF_UP
from datetime import date

from django.conf import settings

from clientes.models      import Cliente
from configuracion.models import ConfiguracionERP
from ventas.models        import Pedido


def calcular_totales(carrito: dict) -> dict:
    """Calcula subtotal, IVA y total del carrito.

    Args:
        carrito: dict de sesión con estructura
                 {str(pk): {precio: str, cantidad: int, ...}}

    Returns:
        dict con subtotal, iva_pct, iva_monto, total (todos Decimal).
    """
    config   = ConfiguracionERP.get_instance()
    iva_pct  = config.iva_porcentaje / Decimal('100')

    subtotal = sum(
        Decimal(datos['precio']) * int(datos['cantidad'])
        for datos in carrito.values()
    )
    iva_monto = (subtotal * iva_pct).quantize(
        Decimal('0.01'), rounding=ROUND_HALF_UP
    )
    total = subtotal + iva_monto

    return {
        'subtotal':  subtotal,
        'iva_pct':   config.iva_porcentaje,
        'iva_monto': iva_monto,
        'total':     total,
    }


def armar_items(carrito: dict) -> list:
    """Convierte el carrito de sesión en una lista con el subtotal por línea.

    Los templates de Django no pueden multiplicar (precio × cantidad),
    por eso el cálculo se hace aquí.

    Returns:
        list de dicts con nombre, precio, cantidad y subtotal (Decimal).
    """
    items = []
    for datos in carrito.values():
        precio   = Decimal(datos['precio'])
        cantidad = int(datos['cantidad'])
        items.append({
            'nombre':   datos['nombre'],
            'precio':   precio,
            'cantidad': cantidad,
            'subtotal': precio * cantidad,
        })
    return items


def obtener_o_crear_cliente(user) -> Cliente:
    """Obtiene o crea un Cliente del ERP vinculado al usuario Django.

    Usa el correo del usuario si existe; si no, genera uno temporal.

    Args:
        user: instancia de django.contrib.auth.models.User.

    Returns:
        Cliente: instancia del modelo Cliente del ERP.
    """
    correo = user.email or f"{user.username}@erp.local"
    nombre = (
        user.get_full_name() or user.username
    )

    cliente, _ = Cliente.objects.get_or_create(
        correo=correo,
        defaults={'nombre': nombre, 'activo': True}
    )
    # Actualizar nombre si el usuario tiene nombre completo
    if cliente.nombre != nombre and user.get_full_name():
        cliente.nombre = nombre
        cliente.save(update_fields=['nombre'])

    return cliente


def generar_numero_pedido() -> str:
    """Genera un número de pedido único con formato PED-YYYY-NNNN.

    Returns:
        str: por ejemplo 'PED-2025-0001'
    """
    anio      = date.today().year
    siguiente = Pedido.objects.filter(
        numero_pedido__startswith=f'PED-{anio}-'
    ).count() + 1
    return f'PED-{anio}-{siguiente:04d}'
```

---

## PARTE 3 — `CheckoutView`, `pago_exitoso` y `pago_error` (25 min)

### 3.1 Agregar imports y configurar Stripe en `catalogo/views.py`

Agregar al inicio de `catalogo/views.py`:

```python
# catalogo/views.py — agregar imports al inicio:
import stripe
from django.conf import settings
from django.contrib.auth.decorators import login_required

from ventas.models import DetalleVenta, Pedido
from .checkout_utils import (
    armar_items,
    calcular_totales,
    generar_numero_pedido,
    obtener_o_crear_cliente,
)

# Configurar la clave secreta de Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY
```

---

### 3.2 Agregar `checkout`, `pago_exitoso` y `pago_error` a `catalogo/views.py`

```python
# catalogo/views.py — agregar al final:

@login_required
def checkout(request):
    """Proceso de pago: muestra resumen y crea PaymentIntent de Stripe.

    GET:  Muestra resumen del carrito con IVA calculado.
          No crea PaymentIntent (espera a POST).

    POST: Valida carrito → crea Pedido → crea PaymentIntent →
          retorna client_secret al template para que Stripe.js
          confirme el pago del lado del cliente.

    Redirige a /catalogo/ si el carrito está vacío.
    """
    carrito = _obtener_carrito(request)
    if not carrito:
        messages.warning(request, 'Tu carrito está vacío.')
        return redirect('catalogo:catalogo')

    totales         = calcular_totales(carrito)
    items           = armar_items(carrito)   # subtotal por línea
    publishable_key = settings.STRIPE_PUBLISHABLE_KEY

    if request.method == 'POST':
        try:
            # ── 1. Vincular usuario con Cliente del ERP ────────────────
            cliente = obtener_o_crear_cliente(request.user)

            # ── 2. Crear el Pedido en estado "pendiente" ───────────────
            numero = generar_numero_pedido()
            pedido = Pedido.objects.create(
                numero_pedido = numero,
                cliente       = cliente,
                estado        = 'pendiente',
                total_pagado  = totales['total'],
            )

            # ── 3. Crear PaymentIntent en Stripe ───────────────────────
            # Monto en centavos (Stripe requiere entero)
            monto_centavos = int(totales['total'] * 100)

            intent = stripe.PaymentIntent.create(
                amount          = monto_centavos,
                currency        = 'mxn',
                metadata        = {
                    'pedido_id':  pedido.pk,
                    'pedido_num': pedido.numero_pedido,
                    'cliente':    cliente.nombre,
                },
                idempotency_key = f'pedido-{pedido.pk}',
            )

            # ── 4. Retornar client_secret al template ──────────────────
            return render(request, 'catalogo/checkout.html', {
                'carrito':         carrito,
                'items':           items,
                'totales':         totales,
                'pedido':          pedido,
                'client_secret':   intent.client_secret,
                'publishable_key': publishable_key,
            })

        except stripe.error.StripeError as exc:
            messages.error(
                request,
                f'Error al conectar con Stripe: {exc.user_message}'
            )
            return redirect('catalogo:pago_error')

        except Exception as exc:
            messages.error(
                request,
                f'Error inesperado en el proceso de pago: {exc}'
            )
            return redirect('catalogo:pago_error')

    # GET — solo mostrar resumen (sin PaymentIntent)
    return render(request, 'catalogo/checkout.html', {
        'carrito':         carrito,
        'items':           items,
        'totales':         totales,
        'client_secret':   None,          # se genera en POST
        'publishable_key': publishable_key,
    })


def pago_exitoso(request, pedido_id: int):
    """Vista de confirmación post-pago exitoso.

    Vacía el carrito de la sesión y muestra el número de pedido.
    Stripe redirige aquí después de `stripe.confirmCardPayment` exitoso.
    """
    from django.shortcuts import get_object_or_404
    pedido = get_object_or_404(Pedido, pk=pedido_id)

    # Vaciar el carrito al confirmar el pago
    _guardar_carrito(request, {})
    messages.success(
        request,
        f'¡Pago exitoso! Tu pedido {pedido.numero_pedido} '
        f'está confirmado. Total: ${pedido.total_pagado}'
    )

    return render(request, 'catalogo/pago_exitoso.html', {
        'pedido': pedido,
    })


def pago_error(request):
    """Vista de error de pago — muestra mensaje y permite reintentar."""
    return render(request, 'catalogo/pago_error.html')
```

---

## PARTE 4 — Template `checkout.html` con Stripe.js (25 min)

### 4.1 Crear `catalogo/templates/catalogo/checkout.html`

> ⚠️ **Ubicación y nombre exactos.** Guarda este archivo (y los de la Parte 5)
> dentro de `catalogo\templates\catalogo\`, no en `catalogo\`, y con extensión
> `.html` (no `.htm`). Si no, Django lanza
> `TemplateDoesNotExist at /catalogo/checkout/`. Verifica con:
>
> ```cmd
> dir catalogo\templates\catalogo
> ```
>
> Deben aparecer `checkout.html`, `pago_exitoso.html` y `pago_error.html`.

```html
{% extends "base.html" %}
{% block title %}Checkout · Proceso de pago{% endblock %}

{% block extra_css %}
<style>
    /* Estilos para el Card Element de Stripe */
    #card-element {
        background: var(--clr-surface);
        border: 1.5px solid var(--clr-border);
        border-radius: 8px;
        padding: .75rem 1rem;
        transition: border-color .2s;
    }
    #card-element.StripeElement--focus {
        border-color: var(--clr-sky);
        box-shadow: 0 0 0 3px rgba(74,144,217,.18);
    }
    #card-element.StripeElement--invalid {
        border-color: var(--clr-danger);
    }
    #card-errors {
        color: var(--clr-danger);
        font-size: .85rem;
        margin-top: .4rem;
        min-height: 1.2rem;
    }
    #submit-btn:disabled {
        opacity: .7;
        cursor: not-allowed;
    }
</style>
{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>💳 Proceso de pago</h2>
    <a href="{% url 'catalogo:carrito' %}"
       class="btn-erp-primary ms-auto">← Volver al carrito</a>
</div>

<div class="row g-4">

    <!-- Resumen del pedido -->
    <div class="col-md-5">
        <div class="erp-card">
            <div class="erp-card-header">🛍️ Resumen de tu pedido</div>
            <table style="width:100%;border-collapse:collapse;margin-top:.5rem;">
                {% for item in items %}
                <tr>
                    <td style="padding:.4rem 0;font-size:.9rem;">
                        {{ item.nombre }}
                        <span style="color:var(--clr-muted);
                                     font-size:.82rem;">
                            × {{ item.cantidad }}
                        </span>
                    </td>
                    <td style="text-align:right;font-weight:600;
                               font-size:.9rem;padding:.4rem 0;">
                        ${{ item.subtotal }}
                    </td>
                </tr>
                {% endfor %}
                <tr style="border-top:1px solid var(--clr-border);">
                    <td style="padding:.5rem 0;color:var(--clr-muted);
                               font-size:.88rem;">
                        Subtotal
                    </td>
                    <td style="text-align:right;color:var(--clr-muted);
                               font-size:.88rem;">
                        ${{ totales.subtotal }}
                    </td>
                </tr>
                <tr>
                    <td style="padding:.3rem 0;color:var(--clr-muted);
                               font-size:.88rem;">
                        IVA ({{ totales.iva_pct }}%)
                    </td>
                    <td style="text-align:right;color:var(--clr-muted);
                               font-size:.88rem;">
                        ${{ totales.iva_monto }}
                    </td>
                </tr>
                <tr style="border-top:2px solid var(--clr-gold);">
                    <td style="padding:.6rem 0;font-weight:700;font-size:1rem;">
                        TOTAL
                    </td>
                    <td style="text-align:right;font-weight:700;
                               font-size:1.2rem;color:var(--clr-gold);">
                        ${{ totales.total }}
                    </td>
                </tr>
            </table>
        </div>

        {% if pedido %}
        <div class="erp-alert-info" style="margin-top:1rem;">
            <strong>Pedido creado:</strong> {{ pedido.numero_pedido }}<br>
            <small style="color:var(--clr-muted);">
                Completa el pago para confirmar tu pedido.
            </small>
        </div>
        {% endif %}
    </div>

    <!-- Formulario de pago -->
    <div class="col-md-7">
        <div class="erp-card">
            <div class="erp-card-header">🔒 Datos de pago</div>

            {% if client_secret %}
            <!-- Formulario de tarjeta con Stripe.js -->
            <p style="color:var(--clr-muted);font-size:.85rem;margin-bottom:1rem;">
                Tus datos de pago son procesados de forma segura por Stripe.
                Nunca pasan por nuestros servidores.
            </p>

            <div class="mb-4">
                <label class="erp-label">Número de tarjeta</label>
                <div id="card-element"></div>
                <div id="card-errors" role="alert"></div>
            </div>

            <button id="submit-btn" class="btn-erp-gold"
                    style="width:100%;padding:.6rem;font-size:1rem;">
                🔐 Confirmar pago de ${{ totales.total }}
            </button>

            <p style="text-align:center;margin-top:.75rem;
                      color:var(--clr-muted);font-size:.78rem;">
                Tarjeta de prueba: <code>4242 4242 4242 4242</code>
                · cualquier fecha futura · cualquier CVC
            </p>

            {% else %}
            <!-- GET: iniciar proceso con POST -->
            <p style="margin-bottom:1.5rem;color:var(--clr-muted);">
                Haz clic en "Proceder al pago" para generar
                tu pedido e introducir los datos de tu tarjeta.
            </p>
            <form method="post">
                {% csrf_token %}
                <button type="submit" class="btn-erp-gold"
                        style="width:100%;padding:.6rem;font-size:1rem;">
                    Proceder al pago →
                </button>
            </form>
            {% endif %}
        </div>
    </div>

</div>
{% endblock %}

{% block extra_js %}
{% if client_secret %}
<script src="https://js.stripe.com/v3/"></script>
<script>
(function () {
    'use strict';

    const stripe     = Stripe('{{ publishable_key }}');
    const elements   = stripe.elements();
    const clientSecret = '{{ client_secret }}';

    // Crear el Card Element con estilos Fable 5 AzulERP
    const card = elements.create('card', {
        style: {
            base: {
                fontFamily: "'Inter', 'Segoe UI', sans-serif",
                fontSize: '15px',
                color: getComputedStyle(document.documentElement)
                            .getPropertyValue('--clr-text').trim() || '#1A1A2E',
                '::placeholder': { color: '#8AA0B8' },
            },
            invalid: { color: '#C0392B', iconColor: '#C0392B' },
        },
    });
    card.mount('#card-element');

    // Mostrar errores en tiempo real (p. ej. número inválido)
    card.on('change', function (event) {
        const errorDiv = document.getElementById('card-errors');
        errorDiv.textContent = event.error ? event.error.message : '';
    });

    // Manejar el submit del botón de pago
    const btn = document.getElementById('submit-btn');
    btn.addEventListener('click', async function () {
        btn.disabled     = true;
        btn.textContent  = '⏳ Procesando…';

        const { error, paymentIntent } = await stripe.confirmCardPayment(
            clientSecret,
            { payment_method: { card: card } }
        );

        if (error) {
            // Mostrar el error y habilitar el botón de nuevo
            document.getElementById('card-errors').textContent = error.message;
            btn.disabled    = false;
            btn.textContent = '🔐 Confirmar pago de ${{ totales.total }}';
        } else if (paymentIntent.status === 'succeeded') {
            // Redirigir a la vista de éxito
            const pedidoId = '{{ pedido.pk }}';
            window.location.href = `/catalogo/pago-exitoso/${pedidoId}/`;
        }
    });
})();
</script>
{% endif %}
{% endblock %}
```

> 💡 **¿Por qué no usar `{% widthratio %}` para el subtotal?** `widthratio`
> sirve para calcular anchos de barras (`a / b × c`), no para multiplicar.
> Convierte su último argumento a entero, y el precio del carrito está guardado
> como texto (`"123.45"`), así que falla con
> `TemplateSyntaxError: widthratio final argument must be a number`. Además
> redondea el resultado y se pierden los centavos. Los templates de Django no
> multiplican: el subtotal se calcula en Python con `armar_items()` (Parte 2.2)
> y la vista lo envía como `items`.

---

## PARTE 5 — Templates `pago_exitoso.html` y `pago_error.html` (15 min)

### 5.1 `catalogo/templates/catalogo/pago_exitoso.html`

```html
{% extends "base.html" %}
{% block title %}¡Pago exitoso!{% endblock %}

{% block content %}
<div style="display:flex;justify-content:center;align-items:center;
            min-height:60vh;">
    <div class="erp-card" style="max-width:520px;text-align:center;">
        <div style="font-size:4rem;margin-bottom:1rem;">✅</div>
        <h2 style="font-family:'Playfair Display',serif;
                   color:var(--clr-navy);margin:0 0 .5rem;">
            ¡Pago confirmado!
        </h2>
        <p style="color:var(--clr-muted);margin-bottom:1.5rem;">
            Tu pedido ha sido registrado exitosamente.
        </p>

        <div class="erp-card" style="background:var(--clr-ice);
                                     border-left:5px solid var(--clr-ok);
                                     text-align:left;margin-bottom:1.5rem;">
            <dl style="margin:0;">
                <dt class="erp-label">Número de pedido</dt>
                <dd style="font-size:1.2rem;font-weight:700;
                           color:var(--clr-navy);margin:.2rem 0 1rem;">
                    {{ pedido.numero_pedido }}
                </dd>

                <dt class="erp-label">Total pagado</dt>
                <dd style="font-size:1.2rem;font-weight:700;
                           color:var(--clr-gold);margin:.2rem 0 1rem;">
                    ${{ pedido.total_pagado }}
                </dd>

                <dt class="erp-label">Estado</dt>
                <dd style="margin:.2rem 0 0;">
                    <span class="badge-erp-active">
                        {{ pedido.get_estado_display }}
                    </span>
                </dd>
            </dl>
        </div>

        <div class="d-flex gap-2 justify-content-center">
            <a href="{% url 'catalogo:catalogo' %}" class="btn-erp-primary">
                Seguir comprando
            </a>
            {% if user.is_authenticated %}
            <a href="{% url 'ventas:detalle' pedido.pk %}"
               class="btn-erp-gold">
                Ver detalle del pedido
            </a>
            {% endif %}
        </div>
    </div>
</div>
{% endblock %}
```

---

### 5.2 `catalogo/templates/catalogo/pago_error.html`

```html
{% extends "base.html" %}
{% block title %}Error en el pago{% endblock %}

{% block content %}
<div style="display:flex;justify-content:center;align-items:center;
            min-height:60vh;">
    <div class="erp-card" style="max-width:480px;text-align:center;">
        <div style="font-size:4rem;margin-bottom:1rem;">❌</div>
        <h2 style="font-family:'Playfair Display',serif;
                   color:var(--clr-danger);margin:0 0 .5rem;">
            Error en el pago
        </h2>
        <p style="color:var(--clr-muted);margin-bottom:1.5rem;">
            No pudimos procesar tu pago. Tu carrito sigue intacto —
            puedes intentarlo de nuevo.
        </p>

        <div class="erp-alert-danger" style="margin-bottom:1.5rem;
                                             text-align:left;">
            <strong>Posibles causas:</strong>
            <ul style="margin:.5rem 0 0;padding-left:1.2rem;font-size:.9rem;">
                <li>Fondos insuficientes en la tarjeta</li>
                <li>Datos de tarjeta incorrectos</li>
                <li>Tarjeta bloqueada por el banco</li>
                <li>Problema temporal de conexión con Stripe</li>
            </ul>
        </div>

        <div class="d-flex gap-2 justify-content-center">
            <a href="{% url 'catalogo:carrito' %}"
               class="btn-erp-primary">
                ← Volver al carrito
            </a>
            <a href="{% url 'catalogo:checkout' %}"
               class="btn-erp-gold">
                Reintentar pago
            </a>
        </div>
    </div>
</div>
{% endblock %}
```

---

## PARTE 6 — Actualizar `catalogo/urls.py` (10 min)

```python
# catalogo/urls.py — versión W14 (reemplaza el placeholder de W13)
"""URLs del módulo catálogo — W14."""
from django.urls import path

from . import views

app_name = 'catalogo'

urlpatterns = [
    # Catálogo público
    path('',
         views.CatalogoView.as_view(),
         name='catalogo'),

    # Carrito (W13)
    path('carrito/',
         views.ver_carrito,
         name='carrito'),
    path('carrito/agregar/<int:producto_id>/',
         views.agregar_al_carrito,
         name='agregar'),
    path('carrito/remover/<int:producto_id>/',
         views.remover_del_carrito,
         name='remover'),
    path('carrito/actualizar/<int:producto_id>/',
         views.actualizar_cantidad,
         name='actualizar'),
    path('carrito/vaciar/',
         views.vaciar_carrito,
         name='vaciar'),

    # Checkout con Stripe (W14)
    path('checkout/',
         views.checkout,
         name='checkout'),
    path('pago-exitoso/<int:pedido_id>/',
         views.pago_exitoso,
         name='pago_exitoso'),
    path('pago-error/',
         views.pago_error,
         name='pago_error'),
]
```

### Verificar en el navegador

```cmd
python manage.py check
python manage.py runserver
```

**Flujo de prueba manual (con claves reales de Stripe sandbox):**

```
1. Agregar 2 productos al carrito desde /catalogo/
2. Ir a /catalogo/carrito/ → verificar items y total
3. Clic en "Proceder al pago" → login si no está autenticado
4. GET /catalogo/checkout/ → muestra resumen + botón "Proceder"
5. POST /catalogo/checkout/ → Card Element de Stripe aparece
6. Ingresar: 4242 4242 4242 4242 · 12/26 · 123 · CP: 12345
7. Clic en "Confirmar pago" → procesando…
8. Redirige a /catalogo/pago-exitoso/<id>/ → ✅ confirmación
9. Carrito queda vacío
10. Verificar en /admin/ que el Pedido existe con estado 'pendiente'
    (cambia a 'pagado' en W15 vía webhook)
```

---

## PARTE 7 — Tests W14 (20 min)

### 7.1 ¿Por qué usar `unittest.mock.patch`?

```python
# SIN mock: los tests llaman a la API real de Stripe
# → requieren internet en el aula
# → son lentos (latencia de red)
# → dependen de que las claves de Stripe estén configuradas

# CON mock: reemplazamos stripe.PaymentIntent.create con un objeto falso
# → sin internet, sin claves
# → rápidos (sin latencia)
# → predecibles (sabemos exactamente qué devuelve)

from unittest.mock import patch, MagicMock

@patch('catalogo.views.stripe.PaymentIntent.create')
def test_post_checkout(self, mock_stripe):
    mock_stripe.return_value = MagicMock(client_secret='pi_test_secret')
    # Ahora stripe.PaymentIntent.create() devuelve el mock
    r = self.client.post(...)
```

---

### 7.2 Crear `tests/test_w14_checkout.py`

```python
"""Suite de pruebas W14 — Checkout y proceso de pago con Stripe.

Usa unittest.mock.patch para simular stripe.PaymentIntent.create
sin requerir claves reales ni conexión a internet.

Ejecutar con:
    python manage.py test tests.test_w14_checkout --verbosity=2

Resultado esperado:
    Ran 8 tests in X.XXXs
    OK
"""
from decimal import Decimal
from unittest.mock import MagicMock, patch

from django.contrib.auth.models import User
from django.test import TestCase
from django.urls import reverse

from clientes.models        import Cliente
from configuracion.models   import ConfiguracionERP
from productos.models       import Categoria, Producto
from ventas.models          import Pedido


def _setup_carrito(client, producto):
    """Agrega un producto al carrito de la sesión del test client."""
    client.post(
        reverse('catalogo:agregar', args=[producto.pk]),
        {'cantidad': 2}
    )


class CheckoutAutenticacionTest(TestCase):
    """Tests de autenticación del checkout."""

    def test_checkout_sin_auth_redirige_a_login(self):
        """GET /catalogo/checkout/ sin login → 302 a /accounts/login/."""
        r = self.client.get(reverse('catalogo:checkout'))
        self.assertEqual(r.status_code, 302)
        self.assertIn('/accounts/login/', r['Location'])

    def test_checkout_carrito_vacio_redirige_a_catalogo(self):
        """Checkout con carrito vacío → redirect al catálogo."""
        user = User.objects.create_user('empty', password='pass')
        self.client.force_login(user)
        r = self.client.get(reverse('catalogo:checkout'))
        self.assertRedirects(r, reverse('catalogo:catalogo'),
                             fetch_redirect_response=False)

    def test_checkout_get_con_carrito_devuelve_200(self):
        """GET /catalogo/checkout/ con carrito → 200 (resumen visible)."""
        ConfiguracionERP.get_instance()
        cat  = Categoria.objects.create(nombre='Cat')
        prod = Producto.objects.create(
            nombre='P', precio=Decimal('100.00'),
            stock=5, categoria=cat
        )
        user = User.objects.create_user('userco', password='pass',
                                        email='userco@test.com')
        self.client.force_login(user)
        _setup_carrito(self.client, prod)
        r = self.client.get(reverse('catalogo:checkout'))
        self.assertEqual(r.status_code, 200)


class CheckoutPagoTest(TestCase):
    """Tests del proceso POST de checkout con Stripe mockeado."""

    def setUp(self):
        ConfiguracionERP.get_instance()
        cat       = Categoria.objects.create(nombre='Cat')
        self.prod = Producto.objects.create(
            nombre='Laptop', precio=Decimal('500.00'),
            stock=5, categoria=cat
        )
        self.user = User.objects.create_user(
            'payer', password='pass', email='payer@test.com'
        )
        self.client.force_login(self.user)
        _setup_carrito(self.client, self.prod)   # 2 × 500 = 1000

    @patch('catalogo.views.stripe.PaymentIntent.create')
    def test_post_checkout_crea_pedido(self, mock_pi):
        """POST /catalogo/checkout/ → se crea un Pedido en BD."""
        mock_pi.return_value = MagicMock(client_secret='pi_test_secret')
        self.client.post(reverse('catalogo:checkout'))
        self.assertEqual(Pedido.objects.count(), 1)

    @patch('catalogo.views.stripe.PaymentIntent.create')
    def test_post_checkout_pedido_estado_pendiente(self, mock_pi):
        """El Pedido creado debe tener estado 'pendiente'."""
        mock_pi.return_value = MagicMock(client_secret='pi_test_secret')
        self.client.post(reverse('catalogo:checkout'))
        pedido = Pedido.objects.first()
        self.assertEqual(pedido.estado, 'pendiente')

    @patch('catalogo.views.stripe.PaymentIntent.create')
    def test_post_checkout_calcula_iva(self, mock_pi):
        """El total del Pedido debe incluir el IVA configurado."""
        mock_pi.return_value = MagicMock(client_secret='pi_test_secret')
        self.client.post(reverse('catalogo:checkout'))
        pedido    = Pedido.objects.first()
        config    = ConfiguracionERP.get_instance()
        subtotal  = Decimal('1000.00')   # 2 × 500
        iva_pct   = config.iva_porcentaje / 100
        esperado  = (subtotal + subtotal * iva_pct).quantize(Decimal('0.01'))
        self.assertEqual(pedido.total_pagado, esperado)

    @patch('catalogo.views.stripe.PaymentIntent.create')
    def test_post_checkout_crea_cliente_erp(self, mock_pi):
        """Se debe crear (o encontrar) un Cliente ERP para el usuario."""
        mock_pi.return_value = MagicMock(client_secret='pi_test_secret')
        self.client.post(reverse('catalogo:checkout'))
        self.assertTrue(
            Cliente.objects.filter(correo=self.user.email).exists()
        )

    @patch('catalogo.views.stripe.PaymentIntent.create')
    def test_post_checkout_llama_stripe_con_monto_correcto(self, mock_pi):
        """Stripe debe recibir el monto en centavos."""
        mock_pi.return_value = MagicMock(client_secret='pi_test_secret')
        self.client.post(reverse('catalogo:checkout'))
        config   = ConfiguracionERP.get_instance()
        subtotal = Decimal('1000.00')
        total    = subtotal + subtotal * (config.iva_porcentaje / 100)
        centavos = int(total.quantize(Decimal('0.01')) * 100)
        mock_pi.assert_called_once()
        args, kwargs = mock_pi.call_args
        self.assertEqual(kwargs.get('amount') or args[0], centavos)


class PagoExitosoTest(TestCase):
    """Tests de la vista pago_exitoso."""

    def setUp(self):
        ConfiguracionERP.get_instance()
        cat  = Categoria.objects.create(nombre='C')
        prod = Producto.objects.create(
            nombre='P', precio=Decimal('100.00'), stock=5, categoria=cat
        )
        cli  = Cliente.objects.create(nombre='C', correo='c@t.com')
        self.pedido = Pedido.objects.create(
            numero_pedido='PED-2025-0001',
            cliente=cli,
            estado='pendiente',
            total_pagado=Decimal('116.00')
        )

    def test_pago_exitoso_devuelve_200(self):
        """GET /catalogo/pago-exitoso/<id>/ → 200."""
        r = self.client.get(
            reverse('catalogo:pago_exitoso', args=[self.pedido.pk])
        )
        self.assertEqual(r.status_code, 200)

    def test_pago_exitoso_vacia_carrito(self):
        """Visitar pago_exitoso vacía la sesión del carrito."""
        session = self.client.session
        session['carrito'] = {'1': {'nombre': 'P', 'precio': '100',
                                     'cantidad': 1}}
        session.save()

        self.client.get(
            reverse('catalogo:pago_exitoso', args=[self.pedido.pk])
        )
        # El carrito en la sesión debe quedar vacío
        self.assertEqual(
            self.client.session.get('carrito', {}), {}
        )
```

### 7.3 Ejecutar los tests

```cmd
python manage.py test tests.test_w14_checkout --verbosity=2
```

**Resultado esperado:**
```
test_checkout_carrito_vacio_redirige_a_catalogo ... ok
test_checkout_get_con_carrito_devuelve_200 ... ok
test_checkout_sin_auth_redirige_a_login ... ok
test_pago_exitoso_devuelve_200 ... ok
test_pago_exitoso_vacia_carrito ... ok
test_post_checkout_calcula_iva ... ok
test_post_checkout_crea_cliente_erp ... ok
test_post_checkout_crea_pedido ... ok
test_post_checkout_llama_stripe_con_monto_correcto ... ok
test_post_checkout_pedido_estado_pendiente ... ok

Ran 10 tests in X.XXXs
OK
```

> *Nota: son 10 tests porque se separaron en dos clases adicionales.
> Dependiendo de la implementación exacta pueden ser 8–10.*

### 7.4 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 139 tests in X.XXXs · OK` (131 + 8 mínimo)

---

## CIERRE — Commit y Respaldo (10 min)

### Actualizar `sprint4_planning.md`

```markdown
## Sprint Backlog — actualización W14

| Tarea | Estado |
|---|---|
| Catálogo + carrito + context processor | ✅ W13 |
| pip install stripe | ✅ W14 |
| STRIPE_* en settings.py y .env | ✅ W14 |
| checkout_utils.py (calcular_totales, obtener_cliente) | ✅ W14 |
| CheckoutView (GET/POST) con PaymentIntent | ✅ W14 |
| Template checkout.html con Stripe.js Card Element | ✅ W14 |
| pago_exitoso: vaciar carrito + template | ✅ W14 |
| pago_error: template con causas y reintento | ✅ W14 |
| Tests con unittest.mock.patch | ✅ W14 |
| Webhooks + actualizar estado pedido | ⏳ W15 |
| Descontar stock al confirmar pago | ⏳ W15 |
```

### Commit de cierre W14

```cmd
git add .
git status

:: Verificar que incluye:
::   catalogo/checkout_utils.py
::   catalogo/views.py (con checkout + pago_exitoso + pago_error)
::   catalogo/urls.py (URLs W14)
::   catalogo/templates/catalogo/checkout.html
::   catalogo/templates/catalogo/pago_exitoso.html
::   catalogo/templates/catalogo/pago_error.html
::   core/settings.py (STRIPE_* vars)
::   tests/test_w14_checkout.py
::   sprint4_planning.md

git commit -m "Sprint 4 W14: checkout Stripe sandbox + PaymentIntent + 139 tests OK"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W14

### Técnico

```
STRIPE SDK
[ ] pip install "stripe==16.1.0" → sin errores (stripe==16.1.0 en requirements.txt)
[ ] STRIPE_SECRET_KEY en .env y settings.py (no hardcodeada)
[ ] STRIPE_PUBLISHABLE_KEY en .env y settings.py
[ ] stripe.api_key = settings.STRIPE_SECRET_KEY en views.py

CHECKOUT UTILS
[ ] checkout_utils.py: calcular_totales() usa ConfiguracionERP
[ ] calcular_totales(): precio guardado como str → convierte a Decimal
[ ] calcular_totales(): IVA redondeado con ROUND_HALF_UP
[ ] obtener_o_crear_cliente(): usa user.email o genera username@erp.local
[ ] generar_numero_pedido(): formato PED-YYYY-NNNN sin colisiones
[ ] armar_items(): subtotal por línea = Decimal(precio) × cantidad

CHECKOUTVIEW
[ ] Sin auth → redirect /accounts/login/?next=/catalogo/checkout/
[ ] Carrito vacío → redirect /catalogo/ con mensaje warning
[ ] GET → template sin client_secret (muestra botón "Proceder")
[ ] POST → crea Pedido con estado='pendiente' + PaymentIntent
[ ] POST → retorna client_secret en contexto → Stripe.js lo usa
[ ] stripe.error.StripeError → redirect pago_error con mensaje

TEMPLATES
[ ] checkout.html: dos estados (GET sin client_secret / POST con él)
[ ] checkout.html: recorre {% for item in items %} y muestra ${{ item.subtotal }}
[ ] Templates en catalogo/templates/catalogo/ con extensión .html
[ ] checkout.html: Stripe.js CDN solo cuando client_secret existe
[ ] checkout.html: card.on('change') muestra errores en tiempo real
[ ] checkout.html: btn.disabled=true durante el procesamiento
[ ] pago_exitoso.html: muestra numero_pedido + total + estado
[ ] pago_error.html: lista de causas + botón reintentar

URLS
[ ] checkout/: views.checkout (reemplaza TemplateView placeholder)
[ ] pago-exitoso/<int:pedido_id>/: views.pago_exitoso
[ ] pago-error/: views.pago_error

TESTS (con mock)
[ ] test tests.test_w14_checkout → ≥ 8 tests OK
[ ] test tests → ≥ 139 tests OK acumulados
[ ] @patch('catalogo.views.stripe.PaymentIntent.create') correctamente
[ ] mock_pi.return_value = MagicMock(client_secret='pi_test')
[ ] test IVA: total incluye iva_porcentaje de ConfiguracionERP
[ ] test vaciar carrito: session['carrito'] == {} después de pago_exitoso

GIT
[ ] sprint4_planning.md actualizado
[ ] Commit con mensaje descriptivo
[ ] .env NO está en el repositorio (verificar)
[ ] git push → GitHub con checkout_utils.py y templates nuevos
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Flujo completo del checkout (W14)

```
USUARIO → GET /catalogo/checkout/
    │ @login_required → sin auth → /accounts/login/
    │ carrito vacío → /catalogo/
    ▼
checkout(request) GET
    ├── calcular_totales(carrito)
    │       → subtotal + IVA + total
    └── render checkout.html (sin client_secret)
            → botón "Proceder al pago"

USUARIO → POST /catalogo/checkout/
    ▼
checkout(request) POST
    ├── obtener_o_crear_cliente(request.user)
    │       → Cliente(correo=user.email)
    ├── Pedido.objects.create(estado='pendiente', total_pagado=total)
    │       → Pedido pk=5, numero_pedido='PED-2025-0005'
    ├── stripe.PaymentIntent.create(
    │       amount=116000,          ← centavos (1160.00 MXN × 100)
    │       currency='mxn',
    │       metadata={pedido_id: 5},
    │       idempotency_key='pedido-5'
    │   )
    │       → {client_secret: 'pi_xxx_secret_yyy'}
    └── render checkout.html (CON client_secret)
            → Stripe.js monta el Card Element

USUARIO ingresa: 4242 4242 4242 4242 · 12/26 · 123
    ▼
stripe.confirmCardPayment(client_secret, {payment_method: {card: cardEl}})
    │
    ├── error → mostrar mensaje en #card-errors + habilitar botón
    │
    └── succeeded → redirect /catalogo/pago-exitoso/5/
            │
            ▼
        pago_exitoso(request, pedido_id=5)
            ├── _guardar_carrito(request, {})  ← vaciar carrito
            └── render pago_exitoso.html
                    → ✅ PED-2025-0005 · $1,160.00 · Pendiente
```

---

## HILO CONDUCTOR → W15

**¿Qué entrega W14?**
El checkout completo con Stripe sandbox: el usuario puede pagar,
el `Pedido` se crea en estado `pendiente` y el carrito se vacía
tras el pago. 139 tests verifican el flujo completo con mocks.

**¿Qué abre W15 / Hito M5?**
Stripe llama al webhook para confirmar el pago. W15 implementa
el endpoint `/catalogo/webhook/` que recibe el evento de Stripe,
verifica la firma y actualiza el pedido a estado `pagado`,
descontando el stock de los productos vendidos.

**¿Qué necesita W15 de W14?**

| Artefacto de W14 | Uso en W15 |
|---|---|
| `Pedido.metadata['pedido_id']` en PaymentIntent | W15 lo lee del evento webhook para saber qué pedido actualizar |
| `STRIPE_WEBHOOK_SECRET` (placeholder en .env) | W15 lo configura con `stripe listen` o desde el dashboard |
| `Pedido.estado = 'pendiente'` | W15 lo cambia a `'pagado'` al recibir `payment_intent.succeeded` |
| `Producto.stock` | W15 lo decrementa por las cantidades del pedido |

**Tarea de investigación para W15:**
> Lee la documentación de Stripe sobre webhooks:
> `https://stripe.com/docs/webhooks`
>
> ¿Qué es `stripe.Webhook.construct_event()`?
> ¿Por qué es crítico verificar la firma del webhook?
> ¿Qué sucede si un atacante envía un evento falso al endpoint?

**Pregunta de reflexión:**
> "En W14 creamos el `Pedido` con `estado='pendiente'` cuando el
> usuario hace POST al checkout, ANTES de que Stripe confirme el pago.
> ¿Qué pasaría si el usuario cierra el navegador justo después del POST
> pero antes de que Stripe confirme? ¿El pedido queda en `pendiente`
> para siempre? ¿Cómo lo resolvería W15 con webhooks?"

---

## Referencia rápida de comandos W14

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py runserver

:: TESTS (sin claves Stripe reales — usa mock)
python manage.py test tests.test_w14_checkout --verbosity=2
python manage.py test tests --verbosity=0   (≥ 139 tests)

:: STRIPE CLI (para probar webhooks en W15)
:: Instalar de: https://stripe.com/docs/stripe-cli
:: stripe listen --forward-to localhost:8000/catalogo/webhook/

:: GIT
git add .
git commit -m "Sprint 4 W14: Stripe checkout + 139 tests OK"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W14 · ERP Django*
*Espiral 5 · Sprint 4 Desarrollo · Checkout + Stripe PaymentIntent*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*