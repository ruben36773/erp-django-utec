# Guía de Laboratorio — W07
## ERP Django · Espiral 3 · Semana 7 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W07 de 24 |
| **Espiral** | E3 — CRUD Web y Autenticación |
| **Sprint Scrum** | Sprint 2 — Planning |
| **Hito** | Sin hito propio · Avance hacia M3 (W09) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 2 — Núcleo ERP |
| **Hilo conductor** | "W06 blindó los datos. W07 los pone en pantalla: ListView y DetailView." |

---

## Respuesta a la tarea de investigación de W06

> **¿Atributos obligatorios en `ListView`?**
>
> Solo **`model`** es estrictamente obligatorio.
> Sin él, Django no sabe de dónde obtener los objetos.
>
> | Atributo | ¿Obligatorio? | Valor por defecto | Descripción |
> |---|---|---|---|
> | `model` | ✅ Sí | — | Modelo a listar |
> | `template_name` | No | `app/modelname_list.html` | Plantilla HTML |
> | `context_object_name` | No | `object_list` | Nombre en el template |
> | `queryset` | No | `Model.objects.all()` | Queryset personalizado |
> | `paginate_by` | No | `None` (sin paginación) | Objetos por página |
>
> **¿Qué hace `context_object_name`?**
> Define el nombre de la variable en el template. Sin él, el contexto
> usa `object_list`, que es menos legible. Con `context_object_name='productos'`
> puedes escribir `{% for p in productos %}` en lugar de
> `{% for p in object_list %}`.
>
> **¿El admin llama `full_clean()` antes de guardar?**
> Sí. El `ModelAdmin` de Django llama `full_clean()` al procesar
> un formulario, por lo que validators y `clean()` se ejecutan
> automáticamente cuando se guarda desde el panel admin.
> Solo al hacer `obj.save()` directo en código NO se llaman.

---

## Objetivos de la sesión

Al terminar W07, el estudiante será capaz de:

1. Redactar el Sprint 2 Planning con Sprint Goal y HUs de lectura
2. Implementar `ListView` con `paginate_by`, `select_related` y
   `context_object_name` para 4 entidades
3. Implementar `DetailView` con `pk_url_kwarg` para 4 entidades
4. Crear 8 templates con Fable 5 AzulERP que extienden `base.html`
5. Actualizar `urls.py` de cada app con rutas de lista y detalle
6. Escribir 12 tests de vista que verifican HTTP, templates y contexto

---

## Stack tecnológico de W07

| Herramienta / Concepto | Novedad en W07 | Descripción |
|---|---|---|
| `ListView` (CBV) | ✅ Nuevo | Vista genérica de listado con paginación |
| `DetailView` (CBV) | ✅ Nuevo | Vista genérica de detalle por PK |
| `paginate_by` | ✅ Nuevo | Divide la lista en páginas de N objetos |
| `select_related()` | ✅ Nuevo | Evita consultas N+1 en FK |
| `prefetch_related()` | ✅ Nuevo | Evita N+1 en relaciones inversas (1:N) |
| `context_object_name` | ✅ Nuevo | Nombre legible de la variable en template |
| `pk_url_kwarg` | ✅ Nuevo | Nombre del parámetro de URL para el PK |
| `{% for %}` / `{% if %}` | ya usado | DTL para iterar y condicionar en templates |
| `{% url %}` con namespace | ya usado | Genera URLs seguras por nombre |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar M2 + Sprint 2 Planning | 15 min |
| Parte 1 | `productos/views.py`: ListView + DetailView | 20 min |
| Parte 2 | `clientes/views.py` + `proveedores/views.py` | 15 min |
| Parte 3 | `ventas/views.py`: Venta ListView + DetailView | 15 min |
| Parte 4 | 8 templates Fable 5 AzulERP (lista + detalle × 4) | 40 min |
| **Commit parcial** | Punto de control seguro | 5 min |
| Parte 5 | Actualizar `urls.py` de las 4 apps | 15 min |
| Parte 6 | Tests W07 (12 pruebas de vista) | 20 min |
| Cierre | Commit final · `finalizar_sesion.bat` · hilo → W08 | 10 min |
| Buffer | | 25 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum + Sprint 2 Planning (15 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W06?
   → Agregué clean(), instalé Jazzmin, escribí 15 tests de modelo
     y cerré el Sprint 1 con M2 declarado.

2. ¿Qué haré en W07?
   → Implementaré ListView y DetailView para 4 entidades,
     crearé los templates Fable 5 y actualizaré las URLs.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado acumulado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 66 tests … OK`

---

### Sprint 2 Planning

**Sprint Goal del Sprint 2:**
> *"Al finalizar el Sprint 2, el ERP mostrará la lista y el detalle
> de productos, clientes, proveedores y ventas en la interfaz web,
> con formularios de alta, edición y borrado protegidos por
> autenticación y roles."*

**Duración:** W07 (lectura) · W08 (escritura) · W09 (auth + M3)

Crear `sprint2_planning.md`:

```markdown
# Sprint 2 Planning — ERP Django
## Semanas W07–W09 · Espiral 3: CRUD Web y Autenticación

**Sprint Goal:**
Al finalizar el Sprint 2, el ERP mostrará lista y detalle de las
entidades principales, con formularios de alta/edición/borrado
protegidos por autenticación y 3 roles de acceso.

**Duración:** W07 (ListView/DetailView) · W08 (CreateView/UpdateView/DeleteView) · W09 (Auth+RBAC · M3)

## HUs seleccionadas

| ID | Historia | Puntos | Semana |
|---|---|---|---|
| HU-E3-01 | Como encargado, quiero ver la lista de productos | 2 | W07 |
| HU-E3-02 | Como admin, quiero ver el detalle de un producto | 2 | W07 |
| HU-E3-03 | Como encargado, quiero ver listas de clientes y proveedores | 2 | W07 |
| HU-E3-04 | Como admin, quiero ver el detalle de ventas con sus líneas | 3 | W07 |
| HU-E3-05 | Como admin, quiero crear y editar productos | 3 | W08 |
| HU-E3-06 | Como vendedor, quiero registrar nuevas ventas con detalles | 5 | W08 |
| HU-E3-07 | Como admin, quiero eliminar registros con confirmación | 2 | W08 |
| HU-E3-08 | Como dev, quiero autenticación login/logout funcional | 3 | W09 |
| HU-E3-09 | Como gerente, quiero 3 roles con permisos diferenciados | 5 | W09 |

**Total Sprint 2:** 27 puntos

## DoD — Sprint 2
- ListView responde HTTP 200 y muestra objetos de la BD
- DetailView responde 200 con datos correctos y 404 para IDs inexistentes
- Formularios de escritura requieren login (redirigen a `/accounts/login/`)
- 3 grupos Django (Gerente, Vendedor, Almacén) con permisos asignados
- python manage.py test tests → ≥ 78 tests OK
```

---

## PARTE 1 — `productos/views.py`: ListView y DetailView (20 min)

### 1.1 Concepto: N+1 y cómo evitarlo

```python
# PROBLEMA — N+1 queries
productos = Producto.objects.all()
for p in productos:
    print(p.categoria.nombre)   # 1 query por producto → N+1 total
    print(p.proveedor.nombre)   # otro N+1

# SOLUCIÓN — select_related (JOIN en una sola query)
productos = Producto.objects.select_related('categoria', 'proveedor').all()
for p in productos:
    print(p.categoria.nombre)   # ya está en memoria — 0 queries extra
```

`select_related()` funciona para `ForeignKey` y `OneToOneField` (relaciones hacia adelante).
`prefetch_related()` funciona para relaciones inversas (1:N) como `venta.detalles.all()`.

---

### 1.2 Reemplazar `productos/views.py`

```python
# productos/views.py
"""Vistas de la app productos — W07.

ListView y DetailView con select_related y paginación.
Escritura (Create/Update/Delete) se implementa en W08.
"""
from django.views.generic import DetailView, ListView

from .models import Producto


class ProductoListView(ListView):
    """Lista paginada de productos activos.

    Atributos:
        model:               Modelo a listar.
        template_name:       Plantilla HTML (Fable 5 AzulERP).
        context_object_name: Nombre de la variable en el template.
        paginate_by:         20 productos por página.
        queryset:            Solo productos activos, con FK pre-cargadas.
    """

    model               = Producto
    template_name       = 'productos/lista.html'
    context_object_name = 'productos'
    paginate_by         = 20

    def get_queryset(self):
        """Devuelve productos activos con FKs pre-cargadas (evita N+1)."""
        return (
            Producto.objects
            .select_related('categoria', 'proveedor')
            .filter(activo=True)
            .order_by('nombre')
        )


class ProductoDetailView(DetailView):
    """Detalle de un producto por ID de URL.

    Atributos:
        model:               Modelo a mostrar.
        template_name:       Plantilla HTML.
        context_object_name: Nombre en el template ('producto').
        pk_url_kwarg:        Parámetro de URL. Usa 'producto_id'
                             para ser consistente con W02.
    """

    model               = Producto
    template_name       = 'productos/detalle.html'
    context_object_name = 'producto'
    pk_url_kwarg        = 'producto_id'

    def get_queryset(self):
        """Pre-carga FKs para evitar queries adicionales en el template."""
        return Producto.objects.select_related('categoria', 'proveedor')
```

---

## PARTE 2 — `clientes/views.py` y `proveedores/views.py` (15 min)

### 2.1 `clientes/views.py`

```python
# clientes/views.py
"""Vistas de la app clientes — W07.

Lectura: ListView y DetailView.
Escritura (Create/Update/Delete): W08.
"""
from django.views.generic import DetailView, ListView

from .models import Cliente


class ClienteListView(ListView):
    """Lista paginada de clientes activos."""

    model               = Cliente
    template_name       = 'clientes/lista.html'
    context_object_name = 'clientes'
    paginate_by         = 20

    def get_queryset(self):
        return Cliente.objects.filter(activo=True).order_by('nombre')


class ClienteDetailView(DetailView):
    """Detalle de un cliente con su historial de ventas."""

    model               = Cliente
    template_name       = 'clientes/detalle.html'
    context_object_name = 'cliente'
    pk_url_kwarg        = 'cliente_id'

    def get_context_data(self, **kwargs):
        """Agrega las ventas del cliente al contexto."""
        ctx = super().get_context_data(**kwargs)
        ctx['ventas'] = (
            self.object.ventas
            .order_by('-fecha')[:10]   # últimas 10 ventas
        )
        return ctx
```

---

### 2.2 `proveedores/views.py`

```python
# proveedores/views.py
"""Vistas de la app proveedores — W07.

Lectura: ListView y DetailView.
"""
from django.views.generic import DetailView, ListView

from .models import Proveedor


class ProveedorListView(ListView):
    """Lista paginada de proveedores activos."""

    model               = Proveedor
    template_name       = 'proveedores/lista.html'
    context_object_name = 'proveedores'
    paginate_by         = 20

    def get_queryset(self):
        return Proveedor.objects.filter(activo=True).order_by('nombre')


class ProveedorDetailView(DetailView):
    """Detalle de un proveedor con sus productos asociados."""

    model               = Proveedor
    template_name       = 'proveedores/detalle.html'
    context_object_name = 'proveedor'
    pk_url_kwarg        = 'proveedor_id'

    def get_context_data(self, **kwargs):
        """Agrega los productos del proveedor al contexto."""
        ctx = super().get_context_data(**kwargs)
        ctx['productos'] = (
            self.object.productos
            .select_related('categoria')
            .filter(activo=True)
            .order_by('nombre')
        )
        return ctx
```

---

## PARTE 3 — `ventas/views.py`: Venta ListView y DetailView (15 min)

```python
# ventas/views.py
"""Vistas de la app ventas — W07.

Lectura: VentaListView y VentaDetailView.
Escritura (crear_venta): W08.
"""
from django.views.generic import DetailView, ListView

from .models import Venta


class VentaListView(ListView):
    """Lista paginada de ventas en orden cronológico inverso."""

    model               = Venta
    template_name       = 'ventas/lista.html'
    context_object_name = 'ventas'
    paginate_by         = 20

    def get_queryset(self):
        """Pre-carga cliente para evitar N+1 en la tabla de ventas."""
        return (
            Venta.objects
            .select_related('cliente')
            .order_by('-fecha')
        )


class VentaDetailView(DetailView):
    """Detalle de una venta con todas sus líneas de producto."""

    model               = Venta
    template_name       = 'ventas/detalle.html'
    context_object_name = 'venta'
    pk_url_kwarg        = 'venta_id'

    def get_queryset(self):
        """Pre-carga cliente y prefetch líneas de detalle."""
        return (
            Venta.objects
            .select_related('cliente')
            .prefetch_related('detalles__producto')
        )
```

---

## PARTE 4 — 8 Templates Fable 5 AzulERP (40 min)

> Los templates de W02 (`index.html`) eran placeholders.
> W07 los reemplaza con templates reales conectados al ORM.

### 4.1 `productos/templates/productos/lista.html`

```html
{% extends "base.html" %}
{% block title %}Productos{% endblock %}
{% block nav_productos %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>📦 Productos</h2>
    <span style="margin-left:auto;color:var(--clr-muted);font-size:.85rem;">
        {{ page_obj.paginator.count }} producto(s)
    </span>
    {% if user.is_authenticated %}
        <a href="{% url 'productos:crear' %}" class="btn-erp-gold">
            + Nuevo producto
        </a>
    {% endif %}
</div>

{% if productos %}
<table class="erp-table">
    <thead>
        <tr>
            <th>#</th>
            <th>Nombre</th>
            <th>Categoría</th>
            <th>Proveedor</th>
            <th>Precio</th>
            <th>Stock</th>
            {% if user.is_authenticated %}<th>Acciones</th>{% endif %}
        </tr>
    </thead>
    <tbody>
        {% for p in productos %}
        <tr>
            <td><code>{{ p.pk }}</code></td>
            <td>
                <a href="{% url 'productos:detalle' p.pk %}"
                   style="color:var(--clr-royal);font-weight:600;">
                    {{ p.nombre }}
                </a>
            </td>
            <td>{{ p.categoria }}</td>
            <td>{{ p.proveedor|default:"—" }}</td>
            <td style="font-weight:600;color:var(--clr-gold);">
                ${{ p.precio }}
            </td>
            <td>
                {% if p.stock < 5 %}
                    <span class="badge-erp-inactive">{{ p.stock }}</span>
                {% else %}
                    <span class="badge-erp-active">{{ p.stock }}</span>
                {% endif %}
            </td>
            {% if user.is_authenticated %}
            <td>
                <a href="{% url 'productos:editar' p.pk %}"
                   class="btn-erp-primary btn-erp-sm">Editar</a>
                <a href="{% url 'productos:eliminar' p.pk %}"
                   class="btn-erp-danger btn-erp-sm">Eliminar</a>
            </td>
            {% endif %}
        </tr>
        {% endfor %}
    </tbody>
</table>

<!-- Paginación -->
{% if is_paginated %}
<div style="display:flex;gap:.5rem;justify-content:center;margin-top:1.5rem;">
    {% if page_obj.has_previous %}
        <a href="?page={{ page_obj.previous_page_number }}"
           class="btn-erp-primary btn-erp-sm">← Anterior</a>
    {% endif %}
    <span style="padding:.35rem .75rem;color:var(--clr-muted);font-size:.88rem;">
        Página {{ page_obj.number }} de {{ page_obj.paginator.num_pages }}
    </span>
    {% if page_obj.has_next %}
        <a href="?page={{ page_obj.next_page_number }}"
           class="btn-erp-primary btn-erp-sm">Siguiente →</a>
    {% endif %}
</div>
{% endif %}

{% else %}
<div class="erp-alert-info">No hay productos registrados aún.</div>
{% endif %}
{% endblock %}
```

---

### 4.2 `productos/templates/productos/detalle.html`

```html
{% extends "base.html" %}
{% block title %}{{ producto.nombre }}{% endblock %}
{% block nav_productos %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>📦 {{ producto.nombre }}</h2>
    {% if user.is_authenticated %}
        <a href="{% url 'productos:editar' producto.pk %}"
           class="btn-erp-gold ms-auto">Editar</a>
        <a href="{% url 'productos:eliminar' producto.pk %}"
           class="btn-erp-danger">Eliminar</a>
    {% endif %}
</div>

<div class="erp-card">
    <div class="erp-card-header">Información del producto</div>
    <dl class="row" style="margin:0;">
        <dt class="col-sm-3">Categoría</dt>
        <dd class="col-sm-9">{{ producto.categoria }}</dd>

        <dt class="col-sm-3">Proveedor</dt>
        <dd class="col-sm-9">{{ producto.proveedor|default:"Sin asignar" }}</dd>

        <dt class="col-sm-3">Precio</dt>
        <dd class="col-sm-9" style="font-weight:700;color:var(--clr-gold);">
            ${{ producto.precio }}
        </dd>

        <dt class="col-sm-3">Stock</dt>
        <dd class="col-sm-9">
            {% if producto.stock < 5 %}
                <span class="badge-erp-inactive">{{ producto.stock }} unidades (bajo)</span>
            {% else %}
                <span class="badge-erp-active">{{ producto.stock }} unidades</span>
            {% endif %}
        </dd>

        <dt class="col-sm-3">Estado</dt>
        <dd class="col-sm-9">
            {% if producto.activo %}
                <span class="badge-erp-active">Activo</span>
            {% else %}
                <span class="badge-erp-inactive">Inactivo</span>
            {% endif %}
        </dd>

        <dt class="col-sm-3">Registrado</dt>
        <dd class="col-sm-9">{{ producto.creado|date:"d/m/Y H:i" }}</dd>
    </dl>
</div>

<a href="{% url 'productos:lista' %}" class="btn-erp-primary">
    ← Volver a la lista
</a>
{% endblock %}
```

---

### 4.3 `clientes/templates/clientes/lista.html`

```html
{% extends "base.html" %}
{% block title %}Clientes{% endblock %}
{% block nav_clientes %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>👥 Clientes</h2>
    <span style="margin-left:auto;color:var(--clr-muted);font-size:.85rem;">
        {{ page_obj.paginator.count }} cliente(s)
    </span>
    {% if user.is_authenticated %}
        <a href="{% url 'clientes:crear' %}" class="btn-erp-gold">+ Nuevo</a>
    {% endif %}
</div>

{% if clientes %}
<table class="erp-table">
    <thead>
        <tr>
            <th>#</th><th>Nombre</th><th>Correo</th>
            <th>Teléfono</th><th>Estado</th>
            {% if user.is_authenticated %}<th>Acciones</th>{% endif %}
        </tr>
    </thead>
    <tbody>
        {% for c in clientes %}
        <tr>
            <td><code>{{ c.pk }}</code></td>
            <td>
                <a href="{% url 'clientes:detalle' c.pk %}"
                   style="color:var(--clr-royal);font-weight:600;">
                    {{ c.nombre }}
                </a>
            </td>
            <td>{{ c.correo }}</td>
            <td>{{ c.telefono|default:"—" }}</td>
            <td>
                {% if c.activo %}
                    <span class="badge-erp-active">Activo</span>
                {% else %}
                    <span class="badge-erp-inactive">Inactivo</span>
                {% endif %}
            </td>
            {% if user.is_authenticated %}
            <td>
                <a href="{% url 'clientes:editar' c.pk %}"
                   class="btn-erp-primary btn-erp-sm">Editar</a>
                <a href="{% url 'clientes:eliminar' c.pk %}"
                   class="btn-erp-danger btn-erp-sm">Eliminar</a>
            </td>
            {% endif %}
        </tr>
        {% endfor %}
    </tbody>
</table>

{% if is_paginated %}
<div style="display:flex;gap:.5rem;justify-content:center;margin-top:1.5rem;">
    {% if page_obj.has_previous %}
        <a href="?page={{ page_obj.previous_page_number }}"
           class="btn-erp-primary btn-erp-sm">← Anterior</a>
    {% endif %}
    <span style="padding:.35rem .75rem;color:var(--clr-muted);font-size:.88rem;">
        Página {{ page_obj.number }} de {{ page_obj.paginator.num_pages }}
    </span>
    {% if page_obj.has_next %}
        <a href="?page={{ page_obj.next_page_number }}"
           class="btn-erp-primary btn-erp-sm">Siguiente →</a>
    {% endif %}
</div>
{% endif %}

{% else %}
<div class="erp-alert-info">No hay clientes registrados aún.</div>
{% endif %}
{% endblock %}
```

---

### 4.4 `clientes/templates/clientes/detalle.html`

```html
{% extends "base.html" %}
{% block title %}{{ cliente.nombre }}{% endblock %}
{% block nav_clientes %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>👤 {{ cliente.nombre }}</h2>
    {% if user.is_authenticated %}
        <a href="{% url 'clientes:editar' cliente.pk %}"
           class="btn-erp-gold ms-auto">Editar</a>
    {% endif %}
</div>

<div class="erp-card">
    <div class="erp-card-header">Datos del cliente</div>
    <dl class="row" style="margin:0;">
        <dt class="col-sm-3">Correo</dt>
        <dd class="col-sm-9">{{ cliente.correo }}</dd>
        <dt class="col-sm-3">Teléfono</dt>
        <dd class="col-sm-9">{{ cliente.telefono|default:"—" }}</dd>
        <dt class="col-sm-3">Estado</dt>
        <dd class="col-sm-9">
            {% if cliente.activo %}
                <span class="badge-erp-active">Activo</span>
            {% else %}
                <span class="badge-erp-inactive">Inactivo</span>
            {% endif %}
        </dd>
        <dt class="col-sm-3">Registrado</dt>
        <dd class="col-sm-9">{{ cliente.creado|date:"d/m/Y H:i" }}</dd>
    </dl>
</div>

<div class="erp-card">
    <div class="erp-card-header">Últimas 10 ventas</div>
    {% if ventas %}
    <table class="erp-table">
        <thead>
            <tr><th>#</th><th>Fecha</th><th>Total</th></tr>
        </thead>
        <tbody>
            {% for v in ventas %}
            <tr>
                <td>
                    <a href="{% url 'ventas:detalle' v.pk %}"
                       style="color:var(--clr-royal);">#{{ v.pk }}</a>
                </td>
                <td>{{ v.fecha|date:"d/m/Y H:i" }}</td>
                <td style="color:var(--clr-gold);font-weight:600;">
                    ${{ v.total }}
                </td>
            </tr>
            {% endfor %}
        </tbody>
    </table>
    {% else %}
    <p style="color:var(--clr-muted);">Este cliente aún no tiene ventas.</p>
    {% endif %}
</div>

<a href="{% url 'clientes:lista' %}" class="btn-erp-primary">← Volver</a>
{% endblock %}
```

---

### 4.5 `proveedores/templates/proveedores/lista.html`

```html
{% extends "base.html" %}
{% block title %}Proveedores{% endblock %}
{% block nav_proveedores %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>🏭 Proveedores</h2>
    {% if user.is_authenticated %}
        <a href="{% url 'proveedores:crear' %}"
           class="btn-erp-gold ms-auto">+ Nuevo</a>
    {% endif %}
</div>

{% if proveedores %}
<table class="erp-table">
    <thead>
        <tr>
            <th>#</th><th>Nombre</th><th>Contacto</th>
            <th>Correo</th><th>Estado</th>
            {% if user.is_authenticated %}<th>Acciones</th>{% endif %}
        </tr>
    </thead>
    <tbody>
        {% for p in proveedores %}
        <tr>
            <td><code>{{ p.pk }}</code></td>
            <td>
                <a href="{% url 'proveedores:detalle' p.pk %}"
                   style="color:var(--clr-royal);font-weight:600;">
                    {{ p.nombre }}
                </a>
            </td>
            <td>{{ p.contacto|default:"—" }}</td>
            <td>{{ p.correo }}</td>
            <td>
                {% if p.activo %}
                    <span class="badge-erp-active">Activo</span>
                {% else %}
                    <span class="badge-erp-inactive">Inactivo</span>
                {% endif %}
            </td>
            {% if user.is_authenticated %}
            <td>
                <a href="{% url 'proveedores:editar' p.pk %}"
                   class="btn-erp-primary btn-erp-sm">Editar</a>
            </td>
            {% endif %}
        </tr>
        {% endfor %}
    </tbody>
</table>
{% else %}
<div class="erp-alert-info">No hay proveedores registrados aún.</div>
{% endif %}
{% endblock %}
```

---

### 4.6 `proveedores/templates/proveedores/detalle.html`

```html
{% extends "base.html" %}
{% block title %}{{ proveedor.nombre }}{% endblock %}
{% block nav_proveedores %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>🏭 {{ proveedor.nombre }}</h2>
    {% if user.is_authenticated %}
        <a href="{% url 'proveedores:editar' proveedor.pk %}"
           class="btn-erp-gold ms-auto">Editar</a>
    {% endif %}
</div>

<div class="erp-card">
    <div class="erp-card-header">Datos del proveedor</div>
    <dl class="row" style="margin:0;">
        <dt class="col-sm-3">Contacto</dt>
        <dd class="col-sm-9">{{ proveedor.contacto|default:"—" }}</dd>
        <dt class="col-sm-3">Correo</dt>
        <dd class="col-sm-9">{{ proveedor.correo }}</dd>
        <dt class="col-sm-3">Teléfono</dt>
        <dd class="col-sm-9">{{ proveedor.telefono|default:"—" }}</dd>
        <dt class="col-sm-3">Estado</dt>
        <dd class="col-sm-9">
            {% if proveedor.activo %}
                <span class="badge-erp-active">Activo</span>
            {% else %}
                <span class="badge-erp-inactive">Inactivo</span>
            {% endif %}
        </dd>
    </dl>
</div>

<div class="erp-card">
    <div class="erp-card-header">Productos suministrados</div>
    {% if productos %}
    <table class="erp-table">
        <thead>
            <tr><th>Nombre</th><th>Categoría</th><th>Precio</th><th>Stock</th></tr>
        </thead>
        <tbody>
            {% for prod in productos %}
            <tr>
                <td>
                    <a href="{% url 'productos:detalle' prod.pk %}"
                       style="color:var(--clr-royal);">{{ prod.nombre }}</a>
                </td>
                <td>{{ prod.categoria }}</td>
                <td style="color:var(--clr-gold);">${{ prod.precio }}</td>
                <td>{{ prod.stock }}</td>
            </tr>
            {% endfor %}
        </tbody>
    </table>
    {% else %}
    <p style="color:var(--clr-muted);">Sin productos asignados.</p>
    {% endif %}
</div>

<a href="{% url 'proveedores:lista' %}" class="btn-erp-primary">← Volver</a>
{% endblock %}
```

---

### 4.7 `ventas/templates/ventas/lista.html`

```html
{% extends "base.html" %}
{% block title %}Ventas{% endblock %}
{% block nav_ventas %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>💰 Ventas</h2>
    {% if user.is_authenticated %}
        <a href="{% url 'ventas:crear' %}"
           class="btn-erp-gold ms-auto">+ Nueva venta</a>
    {% endif %}
</div>

{% if ventas %}
<table class="erp-table">
    <thead>
        <tr>
            <th>#</th><th>Cliente</th><th>Fecha</th><th>Total</th>
            {% if user.is_authenticated %}<th>Acciones</th>{% endif %}
        </tr>
    </thead>
    <tbody>
        {% for v in ventas %}
        <tr>
            <td>
                <a href="{% url 'ventas:detalle' v.pk %}"
                   style="color:var(--clr-royal);font-weight:600;">
                    #{{ v.pk }}
                </a>
            </td>
            <td>{{ v.cliente }}</td>
            <td>{{ v.fecha|date:"d/m/Y H:i" }}</td>
            <td style="font-weight:700;color:var(--clr-gold);">
                ${{ v.total }}
            </td>
            {% if user.is_authenticated %}
            <td>
                <a href="{% url 'ventas:eliminar' v.pk %}"
                   class="btn-erp-danger btn-erp-sm">Eliminar</a>
            </td>
            {% endif %}
        </tr>
        {% endfor %}
    </tbody>
</table>

{% if is_paginated %}
<div style="display:flex;gap:.5rem;justify-content:center;margin-top:1.5rem;">
    {% if page_obj.has_previous %}
        <a href="?page={{ page_obj.previous_page_number }}"
           class="btn-erp-primary btn-erp-sm">← Anterior</a>
    {% endif %}
    <span style="padding:.35rem .75rem;color:var(--clr-muted);font-size:.88rem;">
        Página {{ page_obj.number }} de {{ page_obj.paginator.num_pages }}
    </span>
    {% if page_obj.has_next %}
        <a href="?page={{ page_obj.next_page_number }}"
           class="btn-erp-primary btn-erp-sm">Siguiente →</a>
    {% endif %}
</div>
{% endif %}

{% else %}
<div class="erp-alert-info">No hay ventas registradas aún.</div>
{% endif %}
{% endblock %}
```

---

### 4.8 `ventas/templates/ventas/detalle.html`

```html
{% extends "base.html" %}
{% block title %}Venta #{{ venta.pk }}{% endblock %}
{% block nav_ventas %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>💰 Venta #{{ venta.pk }}</h2>
    {% if user.is_authenticated %}
        <a href="{% url 'ventas:eliminar' venta.pk %}"
           class="btn-erp-danger ms-auto">Eliminar venta</a>
    {% endif %}
</div>

<div class="erp-card">
    <div class="erp-card-header">Encabezado</div>
    <dl class="row" style="margin:0;">
        <dt class="col-sm-3">Cliente</dt>
        <dd class="col-sm-9">
            <a href="{% url 'clientes:detalle' venta.cliente.pk %}"
               style="color:var(--clr-royal);">{{ venta.cliente }}</a>
        </dd>
        <dt class="col-sm-3">Fecha</dt>
        <dd class="col-sm-9">{{ venta.fecha|date:"d/m/Y H:i" }}</dd>
    </dl>
</div>

<div class="erp-card">
    <div class="erp-card-header">Líneas de detalle</div>
    <table class="erp-table">
        <thead>
            <tr>
                <th>Producto</th><th>Precio unit.</th>
                <th>Cantidad</th><th>Subtotal</th>
            </tr>
        </thead>
        <tbody>
            {% for d in venta.detalles.all %}
            <tr>
                <td>
                    <a href="{% url 'productos:detalle' d.producto.pk %}"
                       style="color:var(--clr-royal);">
                        {{ d.producto.nombre }}
                    </a>
                </td>
                <td>${{ d.precio_unitario }}</td>
                <td>{{ d.cantidad }}</td>
                <td style="font-weight:600;">${{ d.subtotal }}</td>
            </tr>
            {% empty %}
            <tr>
                <td colspan="4" style="text-align:center;
                    color:var(--clr-muted);">Sin líneas de detalle.</td>
            </tr>
            {% endfor %}
        </tbody>
        <tfoot>
            <tr>
                <td colspan="3" style="text-align:right;
                    padding:.65rem 1rem;font-weight:600;">
                    Total:
                </td>
                <td style="padding:.65rem 1rem;font-weight:700;
                    color:var(--clr-gold);">
                    ${{ venta.total }}
                </td>
            </tr>
        </tfoot>
    </table>
</div>

<a href="{% url 'ventas:lista' %}" class="btn-erp-primary">← Volver</a>
{% endblock %}
```

### COMMIT PARCIAL

```cmd
git add .
git commit -m "Sprint 2 W07: 8 vistas CBV + 8 templates Fable5 AzulERP"
```

---

## PARTE 5 — Actualizar `urls.py` de las 4 apps (15 min)

### 5.1 `productos/urls.py`

```python
# productos/urls.py
"""URLs de la app productos — W07 (Lista + Detalle)."""
from django.urls import path
from . import views

app_name = 'productos'

urlpatterns = [
    # Lectura (W07)
    path('',
         views.ProductoListView.as_view(),
         name='lista'),
    path('<int:producto_id>/',
         views.ProductoDetailView.as_view(),
         name='detalle'),
    # Escritura (W08) — comentadas hasta implementarlas
    # path('nuevo/',                    views.ProductoCreateView.as_view(), name='crear'),
    # path('<int:producto_id>/editar/',  views.ProductoUpdateView.as_view(), name='editar'),
    # path('<int:producto_id>/eliminar/',views.ProductoDeleteView.as_view(), name='eliminar'),
]
```

### 5.2 `clientes/urls.py`

```python
# clientes/urls.py
"""URLs de la app clientes — W07 (Lista + Detalle)."""
from django.urls import path
from . import views

app_name = 'clientes'

urlpatterns = [
    path('',
         views.ClienteListView.as_view(),
         name='lista'),
    path('<int:cliente_id>/',
         views.ClienteDetailView.as_view(),
         name='detalle'),
    # path('nuevo/',                   views.ClienteCreateView.as_view(),  name='crear'),
    # path('<int:cliente_id>/editar/', views.ClienteUpdateView.as_view(),  name='editar'),
    # path('<int:cliente_id>/eliminar/',views.ClienteDeleteView.as_view(), name='eliminar'),
]
```

### 5.3 `proveedores/urls.py`

```python
# proveedores/urls.py
"""URLs de la app proveedores — W07."""
from django.urls import path
from . import views

app_name = 'proveedores'

urlpatterns = [
    path('',
         views.ProveedorListView.as_view(),
         name='lista'),
    path('<int:proveedor_id>/',
         views.ProveedorDetailView.as_view(),
         name='detalle'),
    # path('nuevo/',                      views.ProveedorCreateView.as_view(),  name='crear'),
    # path('<int:proveedor_id>/editar/',   views.ProveedorUpdateView.as_view(),  name='editar'),
    # path('<int:proveedor_id>/eliminar/', views.ProveedorDeleteView.as_view(), name='eliminar'),
]
```

### 5.4 `ventas/urls.py`

```python
# ventas/urls.py
"""URLs de la app ventas — W07."""
from django.urls import path
from . import views

app_name = 'ventas'

urlpatterns = [
    path('',
         views.VentaListView.as_view(),
         name='lista'),
    path('<int:venta_id>/',
         views.VentaDetailView.as_view(),
         name='detalle'),
    # path('nueva/',                  views.crear_venta,                 name='crear'),
    # path('<int:venta_id>/eliminar/',views.VentaDeleteView.as_view(),   name='eliminar'),
]
```

### 5.5 Verificar las 8 rutas en el navegador

```cmd
python manage.py check
python manage.py runserver
```

| URL | Resultado esperado | Status |
|---|---|---|
| `/productos/` | Tabla de productos con paginación | 200 |
| `/productos/1/` | Detalle del primer producto | 200 |
| `/productos/9999/` | Página de error 404 | 404 |
| `/clientes/` | Tabla de clientes | 200 |
| `/clientes/1/` | Detalle con últimas ventas | 200 |
| `/proveedores/` | Tabla de proveedores | 200 |
| `/proveedores/1/` | Detalle con productos asociados | 200 |
| `/ventas/` | Tabla de ventas | 200 |
| `/ventas/1/` | Detalle con líneas y total | 200 |

---

## PARTE 6 — Tests W07 (20 min)

### 6.1 Crear `tests/test_w07_vistas_lectura.py`

```python
"""Suite de pruebas W07 — Vistas de lectura: ListView y DetailView.

Verifica: HTTP 200, templates correctos, contexto con objetos,
          paginación y 404 para IDs inexistentes.

Ejecutar con:
    python manage.py test tests.test_w07_vistas_lectura --verbosity=2

Resultado esperado:
    Ran 12 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.test import Client, TestCase
from django.urls import reverse

from clientes.models    import Cliente
from productos.models   import Categoria, Producto
from proveedores.models import Proveedor
from ventas.models      import DetalleVenta, Venta


class ProductoVistaTest(TestCase):
    """Tests de ListView y DetailView de Producto."""

    def setUp(self):
        self.cat  = Categoria.objects.create(nombre='Cat Test')
        self.prod = Producto.objects.create(
            nombre='Laptop Test', precio=Decimal('10000.00'),
            stock=5, categoria=self.cat
        )

    def test_lista_productos_http_200(self):
        """GET /productos/ debe devolver HTTP 200."""
        r = self.client.get(reverse('productos:lista'))
        self.assertEqual(r.status_code, 200)

    def test_lista_productos_usa_template_correcto(self):
        """GET /productos/ debe renderizar productos/lista.html."""
        r = self.client.get(reverse('productos:lista'))
        self.assertTemplateUsed(r, 'productos/lista.html')

    def test_lista_muestra_producto_en_contexto(self):
        """El contexto de la lista debe contener el producto creado."""
        r = self.client.get(reverse('productos:lista'))
        self.assertIn('productos', r.context)
        self.assertContains(r, 'Laptop Test')

    def test_detalle_producto_http_200(self):
        """GET /productos/<id>/ debe devolver HTTP 200."""
        r = self.client.get(
            reverse('productos:detalle', args=[self.prod.pk])
        )
        self.assertEqual(r.status_code, 200)

    def test_detalle_producto_404_id_inexistente(self):
        """GET /productos/9999/ debe devolver HTTP 404."""
        r = self.client.get(
            reverse('productos:detalle', args=[9999])
        )
        self.assertEqual(r.status_code, 404)

    def test_lista_paginacion_20_por_pagina(self):
        """Con 25 productos, la página 1 debe mostrar máximo 20."""
        for i in range(24):   # ya existe 1 del setUp → total 25
            Producto.objects.create(
                nombre=f'Prod {i}', precio=Decimal('10.00'),
                stock=1, categoria=self.cat
            )
        r = self.client.get(reverse('productos:lista'))
        self.assertEqual(len(r.context['productos']), 20)
        self.assertTrue(r.context['is_paginated'])


class ClienteVistaTest(TestCase):
    """Tests de ListView y DetailView de Cliente."""

    def setUp(self):
        self.cli = Cliente.objects.create(
            nombre='Ana García', correo='ana@test.com'
        )

    def test_lista_clientes_http_200(self):
        r = self.client.get(reverse('clientes:lista'))
        self.assertEqual(r.status_code, 200)

    def test_lista_clientes_template_correcto(self):
        r = self.client.get(reverse('clientes:lista'))
        self.assertTemplateUsed(r, 'clientes/lista.html')

    def test_detalle_cliente_contiene_nombre(self):
        """El detalle debe mostrar el nombre del cliente."""
        r = self.client.get(
            reverse('clientes:detalle', args=[self.cli.pk])
        )
        self.assertEqual(r.status_code, 200)
        self.assertContains(r, 'Ana García')


class ProveedorVistaTest(TestCase):
    """Tests de ListView de Proveedor."""

    def setUp(self):
        self.prov = Proveedor.objects.create(
            nombre='Dist. Norte', correo='norte@dist.com'
        )

    def test_lista_proveedores_http_200(self):
        r = self.client.get(reverse('proveedores:lista'))
        self.assertEqual(r.status_code, 200)

    def test_detalle_proveedor_http_200(self):
        r = self.client.get(
            reverse('proveedores:detalle', args=[self.prov.pk])
        )
        self.assertEqual(r.status_code, 200)


class VentaVistaTest(TestCase):
    """Tests de ListView y DetailView de Venta."""

    def setUp(self):
        cat   = Categoria.objects.create(nombre='Cat')
        prod  = Producto.objects.create(
            nombre='P', precio=Decimal('100.00'),
            stock=5, categoria=cat
        )
        cli   = Cliente.objects.create(nombre='C', correo='c@t.com')
        self.venta = Venta.objects.create(cliente=cli)
        DetalleVenta.objects.create(
            venta=self.venta, producto=prod,
            cantidad=2, precio_unitario=Decimal('100.00')
        )

    def test_lista_ventas_http_200(self):
        r = self.client.get(reverse('ventas:lista'))
        self.assertEqual(r.status_code, 200)

    def test_detalle_venta_muestra_total(self):
        """El detalle de venta debe mostrar el total calculado."""
        r = self.client.get(
            reverse('ventas:detalle', args=[self.venta.pk])
        )
        self.assertEqual(r.status_code, 200)
        self.assertContains(r, '200.00')   # total = 2 × 100
```

### 6.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w07_vistas_lectura --verbosity=2
```

**Resultado esperado:**
```
test_detalle_cliente_contiene_nombre ... ok
test_detalle_producto_404_id_inexistente ... ok
test_detalle_producto_http_200 ... ok
test_detalle_proveedor_http_200 ... ok
test_detalle_venta_muestra_total ... ok
test_lista_clientes_http_200 ... ok
test_lista_clientes_template_correcto ... ok
test_lista_muestra_producto_en_contexto ... ok
test_lista_paginacion_20_por_pagina ... ok
test_lista_productos_http_200 ... ok
test_lista_productos_usa_template_correcto ... ok
test_lista_ventas_http_200 ... ok

Ran 12 tests in X.XXXs
OK
```

### 6.3 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 78 tests in X.XXXs · OK` (66 + 12)

---

## CIERRE — Commit Final y Respaldo (10 min)

### Actualizar `sprint2_planning.md`

```markdown
## Sprint Backlog — actualización W07

| Tarea | Estado |
|---|---|
| ListView + DetailView para 4 apps | ✅ W07 |
| 8 templates lista.html + detalle.html | ✅ W07 |
| urls.py con rutas lista y detalle | ✅ W07 |
| select_related/prefetch_related anti N+1 | ✅ W07 |
| 12 tests de vistas de lectura | ✅ W07 |
| CreateView + UpdateView + DeleteView | ⏳ W08 |
| Login/Logout + LoginRequiredMixin | ⏳ W09 |
| 3 roles RBAC | ⏳ W09 |
```

### Commit de cierre W07

```cmd
git add .
git status

:: Verificar que incluye:
::   */views.py (4 apps actualizadas)
::   */urls.py  (4 apps actualizadas)
::   */templates/*/lista.html (4 nuevas)
::   */templates/*/detalle.html (4 nuevas)
::   tests/test_w07_vistas_lectura.py
::   sprint2_planning.md

git commit -m "Sprint 2 W07: ListView+DetailView x4 + 8 templates + 78 tests OK"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W07

### Técnico

```
VISTAS CBV
[ ] ProductoListView: model, template, context_object_name='productos',
    paginate_by=20, select_related('categoria','proveedor')
[ ] ProductoDetailView: pk_url_kwarg='producto_id', select_related
[ ] ClienteListView: paginate_by=20, get_context_data con ventas
[ ] ClienteDetailView: pk_url_kwarg='cliente_id', últimas 10 ventas
[ ] ProveedorListView + ProveedorDetailView: productos asociados en contexto
[ ] VentaListView: select_related('cliente')
[ ] VentaDetailView: prefetch_related('detalles__producto')

TEMPLATES (8 archivos)
[ ] productos/lista.html: tabla erp-table + paginación + badge stock
[ ] productos/detalle.html: dl.row con todos los campos
[ ] clientes/lista.html: tabla + estado badge
[ ] clientes/detalle.html: datos + últimas ventas
[ ] proveedores/lista.html: tabla completa
[ ] proveedores/detalle.html: datos + lista de productos
[ ] ventas/lista.html: tabla + total calculado
[ ] ventas/detalle.html: tabla de detalles + tfoot con total

URLs
[ ] 4 apps actualizadas con rutas 'lista' y 'detalle'
[ ] Rutas de escritura comentadas (pendientes W08)
[ ] python manage.py check → 0 issues
[ ] Las 8 URLs devuelven HTTP 200 en el navegador
[ ] /productos/9999/ devuelve 404

TESTS
[ ] test tests.test_w07_vistas_lectura → 12/12 OK
[ ] test tests → 78/78 OK acumulados
[ ] test de paginación: 25 productos → página 1 tiene 20

SCRUM / GIT
[ ] sprint2_planning.md actualizado con estados W07
[ ] Commit parcial post-templates + commit de cierre
[ ] git push → GitHub actualizado
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Flujo de una petición GET en W07

```
Navegador: GET /productos/
    │
    ▼
core/urls.py
  path('productos/', include('productos.urls', namespace='productos'))
    │
    ▼
productos/urls.py
  path('', ProductoListView.as_view(), name='lista')
    │
    ▼
productos/views.py — ProductoListView
  get_queryset():
    Producto.objects
      .select_related('categoria', 'proveedor')   ← 1 sola query SQL
      .filter(activo=True)
      .order_by('nombre')
    │
    ├── paginate_by=20 → divide en páginas
    └── context_object_name='productos'
    │
    ▼
Django Template Engine
  productos/templates/productos/lista.html
  {% extends "base.html" %}           ← Fable 5 AzulERP
  {% for p in productos %}
      {{ p.nombre }}                  ← sin query extra (select_related)
      {{ p.categoria.nombre }}        ← sin query extra
  {% endfor %}
    │
    ▼
HTML con tabla erp-table + paginación + badges → Navegador
```

---

## HILO CONDUCTOR → W08

**¿Qué entrega W07?**
Las vistas de **lectura** completas: lista paginada y detalle para
productos, clientes, proveedores y ventas, con templates Fable 5
AzulERP y select_related para rendimiento óptimo.

**¿Qué abre W08?**
Con la lectura funcionando, W08 implementa la **escritura**:
`CreateView`, `UpdateView`, `DeleteView` con `ModelForm`,
mensajes flash y protección con `LoginRequiredMixin`.

**¿Qué necesita W08 de W07?**

| Artefacto de W07 | Uso en W08 |
|---|---|
| `urls.py` con rutas comentadas | W08 las descomenta y agrega las vistas |
| Templates `lista.html` con enlace "Nuevo" y "Editar" | Ya tienen los `{% url %}` listos; W08 hace que funcionen |
| `pk_url_kwarg` consistente | W08 usa el mismo nombre en UpdateView/DeleteView |
| Suite de 78 tests | W08 agrega tests de formularios POST |

**Tarea de investigación para W08:**
> Lee la documentación de Django sobre `CreateView` y `reverse_lazy`:
> `https://docs.djangoproject.com/en/4.2/ref/class-based-views/generic-editing/`
>
> ¿Por qué se usa `reverse_lazy` (con lazy) en lugar de `reverse` en
> el atributo `success_url` de un CBV? ¿Qué error produce usar `reverse`?

**Pregunta de reflexión:**
> "Los templates de W07 ya tienen los enlaces `{% url 'productos:editar' p.pk %}`
> y `{% url 'productos:crear' %}` escritos, aunque aún apuntan a URLs que no
> existen. ¿Qué pasaría si el usuario hace clic ahora en esos botones?
> ¿Y qué pasará en W08 cuando implementemos esas vistas?"

---

## Referencia rápida de comandos W07

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py runserver

:: TESTS
python manage.py test tests.test_w07_vistas_lectura --verbosity=2
python manage.py test tests --verbosity=0   (78 tests)

:: GIT
git add .
git commit -m "Sprint 2 W07: descripción"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W07 · ERP Django*
*Espiral 3 · Sprint 2 Planning · ListView + DetailView + Templates Fable 5*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*