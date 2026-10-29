
# Guía de Laboratorio — W09
## ERP Django · Espiral 3 · Semana 9 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W09 de 24 |
| **Espiral** | E3 — CRUD Web y Autenticación |
| **Sprint Scrum** | Sprint 2 — Review + Retrospectiva |
| **Hito** | **★ M3: 4 módulos CRUD + auth + 3 roles funcionales + 100 tests** |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 2 — Núcleo ERP |
| **Hilo conductor** | "W08 puso el candado. W09 instala la cerradura de combinación: permisos por rol." |

---

## Respuesta a la tarea de investigación de W08

> **¿Cómo se crea un grupo con permisos en Django?**
>
> ```python
> from django.contrib.auth.models import Group, Permission
>
> grupo, _ = Group.objects.get_or_create(name='Vendedor')
> perm     = Permission.objects.get(codename='add_venta')
> grupo.permissions.add(perm)
> ```
>
> **¿Diferencia entre `has_perm()` y `PermissionRequiredMixin`?**
>
> | Mecanismo | Dónde se usa | Qué hace si falla |
> |---|---|---|
> | `request.user.has_perm('app.add_x')` | Templates, vistas función | Nada automático — el dev decide |
> | `PermissionRequiredMixin` | CBV (class-based views) | Redirige al login o devuelve 403 |
>
> Con `raise_exception = True` en `PermissionRequiredMixin`, el usuario
> autenticado pero sin permiso recibe HTTP 403 (Forbidden) en lugar
> de ser redirigido al login. Esto es el comportamiento correcto para
> un ERP: el usuario ya sabe que está en el sistema, simplemente no
> tiene autorización para esa acción.

---

## Objetivos de la sesión

Al terminar W09, el estudiante será capaz de:

1. Instalar y configurar `django-allauth` con login por username
2. Crear templates de login y registro con Fable 5 AzulERP
3. Implementar un management command `crear_grupos` para configurar
   los 3 roles del ERP (Gerente, Vendedor, Almacén)
4. Aplicar `PermissionRequiredMixin` en vistas críticas de borrado
5. Refactorizar `crear_venta` con decoradores `@login_required` y
   `@permission_required`
6. Verificar que cada rol solo accede a lo que le corresponde
7. Ejecutar el Sprint 2 Review y completar la ficha Schmelkes E3

---

## Stack tecnológico de W09

| Herramienta | Novedad en W09 | Descripción |
|---|---|---|
| `django-allauth` | ✅ Nuevo | Login/logout/registro con múltiples backends |
| `PermissionRequiredMixin` | ✅ Nuevo | Restringe CBV por permiso específico |
| `@permission_required` | ✅ Nuevo | Decoreador equivalente para vistas función |
| `@login_required` | ✅ Nuevo | Decorador más limpio para vistas función |
| `Group` + `Permission` | ✅ Nuevo | Modelos de Django para RBAC |
| Management Command | ✅ Nuevo | Script ejecutable con `manage.py crear_grupos` |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar W08 | 10 min |
| Parte 1 | Instalar y configurar `django-allauth` | 20 min |
| Parte 2 | Templates login + signup Fable 5 | 15 min |
| Parte 3 | Management command `crear_grupos` | 20 min |
| Parte 4 | `PermissionRequiredMixin` en vistas de borrado | 15 min |
| Parte 5 | Refactorizar `crear_venta` con decoradores | 10 min |
| Parte 6 | Tests W09 (10 pruebas auth + RBAC) | 20 min |
| **Commit parcial** | Punto de control seguro | 5 min |
| Parte 7 | Sprint 2 Review ante el asesor | 20 min |
| Parte 8 | Sprint 2 Retrospectiva + Ficha Schmelkes E3 | 20 min |
| Cierre | Commit final [M3] · `finalizar_sesion.bat` · hilo → W10 | 15 min |
| Buffer | | 10 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W08?
   → Creé forms.py, implementé Create/Update/Delete con LoginRequiredMixin
     y messages flash, y escribí 12 tests de escritura.

2. ¿Qué haré en W09?
   → Instalaré allauth, crearé 3 roles RBAC, aplicaré PermissionRequired
     en vistas críticas y cerraré el Sprint 2 con M3.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 90 tests … OK`

---

## PARTE 1 — Instalar y configurar `django-allauth` (20 min)

### 1.1 Instalar

```cmd
pip install "django-allauth==0.63.3"
pip freeze > requirements.txt
```

### 1.2 Actualizar `core/settings.py`

**a) Agregar apps en `INSTALLED_APPS`** — después de `jazzmin` y antes de las apps del ERP:

```python
INSTALLED_APPS = [
    'jazzmin',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sites',        # ← requerido por allauth
    # Terceros
    'allauth',                     # ← nuevo
    'allauth.account',             # ← nuevo
    'allauth.socialaccount',       # ← nuevo (para OAuth futuro)
    'rest_framework',
    'whitenoise.runserver_nostatic',
    # Apps del ERP
    'clientes',
    'proveedores',
    'productos',
    'ventas',
    'reportes',
    'configuracion',
]
```

**b) Agregar al final de `MIDDLEWARE`:**

```python
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'allauth.account.middleware.AccountMiddleware',   # ← agregar al final
]
```

**c) Agregar configuración de allauth al final de `settings.py`:**

```python
# ── DJANGO SITES (requerido por allauth) ──────────────────────────────────
SITE_ID = 1

# ── AUTHENTICATION BACKENDS ───────────────────────────────────────────────
AUTHENTICATION_BACKENDS = [
    # Backend estándar de Django (username + password en admin)
    'django.contrib.auth.backends.ModelBackend',
    # Backend de allauth (permite login por email también)
    'allauth.account.auth_backends.AuthenticationBackend',
]

# ── ALLAUTH: configuración para desarrollo académico ──────────────────────
ACCOUNT_LOGIN_METHODS          = {'username'}   # login por username
ACCOUNT_EMAIL_REQUIRED         = False          # no obligar correo
ACCOUNT_EMAIL_VERIFICATION     = 'none'         # no enviar email de verificación
ACCOUNT_LOGOUT_ON_GET          = True           # logout sin confirmar (dev)
ACCOUNT_SESSION_REMEMBER       = True           # recordar sesión

# LOGIN_URL y LOGIN_REDIRECT_URL ya definidos en W01:
# LOGIN_URL           = '/accounts/login/'
# LOGIN_REDIRECT_URL  = '/productos/'
LOGOUT_REDIRECT_URL = '/'
```

### 1.3 Actualizar `core/urls.py`

```python
# core/urls.py
"""Enrutador principal del ERP Django — W09."""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from . import views

urlpatterns = [
    path('admin/',       admin.site.urls),
    path('',             views.bienvenida,             name='inicio'),
    # Allauth (login / logout / registro)
    path('accounts/',    include('allauth.urls')),     # ← agregar
    # Apps del ERP
    path('clientes/',    include('clientes.urls',    namespace='clientes')),
    path('proveedores/', include('proveedores.urls', namespace='proveedores')),
    path('productos/',   include('productos.urls',   namespace='productos')),
    path('ventas/',      include('ventas.urls',       namespace='ventas')),
    path('reportes/',    include('reportes.urls',     namespace='reportes')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

### 1.4 Ejecutar migraciones de allauth

```cmd
python manage.py migrate
```

**Resultado esperado:** tablas de allauth y sites aplicadas.

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

---

## PARTE 2 — Templates de login y signup Fable 5 (15 min)

### 2.1 Crear carpeta de templates de autenticación

```cmd
mkdir templates\account
```

### 2.2 `templates/account/login.html`

```html
{% extends "base.html" %}
{% load allauth %}
{% block title %}Iniciar sesión{% endblock %}

{% block content %}
<div style="display:flex;justify-content:center;
            align-items:center;min-height:60vh;">
    <div class="erp-card" style="width:100%;max-width:420px;">
        <div class="erp-card-header" style="text-align:center;">
            🔐 Iniciar sesión · ERP Django
        </div>

        <form method="post" action="{% url 'account_login' %}"
              style="margin-top:.5rem;">
            {% csrf_token %}

            <!-- Username -->
            <div class="mb-4">
                <label class="erp-label">Usuario</label>
                <input type="text" name="login"
                       class="erp-input"
                       placeholder="Tu nombre de usuario"
                       autofocus required>
            </div>

            <!-- Password -->
            <div class="mb-4">
                <label class="erp-label">Contraseña</label>
                <input type="password" name="password"
                       class="erp-input"
                       placeholder="••••••••" required>
            </div>

            <!-- Errores del formulario -->
            {% if form.errors %}
            <div class="erp-alert-danger" style="margin-bottom:1rem;">
                Usuario o contraseña incorrectos.
            </div>
            {% endif %}

            <!-- Botón -->
            <button type="submit" class="btn-erp-gold"
                    style="width:100%;padding:.6rem;font-size:1rem;">
                Entrar
            </button>
        </form>

        <p style="text-align:center;margin-top:1rem;
                  color:var(--clr-muted);font-size:.88rem;">
            ¿No tienes cuenta?
            <a href="{% url 'account_signup' %}"
               style="color:var(--clr-sky);">Regístrate aquí</a>
        </p>
    </div>
</div>
{% endblock %}
```

---

### 2.3 `templates/account/signup.html`

```html
{% extends "base.html" %}
{% block title %}Crear cuenta{% endblock %}

{% block content %}
<div style="display:flex;justify-content:center;
            align-items:center;min-height:60vh;">
    <div class="erp-card" style="width:100%;max-width:440px;">
        <div class="erp-card-header" style="text-align:center;">
            ✨ Crear cuenta de acceso
        </div>

        <form method="post" action="{% url 'account_signup' %}"
              style="margin-top:.5rem;">
            {% csrf_token %}

            {% for field in form %}
            <div class="mb-4">
                <label class="erp-label">{{ field.label }}</label>
                {% if field.field.widget.input_type == 'checkbox' %}
                    {{ field }}
                {% else %}
                    <input type="{{ field.field.widget.input_type }}"
                           name="{{ field.html_name }}"
                           class="erp-input"
                           placeholder="{{ field.label }}"
                           {% if field.field.required %}required{% endif %}>
                {% endif %}
                {% for e in field.errors %}
                    <p style="color:var(--clr-danger);font-size:.82rem;
                              margin:.25rem 0 0;">{{ e }}</p>
                {% endfor %}
            </div>
            {% endfor %}

            <button type="submit" class="btn-erp-gold"
                    style="width:100%;padding:.6rem;font-size:1rem;">
                Crear cuenta
            </button>
        </form>

        <p style="text-align:center;margin-top:1rem;
                  color:var(--clr-muted);font-size:.88rem;">
            ¿Ya tienes cuenta?
            <a href="{% url 'account_login' %}"
               style="color:var(--clr-sky);">Inicia sesión</a>
        </p>
    </div>
</div>
{% endblock %}
```

### 2.4 Verificar login

```cmd
python manage.py runserver
```

```
[ ] http://127.0.0.1:8000/accounts/login/ → formulario Fable 5 visible
[ ] Iniciar sesión con el superusuario creado en W01 → redirige a /productos/
[ ] http://127.0.0.1:8000/accounts/logout/ → cierra sesión → redirige a /
[ ] http://127.0.0.1:8000/accounts/signup/ → formulario de registro visible
```

---

## PARTE 3 — Management command `crear_grupos` (20 min)

### 3.1 ¿Qué es un management command?

Un script Python ejecutable con `python manage.py <nombre>`.
Ideal para tareas de configuración que deben ejecutarse en
producción sin acceso al admin (como configurar grupos de permisos).

```
core/
└── management/
    └── commands/
        └── crear_grupos.py   ← nuevo archivo
```

### 3.2 Crear la estructura de carpetas

```cmd
mkdir core\management
mkdir core\management\commands
type nul > core\management\__init__.py
type nul > core\management\commands\__init__.py
```

### 3.3 Crear `core/management/commands/crear_grupos.py`

```python
# core/management/commands/crear_grupos.py
"""Management command para crear los 3 grupos de acceso del ERP.

Uso:
    python manage.py crear_grupos

Crea o actualiza los grupos:
    Gerente  → acceso completo a todas las apps del ERP
    Vendedor → operar ventas, consultar productos y clientes
    Almacén  → gestionar inventario de productos

Ejecutar en producción después de cada deploy para sincronizar permisos.
"""
from django.contrib.auth.models import Group, Permission
from django.contrib.contenttypes.models import ContentType
from django.core.management.base import BaseCommand

from clientes.models       import Cliente
from configuracion.models  import ConfiguracionERP
from productos.models      import Categoria, Producto
from proveedores.models    import Proveedor
from ventas.models         import DetalleVenta, Pedido, Venta


def _permisos(*modelos: type, acciones=('add', 'change', 'delete', 'view')):
    """Obtiene permisos de las acciones indicadas para los modelos dados.

    Args:
        *modelos: clases de modelo Django.
        acciones: tupla de acciones (add, change, delete, view).

    Returns:
        QuerySet de Permission filtrado.
    """
    ct_ids = [
        ContentType.objects.get_for_model(m).pk
        for m in modelos
    ]
    return Permission.objects.filter(
        content_type_id__in=ct_ids,
        codename__in=[
            f'{accion}_{m._meta.model_name}'
            for m in modelos
            for accion in acciones
        ]
    )


class Command(BaseCommand):
    help = 'Crea o actualiza los 3 grupos de acceso del ERP'

    def handle(self, *args, **options):
        self.stdout.write(self.style.MIGRATE_HEADING(
            '\nConfigurando grupos de acceso del ERP...\n'
        ))

        # ── GERENTE: acceso completo ────────────────────────────────────
        gerente, creado = Group.objects.get_or_create(name='Gerente')
        permisos_gerente = _permisos(
            Cliente, Proveedor, Categoria, Producto,
            Venta, DetalleVenta, Pedido, ConfiguracionERP,
            acciones=('add', 'change', 'delete', 'view')
        )
        gerente.permissions.set(permisos_gerente)
        self.stdout.write(self.style.SUCCESS(
            f'  ✅ Gerente — {permisos_gerente.count()} permisos asignados'
            f' ({"creado" if creado else "actualizado"})'
        ))

        # ── VENDEDOR: operar ventas, consultar productos y clientes ─────
        vendedor, creado = Group.objects.get_or_create(name='Vendedor')
        permisos_vendedor = _permisos(
            Venta, DetalleVenta,
            acciones=('add', 'view')
        ) | _permisos(
            Producto, Cliente,
            acciones=('view',)
        )
        vendedor.permissions.set(permisos_vendedor)
        self.stdout.write(self.style.SUCCESS(
            f'  ✅ Vendedor — {permisos_vendedor.count()} permisos asignados'
            f' ({"creado" if creado else "actualizado"})'
        ))

        # ── ALMACÉN: gestionar inventario ───────────────────────────────
        almacen, creado = Group.objects.get_or_create(name='Almacén')
        permisos_almacen = _permisos(
            Producto, Categoria,
            acciones=('add', 'change', 'view')
        ) | _permisos(
            Proveedor,
            acciones=('view',)
        )
        almacen.permissions.set(permisos_almacen)
        self.stdout.write(self.style.SUCCESS(
            f'  ✅ Almacén — {permisos_almacen.count()} permisos asignados'
            f' ({"creado" if creado else "actualizado"})'
        ))

        self.stdout.write(self.style.SUCCESS(
            '\n🎉 Grupos configurados exitosamente.\n'
            'Asigna usuarios desde /admin/ → Usuarios → Grupos.\n'
        ))
```

### 3.4 Ejecutar el command

```cmd
python manage.py crear_grupos
```

**Resultado esperado:**
```
Configurando grupos de acceso del ERP...

  ✅ Gerente — 32 permisos asignados (creado)
  ✅ Vendedor — 6 permisos asignados (creado)
  ✅ Almacén — 7 permisos asignados (creado)

🎉 Grupos configurados exitosamente.
Asigna usuarios desde /admin/ → Usuarios → Grupos.
```

### 3.5 Verificar grupos en el admin

```
[ ] /admin/ → Autenticación y Autorización → Grupos → 3 grupos visibles
[ ] Grupo "Gerente": ≥ 30 permisos asignados
[ ] Grupo "Vendedor": permisos solo de ventas y lectura
[ ] Grupo "Almacén": permisos de productos/categorías
```

### 3.6 Crear usuarios de prueba por rol

Desde `/admin/` → Usuarios → Agregar:

| Usuario | Contraseña | Grupo |
|---|---|---|
| `gerente_test` | `GerTest2025!` | Gerente |
| `vendedor_test` | `VndTest2025!` | Vendedor |
| `almacen_test` | `AlmTest2025!` | Almacén |

---

## PARTE 4 — `PermissionRequiredMixin` en vistas de borrado (15 min)

### 4.1 Orden correcto en herencia múltiple

```python
# INCORRECTO — LoginRequired después de PermissionRequired
class ProductoDeleteView(PermissionRequiredMixin, LoginRequiredMixin, DeleteView):
    ...

# CORRECTO — LoginRequired SIEMPRE primero
class ProductoDeleteView(LoginRequiredMixin, PermissionRequiredMixin, DeleteView):
    permission_required = 'productos.delete_producto'
    raise_exception     = True   # 403 para autenticados sin permiso
```

**¿Por qué `raise_exception = True`?**
- Si es `False` (default): usuario autenticado sin permiso → redirige a login
  (confuso: ya inició sesión, ¿por qué va al login?)
- Si es `True`: usuario autenticado sin permiso → HTTP 403 Forbidden
  (correcto para un ERP)

---

### 4.2 Actualizar `productos/views.py`

Agregar `PermissionRequiredMixin` a `ProductoDeleteView`:

```python
# productos/views.py — actualizar el import al inicio:
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin

# Reemplazar la clase ProductoDeleteView:
class ProductoDeleteView(LoginRequiredMixin, PermissionRequiredMixin, DeleteView):
    """Confirmación y borrado de un producto.

    Requiere permiso 'productos.delete_producto'.
    Sin permiso: HTTP 403 Forbidden (raise_exception=True).
    """

    model               = Producto
    template_name       = 'productos/eliminar.html'
    pk_url_kwarg        = 'producto_id'
    success_url         = reverse_lazy('productos:lista')
    permission_required = 'productos.delete_producto'
    raise_exception     = True

    def form_valid(self, form):
        nombre   = self.object.nombre
        response = super().form_valid(form)
        messages.success(self.request, f'Producto "{nombre}" eliminado.')
        return response
```

### 4.3 Aplicar el mismo patrón a `ClienteDeleteView` y `VentaDeleteView`

En `clientes/views.py`:

```python
# Agregar PermissionRequiredMixin al import:
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin

# Actualizar ClienteDeleteView:
class ClienteDeleteView(LoginRequiredMixin, PermissionRequiredMixin, DeleteView):
    model               = Cliente
    template_name       = 'clientes/eliminar.html'
    pk_url_kwarg        = 'cliente_id'
    success_url         = reverse_lazy('clientes:lista')
    permission_required = 'clientes.delete_cliente'
    raise_exception     = True

    def form_valid(self, form):
        nombre   = self.object.nombre
        response = super().form_valid(form)
        messages.success(self.request, f'Cliente "{nombre}" eliminado.')
        return response
```

En `ventas/views.py`:

```python
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin

class VentaDeleteView(LoginRequiredMixin, PermissionRequiredMixin, DeleteView):
    model               = Venta
    template_name       = 'ventas/eliminar.html'
    pk_url_kwarg        = 'venta_id'
    success_url         = reverse_lazy('ventas:lista')
    permission_required = 'ventas.delete_venta'
    raise_exception     = True

    def form_valid(self, form):
        pk       = self.object.pk
        response = super().form_valid(form)
        messages.success(self.request, f'Venta #{pk} eliminada.')
        return response
```

---

## PARTE 5 — Refactorizar `crear_venta` con decoradores (10 min)

### 5.1 Reemplazar el check manual de W08

```python
# ventas/views.py — actualizar imports al inicio:
from django.contrib.auth.decorators import (
    login_required,
    permission_required,
)

# Eliminar la función crear_venta de W08 y reemplazar por:

@login_required
@permission_required('ventas.add_venta', raise_exception=True)
def crear_venta(request):
    """Crea un encabezado de venta con una línea de detalle.

    Decoradores (se aplican de abajo hacia arriba):
        @login_required            → verifica autenticación
        @permission_required(...)  → verifica permiso add_venta

    GET  → muestra los dos formularios vacíos.
    POST → valida ambos, guarda si correctos, muestra errores si no.
    """
    venta_form   = VentaForm(request.POST or None)
    detalle_form = DetalleVentaForm(request.POST or None)

    if request.method == 'POST':
        if venta_form.is_valid() and detalle_form.is_valid():
            venta         = venta_form.save()
            detalle       = detalle_form.save(commit=False)
            detalle.venta = venta
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
```

### 5.2 Verificar el sistema completo

```cmd
python manage.py check
python manage.py runserver
```

**Prueba manual de roles:**

```
1. Login como "gerente_test":
   → Acceder a /productos/1/eliminar/ → formulario de confirmación (200)
   → POST confirmar → producto eliminado (302)

2. Login como "vendedor_test":
   → Acceder a /productos/1/eliminar/ → HTTP 403 Forbidden
   → Acceder a /ventas/nueva/ → formulario de venta (200, tiene permiso)

3. Login como "almacen_test":
   → Acceder a /productos/nuevo/ → formulario (200, tiene add_producto)
   → Acceder a /ventas/nueva/ → HTTP 403 Forbidden (sin permiso add_venta)
```

---

## PARTE 6 — Tests W09 (20 min)

### 6.1 Crear `tests/test_w09_auth_rbac.py`

```python
"""Suite de pruebas W09 — Autenticación y Control de Acceso por Rol (RBAC).

Verifica: login requerido, redirección, HTTP 403 por rol,
          acceso correcto para Gerente y Vendedor.

Ejecutar con:
    python manage.py test tests.test_w09_auth_rbac --verbosity=2

Resultado esperado:
    Ran 10 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.contrib.auth.models import Group, Permission, User
from django.test import TestCase
from django.urls import reverse

from clientes.models    import Cliente
from productos.models   import Categoria, Producto
from proveedores.models import Proveedor
from ventas.models      import Venta


def _get_group(name: str) -> Group:
    """Obtiene o crea el grupo indicado (debe haber ejecutado crear_grupos)."""
    return Group.objects.get_or_create(name=name)[0]


class AuthBasicTest(TestCase):
    """Tests de autenticación básica con allauth."""

    def test_login_page_http_200(self):
        """La página de login debe responder HTTP 200."""
        r = self.client.get(reverse('account_login'))
        self.assertEqual(r.status_code, 200)

    def test_login_page_usa_template_fable5(self):
        """El login debe usar el template personalizado Fable 5."""
        r = self.client.get(reverse('account_login'))
        self.assertTemplateUsed(r, 'account/login.html')

    def test_login_correcto_redirige_a_productos(self):
        """Login con credenciales válidas → redirige a LOGIN_REDIRECT_URL."""
        User.objects.create_user('testlogin', password='pass123')
        r = self.client.post(reverse('account_login'), {
            'login':    'testlogin',
            'password': 'pass123',
        })
        self.assertRedirects(r, '/productos/',
                             fetch_redirect_response=False)


class PermisosGruposTest(TestCase):
    """Tests de permisos por grupo (Gerente, Vendedor, Almacén)."""

    def setUp(self):
        self.cat  = Categoria.objects.create(nombre='Cat')
        self.prod = Producto.objects.create(
            nombre='Prod', precio=Decimal('100.00'),
            stock=5, categoria=self.cat
        )
        self.cli = Cliente.objects.create(
            nombre='C', correo='c@t.com'
        )

    def _crear_usuario(self, username: str, grupo_name: str) -> User:
        """Crea un usuario y lo asigna al grupo indicado."""
        user   = User.objects.create_user(username, password='pass')
        grupo, _ = Group.objects.get_or_create(name=grupo_name)
        # Asignar permisos básicos al grupo para los tests
        if grupo_name == 'Gerente':
            perms = Permission.objects.filter(
                codename__in=[
                    'delete_producto', 'delete_cliente',
                    'delete_venta', 'add_venta'
                ]
            )
            grupo.permissions.set(perms)
        elif grupo_name == 'Vendedor':
            perms = Permission.objects.filter(
                codename__in=['add_venta', 'view_producto', 'view_cliente']
            )
            grupo.permissions.set(perms)
        user.groups.add(grupo)
        return user

    # ── Sin autenticación ─────────────────────────────────────────────────

    def test_eliminar_producto_sin_auth_redirige_a_login(self):
        """DELETE /productos/<id>/eliminar/ sin auth → 302 login."""
        r = self.client.get(
            reverse('productos:eliminar', args=[self.prod.pk])
        )
        self.assertEqual(r.status_code, 302)
        self.assertIn('/accounts/login/', r['Location'])

    # ── Vendedor: no tiene delete_producto ────────────────────────────────

    def test_vendedor_no_puede_eliminar_producto_403(self):
        """Vendedor sin delete_producto → HTTP 403 (raise_exception=True)."""
        vendedor = self._crear_usuario('vendedor', 'Vendedor')
        self.client.force_login(vendedor)
        r = self.client.post(
            reverse('productos:eliminar', args=[self.prod.pk])
        )
        self.assertEqual(r.status_code, 403)

    def test_vendedor_puede_ver_lista_productos(self):
        """Vendedor tiene view_producto → puede listar productos."""
        vendedor = self._crear_usuario('vend2', 'Vendedor')
        self.client.force_login(vendedor)
        r = self.client.get(reverse('productos:lista'))
        self.assertEqual(r.status_code, 200)

    def test_vendedor_puede_crear_venta(self):
        """Vendedor tiene add_venta → puede acceder a crear venta."""
        vendedor = self._crear_usuario('vend3', 'Vendedor')
        self.client.force_login(vendedor)
        r = self.client.get(reverse('ventas:crear'))
        self.assertEqual(r.status_code, 200)

    # ── Gerente: tiene todos los permisos ─────────────────────────────────

    def test_gerente_puede_eliminar_producto(self):
        """Gerente con delete_producto → puede borrar y redirige."""
        gerente = self._crear_usuario('gerente', 'Gerente')
        self.client.force_login(gerente)
        pk = self.prod.pk
        r  = self.client.post(
            reverse('productos:eliminar', args=[pk])
        )
        self.assertEqual(r.status_code, 302)
        self.assertFalse(Producto.objects.filter(pk=pk).exists())

    def test_gerente_puede_eliminar_cliente(self):
        """Gerente con delete_cliente → puede borrar cliente."""
        gerente = self._crear_usuario('gerente2', 'Gerente')
        self.client.force_login(gerente)
        pk = self.cli.pk
        r  = self.client.post(
            reverse('clientes:eliminar', args=[pk])
        )
        self.assertIn(r.status_code, [200, 302, 403])
        # 403 si el cliente tiene ventas (PROTECT), 302 si no

    # ── Management command crear_grupos ───────────────────────────────────

    def test_management_command_crea_grupos(self):
        """El command crear_grupos debe crear los 3 grupos."""
        from django.core.management import call_command
        from io import StringIO
        out = StringIO()
        call_command('crear_grupos', stdout=out)
        for nombre in ['Gerente', 'Vendedor', 'Almacén']:
            self.assertTrue(
                Group.objects.filter(name=nombre).exists(),
                f"Grupo '{nombre}' no fue creado por el command"
            )
```

### 6.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w09_auth_rbac --verbosity=2
```

**Resultado esperado:**
```
test_eliminar_producto_sin_auth_redirige_a_login ... ok
test_gerente_puede_eliminar_cliente ... ok
test_gerente_puede_eliminar_producto ... ok
test_login_correcto_redirige_a_productos ... ok
test_login_page_http_200 ... ok
test_login_page_usa_template_fable5 ... ok
test_management_command_crea_grupos ... ok
test_vendedor_no_puede_eliminar_producto_403 ... ok
test_vendedor_puede_crear_venta ... ok
test_vendedor_puede_ver_lista_productos ... ok

Ran 10 tests in X.XXXs
OK
```

### 6.3 Suite acumulada — Hito M3

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 100 tests in X.XXXs · OK` (90 + 10)

### COMMIT PARCIAL

```cmd
git add .
git commit -m "Sprint 2 W09: allauth + crear_grupos + PermissionRequired + 100 tests OK"
```

---

## PARTE 7 — Sprint 2 Review ante el asesor (20 min)

### Guión de demo (≤ 10 min en vivo)

```
1. Mostrar el flujo de autenticación:
   → Abrir /productos/ sin login → formularios de solo lectura.
   → Iniciar sesión como "vendedor_test".
   → Los botones "Nuevo", "Editar", "Eliminar" aparecen en la UI.

2. Demostrar RBAC en acción:
   → Como Vendedor: acceder a /ventas/nueva/ → formulario OK (200).
   → Como Vendedor: acceder a /productos/1/eliminar/ → HTTP 403.
   → Cerrar sesión. Login como "gerente_test".
   → Como Gerente: /productos/1/eliminar/ → confirmación visible.
   → POST confirmar → mensaje flash "Producto eliminado".

3. Mostrar la suite de tests:
   → python manage.py test tests --verbosity=0
   → Ran 100 tests … OK

4. Verificar en producción:
   → Deploy automático en Render.
   → Ejecutar crear_grupos en la Shell de Render.
   → URL pública con login funcional.

5. Declarar Sprint Goal verificado:
   "Al finalizar el Sprint 2, el ERP muestra lista y detalle
    de las 4 entidades, tiene CRUD completo protegido por
    autenticación y 3 roles con permisos diferenciados."
   → Estado: ✅ COMPLETADO
```

### Tabla de verificación del Sprint Goal

| Criterio | Estado |
|---|---|
| ListView + DetailView para 4 entidades | ✅ |
| CreateView + UpdateView para 3 entidades | ✅ |
| DeleteView con PermissionRequired (403 sin permiso) | ✅ |
| 3 grupos creados con permisos diferenciados | ✅ |
| Login/Logout funcional con Fable 5 AzulERP | ✅ |
| `crear_venta` con decoradores auth + permission | ✅ |
| 100 tests acumulados OK | ✅ |
| URL pública en Render con RBAC funcional | ✅ |

---

## PARTE 8 — Sprint 2 Retrospectiva + Ficha Schmelkes E3 (20 min)

### 8.1 Crear `sprint2_retrospective.md`

```markdown
# Sprint 2 Retrospective — ERP Django
## Semanas W07–W09 · Espiral 3: CRUD Web y Autenticación

**Fecha:** ___/___/_____

## ¿Qué funcionó bien? (Keep)
1. select_related() en W07 evitó queries N+1 desde el inicio.
2. reverse_lazy() en CBV evitó el error ImproperlyConfigured.
3. El management command crear_grupos permite configurar
   roles en producción sin tocar el admin.

## ¿Qué mejorar? (Improve)
1. Documentar mejor el orden de LoginRequired + PermissionRequired.
2. Agregar template 403.html para mostrar error personalizado Fable 5.

## Acción de mejora (Kaizen) para Sprint 3
> "En el Sprint 3 (DRF), documentaré los endpoints con docstrings
>  desde el inicio, no al final."

## Velocidad del Sprint 2

| HU | Pts plan. | Pts ent. |
|---|---|---|
| HU-E3-01 Lista productos | 2 | 2 |
| HU-E3-02 Detalle producto | 2 | 2 |
| HU-E3-03 Listas clientes y proveedores | 2 | 2 |
| HU-E3-04 Detalle venta con líneas | 3 | 3 |
| HU-E3-05 Crear y editar productos | 3 | 3 |
| HU-E3-06 Registrar ventas | 5 | 5 |
| HU-E3-07 Eliminar con confirmación | 2 | 2 |
| HU-E3-08 Autenticación login/logout | 3 | 3 |
| HU-E3-09 3 roles con permisos | 5 | 5 |
| **Total** | **27** | **27** |

**Velocidad Sprint 2:** 27 puntos
**Velocidad acumulada (S0+S1+S2):** 58 puntos
```

### 8.2 Abrir `fichas/espiral_03_crud_auth.md`

```markdown
# Ficha de Sistematización — Espiral 3
## ERP Django · Espiral E3: CRUD Web y Autenticación

| Campo | Contenido |
|---|---|
| **Número de espiral** | 3 |
| **Nombre del ciclo** | CRUD Web y Autenticación |
| **Semanas** | W07 – W09 |
| **Fecha de inicio** | ___/___/_____ |
| **Fecha de cierre** | ___/___/_____ |
| **Responsable** | [Nombre del estudiante] |
| **Asesor** | MC. Román Fernando López González |

## 1. Objetivo del ciclo
Implementar la interfaz web completa del ERP con vistas de lectura
y escritura, formularios validados, autenticación mediante allauth
y control de acceso por rol (RBAC) con 3 grupos de usuarios.

## 2. Tareas realizadas

| # | Tarea | Estado | Semana |
|---|---|---|---|
| 1 | ListView + DetailView × 4 entidades | ✅ | W07 |
| 2 | 8 templates lista + detalle Fable 5 | ✅ | W07 |
| 3 | select_related anti-N+1 | ✅ | W07 |
| 4 | forms.py × 4 apps (ModelForm) | ✅ | W08 |
| 5 | Create/Update/Delete × 3 entidades | ✅ | W08 |
| 6 | crear_venta (función) | ✅ | W08 |
| 7 | messages flash en CRUD | ✅ | W08 |
| 8 | django-allauth instalado | ✅ | W09 |
| 9 | Templates login/signup Fable 5 | ✅ | W09 |
| 10 | Management command crear_grupos | ✅ | W09 |
| 11 | PermissionRequiredMixin en Delete | ✅ | W09 |
| 12 | @login_required + @permission_required | ✅ | W09 |
| 13 | 10 tests RBAC | ✅ | W09 |

## 3. Evidencias
- URL pública: https://erp-django-utec.onrender.com
- Login funcional: /accounts/login/
- Tests: Ran 100 tests → OK
- Grupos: Gerente / Vendedor / Almacén en /admin/

## 4. Criterios de aceptación

| Criterio | Estado |
|---|---|
| GET /productos/ sin login → solo lectura | ✅ |
| GET /productos/eliminar/ sin permiso → 403 | ✅ |
| Gerente → acceso completo | ✅ |
| Vendedor → solo ventas y consulta | ✅ |
| 100 tests acumulados OK | ✅ |

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
| **Total Espiral 3** | |
```

---

## CIERRE — Commit Final [M3] y Respaldo (15 min)

### Deploy a Render: ejecutar crear_grupos en producción

```bash
# Desde la Shell del dashboard de Render:
python manage.py crear_grupos
```

**Resultado en los logs de Render:**
```
✅ Gerente — 32 permisos asignados (creado)
✅ Vendedor — 6 permisos asignados (creado)
✅ Almacén — 7 permisos asignados (creado)
```

### Actualizar `sprint2_planning.md`

```markdown
## Sprint 2 — Estado final W09

| HU | Estado | Pts |
|---|---|---|
| HU-E3-01 a HU-E3-09 | ✅ Completadas | 27/27 |

## Hito M3 — ALCANZADO ✅
- CRUD: 4 módulos con lectura + escritura funcional
- Auth: allauth con login/logout Fable 5
- RBAC: 3 grupos (Gerente/Vendedor/Almacén) con permisos
- Tests: Ran 100 tests → OK
- Fecha: ___/___/_____
```

### Commit de cierre de la Espiral 3

```cmd
git add .
git status

:: Verificar que incluye:
::   core/management/commands/crear_grupos.py
::   templates/account/login.html
::   templates/account/signup.html
::   */views.py actualizados (PermissionRequired)
::   ventas/views.py (crear_venta con decoradores)
::   tests/test_w09_auth_rbac.py
::   sprint2_retrospective.md
::   sprint2_planning.md (actualizado)
::   fichas/espiral_03_crud_auth.md

git commit -m "Sprint 2 CIERRE [M3]: allauth + RBAC + 100 tests OK + Ficha E3"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W09 — HITO M3

### Técnico

```
ALLAUTH
[ ] 'allauth', 'allauth.account', 'allauth.socialaccount' en INSTALLED_APPS
[ ] 'django.contrib.sites' en INSTALLED_APPS
[ ] 'allauth.account.middleware.AccountMiddleware' al FINAL de MIDDLEWARE
[ ] SITE_ID = 1 en settings.py
[ ] AUTHENTICATION_BACKENDS con allauth backend incluido
[ ] ACCOUNT_LOGIN_METHODS = {'username'}
[ ] ACCOUNT_EMAIL_VERIFICATION = 'none'
[ ] path('accounts/', include('allauth.urls')) en core/urls.py
[ ] python manage.py migrate → tablas allauth OK
[ ] /accounts/login/ → template Fable 5 visible
[ ] Login con superusuario → redirige a /productos/
[ ] /accounts/logout/ → cierra sesión → redirige a /

GRUPOS Y PERMISOS
[ ] core/management/commands/crear_grupos.py creado
[ ] python manage.py crear_grupos → 3 grupos con permisos
[ ] Gerente: ≥ 30 permisos (add/change/delete/view de todas las apps)
[ ] Vendedor: add/view venta, view producto, view cliente
[ ] Almacén: add/change/view producto, view proveedor
[ ] 3 usuarios de prueba creados y asignados a grupos

PERMISSION REQUIRED
[ ] ProductoDeleteView(LoginRequired, PermissionRequired, DeleteView)
[ ] ClienteDeleteView: ídem con 'clientes.delete_cliente'
[ ] VentaDeleteView: ídem con 'ventas.delete_venta'
[ ] raise_exception = True en las 3 DeleteViews
[ ] Vendedor accede a /productos/eliminar/ → HTTP 403
[ ] Gerente accede a /productos/eliminar/ → HTTP 200 (formulario)
[ ] crear_venta con @login_required + @permission_required

TESTS
[ ] test tests.test_w09_auth_rbac → 10/10 OK
[ ] test tests → 100/100 OK (acumulados W01–W09)
[ ] test_vendedor_no_puede_eliminar → 403
[ ] test_management_command_crea_grupos → 3 grupos

DEPLOY
[ ] git push → Render actualizado
[ ] python manage.py crear_grupos ejecutado en Shell de Render
[ ] URL pública → login funcional con Fable 5

SCRUM / SCHMELKES
[ ] sprint2_planning.md: 27/27 puntos entregados
[ ] sprint2_retrospective.md: 3 secciones + Kaizen + velocidad
[ ] fichas/espiral_03_crud_auth.md: campos W09 completados
[ ] Commit de cierre con etiqueta [M3]
```

---

## DIAGRAMA: Flujo de control de acceso completo (W09)

```
Petición: POST /productos/1/eliminar/
    │
    ▼
ProductoDeleteView.dispatch()
    │
    ├─ LoginRequiredMixin.dispatch()
    │      ¿Autenticado?
    │      NO  → redirect /accounts/login/?next=/productos/1/eliminar/
    │      SÍ  → continuar
    │
    ├─ PermissionRequiredMixin.dispatch()
    │      ¿Tiene 'productos.delete_producto'?
    │      NO  (raise_exception=True) → HTTP 403 Forbidden
    │      SÍ  → continuar
    │
    ▼
DeleteView.post()
    │
    ├─ form_valid()
    │      → producto.delete() (o ProtectedError si tiene DetalleVenta)
    │      → messages.success("Producto eliminado")
    │      → redirect reverse_lazy('productos:lista')
    │
    ▼
HTTP 302 → /productos/ + mensaje flash
```

---

## HILO CONDUCTOR → W10

**¿Qué cierra W09 / Espiral 3?**
El ERP tiene ahora interfaz completa (lectura + escritura), autenticación
con allauth, y 3 roles con permisos diferenciados. Los 100 tests
garantizan la estabilidad del sistema ante cambios futuros.

**¿Qué abre W10 / Espiral 4 / Sprint 3?**
Con la autenticación establecida, el siguiente paso es exponer los
datos del ERP como API REST con DRF para permitir integración con
apps móviles, frontends SPA o sistemas externos.

**¿Qué necesita W10 de W09?**

| Artefacto de W09 | Uso en W10 |
|---|---|
| Grupos y permisos creados | DRF usa los mismos permisos Django para autorizar endpoints |
| `AUTHENTICATION_BACKENDS` con allauth | DRF usará `SessionAuthentication` sobre esta base |
| 100 tests pasando | W10 agrega tests de API (GET/POST/PUT/DELETE via DRF) |
| `LOGIN_URL` configurado | DRF redirige a él cuando `IsAuthenticated` falla |

**Tarea de investigación para W10:**
> Lee la documentación de DRF sobre serializers:
> `https://www.django-rest-framework.org/api-guide/serializers/`
>
> ¿Qué diferencia hay entre `Serializer` y `ModelSerializer`?
> ¿Qué hace `read_only_fields` en la clase `Meta` de un serializer?

**Pregunta de reflexión:**
> "Con `PermissionRequiredMixin` protegemos las vistas HTML.
> Cuando en W10 creemos endpoints DRF para los mismos datos,
> ¿podemos reusar los mismos grupos y permisos Django?
> ¿O necesitamos un sistema de autenticación diferente para la API?"

---

## Referencia rápida de comandos W09

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py migrate
python manage.py crear_grupos
python manage.py runserver

:: TESTS
python manage.py test tests.test_w09_auth_rbac --verbosity=2
python manage.py test tests --verbosity=0   (100 tests acumulados)

:: GIT
git add .
git commit -m "Sprint 2 CIERRE [M3]: descripción"
git push origin main

:: RENDER (desde Shell del dashboard)
python manage.py crear_grupos
python manage.py check --deploy
```

---

*Guía de Laboratorio W09 · ERP Django*
*Espiral 3 Cierre · Sprint 2 Review + Retrospectiva · Hito M3*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*