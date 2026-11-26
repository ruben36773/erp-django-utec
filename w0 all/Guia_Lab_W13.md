# Guía de Laboratorio — W13
## ERP Django · Espiral 5 · Semana 13 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W13 de 24 |
| **Espiral** | E5 — E-commerce y Pagos |
| **Sprint Scrum** | Sprint 4 — Planning |
| **Hito** | Sin hito propio · Avance hacia M5 (W15) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 4 — Funcionalidades Avanzadas |
| **Hilo conductor** | "W12 generó documentos. W13 abre la tienda: catálogo público y carrito de compras." |

---

## Respuesta a la tarea de investigación de W12

> **¿Cómo almacenar información en la sesión Django?**
>
> ```python
> # Guardar en sesión
> request.session['carrito'] = {'1': {'nombre': 'Laptop', 'precio': '10000', 'cantidad': 1}}
>
> # Leer de sesión
> carrito = request.session.get('carrito', {})
>
> # Modificar y marcar como modificado (importante para sesiones en BD)
> request.session['carrito'] = carrito
> request.session.modified = True
> ```
>
> **¿Diferencia entre `SESSION_COOKIE_AGE` y la sesión de allauth?**
>
> | Aspecto | `SESSION_COOKIE_AGE` | `ACCOUNT_SESSION_REMEMBER` (allauth) |
> |---|---|---|
> | Qué controla | Duración máxima de la cookie de sesión (segundos) | Si se recuerda la sesión al cerrar el navegador |
> | Default Django | 1,209,600 s (2 semanas) | — |
> | En nuestro ERP | Heredado | `True` (configurado en W09) |
>
> **¿Por qué `str(producto.pk)` como clave del carrito?**
> Django serializa la sesión a JSON. Las claves de diccionario JSON
> deben ser strings. Si usas `int` como clave (`carrito[1]`), al
> deserializar la sesión se convierte a `str` automáticamente —
> lo que rompe la búsqueda posterior. Siempre usar `str(pk)`.
>
> **Optimización del `total @property` con 500 líneas:**
> En lugar de iterar las líneas con Python:
> ```python
> # Lento: N queries si no hay prefetch
> return sum(d.subtotal for d in self.detalles.all())
>
> # Rápido: 1 sola query SQL con SUM()
> from django.db.models import Sum, F, ExpressionWrapper, DecimalField
> return self.detalles.aggregate(
>     total=Sum(ExpressionWrapper(
>         F('cantidad') * F('precio_unitario'),
>         output_field=DecimalField()
>     ))
> )['total'] or Decimal('0.00')
> ```
> En el template del PDF, la vista debería pasar el total pre-calculado
> como variable del contexto en lugar de llamar `venta.total` en el template.

---

## Objetivos de la sesión

Al terminar W13, el estudiante será capaz de:

1. Crear la app `catalogo` con catálogo público filtrable por categoría,
   precio y nombre usando `django-filter`
2. Implementar un carrito de compras en sesión Django con estructura
   de diccionario serializable a JSON
3. Crear vistas para agregar, remover y actualizar productos en el carrito
4. Crear un context processor para mostrar el contador de items en la navbar
5. Construir templates de tarjetas de producto y vista de carrito con Fable 5
6. Escribir 8 tests que verifican el flujo completo del carrito

---

## Stack tecnológico de W13

| Herramienta | Novedad en W13 | Descripción |
|---|---|---|
| `django-filter` | ✅ Nuevo | Filtros parametrizables para querysets |
| `request.session` | ✅ Nuevo | Almacenamiento de datos entre peticiones |
| Context processor | ✅ Nuevo | Inyecta variables en todos los templates |
| App `catalogo` | ✅ Nuevo | Módulo de tienda pública (separado del admin) |
| Tarjetas CSS (grid) | ✅ Nuevo | Layout de productos en cuadrícula responsiva |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + Sprint 4 Planning | 15 min |
| Parte 1 | Crear app `catalogo` + instalar `django-filter` | 15 min |
| Parte 2 | `ProductoFilter` + `CatalogoView` | 20 min |
| Parte 3 | Lógica del carrito en sesión (4 vistas) | 25 min |
| Parte 4 | Context processor para contador del carrito | 10 min |
| Parte 5 | Templates: `catalogo.html` + `carrito.html` | 30 min |
| Parte 6 | URLs + actualizar `base.html` con contador | 10 min |
| Parte 7 | Tests W13 (8 pruebas) | 20 min |
| Cierre | Commit · `finalizar_sesion.bat` · hilo → W14 | 15 min |
| Buffer | | 20 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum + Sprint 4 Planning (15 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W12?
   → Implementé generación de facturas PDF con xhtml2pdf,
     exportación a Excel con openpyxl y cerré el Sprint 3 con M4.

2. ¿Qué haré en W13?
   → Crearé el catálogo público filtrable y el carrito
     de compras con sesiones Django.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 123 tests … OK`

---

### Sprint 4 Planning

**Sprint Goal del Sprint 4:**
> *"Al finalizar el Sprint 4, el ERP tendrá un canal de e-commerce
> con catálogo filtrable, carrito de compras y proceso de pago
> completo con Stripe, incluyendo actualización automática de
> estados de pedido mediante webhooks."*

**Duración:** W13 (catálogo + carrito) · W14 (checkout + Stripe) · W15 (webhooks · M5)

Crear `sprint4_planning.md`:

```markdown
# Sprint 4 Planning — ERP Django
## Semanas W13–W15 · Espiral 5: E-commerce y Pagos

**Sprint Goal:**
Al finalizar el Sprint 4, el ERP tendrá catálogo filtrable,
carrito de compras y pago completo con Stripe sandbox,
actualizando automáticamente el estado del pedido.

## HUs seleccionadas

| ID | Historia | Puntos | Semana |
|---|---|---|---|
| HU-E5-01 | Como cliente, quiero ver el catálogo sin registrarme | 2 | W13 |
| HU-E5-02 | Como cliente, quiero filtrar productos por categoría y precio | 3 | W13 |
| HU-E5-03 | Como cliente, quiero agregar productos a mi carrito | 3 | W13 |
| HU-E5-04 | Como cliente, quiero ver el contenido de mi carrito | 2 | W13 |
| HU-E5-05 | Como cliente, quiero proceder al pago con mis datos | 3 | W14 |
| HU-E5-06 | Como cliente, quiero pagar con tarjeta (Stripe sandbox) | 5 | W14 |
| HU-E5-07 | Como sistema, quiero confirmar el pago vía webhook | 5 | W15 |
| HU-E5-08 | Como admin, quiero que el stock se descuente al confirmar | 3 | W15 |

**Total Sprint 4:** 26 puntos

## DoD — Sprint 4
- GET /catalogo/ → 200 sin autenticación con lista de productos
- Filtrar por categoría → solo productos de esa categoría
- Agregar producto al carrito → contador en navbar se incrementa
- Tarjeta de prueba Stripe 4242... → pedido cambia a "pagado"
- Webhook verifica firma → stock se descuenta
- python manage.py test → ≥ 131 tests OK
```

---

## PARTE 1 — Crear app `catalogo` + instalar `django-filter` (15 min)

### 1.1 Instalar `django-filter`

```cmd
pip install "django-filter==23.5"
pip freeze > requirements.txt
```

### 1.2 Crear la app `catalogo`

```cmd
python manage.py startapp catalogo
```

### 1.3 Registrar en `core/settings.py`

```python
# core/settings.py — actualizar INSTALLED_APPS:
INSTALLED_APPS = [
    'jazzmin',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sites',
    # Terceros
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    'rest_framework',
    'rest_framework.authtoken',
    'django_filters',              # ← nuevo (nombre de app es django_filters)
    'whitenoise.runserver_nostatic',
    # Apps del ERP
    'clientes',
    'proveedores',
    'productos',
    'ventas',
    'reportes',
    'configuracion',
    'catalogo',                    # ← nuevo
]
```

### 1.4 Registrar context processor del carrito en `TEMPLATES`

```python
# core/settings.py — actualizar TEMPLATES[0]['OPTIONS']['context_processors']:
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                # Context processor del carrito — W13
                'catalogo.context_processors.carrito_info',
            ],
        },
    },
]
```

### 1.5 Verificar

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

---

## PARTE 2 — `ProductoFilter` y `CatalogoView` (20 min)

### 2.1 Crear `catalogo/filters.py`

```python
# catalogo/filters.py
"""Filtros para el catálogo público de productos — W13."""
import django_filters

from productos.models import Categoria, Producto


class ProductoFilter(django_filters.FilterSet):
    """Filtro de productos para el catálogo público.

    Permite filtrar por:
        nombre:      contiene el texto (insensible a mayúsculas)
        categoria:   categoría exacta (selector)
        precio_min:  precio mayor o igual a este valor
        precio_max:  precio menor o igual a este valor
    """

    nombre = django_filters.CharFilter(
        field_name='nombre',
        lookup_expr='icontains',
        label='Buscar por nombre',
    )
    categoria = django_filters.ModelChoiceFilter(
        queryset=Categoria.objects.all(),
        label='Categoría',
        empty_label='Todas las categorías',
    )
    precio_min = django_filters.NumberFilter(
        field_name='precio',
        lookup_expr='gte',
        label='Precio mínimo ($)',
    )
    precio_max = django_filters.NumberFilter(
        field_name='precio',
        lookup_expr='lte',
        label='Precio máximo ($)',
    )

    class Meta:
        model  = Producto
        fields = ['nombre', 'categoria', 'precio_min', 'precio_max']
```

---

### 2.2 Crear `catalogo/views.py`

```python
# catalogo/views.py
"""Vistas del módulo de catálogo y carrito — W13.

Módulo público (no requiere autenticación para lectura).
El carrito se almacena en la sesión Django.

Estructura del carrito en sesión:
    request.session['carrito'] = {
        '1': {
            'nombre':   'Laptop HP',
            'precio':   '10000.00',   # str — Decimal no es JSON serializable
            'cantidad': 2,
            'imagen':   'productos/laptop.jpg'  # o None
        },
        ...
    }
"""
from decimal import Decimal

from django.contrib import messages
from django.shortcuts import get_object_or_404, redirect, render
from django.views.generic import ListView

from productos.models import Producto

from .filters import ProductoFilter


# ── CATÁLOGO ───────────────────────────────────────────────────────────────

class CatalogoView(ListView):
    """Catálogo público de productos con filtros.

    No requiere autenticación — accesible para cualquier visitante.
    """

    model               = Producto
    template_name       = 'catalogo/catalogo.html'
    context_object_name = 'productos'
    paginate_by         = 12    # 3 filas de 4 tarjetas

    def get_queryset(self):
        """Filtra productos activos aplicando los filtros del request."""
        qs = (
            Producto.objects
            .select_related('categoria', 'proveedor')
            .filter(activo=True)
            .order_by('nombre')
        )
        self.filtro = ProductoFilter(self.request.GET, queryset=qs)
        return self.filtro.qs

    def get_context_data(self, **kwargs):
        """Agrega el objeto filtro al contexto para renderizar el formulario."""
        ctx = super().get_context_data(**kwargs)
        ctx['filtro']     = self.filtro
        ctx['categorias'] = self.filtro.form.fields['categoria'].queryset
        return ctx


# ── CARRITO ─────────────────────────────────────────────────────────────────

def _obtener_carrito(request: object) -> dict:
    """Obtiene el carrito de la sesión o crea uno vacío."""
    return request.session.get('carrito', {})


def _guardar_carrito(request: object, carrito: dict) -> None:
    """Guarda el carrito en la sesión y marca como modificado."""
    request.session['carrito']  = carrito
    request.session.modified    = True


def ver_carrito(request):
    """Muestra el contenido del carrito con el total calculado.

    Convierte los precios de str a Decimal para el cálculo.
    """
    carrito = _obtener_carrito(request)

    items = []
    total = Decimal('0.00')

    for prod_id, datos in carrito.items():
        precio    = Decimal(datos['precio'])
        cantidad  = int(datos['cantidad'])
        subtotal  = precio * cantidad
        total    += subtotal
        items.append({
            'prod_id':  prod_id,
            'nombre':   datos['nombre'],
            'precio':   precio,
            'cantidad': cantidad,
            'subtotal': subtotal,
            'imagen':   datos.get('imagen'),
        })

    return render(request, 'catalogo/carrito.html', {
        'items': items,
        'total': total,
    })


def agregar_al_carrito(request, producto_id: int):
    """Agrega un producto al carrito o incrementa su cantidad.

    Solo acepta POST para proteger contra CSRF.
    La cantidad puede enviarse como parámetro POST (default: 1).

    Args:
        producto_id: ID del producto a agregar.
    """
    if request.method != 'POST':
        return redirect('catalogo:catalogo')

    producto = get_object_or_404(Producto, pk=producto_id, activo=True)
    carrito  = _obtener_carrito(request)

    clave    = str(producto_id)
    cantidad = int(request.POST.get('cantidad', 1))

    if clave in carrito:
        carrito[clave]['cantidad'] += cantidad
    else:
        carrito[clave] = {
            'nombre':   producto.nombre,
            'precio':   str(producto.precio),   # str para JSON serializable
            'cantidad': cantidad,
            'imagen':   producto.imagen.name if producto.imagen else None,
        }

    _guardar_carrito(request, carrito)
    messages.success(
        request,
        f'"{producto.nombre}" agregado al carrito.'
    )

    # Volver a la página anterior (catálogo, detalle de producto, etc.)
    next_url = request.POST.get('next') or request.META.get('HTTP_REFERER')
    return redirect(next_url or 'catalogo:catalogo')


def remover_del_carrito(request, producto_id: int):
    """Elimina un producto del carrito.

    Solo acepta POST.
    """
    if request.method != 'POST':
        return redirect('catalogo:carrito')

    carrito = _obtener_carrito(request)
    clave   = str(producto_id)

    nombre = carrito.get(clave, {}).get('nombre', 'Producto')
    carrito.pop(clave, None)
    _guardar_carrito(request, carrito)

    messages.warning(request, f'"{nombre}" eliminado del carrito.')
    return redirect('catalogo:carrito')


def actualizar_cantidad(request, producto_id: int):
    """Actualiza la cantidad de un producto en el carrito.

    Solo acepta POST. Si la cantidad llega a 0 o menos, elimina el item.
    """
    if request.method != 'POST':
        return redirect('catalogo:carrito')

    carrito  = _obtener_carrito(request)
    clave    = str(producto_id)
    cantidad = int(request.POST.get('cantidad', 1))

    if clave in carrito:
        if cantidad > 0:
            carrito[clave]['cantidad'] = cantidad
        else:
            carrito.pop(clave)

    _guardar_carrito(request, carrito)
    return redirect('catalogo:carrito')


def vaciar_carrito(request):
    """Elimina todos los productos del carrito."""
    if request.method == 'POST':
        _guardar_carrito(request, {})
        messages.info(request, 'Carrito vaciado.')
    return redirect('catalogo:carrito')
```

---

## PARTE 3 — Context Processor del Carrito (10 min)

### 3.1 Crear `catalogo/context_processors.py`

```python
# catalogo/context_processors.py
"""Context processors de la app catalogo — W13.

carrito_info: inyecta el contador de items del carrito en todos
              los templates, permitiendo mostrarlo en la navbar
              de base.html sin necesidad de pasarlo manualmente
              en cada vista.
"""
from typing import Any


def carrito_info(request) -> dict[str, Any]:
    """Calcula el total de items en el carrito y lo inyecta globalmente.

    Returns:
        dict con:
            carrito_total_items (int): número total de unidades en el carrito.
            carrito_total_productos (int): número de productos distintos.
    """
    carrito = request.session.get('carrito', {})

    total_items     = sum(
        int(item.get('cantidad', 0)) for item in carrito.values()
    )
    total_productos = len(carrito)

    return {
        'carrito_total_items':     total_items,
        'carrito_total_productos': total_productos,
    }
```

---

## PARTE 4 — Templates Fable 5 AzulERP (30 min)

### 4.1 Crear carpeta de templates

```cmd
mkdir catalogo\templates\catalogo
```

### 4.2 `catalogo/templates/catalogo/catalogo.html`

```html
{% extends "base.html" %}
{% block title %}Catálogo de Productos{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>🛒 Catálogo</h2>
    <span style="margin-left:auto;color:var(--clr-muted);font-size:.85rem;">
        {{ page_obj.paginator.count }} producto(s) disponibles
    </span>
    <a href="{% url 'catalogo:carrito' %}"
       class="btn-erp-gold"
       style="position:relative;">
        🛍️ Carrito
        {% if carrito_total_items > 0 %}
        <span style="position:absolute;top:-8px;right:-8px;
                     background:var(--clr-danger);color:#FFF;
                     border-radius:50%;width:20px;height:20px;
                     font-size:.7rem;display:flex;align-items:center;
                     justify-content:center;font-weight:700;">
            {{ carrito_total_items }}
        </span>
        {% endif %}
    </a>
</div>

<!-- Filtros -->
<div class="erp-card" style="margin-bottom:1.5rem;">
    <div class="erp-card-header">🔍 Filtrar productos</div>
    <form method="get" style="margin-top:.5rem;">
        <div class="row g-3 align-items-end">
            <div class="col-md-4">
                <label class="erp-label">Buscar por nombre</label>
                {{ filtro.form.nombre }}
            </div>
            <div class="col-md-3">
                <label class="erp-label">Categoría</label>
                {{ filtro.form.categoria }}
            </div>
            <div class="col-md-2">
                <label class="erp-label">Precio mín. ($)</label>
                {{ filtro.form.precio_min }}
            </div>
            <div class="col-md-2">
                <label class="erp-label">Precio máx. ($)</label>
                {{ filtro.form.precio_max }}
            </div>
            <div class="col-md-1">
                <button type="submit" class="btn-erp-primary w-100">
                    Filtrar
                </button>
            </div>
        </div>
        {% if request.GET %}
        <div style="margin-top:.75rem;">
            <a href="{% url 'catalogo:catalogo' %}"
               style="color:var(--clr-muted);font-size:.85rem;">
                ✕ Limpiar filtros
            </a>
        </div>
        {% endif %}
    </form>
</div>

<!-- Tarjetas de productos -->
{% if productos %}
<div class="row g-3">
    {% for prod in productos %}
    <div class="col-md-3 col-sm-6">
        <div class="erp-card"
             style="height:100%;display:flex;flex-direction:column;">

            <!-- Imagen del producto -->
            {% if prod.imagen %}
            <img src="{{ prod.imagen.url }}"
                 alt="{{ prod.nombre }}"
                 style="width:100%;height:160px;object-fit:cover;
                        border-radius:8px 8px 0 0;margin:-1.5rem -1.5rem 1rem;">
            {% else %}
            <div style="width:calc(100% + 3rem);height:120px;
                        margin:-1.5rem -1.5rem 1rem;
                        background:var(--clr-ice);
                        border-radius:8px 8px 0 0;
                        display:flex;align-items:center;
                        justify-content:center;
                        color:var(--clr-muted);font-size:2.5rem;">
                📦
            </div>
            {% endif %}

            <!-- Nombre y categoría -->
            <div style="flex:1;">
                <p style="font-weight:600;color:var(--clr-navy);
                          margin:0 0 .25rem;font-size:.95rem;">
                    {{ prod.nombre }}
                </p>
                <p style="font-size:.8rem;color:var(--clr-muted);margin:0;">
                    {{ prod.categoria }}
                </p>
            </div>

            <!-- Precio y stock -->
            <div style="margin-top:.75rem;padding-top:.75rem;
                        border-top:1px solid var(--clr-border);">
                <p style="font-size:1.2rem;font-weight:700;
                          color:var(--clr-gold);margin:0;">
                    ${{ prod.precio }}
                </p>
                {% if prod.stock < 5 %}
                <span class="badge-erp-inactive" style="font-size:.72rem;">
                    Pocas unidades: {{ prod.stock }}
                </span>
                {% else %}
                <span class="badge-erp-active" style="font-size:.72rem;">
                    En stock: {{ prod.stock }}
                </span>
                {% endif %}
            </div>

            <!-- Botón agregar al carrito -->
            <form method="post"
                  action="{% url 'catalogo:agregar' prod.pk %}"
                  style="margin-top:.75rem;">
                {% csrf_token %}
                <input type="hidden" name="cantidad" value="1">
                <input type="hidden" name="next"
                       value="{{ request.get_full_path }}">
                <button type="submit"
                        class="btn-erp-primary"
                        style="width:100%;">
                    + Agregar al carrito
                </button>
            </form>
        </div>
    </div>
    {% endfor %}
</div>

<!-- Paginación -->
{% if is_paginated %}
<div style="display:flex;gap:.5rem;justify-content:center;margin-top:2rem;">
    {% if page_obj.has_previous %}
        <a href="?{% if request.GET.urlencode %}{{ request.GET.urlencode }}&{% endif %}page={{ page_obj.previous_page_number }}"
           class="btn-erp-primary btn-erp-sm">← Anterior</a>
    {% endif %}
    <span style="padding:.35rem .75rem;color:var(--clr-muted);font-size:.88rem;">
        Página {{ page_obj.number }} de {{ page_obj.paginator.num_pages }}
    </span>
    {% if page_obj.has_next %}
        <a href="?{% if request.GET.urlencode %}{{ request.GET.urlencode }}&{% endif %}page={{ page_obj.next_page_number }}"
           class="btn-erp-primary btn-erp-sm">Siguiente →</a>
    {% endif %}
</div>
{% endif %}

{% else %}
<div class="erp-alert-info" style="margin-top:1.5rem;">
    No se encontraron productos con los filtros seleccionados.
    <a href="{% url 'catalogo:catalogo' %}" style="color:var(--clr-sky);">
        Ver todos los productos
    </a>
</div>
{% endif %}
{% endblock %}
```

> ⚠️ **No agregues `{% load django_filters %}`.** `django-filter` no incluye
> ninguna librería de *template tags* (no trae carpeta `templatetags/`), así que
> esa línea provoca el error `TemplateSyntaxError: 'django_filters' is not a
> registered tag library`. El filtro se procesa en la vista (`ProductoFilter`) y
> en el template basta con mostrar sus campos: `{{ filtro.form.nombre }}`,
> `{{ filtro.form.categoria }}`, etc. Esas variables no necesitan ningún `{% load %}`.

---

### 4.3 `catalogo/templates/catalogo/carrito.html`

```html
{% extends "base.html" %}
{% block title %}Mi carrito{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>🛍️ Mi carrito</h2>
    <a href="{% url 'catalogo:catalogo' %}"
       class="btn-erp-primary ms-auto">← Seguir comprando</a>
</div>

{% if items %}
<div class="erp-card">
    <table class="erp-table">
        <thead>
            <tr>
                <th>Producto</th>
                <th class="text-end">Precio unit.</th>
                <th style="width:130px;text-align:center;">Cantidad</th>
                <th class="text-end">Subtotal</th>
                <th style="width:60px;"></th>
            </tr>
        </thead>
        <tbody>
            {% for item in items %}
            <tr>
                <td style="font-weight:600;">{{ item.nombre }}</td>
                <td style="text-align:right;">${{ item.precio }}</td>
                <!-- Actualizar cantidad -->
                <td style="text-align:center;">
                    <form method="post"
                          action="{% url 'catalogo:actualizar' item.prod_id %}"
                          style="display:flex;align-items:center;
                                 gap:.25rem;justify-content:center;">
                        {% csrf_token %}
                        <input type="number"
                               name="cantidad"
                               value="{{ item.cantidad }}"
                               min="0" max="99"
                               class="erp-input"
                               style="width:60px;text-align:center;
                                      padding:.3rem .5rem;">
                        <button type="submit"
                                class="btn-erp-primary btn-erp-sm">
                            ↻
                        </button>
                    </form>
                </td>
                <td style="text-align:right;font-weight:600;
                           color:var(--clr-gold);">
                    ${{ item.subtotal }}
                </td>
                <!-- Remover item -->
                <td style="text-align:center;">
                    <form method="post"
                          action="{% url 'catalogo:remover' item.prod_id %}">
                        {% csrf_token %}
                        <button type="submit"
                                class="btn-erp-danger btn-erp-sm"
                                title="Eliminar">✕</button>
                    </form>
                </td>
            </tr>
            {% endfor %}
        </tbody>
        <tfoot>
            <tr style="background:var(--clr-cream);">
                <td colspan="3" style="padding:.75rem 1rem;
                    font-weight:600;text-align:right;">
                    Total del carrito:
                </td>
                <td style="padding:.75rem 1rem;font-weight:700;
                           font-size:1.2rem;text-align:right;
                           color:var(--clr-gold);">
                    ${{ total }}
                </td>
                <td></td>
            </tr>
        </tfoot>
    </table>
</div>

<!-- Acciones del carrito -->
<div class="d-flex gap-2 mt-3 flex-wrap">
    <!-- Vaciar carrito -->
    <form method="post" action="{% url 'catalogo:vaciar' %}">
        {% csrf_token %}
        <button type="submit" class="btn-erp-danger"
                onclick="return confirm('¿Vaciar el carrito?')">
            🗑️ Vaciar carrito
        </button>
    </form>

    <!-- Proceder al checkout — W14 lo implementará -->
    {% if user.is_authenticated %}
    <a href="{% url 'catalogo:checkout' %}"
       class="btn-erp-gold" style="font-size:1rem;padding:.55rem 1.5rem;">
        💳 Proceder al pago →
    </a>
    {% else %}
    <a href="{% url 'account_login' %}?next={% url 'catalogo:checkout' %}"
       class="btn-erp-gold">
        🔐 Inicia sesión para pagar
    </a>
    {% endif %}
</div>

{% else %}
<div class="erp-card" style="text-align:center;padding:3rem;">
    <p style="font-size:3rem;margin:0;">🛒</p>
    <p style="color:var(--clr-muted);margin:.5rem 0 1.5rem;">
        Tu carrito está vacío.
    </p>
    <a href="{% url 'catalogo:catalogo' %}" class="btn-erp-gold">
        Ver catálogo de productos
    </a>
</div>
{% endif %}
{% endblock %}
```

---

## PARTE 5 — URLs + Actualizar `base.html` (10 min)

### 5.1 Crear `catalogo/urls.py`

```python
# catalogo/urls.py
"""URLs del módulo catálogo — W13."""
from django.urls import path
from django.views.generic import TemplateView

from . import views

app_name = 'catalogo'

urlpatterns = [
    # Catálogo público
    path('',
         views.CatalogoView.as_view(),
         name='catalogo'),
    # Carrito
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
    # Checkout — se implementa en W14
    path('checkout/',
         TemplateView.as_view(
             template_name='catalogo/checkout_pendiente.html'
         ),
         name='checkout'),
]
```

### 5.2 Agregar a `core/urls.py`

```python
# core/urls.py — agregar la ruta del catálogo:
urlpatterns = [
    path('admin/',      admin.site.urls),
    path('',            views.bienvenida,             name='inicio'),
    path('accounts/',   include('allauth.urls')),
    # API REST
    path('api/',        include((api_urlpatterns, 'api'))),
    path('api/auth/token/', obtain_auth_token, name='api_token'),
    # E-commerce público — W13
    path('catalogo/',   include('catalogo.urls', namespace='catalogo')),
    # Apps del ERP (interfaz interna)
    path('clientes/',    include('clientes.urls',    namespace='clientes')),
    path('proveedores/', include('proveedores.urls', namespace='proveedores')),
    path('productos/',   include('productos.urls',   namespace='productos')),
    path('ventas/',      include('ventas.urls',       namespace='ventas')),
    path('reportes/',    include('reportes.urls',     namespace='reportes')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

### 5.3 Actualizar navbar en `templates/base.html`

Agregar enlace al catálogo en la sección de navegación:

```html
<!-- En templates/base.html — dentro de erp-nav-links,
     agregar ANTES del enlace "Admin": -->
<a href="{% url 'catalogo:catalogo' %}"
   class="erp-nav-link {% block nav_catalogo %}{% endblock %}">
    🛒 Tienda
</a>
<!-- Contador del carrito en la navbar -->
{% if carrito_total_items > 0 %}
<a href="{% url 'catalogo:carrito' %}"
   class="erp-nav-link"
   style="position:relative;">
    🛍️ ({{ carrito_total_items }})
</a>
{% endif %}
```

### 5.4 Crear template placeholder para checkout

```cmd
:: El checkout real se implementa en W14
:: Crear plantilla temporal:
```

Crear `catalogo/templates/catalogo/checkout_pendiente.html`:

```html
{% extends "base.html" %}
{% block title %}Checkout{% endblock %}

{% block content %}
<div class="erp-card" style="max-width:480px;margin:0 auto;text-align:center;">
    <div class="erp-card-header">💳 Proceso de pago</div>
    <p style="margin:1.5rem 0;color:var(--clr-muted);">
        El proceso de pago con Stripe se implementará en la
        <strong>Semana W14</strong>.
    </p>
    <div class="d-flex gap-2 justify-content-center">
        <a href="{% url 'catalogo:carrito' %}" class="btn-erp-primary">
            ← Volver al carrito
        </a>
    </div>
</div>
{% endblock %}
```

### 5.5 Verificar en el navegador

```cmd
python manage.py check
python manage.py runserver
```

```
[ ] http://127.0.0.1:8000/catalogo/ → catálogo sin login (HTTP 200)
[ ] Filtrar por categoría → solo productos de esa categoría
[ ] Clic en "+ Agregar al carrito" → mensaje flash + contador en navbar
[ ] http://127.0.0.1:8000/catalogo/carrito/ → tabla con el producto
[ ] Actualizar cantidad a 3 → subtotal se recalcula
[ ] Clic en ✕ → producto eliminado del carrito
[ ] Clic en "Vaciar carrito" → carrito vacío
```

---

## PARTE 6 — Tests W13 (20 min)

### 6.1 Crear `tests/test_w13_ecommerce.py`

```python
"""Suite de pruebas W13 — Catálogo público y carrito de compras.

Verifica: catálogo sin auth, filtros, ciclo completo del carrito.

Ejecutar con:
    python manage.py test tests.test_w13_ecommerce --verbosity=2

Resultado esperado:
    Ran 8 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.test import TestCase
from django.urls import reverse

from productos.models import Categoria, Producto


class CatalogoPublicoTest(TestCase):
    """Tests del catálogo público (sin autenticación)."""

    def setUp(self):
        cat        = Categoria.objects.create(nombre='Electrónica')
        self.prod1 = Producto.objects.create(
            nombre='Laptop',  precio=Decimal('10000.00'),
            stock=5, categoria=cat
        )
        self.prod2 = Producto.objects.create(
            nombre='Mouse', precio=Decimal('250.00'),
            stock=20, categoria=cat
        )
        Producto.objects.create(
            nombre='Producto Inactivo', precio=Decimal('100.00'),
            stock=5, categoria=cat, activo=False
        )

    def test_catalogo_accesible_sin_auth(self):
        """GET /catalogo/ sin login → 200 (catálogo es público)."""
        r = self.client.get(reverse('catalogo:catalogo'))
        self.assertEqual(r.status_code, 200)

    def test_catalogo_solo_muestra_activos(self):
        """El catálogo no debe mostrar productos inactivos."""
        r = self.client.get(reverse('catalogo:catalogo'))
        nombres = [p.nombre for p in r.context['productos']]
        self.assertIn('Laptop', nombres)
        self.assertNotIn('Producto Inactivo', nombres)

    def test_catalogo_filtro_por_nombre(self):
        """Filtrar por nombre 'lapt' → solo muestra Laptop."""
        r = self.client.get(
            reverse('catalogo:catalogo'), {'nombre': 'lapt'}
        )
        self.assertEqual(r.status_code, 200)
        nombres = [p.nombre for p in r.context['productos']]
        self.assertIn('Laptop', nombres)
        self.assertNotIn('Mouse', nombres)

    def test_catalogo_filtro_por_precio_max(self):
        """Filtrar precio_max=500 → solo muestra Mouse (250)."""
        r = self.client.get(
            reverse('catalogo:catalogo'), {'precio_max': 500}
        )
        nombres = [p.nombre for p in r.context['productos']]
        self.assertIn('Mouse', nombres)
        self.assertNotIn('Laptop', nombres)


class CarritoTest(TestCase):
    """Tests del carrito de compras en sesión."""

    def setUp(self):
        cat       = Categoria.objects.create(nombre='Cat')
        self.prod = Producto.objects.create(
            nombre='Teclado', precio=Decimal('350.00'),
            stock=10, categoria=cat
        )

    def test_carrito_vacio_al_inicio(self):
        """Un carrito nuevo debe estar vacío."""
        r = self.client.get(reverse('catalogo:carrito'))
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.context['items'], [])

    def test_agregar_producto_incrementa_carrito(self):
        """POST agregar → producto aparece en el carrito."""
        self.client.post(
            reverse('catalogo:agregar', args=[self.prod.pk]),
            {'cantidad': 2}
        )
        r = self.client.get(reverse('catalogo:carrito'))
        self.assertEqual(len(r.context['items']), 1)
        self.assertEqual(r.context['items'][0]['cantidad'], 2)

    def test_agregar_mismo_producto_acumula_cantidad(self):
        """Agregar el mismo producto dos veces → suma las cantidades."""
        url = reverse('catalogo:agregar', args=[self.prod.pk])
        self.client.post(url, {'cantidad': 1})
        self.client.post(url, {'cantidad': 3})
        r = self.client.get(reverse('catalogo:carrito'))
        self.assertEqual(r.context['items'][0]['cantidad'], 4)

    def test_carrito_calcula_total_correcto(self):
        """Total = cantidad × precio. 2 × 350 = 700."""
        self.client.post(
            reverse('catalogo:agregar', args=[self.prod.pk]),
            {'cantidad': 2}
        )
        r = self.client.get(reverse('catalogo:carrito'))
        self.assertEqual(r.context['total'], Decimal('700.00'))

    def test_remover_producto_lo_elimina(self):
        """POST remover → producto desaparece del carrito."""
        self.client.post(
            reverse('catalogo:agregar', args=[self.prod.pk]),
            {'cantidad': 1}
        )
        self.client.post(
            reverse('catalogo:remover', args=[self.prod.pk])
        )
        r = self.client.get(reverse('catalogo:carrito'))
        self.assertEqual(r.context['items'], [])
```

### 6.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w13_ecommerce --verbosity=2
```

**Resultado esperado:**
```
test_agregar_mismo_producto_acumula_cantidad ... ok
test_agregar_producto_incrementa_carrito ... ok
test_carrito_calcula_total_correcto ... ok
test_carrito_vacio_al_inicio ... ok
test_catalogo_accesible_sin_auth ... ok
test_catalogo_filtro_por_nombre ... ok
test_catalogo_filtro_por_precio_max ... ok
test_catalogo_solo_muestra_activos ... ok
test_remover_producto_lo_elimina ... ok

Ran 8 tests in X.XXXs
OK
```

### 6.3 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 131 tests in X.XXXs · OK` (123 + 8)

---

## CIERRE — Commit y Respaldo (15 min)

### Actualizar `sprint4_planning.md`

```markdown
## Sprint Backlog — actualización W13

| Tarea | Estado |
|---|---|
| App catalogo + django-filter | ✅ W13 |
| ProductoFilter (nombre/categoría/precio) | ✅ W13 |
| CatalogoView pública con paginación | ✅ W13 |
| Carrito en sesión (agregar/remover/actualizar/vaciar) | ✅ W13 |
| Context processor carrito_info | ✅ W13 |
| Template catalogo.html con tarjetas | ✅ W13 |
| Template carrito.html con tabla | ✅ W13 |
| Contador carrito en navbar base.html | ✅ W13 |
| 8 tests de e-commerce | ✅ W13 |
| Checkout con Stripe sandbox | ⏳ W14 |
| Webhooks y estados de pedido | ⏳ W15 |
```

### Commit de cierre W13

```cmd
git add .
git status

:: Verificar que incluye:
::   catalogo/ (nueva app completa)
::   core/settings.py (django_filters + context processor)
::   core/urls.py (ruta catalogo/)
::   templates/base.html (enlace catálogo + contador carrito)
::   tests/test_w13_ecommerce.py
::   sprint4_planning.md

git commit -m "Sprint 4 W13: catálogo + carrito sesión + django-filter + 131 tests OK"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W13

### Técnico

```
INSTALACIÓN Y CONFIGURACIÓN
[ ] pip install django-filter → sin errores
[ ] 'django_filters' en INSTALLED_APPS (nombre con guión bajo)
[ ] 'catalogo' en INSTALLED_APPS
[ ] context_processor 'catalogo.context_processors.carrito_info' en TEMPLATES

APP CATALOGO
[ ] catalogo/filters.py: ProductoFilter con 4 campos
[ ] catalogo/views.py: CatalogoView + 5 vistas del carrito
[ ] catalogo/context_processors.py: carrito_info()
[ ] catalogo/urls.py: 7 rutas (catalogo + carrito × 5 + checkout placeholder)
[ ] core/urls.py: path('catalogo/', include('catalogo.urls'))

CARRITO EN SESIÓN
[ ] Clave del carrito: str(producto.pk) (no int)
[ ] Precio guardado como str (no Decimal — no JSON serializable)
[ ] _guardar_carrito: session.modified = True
[ ] agregar_al_carrito: solo acepta POST
[ ] remover_del_carrito: solo acepta POST
[ ] actualizar_cantidad: cantidad=0 elimina el item
[ ] vaciar_carrito: limpia toda la sesión del carrito

TEMPLATES
[ ] catalogo/catalogo.html: tarjetas con imagen, precio, badge stock
[ ] catalogo/catalogo.html: formulario filtros con django_filters
[ ] catalogo/catalogo.html: form POST para agregar con {% csrf_token %}
[ ] catalogo/carrito.html: tabla con cantidad editable + botón remover
[ ] catalogo/carrito.html: total calculado en <tfoot>
[ ] catalogo/checkout_pendiente.html: placeholder W14
[ ] base.html: enlace "Tienda" + contador carrito visible

CONTEXT PROCESSOR
[ ] carrito_total_items disponible en base.html sin pasarlo manualmente
[ ] Contador en navbar se actualiza tras agregar al carrito

TESTS
[ ] test tests.test_w13_ecommerce → 8/8 OK
[ ] test tests → 131/131 OK acumulados
[ ] test catálogo sin auth → 200
[ ] test catálogo no muestra inactivos
[ ] test filtro por nombre
[ ] test carrito vacío al inicio
[ ] test agregar acumula cantidad
[ ] test total correcto (2×350 = 700)

GIT
[ ] sprint4_planning.md con 8 HUs y Sprint Goal
[ ] Commit con mensaje descriptivo
[ ] git push → GitHub con app catalogo completa
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Flujo del carrito de compras (W13)

```
Visitante (sin auth) → GET /catalogo/
    │
    ▼
CatalogoView
    ├── ProductoFilter(request.GET, queryset=Producto.activos())
    │       → filtrar por nombre/categoría/precio
    └── render catalogo/catalogo.html
            → 12 tarjetas por página con formularios POST

POST /catalogo/carrito/agregar/1/
    │ (cualquier visitante — sin auth requerida)
    ▼
agregar_al_carrito(request, producto_id=1)
    │
    ├── carrito = request.session.get('carrito', {})
    │        → {'1': {'nombre': 'Laptop', 'precio': '10000', 'cantidad': 1}}
    ├── request.session['carrito'] = carrito
    ├── request.session.modified   = True
    └── redirect → página anterior (HTTP_REFERER)

GET /catalogo/carrito/
    │
    ▼
ver_carrito(request)
    ├── carrito = request.session.get('carrito', {})
    ├── Calcular total: sum(Decimal(precio) × cantidad)
    └── render catalogo/carrito.html
            → tabla con items + total + botón checkout

Context Processor (en CADA petición):
    carrito_info(request)
        → carrito_total_items = sum(item['cantidad'])
        → disponible en base.html como {{ carrito_total_items }}
        → navbar siempre muestra el contador actualizado
```

---

## HILO CONDUCTOR → W14

**¿Qué entrega W13?**
El catálogo público filtrable y el carrito de compras en sesión.
El visitante puede explorar productos, filtrarlos y agregarlos al carrito
sin necesidad de registrarse. 131 tests verifican la estabilidad.

**¿Qué abre W14?**
Con el carrito funcionando, W14 implementa el **checkout** completo:
formulario de datos del cliente, integración con **Stripe** en modo
sandbox y la creación del pedido con estado `pendiente`.

**¿Qué necesita W14 de W13?**

| Artefacto de W13 | Uso en W14 |
|---|---|
| `request.session['carrito']` | Checkout lee el carrito para crear las líneas del pedido |
| `Pedido` model (W05) | W14 crea el Pedido con estado `pendiente` al iniciar el pago |
| URL `catalogo:checkout` (placeholder) | W14 reemplaza `TemplateView` con `CheckoutView` real |
| `carrito_total_items` (context processor) | El template de checkout muestra el número de items |

**Tarea de investigación para W14:**
> Lee la documentación de Stripe sobre `PaymentIntent`:
> `https://stripe.com/docs/api/payment_intents`
>
> ¿Qué es un `PaymentIntent` y qué estados puede tener?
> ¿Qué tarjeta de prueba produce un pago exitoso?
> ¿Qué tarjeta simula un pago rechazado?

**Pregunta de reflexión:**
> "El carrito usa `request.session`, que es ephemeral (se pierde si
> el usuario cierra el navegador sin 'recordar sesión').
> ¿Qué estrategia usarías para que el carrito persista incluso
> después de cerrar el navegador? ¿Base de datos o cookie firmada?"

---

## Referencia rápida de comandos W13

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py runserver

:: TESTS
python manage.py test tests.test_w13_ecommerce --verbosity=2
python manage.py test tests --verbosity=0   (131 tests)

:: GIT
git add .
git commit -m "Sprint 4 W13: catálogo + carrito + 131 tests OK"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W13 · ERP Django*
*Espiral 5 · Sprint 4 Planning · Catálogo Público + Carrito de Compras*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*