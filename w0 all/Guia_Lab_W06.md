# Guía de Laboratorio — W06
## ERP Django · Espiral 2 · Semana 6 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W06 de 24 |
| **Espiral** | E2 — Modelado de Datos y ORM |
| **Sprint Scrum** | Sprint 1 — Review + Retrospectiva |
| **Hito** | **★ M2: Esquema ER aprobado + migraciones + 15 tests de modelo pasando** |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 2 — Núcleo ERP |
| **Hilo conductor** | "W05 construyó los modelos. W06 los blindan con validadores y los viste con Jazzmin." |

---

## Respuesta a la tarea de investigación de W05

> **¿Diferencia entre `MinValueValidator` y el método `clean()`?**
>
> | Mecanismo | Se ejecuta con | Scope | Cuándo usar |
> |---|---|---|---|
> | `MinValueValidator(n)` | `full_clean()` y formularios | Un solo campo | Límite numérico simple |
> | `clean()` del modelo | `full_clean()` | Múltiples campos o lógica cruzada | Validación de negocio compleja |
>
> **Ejemplo de cuándo usar `clean()`:**
> ```python
> def clean(self):
>     if self.fecha_entrega and self.fecha_entrega < self.fecha_pedido.date():
>         raise ValidationError("La entrega no puede ser antes del pedido.")
> ```
> Esto no puede hacerse con un `MinValueValidator` porque involucra
> dos campos distintos al mismo tiempo.
>
> **Regla práctica:** validators para límites de un campo;
> `clean()` para reglas que cruzan varios campos.

---

## Objetivos de la sesión

Al terminar W06, el estudiante será capaz de:

1. Agregar `clean()` personalizado en modelos con validación de negocio
2. Crear una migración `0002` para campos opcionales de validación adicional
3. Instalar y personalizar `django-jazzmin` con la paleta Fable 5 AzulERP
4. Escribir una suite de ≥ 15 tests que cubra validators, `ProtectedError`,
   `IntegrityError`, `CASCADE` y el patrón singleton
5. Ejecutar el Sprint 1 Review con demo en vivo ante el asesor
6. Completar la ficha Schmelkes E2 y declarar el Hito M2

---

## Stack tecnológico de W06

| Herramienta | Novedad en W06 | Descripción |
|---|---|---|
| `django-jazzmin` | ✅ Nuevo | Tema visual profesional para el admin Django |
| `ValidationError` | ✅ Nuevo | Excepción para validación de negocio en `clean()` |
| `full_clean()` | ✅ Nuevo | Método que dispara todos los validators y `clean()` |
| `ProtectedError` | ✅ Nuevo | Excepción al intentar borrar con `PROTECT` |
| `IntegrityError` | ✅ Nuevo | Excepción al violar restricciones únicas de la BD |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificación W05 + `iniciar_sesion.bat` | 10 min |
| Parte 1 | Método `clean()` en `Producto`, `DetalleVenta` y `Pedido` | 20 min |
| Parte 2 | Migración `0002` para `Pedido.total_pagado` validator | 10 min |
| Parte 3 | Instalar y configurar `django-jazzmin` | 20 min |
| Parte 4 | Suite completa: `test_w06_validadores.py` (15 tests) | 35 min |
| Parte 5 | Deploy a Render: migrate en producción | 10 min |
| **Commit parcial** | Punto de control seguro | 5 min |
| Parte 6 | Sprint 1 Review ante el asesor | 20 min |
| Parte 7 | Sprint 1 Retrospectiva + Ficha Schmelkes E2 | 20 min |
| Cierre | Commit final · `finalizar_sesion.bat` · hilo → W07 | 10 min |
| Buffer | | 20 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W05?
   → Implementé los 8 modelos Django, ejecuté migraciones
     y registré todos los modelos en el panel admin.

2. ¿Qué haré en W06?
   → Agregaré validadores y clean(), instalaré Jazzmin,
     escribiré ≥ 15 tests y cerraré el Sprint 1.

3. ¿Tengo algún impedimento?
   → (registrar aquí cualquier problema)
```

### Verificar estado de W05

```cmd
python manage.py check
python manage.py test tests --verbosity=0
python manage.py showmigrations | findstr "[X]"
```

**Resultado esperado:**
```
System check identified no issues (0 silenced).
Ran 51 tests … OK
[X] 0001_initial   (en clientes, proveedores, productos, ventas, configuracion)
```

---

## PARTE 1 — Métodos `clean()` en modelos (20 min)

### 1.1 ¿Por qué `full_clean()` y no `save()`?

```
save()       → guarda en BD, NO ejecuta validators ni clean()
full_clean() → ejecuta validate_unique() + validate_constraints()
               + run_validators() + clean_fields() + clean()
```

Django llama `full_clean()` automáticamente en formularios
(`ModelForm`). En código Python directo, debes llamarlo explícito.
Los tests en W06 usan `full_clean()` para que los validators se disparen.

---

### 1.2 Agregar `clean()` a `productos/models.py`

Abrir `productos/models.py` y agregar el método a la clase `Producto`:

```python
# Agregar dentro de la clase Producto, después de los campos y antes de Meta:

from django.core.exceptions import ValidationError   # ← agregar al inicio del archivo

    def clean(self) -> None:
        """Validaciones de negocio cruzadas para Producto.

        Ejecutadas por full_clean() (formularios y llamadas explícitas).
        No se ejecutan con save() directo.

        Raises:
            ValidationError: si precio < 0 o stock < 0.
        """
        errors = {}

        if self.precio is not None and self.precio < 0:
            errors['precio'] = (
                'El precio no puede ser negativo. '
                f'Valor recibido: {self.precio}'
            )

        if self.stock is not None and self.stock < 0:
            errors['stock'] = (
                'El stock no puede ser negativo. '
                f'Valor recibido: {self.stock}'
            )

        if errors:
            raise ValidationError(errors)
```

El inicio del archivo `productos/models.py` debe quedar:

```python
# productos/models.py
from decimal import Decimal

from django.core.exceptions import ValidationError      # ← agregar
from django.core.validators import MinValueValidator
from django.db import models

from proveedores.models import Proveedor
```

---

### 1.3 Agregar `clean()` a `ventas/models.py`

En la clase `DetalleVenta`, agregar después de `save()`:

```python
# Agregar al inicio de ventas/models.py:
from django.core.exceptions import ValidationError

# Agregar dentro de la clase DetalleVenta:

    def clean(self) -> None:
        """Validación de negocio para línea de detalle.

        Raises:
            ValidationError: si cantidad < 1.
        """
        if self.cantidad is not None and self.cantidad < 1:
            raise ValidationError(
                {'cantidad': 'La cantidad debe ser al menos 1.'}
            )
```

En la clase `Pedido`, agregar validación de fechas:

```python
# Agregar dentro de la clase Pedido:

    def clean(self) -> None:
        """Valida que la fecha de entrega no sea anterior al pedido.

        Raises:
            ValidationError: si fecha_entrega < fecha_pedido.date().
        """
        if (self.fecha_entrega and self.fecha_pedido and
                self.fecha_entrega < self.fecha_pedido.date()):
            raise ValidationError({
                'fecha_entrega': (
                    'La fecha de entrega no puede ser anterior '
                    'a la fecha del pedido.'
                )
            })
```

---

### 1.4 Verificar que no hay errores de sintaxis

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

---

## PARTE 2 — Migración `0002` para `Pedido` (10 min)

### 2.1 Agregar validator a `Pedido.total_pagado`

En `ventas/models.py`, actualizar el campo `total_pagado` del modelo `Pedido`:

```python
# En la clase Pedido, reemplazar el campo total_pagado:

    total_pagado  = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],  # ← agregar
        verbose_name='Total pagado'
    )
```

Agregar el import al inicio del archivo si no está:

```python
from decimal import Decimal
from django.core.validators import MinValueValidator
```

### 2.2 Crear y aplicar la migración

```cmd
python manage.py makemigrations ventas --name validators_pedido
python manage.py migrate
```

**Resultado esperado:**
```
Migrations for 'ventas':
  ventas/migrations/0002_validators_pedido.py
    - Alter field total_pagado on pedido
Applying ventas.0002_validators_pedido... OK
```

### 2.3 Verificar

```cmd
python manage.py showmigrations ventas
```

```
ventas
 [X] 0001_initial
 [X] 0002_validators_pedido
```

---

## PARTE 3 — Instalar y configurar `django-jazzmin` (20 min)

### 3.1 Instalar

```cmd
pip install django-jazzmin
pip freeze > requirements.txt
```

### 3.2 Registrar en `core/settings.py`

> **Crítico:** `jazzmin` debe ir **ANTES** de `django.contrib.admin`
> en `INSTALLED_APPS`. Si va después, el tema no se aplica.

```python
# core/settings.py — actualizar INSTALLED_APPS
INSTALLED_APPS = [
    # Jazzmin PRIMERO — antes de django.contrib.admin
    'jazzmin',                          # ← nueva línea, primera posición

    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Terceros
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

### 3.3 Agregar `JAZZMIN_SETTINGS` al final de `core/settings.py`

```python
# core/settings.py — agregar al final del archivo

# ── JAZZMIN — Personalización del admin con Fable 5 AzulERP ───────────────
JAZZMIN_SETTINGS = {
    # Identidad
    'site_title':       'ERP Django',
    'site_header':      'ERP UTEC Celaya',
    'site_brand':       '📦 ERP Django',
    'welcome_sign':     'Bienvenido al Sistema ERP · UTEC Celaya',
    'copyright':        'MC. Román Fernando López González · UTEC Celaya',

    # Icono del sitio (usar emoji como fallback)
    'site_icon':        None,
    'site_logo':        None,    # ruta a logo en static/ (agregar en W11+)

    # Búsqueda global en el admin
    'search_model':     ['clientes.Cliente', 'productos.Producto'],

    # Menú superior (top navigation)
    'topmenu_links': [
        {'name': 'Inicio ERP',   'url': '/', 'new_window': False},
        {'name': 'Productos',    'url': '/productos/'},
        {'name': 'Clientes',     'url': '/clientes/'},
        {'name': 'Ventas',       'url': '/ventas/'},
    ],

    # Menú de usuario (avatar)
    'usermenu_links': [
        {'name': 'Ver ERP', 'url': '/', 'new_window': False},
    ],

    # Menú lateral: orden de apps y modelos
    'order_with_respect_to': [
        'clientes', 'proveedores', 'productos',
        'ventas', 'configuracion', 'auth',
    ],

    # Iconos de Font Awesome para cada modelo
    'icons': {
        'auth':                       'fas fa-users-cog',
        'auth.user':                  'fas fa-user',
        'auth.Group':                 'fas fa-users',
        'clientes.Cliente':           'fas fa-user-tie',
        'proveedores.Proveedor':      'fas fa-truck',
        'productos.Categoria':        'fas fa-tags',
        'productos.Producto':         'fas fa-box',
        'ventas.Venta':               'fas fa-file-invoice-dollar',
        'ventas.DetalleVenta':        'fas fa-list',
        'ventas.Pedido':              'fas fa-shopping-cart',
        'configuracion.ConfiguracionERP': 'fas fa-cogs',
    },
    'default_icon_parents': 'fas fa-folder',
    'default_icon_children': 'fas fa-circle',

    # Apariencia
    'related_modal_active':     True,
    'custom_css':               'erp_custom.css',   # archivo en static/
    'show_sidebar':             True,
    'navigation_expanded':      True,
    'hide_apps':                [],
    'hide_models':              [],

    # UI tweaks
    'changeform_format':        'horizontal_tabs',
    'language_chooser':         False,
}

JAZZMIN_UI_TWEAKS = {
    'navbar_small_text':        False,
    'footer_small_text':        False,
    'body_small_text':          False,
    'brand_small_text':         False,
    'brand_colour':             'navbar-dark',
    'accent':                   'accent-navy',
    'navbar':                   'navbar-dark',
    'no_navbar_border':         False,
    'navbar_fixed':             True,
    'layout_boxed':             False,
    'footer_fixed':             False,
    'sidebar_fixed':            True,
    'sidebar':                  'sidebar-dark-navy',
    'sidebar_nav_small_text':   False,
    'sidebar_disable_expand':   False,
    'sidebar_nav_child_indent': True,
    'sidebar_nav_compact_style': False,
    'sidebar_nav_legacy_style': False,
    'sidebar_nav_flat_style':   False,
    'theme':                    'default',
    'dark_mode_theme':          None,
    'button_classes': {
        'primary':   'btn-primary',
        'secondary': 'btn-secondary',
        'info':      'btn-info',
        'warning':   'btn-warning',
        'danger':    'btn-danger',
        'success':   'btn-success',
    },
}
```

### 3.4 Colores personalizados en `static/erp_custom.css`

Agregar al final del archivo `static/erp_custom.css`:

```css
/* ── JAZZMIN: Override de colores con Fable 5 AzulERP ─────────────────── */

/* Sidebar color navy */
.main-sidebar, .sidebar { background-color: #0A2342 !important; }

/* Navbar color navy */
.main-header.navbar { background-color: #0A2342 !important; }

/* Brand / logo area */
.brand-link { border-bottom: 1px solid #B8860B !important; }
.brand-text  { color: #D4AF37 !important; font-weight: 700 !important; }

/* Sidebar links */
.nav-sidebar .nav-link { color: rgba(255,255,255,.82) !important; }
.nav-sidebar .nav-link:hover,
.nav-sidebar .nav-link.active {
    background-color: #1B4F8A !important;
    color: #FFFFFF !important;
}

/* Accent: botones y badges en dorado */
.accent-navy .nav-sidebar .nav-link.active {
    background-color: #B8860B !important;
}

/* Footer */
.main-footer { border-top: 2px solid #B8860B; }
```

### 3.5 Verificar Jazzmin

```cmd
python manage.py check
python manage.py runserver
```

Abrir `http://127.0.0.1:8000/admin/` — debe verse el sidebar azul oscuro
con el menú lateral colapsable y los iconos de Font Awesome.

```
[ ] Sidebar color azul marino (#0A2342)
[ ] Brand "📦 ERP Django" en color dorado
[ ] Iconos Font Awesome en cada modelo
[ ] Menú superior con enlace a "Inicio ERP"
[ ] Layout no roto (no hay errores 500)
```

---

## PARTE 4 — Suite completa: `test_w06_validadores.py` (35 min)

### 4.1 Concepto clave antes de escribir los tests

```python
# INCORRECTO — save() NO ejecuta validators
producto.precio = Decimal('-10.00')
producto.save()            # no lanza error — guarda -10 en BD

# CORRECTO — full_clean() ejecuta todos los validators y clean()
producto.precio = Decimal('-10.00')
producto.full_clean()      # lanza ValidationError aquí
```

### 4.2 Crear `tests/test_w06_validadores.py`

```python
"""Suite de pruebas W06 — Validators, integridad y comportamiento de modelos.

Cubre: ValidationError, IntegrityError, ProtectedError, CASCADE,
       singleton, propiedad total, captura de precio histórico.

Ejecutar con:
    python manage.py test tests.test_w06_validadores --verbosity=2

Resultado esperado:
    Ran 15 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.db.models.deletion import ProtectedError
from django.test import TestCase

from clientes.models       import Cliente
from configuracion.models  import ConfiguracionERP
from productos.models      import Categoria, Producto
from proveedores.models    import Proveedor
from ventas.models         import DetalleVenta, Pedido, Venta


# ── Fixtures reutilizables ────────────────────────────────────────────────

def crear_fixtures():
    """Crea objetos base para los tests."""
    cat  = Categoria.objects.create(nombre='Test Cat')
    prov = Proveedor.objects.create(nombre='Prov Test', correo='prov@t.com')
    cli  = Cliente.objects.create(nombre='Cliente Test', correo='cli@t.com')
    prod = Producto.objects.create(
        nombre='Prod Test', precio=Decimal('100.00'), stock=10, categoria=cat
    )
    return cat, prov, cli, prod


# ── BLOQUE 1: Validators de campos ───────────────────────────────────────

class ValidadoresCamposTest(TestCase):
    """Tests de MinValueValidator y clean() en campos individuales."""

    def setUp(self):
        self.cat = Categoria.objects.create(nombre='Electrónica')

    def test_precio_negativo_lanza_validation_error(self):
        """Producto con precio negativo debe lanzar ValidationError."""
        prod = Producto(
            nombre='X', precio=Decimal('-1.00'),
            stock=5, categoria=self.cat
        )
        with self.assertRaises(ValidationError) as ctx:
            prod.full_clean()
        self.assertIn('precio', ctx.exception.message_dict)

    def test_precio_cero_es_valido(self):
        """Precio = 0 debe ser válido (gratis / promoción)."""
        prod = Producto(
            nombre='Gratis', precio=Decimal('0.00'),
            stock=5, categoria=self.cat
        )
        try:
            prod.full_clean()
        except ValidationError as e:
            if 'precio' in e.message_dict:
                self.fail("Precio 0.00 no debería lanzar ValidationError")

    def test_stock_negativo_lanza_validation_error(self):
        """Producto con stock negativo debe lanzar ValidationError."""
        prod = Producto(
            nombre='Y', precio=Decimal('50.00'),
            stock=-1, categoria=self.cat
        )
        with self.assertRaises(ValidationError) as ctx:
            prod.full_clean()
        self.assertIn('stock', ctx.exception.message_dict)

    def test_detalle_cantidad_cero_lanza_error(self):
        """DetalleVenta con cantidad 0 debe lanzar ValidationError."""
        cat  = self.cat
        cli  = Cliente.objects.create(nombre='C', correo='c@t.com')
        prod = Producto.objects.create(
            nombre='P', precio=Decimal('10.00'), stock=5, categoria=cat
        )
        venta = Venta.objects.create(cliente=cli)
        det   = DetalleVenta(
            venta=venta, producto=prod,
            cantidad=0, precio_unitario=Decimal('10.00')
        )
        with self.assertRaises(ValidationError) as ctx:
            det.full_clean()
        self.assertIn('cantidad', ctx.exception.message_dict)


# ── BLOQUE 2: Restricciones de unicidad ──────────────────────────────────

class UnicidadTest(TestCase):
    """Tests de unique=True en correos de Cliente y Proveedor."""

    def test_correo_duplicado_cliente_lanza_integrity_error(self):
        """Dos clientes con el mismo correo deben lanzar IntegrityError."""
        Cliente.objects.create(nombre='A', correo='dup@test.com')
        with self.assertRaises(IntegrityError):
            Cliente.objects.create(nombre='B', correo='dup@test.com')

    def test_correo_duplicado_proveedor_lanza_integrity_error(self):
        """Dos proveedores con el mismo correo deben lanzar IntegrityError."""
        Proveedor.objects.create(nombre='P1', correo='dup@prov.com')
        with self.assertRaises(IntegrityError):
            Proveedor.objects.create(nombre='P2', correo='dup@prov.com')


# ── BLOQUE 3: on_delete PROTECT, SET_NULL y CASCADE ──────────────────────

class OnDeleteTest(TestCase):
    """Tests del comportamiento on_delete de cada ForeignKey."""

    def setUp(self):
        self.cat, self.prov, self.cli, self.prod = crear_fixtures()

    def test_categoria_protect_no_borrar_con_productos(self):
        """No debe poder borrarse una Categoria que tiene Productos (D-01)."""
        with self.assertRaises(ProtectedError):
            self.cat.delete()

    def test_proveedor_set_null_al_borrar(self):
        """Al borrar Proveedor, Producto.proveedor debe quedar en NULL (D-02)."""
        self.prod.proveedor = self.prov
        self.prod.save()
        self.prov.delete()
        self.prod.refresh_from_db()
        self.assertIsNone(self.prod.proveedor)

    def test_venta_protect_no_borrar_cliente_con_ventas(self):
        """No debe poder borrarse un Cliente que tiene Ventas (D-03)."""
        Venta.objects.create(cliente=self.cli)
        with self.assertRaises(ProtectedError):
            self.cli.delete()

    def test_detalle_venta_cascade_al_borrar_venta(self):
        """Al borrar una Venta, sus DetalleVenta deben borrarse en cascada."""
        venta = Venta.objects.create(cliente=self.cli)
        DetalleVenta.objects.create(
            venta=venta, producto=self.prod,
            cantidad=2, precio_unitario=Decimal('100.00')
        )
        self.assertEqual(DetalleVenta.objects.count(), 1)
        venta.delete()
        self.assertEqual(DetalleVenta.objects.count(), 0)

    def test_producto_protect_no_borrar_con_detalles(self):
        """No debe poder borrarse un Producto con DetalleVenta (D-05)."""
        venta = Venta.objects.create(cliente=self.cli)
        DetalleVenta.objects.create(
            venta=venta, producto=self.prod,
            cantidad=1, precio_unitario=Decimal('100.00')
        )
        with self.assertRaises(ProtectedError):
            self.prod.delete()


# ── BLOQUE 4: Precio histórico y propiedad total ──────────────────────────

class PrecioHistoricoTest(TestCase):
    """Tests de DetalleVenta.precio_unitario y Venta.total."""

    def setUp(self):
        cat  = Categoria.objects.create(nombre='Cat')
        self.prod = Producto.objects.create(
            nombre='P', precio=Decimal('200.00'), stock=5, categoria=cat
        )
        cli   = Cliente.objects.create(nombre='C', correo='c@t.com')
        self.venta = Venta.objects.create(cliente=cli)

    def test_detalle_captura_precio_del_producto(self):
        """Si precio_unitario es None, debe capturarse del producto (D-06)."""
        det = DetalleVenta.objects.create(
            venta=self.venta, producto=self.prod,
            cantidad=1, precio_unitario=None   # None → debe usar Producto.precio
        )
        self.assertEqual(det.precio_unitario, Decimal('200.00'))

    def test_detalle_no_sobreescribe_precio_cero(self):
        """precio_unitario = 0.00 (descuento total) no debe sobreescribirse."""
        det = DetalleVenta.objects.create(
            venta=self.venta, producto=self.prod,
            cantidad=1, precio_unitario=Decimal('0.00')  # 0 válido
        )
        self.assertEqual(det.precio_unitario, Decimal('0.00'))

    def test_venta_total_dos_lineas(self):
        """Total con dos líneas: (3 × 200) + (2 × 50) = 700."""
        cat2  = Categoria.objects.create(nombre='Cat2')
        prod2 = Producto.objects.create(
            nombre='P2', precio=Decimal('50.00'), stock=5, categoria=cat2
        )
        DetalleVenta.objects.create(
            venta=self.venta, producto=self.prod,
            cantidad=3, precio_unitario=Decimal('200.00')
        )
        DetalleVenta.objects.create(
            venta=self.venta, producto=prod2,
            cantidad=2, precio_unitario=Decimal('50.00')
        )
        self.assertEqual(self.venta.total, Decimal('700.00'))


# ── BLOQUE 5: Representación __str__ y singleton ──────────────────────────

class StrYSingletonTest(TestCase):
    """Tests de __str__ y patrón singleton."""

    def test_venta_str_contiene_pk_y_cliente(self):
        """__str__ de Venta debe contener el pk y el nombre del cliente."""
        cli   = Cliente.objects.create(nombre='María', correo='m@t.com')
        venta = Venta.objects.create(cliente=cli)
        resultado = str(venta)
        self.assertIn(str(venta.pk), resultado)
        self.assertIn('María', resultado)

    def test_pedido_choices_pendiente_por_defecto(self):
        """Un pedido nuevo debe tener estado 'pendiente' por defecto."""
        cli = Cliente.objects.create(nombre='Z', correo='z@t.com')
        p   = Pedido.objects.create(
            numero_pedido='PED-001', cliente=cli
        )
        self.assertEqual(p.estado, 'pendiente')

    def test_configuracion_singleton_pk_siempre_1(self):
        """Aunque se llame save() dos veces, pk siempre debe ser 1 (D-07)."""
        cfg = ConfiguracionERP.objects.create(
            pk=1, nombre_empresa='Empresa A'
        )
        cfg.nombre_empresa = 'Empresa B'
        cfg.save()
        self.assertEqual(ConfiguracionERP.objects.count(), 1)
        self.assertEqual(ConfiguracionERP.objects.first().pk, 1)
```

### 4.3 Ejecutar los tests

```cmd
python manage.py test tests.test_w06_validadores --verbosity=2
```

**Resultado esperado:**
```
test_categoria_protect_no_borrar_con_productos ... ok
test_configuracion_singleton_pk_siempre_1 ... ok
test_correo_duplicado_cliente_lanza_integrity_error ... ok
test_correo_duplicado_proveedor_lanza_integrity_error ... ok
test_detalle_cantidad_cero_lanza_error ... ok
test_detalle_captura_precio_del_producto ... ok
test_detalle_no_sobreescribe_precio_cero ... ok
test_detalle_venta_cascade_al_borrar_venta ... ok
test_pedido_choices_pendiente_por_defecto ... ok
test_precio_cero_es_valido ... ok
test_precio_negativo_lanza_validation_error ... ok
test_producto_protect_no_borrar_con_detalles ... ok
test_proveedor_set_null_al_borrar ... ok
test_stock_negativo_lanza_validation_error ... ok
test_venta_protect_no_borrar_cliente_con_ventas ... ok
test_venta_str_contiene_pk_y_cliente ... ok
test_venta_total_dos_lineas ... ok

Ran 15 tests in X.XXXs
OK
```

### 4.4 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 66 tests in X.XXXs · OK` (51 + 15)

---

## PARTE 5 — Deploy a Render: migrate en producción (10 min)

### 5.1 Push con las nuevas migraciones

```cmd
git add .
git commit -m "Sprint 1 W06: clean() + Jazzmin + 66 tests OK [pre-M2]"
git push origin main
```

### 5.2 Render ejecuta las migraciones automáticamente

El `buildCommand` de `render.yaml` ya incluye `python manage.py migrate`.
Al hacer push, Render lo ejecutará automáticamente.

Verificar en el dashboard de Render → **Logs**:

```
==> Running: python manage.py migrate
    Applying ventas.0002_validators_pedido... OK
==> Build successful
```

### 5.3 Verificar la URL pública

```
[ ] https://erp-django-utec.onrender.com/ → HTTP 200
[ ] https://erp-django-utec.onrender.com/admin/ → Jazzmin visible (sidebar azul)
[ ] Logs de Render: 0002_validators_pedido aplicada
```

### COMMIT PARCIAL — punto de control seguro

```cmd
:: (ya se hizo el commit antes del push — este es el momento de verificar)
git log --oneline -5
```

---

## PARTE 6 — Sprint 1 Review (20 min)

### Formato de la demo (guión de 5 minutos)

```
1. Abrir el admin en producción:
   → https://erp-django-utec.onrender.com/admin/
   → Mostrar el tema Jazzmin con sidebar azul/dorado.
   → "El admin fue personalizado con el sistema Fable 5 AzulERP."

2. Crear datos reales en producción:
   → Crear Categoria: "Electrónica"
   → Crear Producto: "Laptop HP" / $12,500.00 / stock: 5
   → Crear Cliente: "Juan Pérez" / juan@utec.com
   → Crear Venta con 2 líneas de DetalleVenta
   → Mostrar que total_admin muestra el valor correcto.

3. Demostrar el DoD del Sprint 1:
   → python manage.py showmigrations → [X] en 5 apps
   → python manage.py test tests --verbosity=0 → 66 tests OK
   → Intentar borrar la Categoria con Productos → error ProtectedError

4. Mostrar el repositorio en GitHub:
   → docs/diagramas/diagrama_er.md renderizado con Mermaid
   → fichas/espiral_02_modelos.md
   → tests/ con test_w05 y test_w06 visibles

5. Declarar Sprint Goal verificado:
   "Al finalizar el Sprint 1, el ERP tiene un esquema de BD completo
    con 8 entidades, migraciones aplicadas, admin funcional con
    Jazzmin y 66 tests pasando."
   → Estado: ✅ COMPLETADO
```

### Tabla de verificación del Sprint Goal

| Criterio del Sprint Goal | Estado |
|---|---|
| Diagrama ER aprobado formalmente | ✅ |
| `showmigrations` → `[X] 0001_initial` en 5 apps | ✅ |
| `[X] 0002_validators_pedido` en ventas | ✅ |
| Panel `/admin/` con 8 modelos visibles | ✅ |
| Tema Jazzmin azul/dorado activo | ✅ |
| ≥ 15 tests de modelo pasando | ✅ (17 en W06) |
| 66 tests acumulados OK | ✅ |
| URL pública en Render con migraciones | ✅ |

---

## PARTE 7 — Sprint 1 Retrospectiva + Ficha Schmelkes E2 (20 min)

### 7.1 Crear `sprint1_retrospective.md`

```markdown
# Sprint 1 Retrospective — ERP Django
## Semanas W04–W06 · Espiral 2: Modelado de Datos y ORM

**Fecha:** ___/___/_____

## ¿Qué funcionó bien? (Keep)
1. Diseñar el ER en papel antes de escribir código evitó errores de FK.
2. Los smoke tests de W05 detectaron un bug en precio_unitario is None.
3. Jazzmin mejora significativamente la UX del admin.

## ¿Qué mejorar? (Improve)
1. Documentar el diagrama ER con más detalle antes de la revisión.
2. Ejecutar full_clean() en los tests desde el principio (no solo save()).

## Acción de mejora (Kaizen) para Sprint 2
> "En el Sprint 2, voy a crear primero los archivos de template
>  y las urls.py antes de escribir las vistas, para no repetir
>  el error de W01 donde las vistas estaban en urls.py."

## Velocidad del Sprint 1

| HU | Puntos planificados | Puntos entregados |
|---|---|---|
| HU-E2-01 Diagrama ER aprobado | 3 | 3 |
| HU-E2-02 Modelo Cliente | 2 | 2 |
| HU-E2-03 Modelo Proveedor | 2 | 2 |
| HU-E2-04 Modelo Categoria | 1 | 1 |
| HU-E2-05 Modelo Producto | 3 | 3 |
| HU-E2-06 Modelos Venta + Detalle | 5 | 5 |
| HU-E2-07 Suite ≥ 15 tests | 3 | 3 |
| HU-E2-08 Admin con Jazzmin | 2 | 2 |
| **Total** | **21** | **21** |

**Velocidad del equipo Sprint 1:** 21 puntos
**Velocidad acumulada (S0 + S1):** 31 puntos
```

---

### 7.2 Completar `fichas/espiral_02_modelos.md`

Abrir el archivo y completar todos los campos que quedaron pendientes:

```
[ ] Fechas de inicio y cierre correctas
[ ] Tabla de tareas: todos en ✅ con tiempos reales
[ ] Evidencias: URL de Render, resultado de showmigrations, resultado de tests
[ ] git log --oneline -5 pegado en el campo de evidencias
[ ] Criterios de aceptación: todos marcados ✅
[ ] Al menos 1 problema encontrado documentado con su solución
[ ] 3 lecciones aprendidas redactadas
[ ] Tiempo total invertido calculado (W04 + W05 + W06)
[ ] Campo "Aprobación formal" con fecha y observaciones del asesor
```

---

## CIERRE — Commit Final, Respaldo y Declaración M2 (10 min)

### Actualizar `sprint1_planning.md`

```markdown
## Sprint 1 — Estado final W06

| Tarea | Estado |
|---|---|
| Diseño ER + aprobación | ✅ W04 |
| Implementar models.py × 6 apps | ✅ W05 |
| makemigrations 0001_initial + migrate | ✅ W05 |
| Registrar admin.py | ✅ W05 |
| clean() en Producto, DetalleVenta, Pedido | ✅ W06 |
| Migración 0002_validators_pedido | ✅ W06 |
| Instalar y configurar django-jazzmin | ✅ W06 |
| Suite 15+ tests de modelo | ✅ W06 (17 tests) |

## Hito M2 — ALCANZADO ✅
- showmigrations: [X] en 5 apps (0001 + 0002)
- Tests: Ran 66 tests → OK
- Admin: 8 modelos con Jazzmin
- URL producción: https://erp-django-utec.onrender.com/admin/
- Fecha: ___/___/_____
```

### Commit final de la Espiral 2

```cmd
git add .
git status

:: Verificar que incluye:
::   tests/test_w06_validadores.py
::   ventas/migrations/0002_validators_pedido.py
::   core/settings.py (con JAZZMIN_SETTINGS)
::   static/erp_custom.css (actualizado)
::   sprint1_retrospective.md
::   sprint1_planning.md (actualizado)
::   fichas/espiral_02_modelos.md (completa)

git commit -m "Sprint 1 CIERRE [M2]: Jazzmin + clean() + 66 tests OK + Ficha Schmelkes E2"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

Verificar en `E:\WorkSpace_ERP\`:

```
[ ] ventas/migrations/0002_validators_pedido.py
[ ] tests/test_w06_validadores.py
[ ] core/settings.py con JAZZMIN_SETTINGS y JAZZMIN_UI_TWEAKS
[ ] static/erp_custom.css con overrides de Jazzmin
[ ] sprint1_retrospective.md
[ ] fichas/espiral_02_modelos.md (completa)
[ ] requirements.txt con django-jazzmin
```

---

## CHECKLIST FINAL W06 — HITO M2

### Técnico

```
VALIDADORES Y clean()
[ ] Producto.clean(): ValidationError en precio < 0 Y stock < 0
[ ] DetalleVenta.clean(): ValidationError en cantidad < 1
[ ] Pedido.clean(): ValidationError si fecha_entrega < fecha_pedido
[ ] Pedido.total_pagado: MinValueValidator(0)
[ ] ventas/migrations/0002_validators_pedido.py creada y aplicada

JAZZMIN
[ ] 'jazzmin' en INSTALLED_APPS ANTES de 'django.contrib.admin'
[ ] JAZZMIN_SETTINGS completo en settings.py
[ ] JAZZMIN_UI_TWEAKS definido
[ ] /admin/ muestra sidebar azul marino y texto dorado
[ ] Iconos Font Awesome en cada modelo del menú
[ ] requirements.txt incluye django-jazzmin

TESTS
[ ] test tests.test_w06_validadores → 15/15 OK (17 en suite real)
[ ] test tests → 66/66 OK acumulados (W01–W06)
[ ] test_precio_negativo: usa full_clean() (no save())
[ ] test_proveedor_set_null: usa refresh_from_db()
[ ] test_categoria_protect: assertRaises(ProtectedError)

DEPLOY
[ ] git push → Render ejecuta 0002_validators_pedido automáticamente
[ ] URL pública → Jazzmin visible en producción
[ ] Logs de Render: 0002 OK

SCRUM / SCHMELKES
[ ] sprint1_planning.md: 21/21 puntos entregados
[ ] sprint1_retrospective.md: 3 secciones + Kaizen + velocidad
[ ] fichas/espiral_02_modelos.md: todos los campos completos
[ ] Commit de cierre con etiqueta [M2]
[ ] git push → GitHub con 66 tests acumulados
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Estado del sistema al cerrar Espiral 2

```
BD SQLite (dev) / PostgreSQL (prod)
┌──────────────────────────────────────────────────────┐
│  CATEGORIA     PROVEEDOR      CLIENTE                 │
│  id, nombre    id, nombre     id, nombre              │
│  descripcion   correo(UK)     correo(UK)              │
│                contacto       telefono                 │
│                               activo, creado          │
│       │              │                │               │
│       ▼              ▼                ▼               │
│    PRODUCTO         VENTA          PEDIDO             │
│    nombre           cliente_id FK  numero_pedido(UK)  │
│    precio(≥0)       fecha          cliente_id FK       │
│    stock(≥0)        total(@prop)   estado(choices)    │
│    categoria_id FK               total_pagado(≥0)     │
│    proveedor_id FK               fecha_entrega        │
│    activo,creado      │                               │
│            │          ▼                               │
│            └──► DETALLE_VENTA                         │
│                 venta_id FK (CASCADE)                 │
│                 producto_id FK (PROTECT)              │
│                 cantidad(≥1)                          │
│                 precio_unitario (histórico D-06)      │
│                                                        │
│  CONFIGURACION_ERP  (singleton pk=1)                  │
│  nombre_empresa, rfc, moneda, iva_porcentaje, logo    │
└──────────────────────────────────────────────────────┘

Admin: Django Jazzmin ← Fable 5 AzulERP (navy + dorado)
Tests: 66 OK (W01–W06)
Prod:  https://erp-django-utec.onrender.com
```

---

## HILO CONDUCTOR → W07

**¿Qué cierra W06 / Espiral 2?**
El corazón del ERP: 8 modelos validados, migrados a producción,
visibles en Jazzmin y cubiertos por 66 tests. El esquema de datos
es la base sobre la que se construirán todas las vistas del Sprint 2.

**¿Qué abre W07 / Espiral 3 / Sprint 2?**
Con datos que ahora pueden crearse en el admin, el siguiente paso
es exponer esos datos en la interfaz web pública con vistas `ListView`
y `DetailView`, usando los templates Fable 5 AzulERP de W02.

**¿Qué necesita W07 de W06?**

| Artefacto de W06 | Uso en W07 |
|---|---|
| `Producto.objects.all()` | `ProductoListView` lo usa como queryset |
| Templates `base.html` (W02) | `lista.html` y `detalle.html` lo extienden |
| `app_name` en `urls.py` (W02) | W07 agrega rutas de lista y detalle |
| 66 tests pasando | W07 los amplía con tests de vista HTTP 200 |

**Tarea de investigación para W07:**
> Lee la documentación de Django sobre `ListView` y `DetailView`:
> `https://docs.djangoproject.com/en/4.2/ref/class-based-views/generic-display/`
>
> ¿Qué atributos son obligatorios en un `ListView`?
> ¿Qué hace `context_object_name` y cuál es su valor por defecto?

**Pregunta de reflexión:**
> "En W06 vimos que `full_clean()` dispara los validators pero
> `save()` no lo hace. ¿Qué implicación tiene esto cuando los datos
> se crean desde el admin de Django vs desde código Python directo?
> ¿El admin llama `full_clean()` antes de guardar?"

---

## Referencia rápida de comandos W06

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py makemigrations ventas --name validators_pedido
python manage.py showmigrations
python manage.py migrate
python manage.py runserver
python manage.py collectstatic --no-input

:: SHELL — probar validators manualmente
python manage.py shell
>>> from productos.models import Producto, Categoria
>>> from decimal import Decimal
>>> cat = Categoria.objects.first()
>>> p = Producto(nombre='Test', precio=Decimal('-5.00'), stock=1, categoria=cat)
>>> p.full_clean()   # debe lanzar ValidationError

:: TESTS
python manage.py test tests.test_w06_validadores --verbosity=2
python manage.py test tests --verbosity=0   (66 tests acumulados)

:: GIT
git add .
git commit -m "Sprint 1 CIERRE [M2]: descripción"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W06 · ERP Django*
*Espiral 2 Cierre · Sprint 1 Review + Retrospectiva · Hito M2*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*