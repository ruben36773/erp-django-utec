# Guía de Laboratorio — W05
## ERP Django · Espiral 2 · Semana 5 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W05 de 24 |
| **Espiral** | E2 — Modelado de Datos y ORM |
| **Sprint Scrum** | Sprint 1 — Desarrollo |
| **Hito** | Sin hito propio · Avance hacia M2 (W06) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 2 — Núcleo ERP |
| **Hilo conductor** | "El plano fue aprobado en W04. W05 vierte el concreto: los modelos Django." |

> **⚠️ Prerrequisito obligatorio.** W05 solo puede iniciar si el diagrama ER
> tiene la firma de aprobación del asesor en `fichas/espiral_02_modelos.md`.
> Si no está aprobado, completar esa gestión antes de escribir código.

---

## Respuesta a la tarea de investigación de W04

> **¿Diferencia entre `null=True` y `blank=True`?**
>
> | Parámetro | Afecta a | Significado |
> |---|---|---|
> | `null=True` | **Base de datos** | El campo puede almacenar `NULL` en la columna |
> | `blank=True` | **Validación Django** | El campo puede enviarse vacío en un formulario |
>
> **Regla práctica:**
> - `CharField` / `EmailField`: usar `blank=True` (no `null=True`) —
>   Django usa `''` (cadena vacía), no `NULL`, para texto vacío
> - `ForeignKey`, `DecimalField`, `DateField`: usar `null=True, blank=True`
>   cuando el campo es opcional — la BD necesita `NULL` para "sin valor"
> - Nunca usar `null=True` en `CharField` — tendrías dos representaciones
>   de "vacío": `NULL` y `''`

---

## Objetivos de la sesión

Al terminar W05, el estudiante será capaz de:

1. Crear una nueva app Django (`configuracion`) y registrarla correctamente
2. Implementar 8 modelos siguiendo el ER aprobado con tipos, relaciones y Meta
3. Aplicar las decisiones D-01 a D-07 en el código real
4. Ejecutar `makemigrations` y `migrate` verificando cada paso
5. Registrar los 8 modelos en `admin.py` con inlines y `list_display`
6. Verificar visualmente en el panel `/admin/`

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar aprobación ER + `iniciar_sesion.bat` | 10 min |
| Parte 1 | Crear app `configuracion` + actualizar `settings.py` | 10 min |
| Parte 2 | Modelos sin FK: `Categoria`, `Proveedor`, `Cliente` | 20 min |
| Parte 3 | Modelo con FK: `Producto` | 15 min |
| Parte 4 | Modelos complejos: `Venta`, `DetalleVenta`, `Pedido` | 25 min |
| Parte 5 | Modelo singleton: `ConfiguracionERP` | 10 min |
| Parte 6 | `makemigrations` + `migrate` + verificación | 15 min |
| **Commit parcial** | Punto de control seguro | 5 min |
| Parte 7 | `admin.py` para las 6 apps | 25 min |
| Parte 8 | Tests W05 (10 smoke tests) | 15 min |
| Cierre | Commit final · `finalizar_sesion.bat` · checklist · hilo → W06 | 10 min |
| **Total** | | **160 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Verificar prerrequisito obligatorio

```cmd
:: Comprobar que la firma de aprobación existe en la ficha
findstr /i "Aprobado" fichas\espiral_02_modelos.md
```

Si no aparece `Aprobado ✅`, **no continuar** con W05 hasta obtenerla.

### Daily Scrum

```
1. ¿Qué hice en W04?
   → Diseñé el diagrama ER con 8 entidades, documenté 7 decisiones
     de diseño y obtuve la aprobación del asesor.

2. ¿Qué haré en W05?
   → Implementaré los 8 modelos Django basados en el ER aprobado,
     ejecutaré las migraciones y registraré los modelos en el admin.

3. ¿Tengo algún impedimento?
   → (registrar aquí cualquier problema)
```

### Verificar estado acumulado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` + `Ran 41 tests … OK`

---

## PARTE 1 — Crear app `configuracion` (10 min)

### 1.1 Crear la app

```cmd
python manage.py startapp configuracion
```

### 1.2 Registrar en `core/settings.py`

Abrir `core/settings.py` → agregar `'configuracion'` a `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
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
    'configuracion',   # ← nueva app W05
]
```

### 1.3 Verificar

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

---

## PARTE 2 — Modelos sin FK (20 min)

Estos tres modelos son independientes: no referencian otras entidades.
Implementar en el orden indicado.

### 2.1 `clientes/models.py`

Reemplazar el contenido (el archivo por defecto está vacío de modelos):

```python
# clientes/models.py
"""Modelos de la app clientes — Espiral 2 W05."""
from django.db import models


class Cliente(models.Model):
    """Representa a un cliente del sistema ERP.

    Atributos:
        nombre:   Nombre completo o razón social.
        correo:   Correo electrónico único (identificador principal).
        telefono: Teléfono de contacto (opcional).
        activo:   Soft-delete: False = dado de baja sin borrar historial.
        creado:   Fecha de registro (automática, inmutable).
    """

    nombre   = models.CharField(
        max_length=150, verbose_name='Nombre'
    )
    correo   = models.EmailField(
        unique=True, verbose_name='Correo electrónico'
    )
    telefono = models.CharField(
        max_length=20, blank=True, verbose_name='Teléfono'
    )
    activo   = models.BooleanField(
        default=True, verbose_name='Activo'
    )
    creado   = models.DateTimeField(
        auto_now_add=True, verbose_name='Fecha de registro'
    )

    class Meta:
        verbose_name        = 'Cliente'
        verbose_name_plural = 'Clientes'
        ordering            = ['nombre']

    def __str__(self) -> str:
        return self.nombre
```

---

### 2.2 `proveedores/models.py`

```python
# proveedores/models.py
"""Modelos de la app proveedores — Espiral 2 W05."""
from django.db import models


class Proveedor(models.Model):
    """Representa a un proveedor de mercancía.

    Atributos:
        nombre:   Nombre comercial o razón social.
        contacto: Persona de contacto (opcional).
        correo:   Correo electrónico único.
        telefono: Teléfono (opcional).
        activo:   Soft-delete.
        creado:   Fecha de registro (automática).
    """

    nombre   = models.CharField(
        max_length=150, verbose_name='Nombre'
    )
    contacto = models.CharField(
        max_length=100, blank=True, verbose_name='Persona de contacto'
    )
    correo   = models.EmailField(
        unique=True, verbose_name='Correo electrónico'
    )
    telefono = models.CharField(
        max_length=20, blank=True, verbose_name='Teléfono'
    )
    activo   = models.BooleanField(
        default=True, verbose_name='Activo'
    )
    creado   = models.DateTimeField(
        auto_now_add=True, verbose_name='Fecha de registro'
    )

    class Meta:
        verbose_name        = 'Proveedor'
        verbose_name_plural = 'Proveedores'
        ordering            = ['nombre']

    def __str__(self) -> str:
        return self.nombre
```

---

### 2.3 `productos/models.py` — solo `Categoria` por ahora

```python
# productos/models.py
"""Modelos de la app productos — Espiral 2 W05.

Orden de implementación:
  1. Categoria  (sin FK)
  2. Producto   (FK → Categoria, FK → Proveedor)  ← Parte 3
"""
from decimal import Decimal

from django.core.validators import MinValueValidator
from django.db import models

from proveedores.models import Proveedor


class Categoria(models.Model):
    """Categoría para clasificar productos del catálogo.

    Atributos:
        nombre:      Nombre único de la categoría.
        descripcion: Descripción opcional.
    """

    nombre      = models.CharField(
        max_length=100, unique=True, verbose_name='Nombre'
    )
    descripcion = models.TextField(
        blank=True, verbose_name='Descripción'
    )

    class Meta:
        verbose_name        = 'Categoría'
        verbose_name_plural = 'Categorías'
        ordering            = ['nombre']

    def __str__(self) -> str:
        return self.nombre
```

> **Nota:** `Producto` se agrega en la Parte 3. Guardar el archivo con
> solo `Categoria` por ahora; se completará a continuación.

---

## PARTE 3 — Modelo `Producto` con FK (15 min)

### 3.1 Por qué `Producto` va después de `Categoria` y `Proveedor`

Django resuelve dependencias automáticamente en migraciones, pero
escribir en este orden evita errores de importación (`NameError`).
`Producto` importa `Proveedor` desde otra app → esa app debe tener
su modelo definido primero.

### 3.2 Agregar `Producto` al final de `productos/models.py`

```python
# Agregar después de la clase Categoria en productos/models.py

class Producto(models.Model):
    """Artículo del inventario del ERP.

    Decisiones de diseño aplicadas:
        D-01: categoria usa on_delete=PROTECT.
        D-02: proveedor usa on_delete=SET_NULL (puede ser null).
    """

    nombre    = models.CharField(
        max_length=200, verbose_name='Nombre'
    )
    precio    = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Precio ($)',
        help_text='El precio no puede ser negativo.'
    )
    stock     = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        verbose_name='Stock disponible'
    )
    categoria = models.ForeignKey(
        Categoria,
        on_delete=models.PROTECT,          # D-01: no borrar categoría con productos
        related_name='productos',
        verbose_name='Categoría'
    )
    proveedor = models.ForeignKey(
        Proveedor,
        on_delete=models.SET_NULL,         # D-02: producto puede quedar sin proveedor
        null=True,
        blank=True,
        related_name='productos',
        verbose_name='Proveedor'
    )
    activo    = models.BooleanField(
        default=True, verbose_name='Activo'
    )
    creado    = models.DateTimeField(
        auto_now_add=True, verbose_name='Fecha de registro'
    )

    class Meta:
        verbose_name        = 'Producto'
        verbose_name_plural = 'Productos'
        ordering            = ['nombre']

    def __str__(self) -> str:
        return f"{self.nombre} (${self.precio:.2f})"
```

---

## PARTE 4 — Modelos Complejos: Venta, DetalleVenta, Pedido (25 min)

### 4.1 `ventas/models.py` completo

```python
# ventas/models.py
"""Modelos de la app ventas — Espiral 2 W05.

Modelos implementados:
    Venta        — encabezado de una venta interna.
    DetalleVenta — línea de producto dentro de una venta.
    Pedido       — orden de compra del canal e-commerce (Espiral 5).

Decisiones de diseño aplicadas:
    D-03: Venta.cliente  → PROTECT.
    D-04: Venta.total    → @property calculada, no campo de BD.
    D-05: DetalleVenta.producto → PROTECT.
    D-06: DetalleVenta.precio_unitario → almacenado (histórico).
"""
from decimal import Decimal

from django.db import models

from clientes.models  import Cliente
from productos.models import Producto


# ── Venta ─────────────────────────────────────────────────────────────────

class Venta(models.Model):
    """Encabezado de una venta interna.

    El total no se almacena en la BD (D-04); se calcula
    sumando los subtotales de cada DetalleVenta asociado.
    """

    cliente = models.ForeignKey(
        Cliente,
        on_delete=models.PROTECT,      # D-03: no borrar cliente con ventas
        related_name='ventas',
        verbose_name='Cliente'
    )
    fecha   = models.DateTimeField(
        auto_now_add=True, verbose_name='Fecha'
    )

    class Meta:
        verbose_name        = 'Venta'
        verbose_name_plural = 'Ventas'
        ordering            = ['-fecha']

    def __str__(self) -> str:
        return f"Venta #{self.pk} — {self.cliente} ({self.fecha:%d/%m/%Y})"

    @property
    def total(self) -> Decimal:
        """Total de la venta: suma de subtotales de cada línea.

        Decisión D-04: no se almacena en BD para cumplir 3FN.
        Para dashboards con muchos registros, usar:
            Venta.objects.annotate(total=Sum(...))

        Returns:
            Decimal: suma de (cantidad × precio_unitario) por línea.
        """
        return sum(
            (d.subtotal for d in self.detalles.all()),
            Decimal('0.00')        # valor inicial para venta sin detalles
        )


# ── DetalleVenta ───────────────────────────────────────────────────────────

class DetalleVenta(models.Model):
    """Línea de producto dentro de una venta.

    precio_unitario se almacena (D-06) porque el precio del producto
    puede cambiar después de la venta; se necesita el histórico exacto.
    """

    venta           = models.ForeignKey(
        Venta,
        on_delete=models.CASCADE,      # borrar Venta → borrar sus líneas
        related_name='detalles',
        verbose_name='Venta'
    )
    producto        = models.ForeignKey(
        Producto,
        on_delete=models.PROTECT,      # D-05: no borrar producto con ventas
        related_name='detalles_venta',
        verbose_name='Producto'
    )
    cantidad        = models.PositiveIntegerField(
        verbose_name='Cantidad'
    )
    precio_unitario = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name='Precio unitario',
        help_text='Precio al momento de la venta (D-06).'
    )

    class Meta:
        verbose_name        = 'Detalle de venta'
        verbose_name_plural = 'Detalles de venta'

    def __str__(self) -> str:
        return f"{self.producto.nombre} × {self.cantidad}"

    @property
    def subtotal(self) -> Decimal:
        """Subtotal de la línea: cantidad × precio_unitario."""
        return self.precio_unitario * self.cantidad

    def save(self, *args, **kwargs) -> None:
        """Captura el precio actual del producto si no se especificó.

        Uso de 'is None' (no 'not') porque Decimal('0.00') es falsy
        pero es un valor válido que NO debe sobreescribirse.
        """
        if self.precio_unitario is None:
            self.precio_unitario = self.producto.precio
        super().save(*args, **kwargs)


# ── Pedido ─────────────────────────────────────────────────────────────────

class Pedido(models.Model):
    """Orden de compra del canal e-commerce.

    Nota: se implementa en la Espiral 5 (W13–W15).
    Se define aquí para completar el esquema ER aprobado.
    """

    ESTADO_CHOICES = [
        ('pendiente',  'Pendiente de pago'),
        ('pagado',     'Pago confirmado'),
        ('enviado',    'En camino'),
        ('entregado',  'Entregado'),
        ('cancelado',  'Cancelado'),
    ]

    numero_pedido = models.CharField(
        max_length=20,
        unique=True,
        verbose_name='Número de pedido',
        help_text='Formato sugerido: PED-YYYY-NNNN'
    )
    cliente       = models.ForeignKey(
        Cliente,
        on_delete=models.PROTECT,
        related_name='pedidos',
        verbose_name='Cliente'
    )
    estado        = models.CharField(
        max_length=20,
        choices=ESTADO_CHOICES,
        default='pendiente',
        verbose_name='Estado'
    )
    fecha_pedido  = models.DateTimeField(
        auto_now_add=True, verbose_name='Fecha del pedido'
    )
    fecha_entrega = models.DateField(
        null=True, blank=True, verbose_name='Fecha de entrega'
    )
    total_pagado  = models.DecimalField(
        max_digits=10, decimal_places=2,
        null=True, blank=True,
        verbose_name='Total pagado'
    )

    class Meta:
        verbose_name        = 'Pedido'
        verbose_name_plural = 'Pedidos'
        ordering            = ['-fecha_pedido']

    def __str__(self) -> str:
        return f"{self.numero_pedido} — {self.cliente} [{self.get_estado_display()}]"
```

---

## PARTE 5 — Modelo Singleton: `ConfiguracionERP` (10 min)

### 5.1 `configuracion/models.py`

```python
# configuracion/models.py
"""Modelo de configuración global del sistema ERP — Espiral 2 W05.

Decisión D-07: singleton — siempre existe exactamente un registro (pk=1).
"""
from decimal import Decimal

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class ConfiguracionERP(models.Model):
    """Configuración global del sistema ERP.

    Implementa el patrón Singleton: save() fuerza pk=1, garantizando
    que solo exista un registro en la base de datos.

    Uso:
        config = ConfiguracionERP.get_instance()
        print(config.nombre_empresa)
    """

    nombre_empresa = models.CharField(
        max_length=200, verbose_name='Nombre de la empresa'
    )
    rfc            = models.CharField(
        max_length=13, blank=True, verbose_name='RFC'
    )
    moneda         = models.CharField(
        max_length=3,
        default='MXN',
        verbose_name='Moneda (ISO 4217)',
        help_text='Ejemplos: MXN, USD, EUR'
    )
    iva_porcentaje = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('16.00'),
        validators=[
            MinValueValidator(Decimal('0.00')),
            MaxValueValidator(Decimal('100.00')),
        ],
        verbose_name='IVA (%)'
    )
    logo           = models.ImageField(
        upload_to='configuracion/',
        null=True, blank=True,
        verbose_name='Logo de la empresa'
    )

    class Meta:
        verbose_name        = 'Configuración ERP'
        verbose_name_plural = 'Configuración ERP'

    def __str__(self) -> str:
        return f"{self.nombre_empresa} — IVA {self.iva_porcentaje}%"

    def save(self, *args, **kwargs) -> None:
        """Fuerza pk=1 para garantizar el patrón singleton (D-07)."""
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get_instance(cls) -> 'ConfiguracionERP':
        """Obtiene o crea la instancia única de configuración.

        Returns:
            ConfiguracionERP: la única instancia del sistema.
        """
        obj, _ = cls.objects.get_or_create(
            pk=1,
            defaults={
                'nombre_empresa': 'Mi Empresa ERP',
                'moneda':         'MXN',
                'iva_porcentaje': Decimal('16.00'),
            }
        )
        return obj
```

---

## PARTE 6 — `makemigrations` + `migrate` (15 min)

### 6.1 Verificar que no hay errores antes de migrar

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

Si hay errores, corregirlos antes de continuar.

### 6.2 Crear las migraciones

```cmd
:: Generar migraciones para cada app en orden de dependencia
python manage.py makemigrations clientes
python manage.py makemigrations proveedores
python manage.py makemigrations configuracion
python manage.py makemigrations productos
python manage.py makemigrations ventas
```

**Resultado esperado por cada app:**
```
Migrations for 'clientes':
  clientes/migrations/0001_initial.py
    - Create model Cliente
```

### 6.3 Verificar las migraciones creadas

```cmd
python manage.py showmigrations
```

**Resultado esperado:**
```
clientes
 [ ] 0001_initial
configuracion
 [ ] 0001_initial
productos
 [ ] 0001_initial
proveedores
 [ ] 0001_initial
ventas
 [ ] 0001_initial
```

### 6.4 Aplicar migraciones a la base de datos

```cmd
python manage.py migrate
```

**Resultado esperado:**
```
Applying clientes.0001_initial...       OK
Applying proveedores.0001_initial...    OK
Applying configuracion.0001_initial...  OK
Applying productos.0001_initial...      OK
Applying ventas.0001_initial...         OK
```

### 6.5 Verificación post-migración

```cmd
python manage.py showmigrations
```

Todos los items deben mostrar `[X]` (aplicado):

```
clientes
 [X] 0001_initial
configuracion
 [X] 0001_initial
productos
 [X] 0001_initial
proveedores
 [X] 0001_initial
ventas
 [X] 0001_initial
```

### COMMIT PARCIAL — punto de control seguro

```cmd
git add .
git commit -m "Sprint 1 W05: 8 modelos Django + migraciones aplicadas"
```

---

## PARTE 7 — Registrar modelos en `admin.py` (25 min)

### 7.1 `clientes/admin.py`

```python
# clientes/admin.py
"""Configuración del panel admin para la app clientes."""
from django.contrib import admin

from .models import Cliente


@admin.register(Cliente)
class ClienteAdmin(admin.ModelAdmin):
    """Admin de clientes: lista, búsqueda y filtros."""

    list_display   = ['pk', 'nombre', 'correo', 'telefono',
                      'activo', 'creado']
    search_fields  = ['nombre', 'correo', 'telefono']
    list_filter    = ['activo']
    list_editable  = ['activo']
    readonly_fields = ['creado']
    date_hierarchy = 'creado'
    ordering       = ['nombre']
```

---

### 7.2 `proveedores/admin.py`

```python
# proveedores/admin.py
"""Configuración del panel admin para la app proveedores."""
from django.contrib import admin

from .models import Proveedor


@admin.register(Proveedor)
class ProveedorAdmin(admin.ModelAdmin):
    """Admin de proveedores: lista, búsqueda y filtros."""

    list_display   = ['pk', 'nombre', 'contacto', 'correo',
                      'telefono', 'activo', 'creado']
    search_fields  = ['nombre', 'contacto', 'correo']
    list_filter    = ['activo']
    list_editable  = ['activo']
    readonly_fields = ['creado']
    date_hierarchy = 'creado'
```

---

### 7.3 `productos/admin.py`

```python
# productos/admin.py
"""Configuración del panel admin para la app productos."""
from django.contrib import admin

from .models import Categoria, Producto


@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    """Admin de categorías."""

    list_display  = ['pk', 'nombre', 'descripcion']
    search_fields = ['nombre']


@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    """Admin de productos: lista con categoría, proveedor y stock."""

    list_display   = ['pk', 'nombre', 'precio', 'stock',
                      'categoria', 'proveedor', 'activo', 'creado']
    search_fields  = ['nombre', 'categoria__nombre', 'proveedor__nombre']
    list_filter    = ['activo', 'categoria']
    list_editable  = ['precio', 'stock', 'activo']
    readonly_fields = ['creado']
    autocomplete_fields = ['proveedor']     # requiere search_fields en Proveedor
    date_hierarchy = 'creado'
    ordering       = ['nombre']
```

---

### 7.4 `ventas/admin.py`

```python
# ventas/admin.py
"""Configuración del panel admin para la app ventas."""
from django.contrib import admin

from .models import DetalleVenta, Pedido, Venta


class DetalleVentaInline(admin.TabularInline):
    """Líneas de detalle dentro del admin de Venta."""

    model       = DetalleVenta
    extra       = 1            # mostrar 1 fila vacía para agregar
    fields      = ['producto', 'cantidad', 'precio_unitario']
    readonly_fields = []


@admin.register(Venta)
class VentaAdmin(admin.ModelAdmin):
    """Admin de ventas con detalles inline y total calculado."""

    list_display    = ['pk', 'cliente', 'fecha', 'total_admin']
    search_fields   = ['cliente__nombre', 'cliente__correo']
    readonly_fields = ['fecha']
    inlines         = [DetalleVentaInline]
    date_hierarchy  = 'fecha'

    @admin.display(description='Total ($)')
    def total_admin(self, obj: Venta) -> str:
        """Muestra el total calculado de la venta en la lista."""
        return f"${obj.total:.2f}"


@admin.register(DetalleVenta)
class DetalleVentaAdmin(admin.ModelAdmin):
    """Admin de líneas de detalle (vista independiente)."""

    list_display  = ['pk', 'venta', 'producto', 'cantidad',
                     'precio_unitario', 'subtotal_admin']
    search_fields = ['producto__nombre', 'venta__pk']
    readonly_fields = ['precio_unitario']

    @admin.display(description='Subtotal ($)')
    def subtotal_admin(self, obj: DetalleVenta) -> str:
        return f"${obj.subtotal:.2f}"


@admin.register(Pedido)
class PedidoAdmin(admin.ModelAdmin):
    """Admin de pedidos de e-commerce."""

    list_display   = ['numero_pedido', 'cliente', 'estado',
                      'fecha_pedido', 'total_pagado']
    search_fields  = ['numero_pedido', 'cliente__nombre']
    list_filter    = ['estado']
    readonly_fields = ['fecha_pedido']
```

---

### 7.5 `configuracion/admin.py`

```python
# configuracion/admin.py
"""Configuración del panel admin para ConfiguracionERP (singleton)."""
from django.contrib import admin

from .models import ConfiguracionERP


@admin.register(ConfiguracionERP)
class ConfiguracionERPAdmin(admin.ModelAdmin):
    """Admin de configuración global.

    Al ser singleton (D-07), se deshabilita el botón 'Agregar'
    para evitar crear más de un registro.
    """

    list_display = ['nombre_empresa', 'rfc', 'moneda', 'iva_porcentaje']

    def has_add_permission(self, request) -> bool:
        """Deshabilita el botón 'Agregar' si ya existe el registro."""
        return not ConfiguracionERP.objects.exists()

    def has_delete_permission(self, request, obj=None) -> bool:
        """No permitir borrar la configuración del sistema."""
        return False
```

### 7.6 Verificar el panel admin

```cmd
python manage.py runserver
```

Abrir `http://127.0.0.1:8000/admin/` y verificar:

```
[ ] Sección CLIENTES: Cliente visible con list_display correcto
[ ] Sección PROVEEDORES: Proveedor visible
[ ] Sección PRODUCTOS: Categoria + Producto visibles
[ ] Sección VENTAS: Venta (con inline DetalleVenta) + Pedido visibles
[ ] CONFIGURACION: ConfiguracionERP visible (sin botón Agregar si ya existe)
[ ] Crear un Cliente de prueba → aparece en la lista
[ ] Crear una Categoria + Producto → FK funciona en selector
[ ] Crear una Venta + agregar DetalleVenta inline → total_admin muestra valor
```

---

## PARTE 8 — Tests W05 (15 min)

### 8.1 Crear `tests/test_w05_modelos.py`

```python
"""Suite de pruebas W05 — Smoke tests de modelos Django.

Verifica que los 8 modelos pueden crearse y sus métodos básicos
funcionan correctamente. La suite completa con validators y
casos borde se implementa en W06 (≥ 15 tests).

Ejecutar con:
    python manage.py test tests.test_w05_modelos --verbosity=2

Resultado esperado:
    Ran 10 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.test import TestCase

from clientes.models       import Cliente
from configuracion.models  import ConfiguracionERP
from productos.models      import Categoria, Producto
from proveedores.models    import Proveedor
from ventas.models         import DetalleVenta, Pedido, Venta


class ClienteModelTest(TestCase):
    """Smoke tests del modelo Cliente."""

    def test_cliente_puede_crearse(self):
        """Un cliente con datos válidos debe guardarse sin errores."""
        c = Cliente.objects.create(nombre='Ana Pérez', correo='ana@test.com')
        self.assertEqual(Cliente.objects.count(), 1)
        self.assertEqual(c.nombre, 'Ana Pérez')

    def test_str_cliente(self):
        """__str__ de Cliente debe devolver el nombre."""
        c = Cliente(nombre='Luis García', correo='luis@test.com')
        self.assertEqual(str(c), 'Luis García')

    def test_cliente_activo_por_defecto(self):
        """Un cliente nuevo debe estar activo por defecto."""
        c = Cliente.objects.create(nombre='X', correo='x@test.com')
        self.assertTrue(c.activo)


class ProductoModelTest(TestCase):
    """Smoke tests del modelo Producto."""

    def setUp(self):
        self.cat  = Categoria.objects.create(nombre='Electrónica')
        self.prov = Proveedor.objects.create(
            nombre='Dist. Tech', correo='dist@tech.com'
        )

    def test_producto_puede_crearse(self):
        """Un producto con FK válidas debe guardarse sin errores."""
        p = Producto.objects.create(
            nombre='Laptop', precio=Decimal('12500.00'),
            stock=5, categoria=self.cat
        )
        self.assertEqual(p.nombre, 'Laptop')
        self.assertIsNone(p.proveedor)   # proveedor es opcional

    def test_str_producto_formato_correcto(self):
        """__str__ de Producto debe mostrar nombre y precio formateado."""
        p = Producto(nombre='Mouse', precio=Decimal('250.00'),
                     stock=10, categoria=self.cat)
        self.assertEqual(str(p), 'Mouse ($250.00)')

    def test_producto_sin_proveedor_es_valido(self):
        """Producto puede existir sin proveedor (D-02)."""
        p = Producto.objects.create(
            nombre='Interno', precio=Decimal('100.00'),
            stock=1, categoria=self.cat, proveedor=None
        )
        self.assertIsNone(p.proveedor)


class VentaModelTest(TestCase):
    """Smoke tests del modelo Venta y su propiedad total."""

    def setUp(self):
        cat       = Categoria.objects.create(nombre='General')
        self.prod = Producto.objects.create(
            nombre='Teclado', precio=Decimal('350.00'),
            stock=10, categoria=cat
        )
        self.cli  = Cliente.objects.create(
            nombre='Juan', correo='juan@test.com'
        )
        self.venta = Venta.objects.create(cliente=self.cli)

    def test_venta_puede_crearse(self):
        """Una venta con cliente válido debe guardarse."""
        self.assertEqual(Venta.objects.count(), 1)

    def test_venta_total_sin_detalles_es_cero(self):
        """Una venta sin líneas debe tener total = 0."""
        self.assertEqual(self.venta.total, Decimal('0.00'))

    def test_detalle_venta_subtotal(self):
        """Subtotal = cantidad × precio_unitario."""
        d = DetalleVenta.objects.create(
            venta=self.venta, producto=self.prod,
            cantidad=3, precio_unitario=Decimal('350.00')
        )
        self.assertEqual(d.subtotal, Decimal('1050.00'))

    def test_venta_total_con_detalles(self):
        """Total de la venta = suma de subtotales de sus líneas (D-04)."""
        DetalleVenta.objects.create(
            venta=self.venta, producto=self.prod,
            cantidad=2, precio_unitario=Decimal('350.00')
        )
        self.assertEqual(self.venta.total, Decimal('700.00'))


class ConfiguracionERPTest(TestCase):
    """Smoke tests del modelo singleton ConfiguracionERP."""

    def test_get_instance_crea_registro(self):
        """get_instance() debe crear el registro con pk=1."""
        cfg = ConfiguracionERP.get_instance()
        self.assertEqual(cfg.pk, 1)

    def test_get_instance_es_singleton(self):
        """Dos llamadas a get_instance() deben devolver el mismo registro."""
        cfg1 = ConfiguracionERP.get_instance()
        cfg2 = ConfiguracionERP.get_instance()
        self.assertEqual(cfg1.pk, cfg2.pk)
        self.assertEqual(ConfiguracionERP.objects.count(), 1)
```

### 8.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w05_modelos --verbosity=2
```

**Resultado esperado:**
```
test_cliente_activo_por_defecto ... ok
test_cliente_puede_crearse ... ok
test_detalle_venta_subtotal ... ok
test_get_instance_crea_registro ... ok
test_get_instance_es_singleton ... ok
test_producto_puede_crearse ... ok
test_producto_sin_proveedor_es_valido ... ok
test_str_cliente ... ok
test_str_producto_formato_correcto ... ok
test_venta_total_con_detalles ... ok
test_venta_total_sin_detalles_es_cero ... ok

Ran 10 tests in X.XXXs
OK
```

### 8.3 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 51 tests in X.XXXs · OK` (41 + 10)

---

## CIERRE — Commit Final y Respaldo (10 min)

### Actualizar `sprint1_planning.md`

```markdown
## Sprint Backlog — actualización de estados W05

| Tarea | Estado |
|---|---|
| Diseño diagrama ER (8 entidades) | ✅ W04 |
| Normalizar 3FN + decisiones | ✅ W04 |
| Aprobación del asesor | ✅ W04 |
| Crear app configuracion | ✅ W05 |
| Implementar models.py × 6 apps | ✅ W05 |
| Ejecutar makemigrations + migrate | ✅ W05 |
| Registrar en admin.py | ✅ W05 |
| 10 smoke tests pasando | ✅ W05 |
| Agregar validators a campos críticos | ⏳ W06 |
| Suite completa ≥ 15 tests | ⏳ W06 |
| Instalar y configurar django-jazzmin | ⏳ W06 |
```

### Commit de cierre W05

```cmd
git add .
git status

:: Verificar que incluye:
::   configuracion/models.py, configuracion/admin.py
::   clientes/models.py, proveedores/models.py
::   productos/models.py, ventas/models.py
::   */migrations/0001_initial.py (× 5 apps)
::   tests/test_w05_modelos.py
::   sprint1_planning.md (actualizado)

git commit -m "Sprint 1 W05: 8 modelos + migraciones + admin + 51 tests OK"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W05

### Modelos

```
MODELOS IMPLEMENTADOS
[ ] clientes/models.py: Cliente (5 campos + Meta + __str__)
[ ] proveedores/models.py: Proveedor (6 campos + Meta + __str__)
[ ] productos/models.py: Categoria + Producto (FK PROTECT + FK SET_NULL)
[ ] ventas/models.py: Venta (total @property D-04) +
                      DetalleVenta (subtotal @property + save() D-06) +
                      Pedido (choices estado)
[ ] configuracion/models.py: ConfiguracionERP (singleton D-07 + get_instance())

CONSISTENCIA CON ER APROBADO
[ ] Cada modelo tiene exactamente los campos del diagrama ER
[ ] on_delete de cada FK coincide con decisiones D-01 a D-05
[ ] Venta.total NO es campo de BD (es @property)
[ ] DetalleVenta.precio_unitario es campo almacenado (no derivado)
[ ] ConfiguracionERP.pk siempre = 1 (save() lo fuerza)

MIGRACIONES
[ ] makemigrations: 0001_initial en 5 apps (clientes, proveedores,
    productos, ventas, configuracion)
[ ] migrate: todos los [X] en showmigrations
[ ] python manage.py check → 0 issues

ADMIN
[ ] /admin/ muestra las 6 apps con sus modelos
[ ] VentaAdmin tiene DetalleVentaInline (agregar líneas desde la venta)
[ ] ConfiguracionERPAdmin: sin botón "Agregar" si ya existe registro
[ ] Crear Cliente de prueba → aparece en lista
[ ] Crear Categoria + Producto → selector FK funciona
[ ] Crear Venta + DetalleVenta → total_admin muestra valor correcto

TESTS Y GIT
[ ] test tests.test_w05_modelos → 10/10 OK (smoke tests)
[ ] test tests → 51/51 OK (acumulados W01–W05)
[ ] Commit parcial post-migraciones
[ ] Commit de cierre con mensaje descriptivo
[ ] git push → GitHub con migraciones y admin actualizados
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Árbol de importaciones entre modelos

```
configuracion/models.py
  (sin dependencias)

clientes/models.py
  (sin dependencias)

proveedores/models.py
  (sin dependencias)

productos/models.py
  ← from proveedores.models import Proveedor

ventas/models.py
  ← from clientes.models  import Cliente
  ← from productos.models import Producto
```

> **Regla de importación:** nunca circular. El gráfico de dependencias
> debe ser un DAG (grafo dirigido acíclico). Si `clientes` importara
> desde `ventas`, habría un ciclo → Django lo rechazaría en el arranque.

---

## HILO CONDUCTOR → W06

**¿Qué entrega W05?**
Los 8 modelos Django implementados, migrados a la BD y visibles
en el admin. Los 10 smoke tests verifican que los modelos
funcionan en escenarios básicos.

**¿Qué necesita W06 de W05?**

| Artefacto de W05 | Uso en W06 |
|---|---|
| `models.py` × 6 apps | W06 agrega `validators` y `clean()` para integridad |
| `migrations/0001_initial.py` | W06 crea `0002_validators.py` sobre esta base |
| `admin.py` básico | W06 instala `django-jazzmin` y lo personaliza |
| 10 smoke tests | W06 los amplía a ≥ 15 con casos borde y validators |

**Tarea de investigación para W06:**
> Lee la documentación de Django sobre `validators`:
> `https://docs.djangoproject.com/en/4.2/ref/validators/`
>
> ¿Cuál es la diferencia entre `MinValueValidator` y el método `clean()`
> de un modelo? ¿Cuándo usarías uno y cuándo el otro?

**Pregunta de reflexión:**
> "En W05 creamos el `save()` de `DetalleVenta` con `if self.precio_unitario is None`.
> ¿Por qué usamos `is None` y no simplemente `if not self.precio_unitario`?
> ¿Qué diferencia hace cuando `precio_unitario = Decimal('0.00')`?"

---

## Referencia rápida de comandos W05

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO — MODELOS
python manage.py check
python manage.py makemigrations <nombre_app>
python manage.py makemigrations
python manage.py showmigrations
python manage.py migrate
python manage.py runserver

:: SHELL — verificar modelos manualmente
python manage.py shell
>>> from clientes.models import Cliente
>>> Cliente.objects.create(nombre='Test', correo='t@t.com')
>>> from ventas.models import Venta
>>> from clientes.models import Cliente
>>> c = Cliente.objects.first()
>>> v = Venta.objects.create(cliente=c)
>>> v.total
Decimal('0.00')

:: TESTS
python manage.py test tests.test_w05_modelos --verbosity=2
python manage.py test tests --verbosity=0   (51 tests acumulados)

:: GIT
git add .
git commit -m "Sprint 1 W05: descripción del avance"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W05 · ERP Django*
*Espiral 2 · Sprint 1 Desarrollo · 8 Modelos Django + Migraciones + Admin*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*