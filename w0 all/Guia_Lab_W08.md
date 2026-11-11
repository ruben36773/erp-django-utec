# Guía de Laboratorio — W08
## ERP Django · Espiral 3 · Semana 8 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W08 de 24 |
| **Espiral** | E3 — CRUD Web y Autenticación |
| **Sprint Scrum** | Sprint 2 — Desarrollo |
| **Hito** | Sin hito propio · Avance hacia M3 (W09) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 2 — Núcleo ERP |
| **Hilo conductor** | "W07 abrió las ventanas para ver los datos. W08 abre las puertas para modificarlos." |

---

## Respuesta a la tarea de investigación de W07

> **¿Por qué `reverse_lazy` y no `reverse` en `success_url`?**
>
> ```python
> # INCORRECTO — falla con ImproperlyConfigured
> class ProductoCreateView(LoginRequiredMixin, CreateView):
>     success_url = reverse('productos:lista')   # ← se evalúa al importar el módulo
>                                                 #   antes de que las URLs carguen
>
> # CORRECTO — se evalúa en tiempo de ejecución (cuando ya cargaron las URLs)
> class ProductoCreateView(LoginRequiredMixin, CreateView):
>     success_url = reverse_lazy('productos:lista')  # ← lazy = diferido
> ```
>
> `reverse()` se ejecuta cuando Python importa el archivo `views.py`.
> En ese momento las URLs de Django todavía no están configuradas,
> lo que lanza `django.core.exceptions.ImproperlyConfigured`.
> `reverse_lazy()` devuelve un objeto proxy que solo resuelve la URL
> cuando se accede por primera vez durante una petición real.
>
> **Regla:** en atributos de clase de CBV → siempre `reverse_lazy`.
> En el cuerpo de funciones o métodos → `reverse` es correcto.

---

## Objetivos de la sesión

Al terminar W08, el estudiante será capaz de:

1. Crear `forms.py` con `ModelForm` y widgets Fable 5 AzulERP para 4 apps
2. Implementar `CreateView`, `UpdateView` y `DeleteView` protegidas con
   `LoginRequiredMixin` como primer argumento en la herencia
3. Agregar mensajes flash con `django.contrib.messages` en cada operación
4. Crear 12 templates de escritura con confirmación POST en `DeleteView`
5. Descomentar y completar las rutas de escritura en los 4 `urls.py`
6. Escribir 12 tests que verifican autenticación, POST válido/inválido y borrado

---

## Stack tecnológico de W08

| Herramienta / Concepto | Novedad en W08 | Descripción |
|---|---|---|
| `CreateView` (CBV) | ✅ Nuevo | Vista genérica para formularios de alta |
| `UpdateView` (CBV) | ✅ Nuevo | Vista genérica para edición |
| `DeleteView` (CBV) | ✅ Nuevo | Vista genérica de confirmación y borrado |
| `LoginRequiredMixin` | ✅ Nuevo | Protege vistas; redirige a login si no autenticado |
| `ModelForm` | ✅ Nuevo | Formulario generado desde el modelo |
| `reverse_lazy` | ✅ Nuevo | URL diferida para `success_url` en CBV |
| `django.contrib.messages` | ✅ Nuevo | Mensajes flash (success, error, warning) |
| `{% csrf_token %}` | ya usado | Token de seguridad obligatorio en formularios POST |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar W07 | 10 min |
| Parte 1 | `forms.py` × 4 apps con widgets Fable 5 | 20 min |
| Parte 2 | Vistas de escritura: Producto (Create/Update/Delete) | 20 min |
| Parte 3 | Vistas de escritura: Cliente + Proveedor | 15 min |
| Parte 4 | Vistas de escritura: Venta (función + DeleteView) | 15 min |
| Parte 5 | 12 templates de escritura Fable 5 AzulERP | 35 min |
| **Commit parcial** | Punto de control seguro | 5 min |
| Parte 6 | Actualizar `urls.py` × 4 apps | 10 min |
| Parte 7 | Tests W08 (12 pruebas de escritura) | 20 min |
| Cierre | Commit final · `finalizar_sesion.bat` · hilo → W09 | 10 min |
| Buffer | | 20 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W07?
   → Implementé ListView y DetailView para 4 entidades,
     creé 8 templates Fable 5 AzulERP y actualicé las URLs.

2. ¿Qué haré en W08?
   → Crearé los forms.py, implementaré CreateView/UpdateView/DeleteView
     con LoginRequiredMixin y messages flash.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 78 tests … OK`

---

## PARTE 1 — `forms.py` × 4 apps con widgets Fable 5 (20 min)

### 1.1 Concepto: `ModelForm` vs `Form`

```
Form        → campos definidos manualmente, sin relación directa al modelo
ModelForm   → campos generados automáticamente desde Meta.model
              ventaja: validaciones del modelo se heredan automáticamente
              ventaja: save() crea/actualiza el objeto directamente
```

**Regla de seguridad:** usar `Meta.fields = [...]` (lista explícita),
nunca `Meta.fields = '__all__'` — evita que campos internos
(como `creado` o `activo`) sean enviados por el usuario.

---

### 1.2 `productos/forms.py`

```python
# productos/forms.py
"""Formularios de la app productos — W08."""
from django import forms

from .models import Producto


class ProductoForm(forms.ModelForm):
    """Formulario para crear y editar productos.

    Excluye: id, creado (auto-generados).
    Incluye: activo (admin puede activar/desactivar).
    """

    class Meta:
        model  = Producto
        fields = ['nombre', 'precio', 'stock', 'categoria',
                  'proveedor', 'activo']
        widgets = {
            'nombre':    forms.TextInput(
                attrs={'class': 'erp-input',
                       'placeholder': 'Nombre del producto'}
            ),
            'precio':    forms.NumberInput(
                attrs={'class': 'erp-input', 'step': '0.01', 'min': '0'}
            ),
            'stock':     forms.NumberInput(
                attrs={'class': 'erp-input', 'min': '0'}
            ),
            'categoria': forms.Select(
                attrs={'class': 'erp-input'}
            ),
            'proveedor': forms.Select(
                attrs={'class': 'erp-input'}
            ),
        }
        labels = {
            'nombre':    'Nombre',
            'precio':    'Precio ($)',
            'stock':     'Stock disponible',
            'categoria': 'Categoría',
            'proveedor': 'Proveedor',
            'activo':    'Activo',
        }
```

---

### 1.3 `clientes/forms.py`

```python
# clientes/forms.py
"""Formularios de la app clientes — W08."""
from django import forms

from .models import Cliente


class ClienteForm(forms.ModelForm):
    """Formulario para crear y editar clientes."""

    class Meta:
        model  = Cliente
        fields = ['nombre', 'correo', 'telefono', 'activo']
        widgets = {
            'nombre':   forms.TextInput(
                attrs={'class': 'erp-input',
                       'placeholder': 'Nombre completo o razón social'}
            ),
            'correo':   forms.EmailInput(
                attrs={'class': 'erp-input',
                       'placeholder': 'correo@ejemplo.com'}
            ),
            'telefono': forms.TextInput(
                attrs={'class': 'erp-input',
                       'placeholder': '461 123 4567'}
            ),
        }
```

---

### 1.4 `proveedores/forms.py`

```python
# proveedores/forms.py
"""Formularios de la app proveedores — W08."""
from django import forms

from .models import Proveedor


class ProveedorForm(forms.ModelForm):
    """Formulario para crear y editar proveedores."""

    class Meta:
        model  = Proveedor
        fields = ['nombre', 'contacto', 'correo', 'telefono', 'activo']
        widgets = {
            'nombre':   forms.TextInput(
                attrs={'class': 'erp-input',
                       'placeholder': 'Nombre comercial'}
            ),
            'contacto': forms.TextInput(
                attrs={'class': 'erp-input',
                       'placeholder': 'Nombre de la persona de contacto'}
            ),
            'correo':   forms.EmailInput(
                attrs={'class': 'erp-input'}
            ),
            'telefono': forms.TextInput(
                attrs={'class': 'erp-input'}
            ),
        }
```

---

### 1.5 `ventas/forms.py`

```python
# ventas/forms.py
"""Formularios de la app ventas — W08."""
from django import forms

from .models import DetalleVenta, Venta


class VentaForm(forms.ModelForm):
    """Formulario para el encabezado de una venta."""

    class Meta:
        model   = Venta
        fields  = ['cliente']
        widgets = {
            'cliente': forms.Select(attrs={'class': 'erp-input'}),
        }


class DetalleVentaForm(forms.ModelForm):
    """Formulario para una línea de detalle.

    precio_unitario se pre-llena en la vista desde el producto
    seleccionado, pero el usuario puede ajustarlo.
    """

    class Meta:
        model  = DetalleVenta
        fields = ['producto', 'cantidad', 'precio_unitario']
        widgets = {
            'producto':        forms.Select(
                attrs={'class': 'erp-input'}
            ),
            'cantidad':        forms.NumberInput(
                attrs={'class': 'erp-input', 'min': '1', 'value': '1'}
            ),
            'precio_unitario': forms.NumberInput(
                attrs={'class': 'erp-input',
                       'step': '0.01', 'min': '0'}
            ),
        }
        labels = {
            'precio_unitario': 'Precio unitario ($)',
        }
```

---

## PARTE 2 — Vistas de escritura: Producto (20 min)

### 2.1 Regla crítica: `LoginRequiredMixin` va PRIMERO

```python
# INCORRECTO — MRO (Method Resolution Order) erróneo
class ProductoCreateView(CreateView, LoginRequiredMixin):
    ...   # LoginRequiredMixin no tiene efecto

# CORRECTO — LoginRequiredMixin primero en la herencia
class ProductoCreateView(LoginRequiredMixin, CreateView):
    ...   # verifica autenticación antes de procesar la vista
```

Python resuelve métodos de izquierda a derecha en la herencia múltiple.
Si `LoginRequiredMixin` va después, su `dispatch()` nunca se ejecuta.

---

### 2.2 Agregar vistas de escritura a `productos/views.py`

Agregar al final del archivo (después de `ProductoDetailView`):

```python
# productos/views.py — agregar los imports al inicio del archivo:
from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import (
    CreateView, DeleteView, DetailView, ListView, UpdateView
)

from .forms import ProductoForm


class ProductoCreateView(LoginRequiredMixin, CreateView):
    """Formulario para crear un nuevo producto.

    LoginRequiredMixin PRIMERO en la herencia (obligatorio).
    Redirige a /accounts/login/ si el usuario no está autenticado.
    """

    model         = Producto
    form_class    = ProductoForm
    template_name = 'productos/crear.html'
    success_url   = reverse_lazy('productos:lista')  # reverse_lazy (no reverse)

    def form_valid(self, form):
        """Agrega mensaje flash de éxito al guardar."""
        response = super().form_valid(form)
        messages.success(
            self.request,
            f'Producto "{self.object.nombre}" creado exitosamente.'
        )
        return response


class ProductoUpdateView(LoginRequiredMixin, UpdateView):
    """Formulario para editar un producto existente."""

    model         = Producto
    form_class    = ProductoForm
    template_name = 'productos/editar.html'
    pk_url_kwarg  = 'producto_id'
    success_url   = reverse_lazy('productos:lista')

    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(
            self.request,
            f'Producto "{self.object.nombre}" actualizado.'
        )
        return response


class ProductoDeleteView(LoginRequiredMixin, DeleteView):
    """Confirmación y borrado de un producto.

    SOLO acepta POST. El template debe incluir
    un formulario con {% csrf_token %} para evitar CSRF.
    """

    model         = Producto
    template_name = 'productos/eliminar.html'
    pk_url_kwarg  = 'producto_id'
    success_url   = reverse_lazy('productos:lista')

    def form_valid(self, form):
        nombre   = self.object.nombre
        response = super().form_valid(form)
        messages.success(
            self.request,
            f'Producto "{nombre}" eliminado.'
        )
        return response
```

---

## PARTE 3 — Vistas de escritura: Cliente + Proveedor (15 min)

### 3.1 Agregar a `clientes/views.py`

Agregar imports al inicio y las 3 vistas al final:

```python
# clientes/views.py — agregar imports al inicio:
from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import (
    CreateView, DeleteView, DetailView, ListView, UpdateView
)
from .forms import ClienteForm


class ClienteCreateView(LoginRequiredMixin, CreateView):
    """Formulario para crear un nuevo cliente."""

    model         = Cliente
    form_class    = ClienteForm
    template_name = 'clientes/crear.html'
    success_url   = reverse_lazy('clientes:lista')

    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(
            self.request,
            f'Cliente "{self.object.nombre}" creado exitosamente.'
        )
        return response


class ClienteUpdateView(LoginRequiredMixin, UpdateView):
    """Formulario para editar un cliente."""

    model         = Cliente
    form_class    = ClienteForm
    template_name = 'clientes/editar.html'
    pk_url_kwarg  = 'cliente_id'
    success_url   = reverse_lazy('clientes:lista')

    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(
            self.request,
            f'Cliente "{self.object.nombre}" actualizado.'
        )
        return response


class ClienteDeleteView(LoginRequiredMixin, DeleteView):
    """Confirmación y borrado de un cliente."""

    model         = Cliente
    template_name = 'clientes/eliminar.html'
    pk_url_kwarg  = 'cliente_id'
    success_url   = reverse_lazy('clientes:lista')

    def form_valid(self, form):
        nombre   = self.object.nombre
        response = super().form_valid(form)
        messages.success(self.request, f'Cliente "{nombre}" eliminado.')
        return response
```

### 3.2 Agregar a `proveedores/views.py`

```python
# proveedores/views.py — agregar imports al inicio:
from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from django.views.generic import (
    CreateView, DeleteView, DetailView, ListView, UpdateView
)
from .forms import ProveedorForm


class ProveedorCreateView(LoginRequiredMixin, CreateView):
    """Formulario para crear un proveedor."""

    model         = Proveedor
    form_class    = ProveedorForm
    template_name = 'proveedores/crear.html'
    success_url   = reverse_lazy('proveedores:lista')

    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(
            self.request,
            f'Proveedor "{self.object.nombre}" creado exitosamente.'
        )
        return response


class ProveedorUpdateView(LoginRequiredMixin, UpdateView):
    """Formulario para editar un proveedor."""

    model         = Proveedor
    form_class    = ProveedorForm
    template_name = 'proveedores/editar.html'
    pk_url_kwarg  = 'proveedor_id'
    success_url   = reverse_lazy('proveedores:lista')

    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(
            self.request,
            f'Proveedor "{self.object.nombre}" actualizado.'
        )
        return response


class ProveedorDeleteView(LoginRequiredMixin, DeleteView):
    """Confirmación y borrado de un proveedor."""

    model         = Proveedor
    template_name = 'proveedores/eliminar.html'
    pk_url_kwarg  = 'proveedor_id'
    success_url   = reverse_lazy('proveedores:lista')

    def form_valid(self, form):
        nombre   = self.object.nombre
        response = super().form_valid(form)
        messages.success(self.request, f'Proveedor "{nombre}" eliminado.')
        return response
```

---

## PARTE 4 — Vistas de escritura: Venta (15 min)

### 4.1 ¿Por qué `crear_venta` es una vista función y no CBV?

`CreateView` maneja **un solo formulario**. La creación de una venta
necesita **dos formularios simultáneos**: `VentaForm` (encabezado)
y `DetalleVentaForm` (línea de producto). Una vista función es más
clara para este caso que forzar un formset en un CBV.

### 4.2 Agregar a `ventas/views.py`

```python
# ventas/views.py — agregar imports al inicio:
from django.conf import settings
from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import redirect, render
from django.urls import reverse_lazy
from django.views.generic import DeleteView, DetailView, ListView

from .forms  import DetalleVentaForm, VentaForm
from .models import DetalleVenta, Venta


def crear_venta(request):
    """Crea un encabezado de venta con una línea de detalle.

    GET  → muestra los dos formularios vacíos.
    POST → valida ambos, guarda si correctos, muestra errores si no.

    Protección: redirige a login si no autenticado.
    Nota: para múltiples líneas usar formsets (implementar en Espiral 5).
    """
    if not request.user.is_authenticated:
        return redirect(
            f"{settings.LOGIN_URL}?next={request.path}"
        )

    venta_form   = VentaForm(request.POST or None)
    detalle_form = DetalleVentaForm(request.POST or None)

    if request.method == 'POST':
        if venta_form.is_valid() and detalle_form.is_valid():
            venta          = venta_form.save()
            detalle        = detalle_form.save(commit=False)
            detalle.venta  = venta
            # precio_unitario se auto-captura en save() si es None
            detalle.save()
            messages.success(
                request,
                f'Venta #{venta.pk} registrada. '
                f'Total: ${venta.total:.2f}'
            )
            return redirect('ventas:detalle', venta_id=venta.pk)

    return render(request, 'ventas/crear.html', {
        'venta_form':   venta_form,
        'detalle_form': detalle_form,
    })


class VentaDeleteView(LoginRequiredMixin, DeleteView):
    """Confirmación y borrado de una venta (y sus detalles en cascada)."""

    model         = Venta
    template_name = 'ventas/eliminar.html'
    pk_url_kwarg  = 'venta_id'
    success_url   = reverse_lazy('ventas:lista')

    def form_valid(self, form):
        pk       = self.object.pk
        response = super().form_valid(form)
        messages.success(self.request, f'Venta #{pk} eliminada.')
        return response
```

---

## PARTE 5 — 12 Templates de escritura Fable 5 AzulERP (35 min)

> **Patrón reutilizable para todos los formularios.**
> Los templates de creación y edición son casi idénticos.
> El template de eliminación solo tiene un botón de confirmación POST.

### 5.1 `productos/templates/productos/crear.html`

```html
{% extends "base.html" %}
{% block title %}Nuevo producto{% endblock %}
{% block nav_productos %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>📦 Nuevo producto</h2>
</div>

<div class="erp-card" style="max-width:640px;">
    <div class="erp-card-header">Datos del producto</div>
    <form method="post" style="margin-top:.5rem;">
        {% csrf_token %}
        {% for field in form %}
        <div class="mb-4">
            <label class="erp-label">{{ field.label }}</label>
            {{ field }}
            {% if field.errors %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            {% endif %}
        </div>
        {% endfor %}
        <div class="d-flex gap-2 mt-3">
            <button type="submit" class="btn-erp-gold">Guardar</button>
            <a href="{% url 'productos:lista' %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

### 5.2 `productos/templates/productos/editar.html`

```html
{% extends "base.html" %}
{% block title %}Editar — {{ producto.nombre }}{% endblock %}
{% block nav_productos %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>✏️ Editar: {{ producto.nombre }}</h2>
</div>

<div class="erp-card" style="max-width:640px;">
    <div class="erp-card-header">Modificar datos</div>
    <form method="post" style="margin-top:.5rem;">
        {% csrf_token %}
        {% for field in form %}
        <div class="mb-4">
            <label class="erp-label">{{ field.label }}</label>
            {{ field }}
            {% if field.errors %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            {% endif %}
        </div>
        {% endfor %}
        <div class="d-flex gap-2 mt-3">
            <button type="submit" class="btn-erp-gold">Actualizar</button>
            <a href="{% url 'productos:detalle' producto.pk %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

### 5.3 `productos/templates/productos/eliminar.html`

```html
{% extends "base.html" %}
{% block title %}Eliminar — {{ producto.nombre }}{% endblock %}
{% block nav_productos %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>🗑️ Eliminar producto</h2>
</div>

<div class="erp-card" style="max-width:540px;">
    <div class="erp-alert-danger" style="margin-bottom:1.5rem;">
        <strong>¿Eliminar "{{ producto.nombre }}"?</strong>
        <p style="margin:.5rem 0 0;">Esta acción no se puede deshacer.</p>
        <p style="margin:.25rem 0 0;font-size:.88rem;
                  color:var(--clr-muted);">
            Nota: si el producto tiene ventas asociadas,
            no podrá eliminarse (restricción PROTECT).
        </p>
    </div>
    <!-- SIEMPRE formulario POST para borrar — nunca GET -->
    <form method="post">
        {% csrf_token %}
        <div class="d-flex gap-2">
            <button type="submit" class="btn-erp-danger">
                Sí, eliminar
            </button>
            <a href="{% url 'productos:detalle' producto.pk %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

### 5.4 Templates de clientes (crear + editar + eliminar)

**`clientes/templates/clientes/crear.html`**

```html
{% extends "base.html" %}
{% block title %}Nuevo cliente{% endblock %}
{% block nav_clientes %}active{% endblock %}

{% block content %}
<div class="erp-page-title"><h2>👥 Nuevo cliente</h2></div>
<div class="erp-card" style="max-width:580px;">
    <div class="erp-card-header">Datos del cliente</div>
    <form method="post" style="margin-top:.5rem;">
        {% csrf_token %}
        {% for field in form %}
        <div class="mb-4">
            <label class="erp-label">{{ field.label }}</label>
            {{ field }}
            {% if field.errors %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            {% endif %}
        </div>
        {% endfor %}
        <div class="d-flex gap-2 mt-3">
            <button type="submit" class="btn-erp-gold">Guardar</button>
            <a href="{% url 'clientes:lista' %}" class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

**`clientes/templates/clientes/editar.html`**

```html
{% extends "base.html" %}
{% block title %}Editar — {{ cliente.nombre }}{% endblock %}
{% block nav_clientes %}active{% endblock %}

{% block content %}
<div class="erp-page-title"><h2>✏️ Editar: {{ cliente.nombre }}</h2></div>
<div class="erp-card" style="max-width:580px;">
    <div class="erp-card-header">Modificar datos</div>
    <form method="post" style="margin-top:.5rem;">
        {% csrf_token %}
        {% for field in form %}
        <div class="mb-4">
            <label class="erp-label">{{ field.label }}</label>
            {{ field }}
            {% if field.errors %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            {% endif %}
        </div>
        {% endfor %}
        <div class="d-flex gap-2 mt-3">
            <button type="submit" class="btn-erp-gold">Actualizar</button>
            <a href="{% url 'clientes:detalle' cliente.pk %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

**`clientes/templates/clientes/eliminar.html`**

```html
{% extends "base.html" %}
{% block title %}Eliminar — {{ cliente.nombre }}{% endblock %}
{% block nav_clientes %}active{% endblock %}

{% block content %}
<div class="erp-page-title"><h2>🗑️ Eliminar cliente</h2></div>
<div class="erp-card" style="max-width:540px;">
    <div class="erp-alert-danger" style="margin-bottom:1.5rem;">
        <strong>¿Eliminar a "{{ cliente.nombre }}"?</strong>
        <p style="margin:.5rem 0 0;">
            Si el cliente tiene ventas, no podrá eliminarse (PROTECT).
            Considerar usar "Activo = False" para desactivarlo.
        </p>
    </div>
    <form method="post">
        {% csrf_token %}
        <div class="d-flex gap-2">
            <button type="submit" class="btn-erp-danger">Sí, eliminar</button>
            <a href="{% url 'clientes:detalle' cliente.pk %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

### 5.5 Templates de proveedores (crear + editar + eliminar)

**`proveedores/templates/proveedores/crear.html`**

```html
{% extends "base.html" %}
{% block title %}Nuevo proveedor{% endblock %}
{% block nav_proveedores %}active{% endblock %}

{% block content %}
<div class="erp-page-title"><h2>🏭 Nuevo proveedor</h2></div>
<div class="erp-card" style="max-width:580px;">
    <div class="erp-card-header">Datos del proveedor</div>
    <form method="post" style="margin-top:.5rem;">
        {% csrf_token %}
        {% for field in form %}
        <div class="mb-4">
            <label class="erp-label">{{ field.label }}</label>
            {{ field }}
            {% if field.errors %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            {% endif %}
        </div>
        {% endfor %}
        <div class="d-flex gap-2 mt-3">
            <button type="submit" class="btn-erp-gold">Guardar</button>
            <a href="{% url 'proveedores:lista' %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

**`proveedores/templates/proveedores/editar.html`**

```html
{% extends "base.html" %}
{% block title %}Editar — {{ proveedor.nombre }}{% endblock %}
{% block nav_proveedores %}active{% endblock %}

{% block content %}
<div class="erp-page-title"><h2>✏️ Editar: {{ proveedor.nombre }}</h2></div>
<div class="erp-card" style="max-width:580px;">
    <div class="erp-card-header">Modificar datos</div>
    <form method="post" style="margin-top:.5rem;">
        {% csrf_token %}
        {% for field in form %}
        <div class="mb-4">
            <label class="erp-label">{{ field.label }}</label>
            {{ field }}
            {% if field.errors %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            {% endif %}
        </div>
        {% endfor %}
        <div class="d-flex gap-2 mt-3">
            <button type="submit" class="btn-erp-gold">Actualizar</button>
            <a href="{% url 'proveedores:detalle' proveedor.pk %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

**`proveedores/templates/proveedores/eliminar.html`**

```html
{% extends "base.html" %}
{% block title %}Eliminar — {{ proveedor.nombre }}{% endblock %}
{% block nav_proveedores %}active{% endblock %}

{% block content %}
<div class="erp-page-title"><h2>🗑️ Eliminar proveedor</h2></div>
<div class="erp-card" style="max-width:540px;">
    <div class="erp-alert-danger" style="margin-bottom:1.5rem;">
        <strong>¿Eliminar a "{{ proveedor.nombre }}"?</strong>
        <p style="margin:.5rem 0 0;">
            Los productos asociados quedarán sin proveedor (SET_NULL).
        </p>
    </div>
    <form method="post">
        {% csrf_token %}
        <div class="d-flex gap-2">
            <button type="submit" class="btn-erp-danger">Sí, eliminar</button>
            <a href="{% url 'proveedores:detalle' proveedor.pk %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

### 5.6 Templates de ventas (crear + eliminar)

**`ventas/templates/ventas/crear.html`**

```html
{% extends "base.html" %}
{% block title %}Nueva venta{% endblock %}
{% block nav_ventas %}active{% endblock %}

{% block content %}
<div class="erp-page-title"><h2>💰 Nueva venta</h2></div>

<form method="post">
    {% csrf_token %}

    <!-- Encabezado: cliente -->
    <div class="erp-card" style="max-width:640px;margin-bottom:1rem;">
        <div class="erp-card-header">Cliente</div>
        {% for field in venta_form %}
        <div class="mb-4" style="margin-top:.5rem;">
            <label class="erp-label">{{ field.label }}</label>
            {{ field }}
            {% if field.errors %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            {% endif %}
        </div>
        {% endfor %}
    </div>

    <!-- Línea de detalle: producto + cantidad + precio -->
    <div class="erp-card" style="max-width:640px;margin-bottom:1rem;">
        <div class="erp-card-header" style="background:var(--clr-royal);">
            Línea de producto
        </div>
        {% for field in detalle_form %}
        <div class="mb-4" style="margin-top:.5rem;">
            <label class="erp-label">{{ field.label }}</label>
            {{ field }}
            {% if field.errors %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            {% endif %}
        </div>
        {% endfor %}
    </div>

    <div class="d-flex gap-2">
        <button type="submit" class="btn-erp-gold">Registrar venta</button>
        <a href="{% url 'ventas:lista' %}" class="btn-erp-primary">Cancelar</a>
    </div>
</form>
{% endblock %}
```

**`ventas/templates/ventas/eliminar.html`**

```html
{% extends "base.html" %}
{% block title %}Eliminar venta #{{ venta.pk }}{% endblock %}
{% block nav_ventas %}active{% endblock %}

{% block content %}
<div class="erp-page-title"><h2>🗑️ Eliminar venta</h2></div>
<div class="erp-card" style="max-width:540px;">
    <div class="erp-alert-danger" style="margin-bottom:1.5rem;">
        <strong>¿Eliminar la venta #{{ venta.pk }}?</strong>
        <p style="margin:.5rem 0 0;">
            Cliente: {{ venta.cliente }} ·
            Total: ${{ venta.total }}
        </p>
        <p style="margin:.25rem 0 0;font-size:.88rem;">
            También se eliminarán todas las líneas de detalle (CASCADE).
        </p>
    </div>
    <form method="post">
        {% csrf_token %}
        <div class="d-flex gap-2">
            <button type="submit" class="btn-erp-danger">Sí, eliminar</button>
            <a href="{% url 'ventas:detalle' venta.pk %}"
               class="btn-erp-primary">Cancelar</a>
        </div>
    </form>
</div>
{% endblock %}
```

### COMMIT PARCIAL

```cmd
git add .
git commit -m "Sprint 2 W08: forms.py + Create/Update/Delete views + 12 templates"
```

---

## PARTE 6 — Actualizar `urls.py` × 4 apps (10 min)

### 6.1 `productos/urls.py` — descomentar rutas de escritura

```python
# productos/urls.py
"""URLs de la app productos — W08 (CRUD completo)."""
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
    # Escritura (W08) — descomentadas
    path('nuevo/',
         views.ProductoCreateView.as_view(),
         name='crear'),
    path('<int:producto_id>/editar/',
         views.ProductoUpdateView.as_view(),
         name='editar'),
    path('<int:producto_id>/eliminar/',
         views.ProductoDeleteView.as_view(),
         name='eliminar'),
]
```

### 6.2 `clientes/urls.py`

```python
# clientes/urls.py
from django.urls import path
from . import views

app_name = 'clientes'

urlpatterns = [
    path('',                          views.ClienteListView.as_view(),   name='lista'),
    path('<int:cliente_id>/',         views.ClienteDetailView.as_view(), name='detalle'),
    path('nuevo/',                    views.ClienteCreateView.as_view(), name='crear'),
    path('<int:cliente_id>/editar/',  views.ClienteUpdateView.as_view(), name='editar'),
    path('<int:cliente_id>/eliminar/',views.ClienteDeleteView.as_view(), name='eliminar'),
]
```

### 6.3 `proveedores/urls.py`

```python
# proveedores/urls.py
from django.urls import path
from . import views

app_name = 'proveedores'

urlpatterns = [
    path('',                            views.ProveedorListView.as_view(),   name='lista'),
    path('<int:proveedor_id>/',         views.ProveedorDetailView.as_view(), name='detalle'),
    path('nuevo/',                      views.ProveedorCreateView.as_view(), name='crear'),
    path('<int:proveedor_id>/editar/',  views.ProveedorUpdateView.as_view(), name='editar'),
    path('<int:proveedor_id>/eliminar/',views.ProveedorDeleteView.as_view(), name='eliminar'),
]
```

### 6.4 `ventas/urls.py`

```python
# ventas/urls.py
from django.urls import path
from . import views

app_name = 'ventas'

urlpatterns = [
    path('',                        views.VentaListView.as_view(),  name='lista'),
    path('<int:venta_id>/',         views.VentaDetailView.as_view(),name='detalle'),
    path('nueva/',                  views.crear_venta,              name='crear'),
    path('<int:venta_id>/eliminar/',views.VentaDeleteView.as_view(),name='eliminar'),
]
```

### 6.5 Verificar todo el CRUD en el navegador

```cmd
python manage.py check
python manage.py runserver
```

| URL | Acción | Status esperado |
|---|---|---|
| `GET /productos/nuevo/` sin login | — | 302 → `/accounts/login/` |
| `GET /productos/nuevo/` con login | Formulario vacío | 200 |
| `POST /productos/nuevo/` datos válidos | Crear + redirect | 302 → lista |
| `POST /productos/nuevo/` datos inválidos | Errores en form | 200 |
| `GET /productos/1/editar/` con login | Form pre-poblado | 200 |
| `POST /productos/1/eliminar/` con login | Borrar + redirect | 302 → lista |
| `GET /productos/1/eliminar/` con login | Confirmación | 200 |

---

## PARTE 7 — Tests W08 (20 min)

### 7.1 Crear `tests/test_w08_escritura.py`

```python
"""Suite de pruebas W08 — Vistas de escritura: Create, Update, Delete.

Verifica: redirección sin auth, GET con auth, POST válido,
          POST inválido, borrado con redirect.

Ejecutar con:
    python manage.py test tests.test_w08_escritura --verbosity=2

Resultado esperado:
    Ran 12 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.contrib.auth.models import User
from django.test import Client, TestCase
from django.urls import reverse

from clientes.models    import Cliente
from productos.models   import Categoria, Producto
from proveedores.models import Proveedor
from ventas.models      import Venta


class ProductoEscrituraTest(TestCase):
    """Tests de CreateView, UpdateView y DeleteView de Producto."""

    def setUp(self):
        self.user = User.objects.create_user(
            'testuser', password='testpass123'
        )
        self.cat  = Categoria.objects.create(nombre='Cat Test')
        self.prod = Producto.objects.create(
            nombre='Laptop', precio=Decimal('10000.00'),
            stock=5, categoria=self.cat
        )

    # ── Protección de autenticación ──────────────────────────────────────

    def test_crear_sin_auth_redirige_a_login(self):
        """GET /productos/nuevo/ sin login → 302 a /accounts/login/."""
        r = self.client.get(reverse('productos:crear'))
        self.assertEqual(r.status_code, 302)
        self.assertIn('/accounts/login/', r['Location'])

    def test_editar_sin_auth_redirige_a_login(self):
        """GET /productos/<id>/editar/ sin login → 302."""
        r = self.client.get(
            reverse('productos:editar', args=[self.prod.pk])
        )
        self.assertEqual(r.status_code, 302)
        self.assertIn('/accounts/login/', r['Location'])

    # ── Vistas con autenticación ─────────────────────────────────────────

    def test_crear_con_auth_http_200(self):
        """GET /productos/nuevo/ con login → 200."""
        self.client.force_login(self.user)
        r = self.client.get(reverse('productos:crear'))
        self.assertEqual(r.status_code, 200)
        self.assertTemplateUsed(r, 'productos/crear.html')

    def test_post_valido_crea_producto(self):
        """POST con datos válidos crea el producto y redirige a la lista."""
        self.client.force_login(self.user)
        datos = {
            'nombre':    'Monitor 4K',
            'precio':    '5500.00',
            'stock':     '3',
            'categoria': self.cat.pk,
            'activo':    True,
        }
        r = self.client.post(reverse('productos:crear'), datos)
        self.assertRedirects(r, reverse('productos:lista'))
        self.assertTrue(
            Producto.objects.filter(nombre='Monitor 4K').exists()
        )

    def test_post_invalido_muestra_errores(self):
        """POST con precio negativo → 200 con errores en el formulario."""
        self.client.force_login(self.user)
        datos = {
            'nombre':    'Producto mal',
            'precio':    '-100.00',   # inválido
            'stock':     '5',
            'categoria': self.cat.pk,
        }
        r = self.client.post(reverse('productos:crear'), datos)
        self.assertEqual(r.status_code, 200)
        self.assertFormError(r, 'form', 'precio',
                             'Ensure this value is greater than or equal to 0.00.')

    def test_delete_elimina_producto(self):
        """POST /productos/<id>/eliminar/ → borra el producto y redirige."""
        self.client.force_login(self.user)
        pk = self.prod.pk
        r  = self.client.post(
            reverse('productos:eliminar', args=[pk])
        )
        self.assertRedirects(r, reverse('productos:lista'))
        self.assertFalse(Producto.objects.filter(pk=pk).exists())


class ClienteEscrituraTest(TestCase):
    """Tests de CreateView de Cliente."""

    def setUp(self):
        self.user = User.objects.create_user('userC', password='pass')

    def test_crear_cliente_sin_auth_redirige(self):
        r = self.client.get(reverse('clientes:crear'))
        self.assertEqual(r.status_code, 302)

    def test_post_valido_crea_cliente(self):
        """POST válido crea el cliente y redirige."""
        self.client.force_login(self.user)
        r = self.client.post(reverse('clientes:crear'), {
            'nombre': 'María López',
            'correo': 'maria@test.com',
            'activo': True,
        })
        self.assertRedirects(r, reverse('clientes:lista'))
        self.assertTrue(
            Cliente.objects.filter(correo='maria@test.com').exists()
        )

    def test_post_correo_duplicado_muestra_error(self):
        """POST con correo ya existente → 200 con error de unicidad."""
        Cliente.objects.create(nombre='Ana', correo='dup@test.com')
        self.client.force_login(self.user)
        r = self.client.post(reverse('clientes:crear'), {
            'nombre': 'Otro',
            'correo': 'dup@test.com',
            'activo': True,
        })
        self.assertEqual(r.status_code, 200)
        self.assertContains(r, 'ya existe')


class ProveedorEscrituraTest(TestCase):
    """Tests de CreateView y DeleteView de Proveedor."""

    def setUp(self):
        self.user = User.objects.create_user('userP', password='pass')
        self.prov = Proveedor.objects.create(
            nombre='Prov Test', correo='prov@test.com'
        )

    def test_crear_proveedor_sin_auth_redirige(self):
        r = self.client.get(reverse('proveedores:crear'))
        self.assertEqual(r.status_code, 302)

    def test_delete_proveedor_con_auth(self):
        """POST /proveedores/<id>/eliminar/ → borra y redirige."""
        self.client.force_login(self.user)
        pk = self.prov.pk
        r  = self.client.post(
            reverse('proveedores:eliminar', args=[pk])
        )
        self.assertRedirects(r, reverse('proveedores:lista'))
        self.assertFalse(Proveedor.objects.filter(pk=pk).exists())


class VentaEscrituraTest(TestCase):
    """Tests de crear_venta y VentaDeleteView."""

    def setUp(self):
        self.user = User.objects.create_user('userV', password='pass')
        cat       = Categoria.objects.create(nombre='Cat')
        self.prod = Producto.objects.create(
            nombre='P', precio=Decimal('100.00'), stock=5, categoria=cat
        )
        self.cli  = Cliente.objects.create(nombre='C', correo='c@t.com')

    def test_crear_venta_sin_auth_redirige(self):
        r = self.client.get(reverse('ventas:crear'))
        self.assertEqual(r.status_code, 302)

    def test_post_valido_crea_venta(self):
        """POST válido crea Venta + DetalleVenta y redirige al detalle."""
        self.client.force_login(self.user)
        r = self.client.post(reverse('ventas:crear'), {
            'cliente':         self.cli.pk,
            'producto':        self.prod.pk,
            'cantidad':        2,
            'precio_unitario': '100.00',
        })
        self.assertEqual(r.status_code, 302)
        self.assertEqual(Venta.objects.count(), 1)
        venta = Venta.objects.first()
        self.assertEqual(venta.total, Decimal('200.00'))
```

### 7.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w08_escritura --verbosity=2
```

**Resultado esperado:**
```
test_crear_cliente_sin_auth_redirige ... ok
test_crear_proveedor_sin_auth_redirige ... ok
test_crear_sin_auth_redirige_a_login ... ok
test_crear_venta_sin_auth_redirige ... ok
test_crear_con_auth_http_200 ... ok
test_delete_elimina_producto ... ok
test_delete_proveedor_con_auth ... ok
test_editar_sin_auth_redirige_a_login ... ok
test_post_correo_duplicado_muestra_error ... ok
test_post_invalido_muestra_errores ... ok
test_post_valido_crea_cliente ... ok
test_post_valido_crea_producto ... ok
test_post_valido_crea_venta ... ok

Ran 12 tests in X.XXXs
OK
```

### 7.3 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 90 tests in X.XXXs · OK` (78 + 12)

---

## CIERRE — Commit Final y Respaldo (10 min)

### Actualizar `sprint2_planning.md`

```markdown
## Sprint Backlog — actualización W08

| Tarea | Estado |
|---|---|
| ListView + DetailView × 4 apps | ✅ W07 |
| 8 templates lista + detalle | ✅ W07 |
| forms.py × 4 apps (ModelForm + widgets erp-input) | ✅ W08 |
| CreateView + UpdateView + DeleteView × 3 apps | ✅ W08 |
| crear_venta (función) + VentaDeleteView | ✅ W08 |
| 12 templates crear + editar + eliminar | ✅ W08 |
| Descomentar rutas escritura en urls.py × 4 | ✅ W08 |
| messages flash en cada operación CRUD | ✅ W08 |
| 12 tests de escritura (auth + POST válido/inválido) | ✅ W08 |
| Login/Logout + LoginRequired ya aplicado | ✅ W08 |
| 3 roles RBAC (Gerente/Vendedor/Almacén) | ⏳ W09 |
```

### Commit de cierre W08

```cmd
git add .
git status

:: Verificar que incluye:
::   */forms.py × 4 apps
::   */views.py × 4 apps (con Create/Update/Delete)
::   */urls.py × 4 apps (rutas descomentadas)
::   */templates/*/crear.html × 4
::   */templates/*/editar.html × 3 (no ventas)
::   */templates/*/eliminar.html × 4
::   tests/test_w08_escritura.py

git commit -m "Sprint 2 W08: CRUD completo + LoginRequired + messages + 90 tests OK"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W08

### Técnico

```
FORMS
[ ] productos/forms.py: ProductoForm con widgets erp-input
[ ] clientes/forms.py:  ClienteForm con widgets erp-input
[ ] proveedores/forms.py: ProveedorForm con widgets erp-input
[ ] ventas/forms.py: VentaForm + DetalleVentaForm con widgets

VISTAS DE ESCRITURA
[ ] ProductoCreateView(LoginRequiredMixin, CreateView) — Login PRIMERO
[ ] ProductoUpdateView: pk_url_kwarg='producto_id', success_url=reverse_lazy
[ ] ProductoDeleteView: pk_url_kwarg='producto_id'
[ ] ClienteCreateView + ClienteUpdateView + ClienteDeleteView: ídem
[ ] ProveedorCreateView + ProveedorUpdateView + ProveedorDeleteView: ídem
[ ] crear_venta: función con auth manual + 2 forms + messages.success
[ ] VentaDeleteView: pk_url_kwarg='venta_id'
[ ] messages.success en form_valid() de cada vista

TEMPLATES (12 nuevos archivos)
[ ] productos/crear.html + editar.html + eliminar.html
[ ] clientes/crear.html + editar.html + eliminar.html
[ ] proveedores/crear.html + editar.html + eliminar.html
[ ] ventas/crear.html (2 forms) + eliminar.html
[ ] Todos tienen {% csrf_token %} en el form
[ ] eliminar.html usa POST (no GET) — botón en <form method="post">

URLS
[ ] urls.py × 4 apps: rutas nuevo/editar/eliminar descomentadas
[ ] GET /productos/nuevo/ sin auth → 302 a /accounts/login/
[ ] GET /productos/nuevo/ con auth → 200
[ ] POST /productos/nuevo/ válido → 302 a lista con mensaje flash
[ ] POST /productos/nuevo/ inválido → 200 con errores visibles

TESTS
[ ] test tests.test_w08_escritura → 12/12 OK
[ ] test tests → 90/90 OK acumulados
[ ] test de auth verifica redirect a /accounts/login/
[ ] test POST válido verifica objeto en BD con .exists()
[ ] test POST inválido verifica assertFormError

GIT
[ ] sprint2_planning.md actualizado
[ ] Commit parcial + commit de cierre
[ ] git push → GitHub con forms + vistas + templates
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Flujo POST de Create/Update/Delete

```
POST /productos/nuevo/
    │
    ▼
Django → ProductoCreateView.dispatch()
    │
    ├── ¿Usuario autenticado?
    │       NO → redirect /accounts/login/?next=/productos/nuevo/
    │       SÍ → continuar
    │
    ▼
ProductoCreateView.post()
    │
    ├── ProductoForm(request.POST)
    │
    ├── form.is_valid()?
    │       NO  → render 'productos/crear.html' con errores (HTTP 200)
    │       SÍ  → form.save() → Producto creado en BD
    │               messages.success(request, "Producto creado...")
    │               redirect → reverse_lazy('productos:lista')
    │
    ▼
HTTP 302 → /productos/
    │
    ▼
ProductoListView → muestra lista + mensaje flash en base.html
```

---

## HILO CONDUCTOR → W09

**¿Qué entrega W08?**
CRUD completo para las 4 entidades principales con formularios Fable 5,
`LoginRequiredMixin` en todas las vistas de escritura, mensajes flash,
y 90 tests acumulados.

**¿Qué abre W09?**
Con la autenticación básica (login/logout) ya funcionando mediante
`LoginRequiredMixin`, W09 agrega **granularidad de permisos**:
3 grupos (Gerente, Vendedor, Almacén) con accesos diferenciados.

**¿Qué necesita W09 de W08?**

| Artefacto de W08 | Uso en W09 |
|---|---|
| `LoginRequiredMixin` en todas las vistas de escritura | W09 agrega `PermissionRequiredMixin` sobre ese foundation |
| `crear_venta` con check de autenticación manual | W09 lo reemplaza con `@login_required` decorator |
| 90 tests pasando | W09 agrega tests por rol (Vendedor no puede borrar, Gerente sí) |

**Tarea de investigación para W09:**
> Lee la documentación de Django sobre grupos y permisos:
> `https://docs.djangoproject.com/en/4.2/topics/auth/default/#permissions-and-authorization`
>
> ¿Cómo se crea un grupo en Django con permisos específicos?
> ¿Qué diferencia hay entre `has_perm('app.add_producto')` y
> `PermissionRequiredMixin`?

**Pregunta de reflexión:**
> "En W08 protegimos las vistas con `LoginRequiredMixin`, que verifica
> si el usuario está autenticado. ¿Es suficiente para un ERP real?
> ¿Qué pasaría si un vendedor pudiera acceder a `/productos/eliminar/`?
> ¿Cómo se resuelve eso en W09?"

---

## Referencia rápida de comandos W08

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py runserver

:: TESTS
python manage.py test tests.test_w08_escritura --verbosity=2
python manage.py test tests --verbosity=0   (90 tests)

:: GIT
git add .
git commit -m "Sprint 2 W08: descripción"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W08 · ERP Django*
*Espiral 3 · Sprint 2 Desarrollo · CRUD Completo + LoginRequiredMixin + Messages*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*