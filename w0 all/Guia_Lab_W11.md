# Guía de Laboratorio — W11
## ERP Django · Espiral 4 · Semana 11 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W11 de 24 |
| **Espiral** | E4 — API REST y Media |
| **Sprint Scrum** | Sprint 3 — Desarrollo |
| **Hito** | Sin hito propio · Avance hacia M4 (W12) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 3 — Infraestructura |
| **Hilo conductor** | "W10 abrió la API. W11 le da ojos: imágenes de productos validadas y almacenadas." |

---

## Respuesta a la tarea de investigación de W10

> **¿Diferencia entre `MEDIA_ROOT` y `STATIC_ROOT`?**
>
> | Aspecto | `STATIC_ROOT` | `MEDIA_ROOT` |
> |---|---|---|
> | Origen | Archivos del desarrollador (CSS, JS, imágenes del diseño) | Archivos subidos por usuarios en tiempo de ejecución |
> | Comando | `collectstatic` los recolecta antes del deploy | No se recolectan — se generan en producción |
> | Servicio en prod | Nginx, WhiteNoise, CDN | Nginx, S3, MinIO — **nunca Gunicorn** |
> | En `.gitignore` | `staticfiles/` (sí, el resultado de collectstatic) | `media/` (sí, son datos del sistema) |
>
> **¿Por qué no servir media con Gunicorn en producción?**
> Gunicorn es un servidor WSGI de aplicación: procesa Python, no sirve archivos.
> Servir archivos con Gunicorn bloquea workers durante la transferencia,
> degradando el rendimiento. Nginx sirve archivos estáticos 100× más
> eficientemente porque lee directamente del disco sin invocar Python.
>
> **¿Qué es `django-storages` y `S3Boto3Storage`?**
> `django-storages` es un paquete que implementa backends de almacenamiento
> alternativos al sistema de archivos local. `S3Boto3Storage` redirige
> las operaciones `FileField.save()` hacia un bucket de Amazon S3 (o
> compatible: MinIO, Cloudflare R2, DigitalOcean Spaces).

---

## Objetivos de la sesión

Al terminar W11, el estudiante será capaz de:

1. Agregar `ImageField` al modelo `Producto` con validación de tipo y tamaño
2. Crear una migración descriptiva para el nuevo campo
3. Actualizar el serializer DRF para exponer la URL completa de la imagen
4. Actualizar el formulario y el template para subir y mostrar imágenes
5. Agregar previsualización de imagen en el panel admin con Jazzmin
6. Instalar y configurar `django-storages` para producción (S3/MinIO)
7. Escribir 8 tests que verifican subida, validación y presencia en la API

---

## Stack tecnológico de W11

| Herramienta | Novedad en W11 | Descripción |
|---|---|---|
| `Pillow` | ✅ Activo (ya instalado) | Procesamiento de imágenes: validación y thumbnails |
| `ImageField` | ✅ Nuevo | Campo de modelo Django para imágenes |
| `SimpleUploadedFile` | ✅ Nuevo | Archivo en memoria para tests de subida |
| `django-storages` | ✅ Nuevo (instalado) | Backends de almacenamiento alternativos |
| `S3Boto3Storage` | ✅ Configurado en prod | Almacena archivos en Amazon S3 o compatible |
| `filetype` | ✅ Nuevo | Detecta MIME real del archivo (más seguro que extensión) |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + verificar W10 | 10 min |
| Parte 1 | Instalar dependencias + `ImageField` + migración | 20 min |
| Parte 2 | Validador custom de imagen (tipo MIME + tamaño) | 20 min |
| Parte 3 | Actualizar `ProductoSerializer` con `imagen_url` | 15 min |
| Parte 4 | Actualizar `ProductoForm` + templates | 20 min |
| Parte 5 | Actualizar `ProductoAdmin` con preview | 10 min |
| Parte 6 | Configurar `django-storages` para producción | 15 min |
| Parte 7 | Tests W11 (8 pruebas con `SimpleUploadedFile`) | 20 min |
| Cierre | Commit · `finalizar_sesion.bat` · hilo → W12 | 10 min |
| Buffer | | 20 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W10?
   → Creé serializers para 5 entidades, implementé las vistas de API
     con autenticación por token y escribí 7 tests con APIClient.

2. ¿Qué haré en W11?
   → Agregaré ImageField al modelo Producto, crearé un validador
     de tipo MIME, actualizaré la API para exponer URLs de imagen
     y configuraré django-storages para producción.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 107 tests … OK`

---

## PARTE 1 — Dependencias + `ImageField` + Migración (20 min)

### 1.1 Instalar dependencias

```cmd
pip install Pillow "django-storages[s3]==1.14.2" "filetype==1.2.0"
pip freeze > requirements.txt
```

Verificar instalación:
```cmd
python -c "import PIL; print('Pillow', PIL.__version__)"
python -c "import storages; print('storages OK')"
python -c "import filetype; print('filetype OK')"
```

---

### 1.2 Agregar `ImageField` a `productos/models.py`

Agregar el import del validador al inicio (lo crearemos en Parte 2):

```python
# productos/models.py — al inicio, agregar:
# (el validador se definirá en validators.py en Parte 2)
```

Agregar el campo `imagen` a la clase `Producto`, después del campo `activo`:

```python
# En la clase Producto — agregar campo imagen:

    imagen = models.ImageField(
        upload_to='productos/',      # subcarpeta dentro de MEDIA_ROOT
        null=True,
        blank=True,
        verbose_name='Imagen del producto',
        help_text='Formatos permitidos: JPEG, PNG, WEBP. Máximo 5 MB.'
    )
```

El modelo `Producto` completo con el nuevo campo queda así
(solo se muestra la sección de campos relevante):

```python
class Producto(models.Model):
    nombre    = models.CharField(max_length=200, verbose_name='Nombre')
    precio    = models.DecimalField(...)
    stock     = models.IntegerField(...)
    categoria = models.ForeignKey(Categoria, ...)
    proveedor = models.ForeignKey(Proveedor, ...)
    activo    = models.BooleanField(default=True, verbose_name='Activo')
    imagen    = models.ImageField(          # ← nuevo campo W11
        upload_to='productos/',
        null=True,
        blank=True,
        verbose_name='Imagen del producto',
        help_text='Formatos permitidos: JPEG, PNG, WEBP. Máximo 5 MB.'
    )
    creado    = models.DateTimeField(auto_now_add=True)
```

> **Orden:** `imagen` va antes de `creado` para que la migración sea limpia.
> Si `creado` ya tiene `auto_now_add=True`, no es un campo nullable → Django
> no pedirá valor por defecto para `imagen` porque ya tiene `null=True`.

---

### 1.3 Crear la migración

```cmd
python manage.py makemigrations productos --name imagen_producto
```

**Resultado esperado:**
```
Migrations for 'productos':
  productos/migrations/0002_imagen_producto.py
    - Add field imagen to producto
```

```cmd
python manage.py migrate
```

**Resultado esperado:**
```
Applying productos.0002_imagen_producto... OK
```

### 1.4 Verificar

```cmd
python manage.py check
python manage.py showmigrations productos
```

```
productos
 [X] 0001_initial
 [X] 0002_imagen_producto
```

---

## PARTE 2 — Validador Custom de Imagen (20 min)

### 2.1 ¿Por qué no confiar solo en la extensión del archivo?

```
Archivo renombrado: virus.exe → imagen.jpg
                                   ↑
                    La extensión dice "jpg" pero el contenido es un ejecutable.
                    Sin validación MIME, Django lo guarda sin protestar.
```

La solución correcta es leer los **primeros bytes** del archivo para
detectar el tipo real. `Pillow` puede verificar si el contenido
es una imagen válida; `filetype` detecta el MIME desde los magic bytes.

---

### 2.2 Crear `productos/validators.py`

```python
# productos/validators.py
"""Validadores de archivos de imagen para la app productos — W11.

Valida:
    - Que el archivo sea realmente una imagen (Pillow + filetype)
    - Que el formato sea JPEG, PNG o WEBP
    - Que el tamaño no supere MAX_IMAGE_SIZE
"""
import filetype
from PIL import Image, UnidentifiedImageError

from django.core.exceptions import ValidationError


# Tamaño máximo permitido: 5 MB
MAX_IMAGE_SIZE = 5 * 1024 * 1024   # 5,242,880 bytes

# Formatos de imagen aceptados
FORMATOS_MIME_PERMITIDOS = {'image/jpeg', 'image/png', 'image/webp'}
FORMATOS_PILLOW_PERMITIDOS = {'JPEG', 'PNG', 'WEBP'}


def validar_imagen_producto(archivo) -> None:
    """Valida un archivo subido como imagen de producto.

    Verificaciones realizadas (en orden):
        1. Tamaño máximo 5 MB.
        2. Tipo MIME real (magic bytes) es image/jpeg, image/png o image/webp.
        3. El contenido puede abrirse con Pillow (imagen no corrupta).

    Args:
        archivo: archivo Django (InMemoryUploadedFile o TemporaryUploadedFile).

    Raises:
        ValidationError: si alguna verificación falla.
    """
    # ── 1. Verificar tamaño ───────────────────────────────────────────────
    if archivo.size > MAX_IMAGE_SIZE:
        raise ValidationError(
            f'La imagen supera el tamaño máximo permitido de 5 MB. '
            f'Tamaño recibido: {archivo.size / (1024 * 1024):.1f} MB.'
        )

    # ── 2. Detectar MIME desde magic bytes (no confiar en extensión) ──────
    archivo.seek(0)
    cabecera = archivo.read(512)   # los primeros 512 bytes son suficientes
    archivo.seek(0)

    tipo = filetype.guess(cabecera)
    if tipo is None or tipo.mime not in FORMATOS_MIME_PERMITIDOS:
        mime_detectado = tipo.mime if tipo else 'desconocido'
        raise ValidationError(
            f'Tipo de archivo no permitido: {mime_detectado}. '
            f'Solo se aceptan: JPEG, PNG, WEBP.'
        )

    # ── 3. Verificar que Pillow puede abrir la imagen (no corrupta) ───────
    archivo.seek(0)
    try:
        img = Image.open(archivo)
        img.verify()               # verify() cierra el stream internamente
    except (UnidentifiedImageError, Exception) as exc:
        raise ValidationError(
            f'El archivo no es una imagen válida o está corrupto: {exc}'
        )
    finally:
        archivo.seek(0)            # reset para que Django pueda guardar el archivo
```

---

### 2.3 Conectar el validador al campo `ImageField`

Actualizar `productos/models.py` — agregar el import y el validador:

```python
# productos/models.py — agregar al inicio:
from .validators import validar_imagen_producto

# Actualizar el campo imagen en la clase Producto:
    imagen = models.ImageField(
        upload_to='productos/',
        null=True,
        blank=True,
        verbose_name='Imagen del producto',
        help_text='Formatos: JPEG, PNG, WEBP. Máximo 5 MB.',
        validators=[validar_imagen_producto],   # ← agregar
    )
```

### 2.4 Verificar

```cmd
python manage.py check
```

**Resultado esperado:** `System check identified no issues (0 silenced).`

---

## PARTE 3 — Actualizar `ProductoSerializer` con `imagen_url` (15 min)

### 3.1 ¿Por qué `SerializerMethodField` y no el campo directamente?

```python
# Opción A — campo directo (devuelve ruta relativa)
imagen = serializers.ImageField()
# Respuesta: "imagen": "productos/foto.jpg"  ← ruta relativa, inutilizable
# El cliente externo no sabe la URL base del servidor.

# Opción B — SerializerMethodField (devuelve URL absoluta)
imagen_url = serializers.SerializerMethodField()
def get_imagen_url(self, obj):
    request = self.context.get('request')
    if obj.imagen and request:
        return request.build_absolute_uri(obj.imagen.url)
    return None
# Respuesta: "imagen_url": "https://erp.onrender.com/media/productos/foto.jpg"
# El cliente externo tiene la URL completa lista para mostrar.
```

---

### 3.2 Actualizar `productos/serializers.py`

```python
# productos/serializers.py — versión W11
"""Serializers de la app productos — W11.

Novedades respecto a W10:
    ProductoSerializer: agrega imagen_url (URL absoluta de la imagen).
"""
from rest_framework import serializers

from .models import Categoria, Producto


class CategoriaSerializer(serializers.ModelSerializer):
    """Serializer de Categoria — sin cambios respecto a W10."""

    class Meta:
        model            = Categoria
        fields           = ['id', 'nombre', 'descripcion']
        read_only_fields = ['id']


class ProductoSerializer(serializers.ModelSerializer):
    """Serializer de Producto con URL absoluta de imagen.

    imagen_url: URL completa de la imagen del producto.
                None si el producto no tiene imagen.
                Requiere que el contexto incluya 'request'
                (automático en vistas APIView).
    """

    categoria_nombre = serializers.CharField(
        source='categoria.nombre',
        read_only=True
    )
    proveedor_nombre = serializers.CharField(
        source='proveedor.nombre',
        read_only=True,
        allow_null=True
    )
    imagen_url = serializers.SerializerMethodField()

    class Meta:
        model  = Producto
        fields = [
            'id', 'nombre', 'precio', 'stock',
            'categoria', 'categoria_nombre',
            'proveedor', 'proveedor_nombre',
            'activo', 'imagen', 'imagen_url', 'creado',
        ]
        read_only_fields = [
            'id', 'creado',
            'categoria_nombre', 'proveedor_nombre',
            'imagen_url',       # solo lectura — se construye en get_imagen_url
        ]
        extra_kwargs = {
            'imagen': {'required': False, 'allow_null': True},
        }

    def get_imagen_url(self, obj: Producto) -> str | None:
        """Devuelve la URL absoluta de la imagen del producto.

        Args:
            obj: instancia de Producto.

        Returns:
            URL absoluta como string, o None si no hay imagen.
        """
        request = self.context.get('request')
        if obj.imagen and request:
            return request.build_absolute_uri(obj.imagen.url)
        if obj.imagen:
            return obj.imagen.url   # fallback sin request (tests)
        return None
```

---

## PARTE 4 — Actualizar `ProductoForm` y Templates (20 min)

### 4.1 Actualizar `productos/forms.py`

Agregar el campo `imagen` a la lista de campos del formulario:

```python
# productos/forms.py — actualizar la clase ProductoForm:
class ProductoForm(forms.ModelForm):
    """Formulario para crear y editar productos — W11.

    Incluye campo imagen con widget de archivo.
    El template debe usar enctype="multipart/form-data".
    """

    class Meta:
        model  = Producto
        fields = ['nombre', 'precio', 'stock', 'categoria',
                  'proveedor', 'activo', 'imagen']   # ← agregar imagen
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
            'categoria': forms.Select(attrs={'class': 'erp-input'}),
            'proveedor': forms.Select(attrs={'class': 'erp-input'}),
            'imagen':    forms.ClearableFileInput(
                attrs={'class': 'erp-input',
                       'accept': 'image/jpeg,image/png,image/webp'}
            ),
        }
        labels = {
            'nombre':    'Nombre',
            'precio':    'Precio ($)',
            'stock':     'Stock disponible',
            'categoria': 'Categoría',
            'proveedor': 'Proveedor',
            'activo':    'Activo',
            'imagen':    'Imagen del producto',
        }
```

---

### 4.2 Actualizar templates para `enctype="multipart/form-data"`

**Crítico:** sin `enctype="multipart/form-data"` en el tag `<form>`,
el archivo no se envía al servidor y `request.FILES` estará vacío.

Abrir `productos/templates/productos/crear.html` y actualizar la etiqueta form:

```html
<!-- En crear.html y editar.html — reemplazar la línea del form: -->
<form method="post" enctype="multipart/form-data" style="margin-top:.5rem;">
```

El resto del template permanece igual — el campo `imagen` aparecerá
automáticamente al iterar `{% for field in form %}`.

Abrir `productos/templates/productos/editar.html` y aplicar el mismo cambio.

---

### 4.3 Actualizar `productos/views.py` para manejar archivos

Las vistas `CreateView` y `UpdateView` de Django manejan `request.FILES`
automáticamente cuando el formulario es un `ModelForm`. No es necesario
cambiar el código de las vistas — Django lo gestiona internamente.

Sin embargo, verificar que las vistas usan `form_class = ProductoForm`
(no `fields = [...]` directamente), ya que el widget de imagen
está definido en el formulario:

```python
# productos/views.py — verificar que ProductoCreateView y ProductoUpdateView
# usan form_class = ProductoForm (ya configurado en W08)
class ProductoCreateView(LoginRequiredMixin, CreateView):
    model         = Producto
    form_class    = ProductoForm      # ← debe usar el formulario, no fields
    template_name = 'productos/crear.html'
    success_url   = reverse_lazy('productos:lista')
    ...
```

---

### 4.4 Actualizar `productos/templates/productos/detalle.html`

Agregar la sección de imagen antes del `<dl>` de atributos:

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

<!-- Imagen del producto — W11 -->
{% if producto.imagen %}
<div class="erp-card" style="max-width:480px;margin-bottom:1rem;">
    <div class="erp-card-header">Imagen del producto</div>
    <div style="text-align:center;padding:.5rem;">
        <img src="{{ producto.imagen.url }}"
             alt="{{ producto.nombre }}"
             style="max-width:100%;max-height:320px;
                    border-radius:8px;object-fit:contain;">
    </div>
</div>
{% endif %}

<div class="erp-card">
    <div class="erp-card-header">Información del producto</div>
    <dl class="row" style="margin:0;">
        <dt class="col-sm-3">Categoría</dt>
        <dd class="col-sm-9">{{ producto.categoria }}</dd>

        <dt class="col-sm-3">Proveedor</dt>
        <dd class="col-sm-9">{{ producto.proveedor|default:"Sin asignar" }}</dd>

        <dt class="col-sm-3">Precio</dt>
        <dd class="col-sm-9"
            style="font-weight:700;color:var(--clr-gold);">
            ${{ producto.precio }}
        </dd>

        <dt class="col-sm-3">Stock</dt>
        <dd class="col-sm-9">
            {% if producto.stock < 5 %}
                <span class="badge-erp-inactive">
                    {{ producto.stock }} unidades (stock bajo)
                </span>
            {% else %}
                <span class="badge-erp-active">
                    {{ producto.stock }} unidades
                </span>
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

### 4.5 Verificar subida de imagen en el navegador

```cmd
python manage.py runserver
```

```
[ ] /productos/nuevo/ → campo "Imagen del producto" visible
[ ] Subir una imagen .jpg válida → producto guardado con imagen
[ ] /productos/<id>/ → imagen visible en la página de detalle
[ ] Subir un archivo .txt → ValidationError "Tipo de archivo no permitido"
[ ] Subir imagen > 5MB → ValidationError "supera el tamaño máximo"
```

---

## PARTE 5 — Actualizar `ProductoAdmin` con Preview (10 min)

### 5.1 Agregar preview de imagen en `productos/admin.py`

```python
# productos/admin.py — actualizar ProductoAdmin:
from django.contrib  import admin
from django.utils.html import format_html

from .models import Categoria, Producto


@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    list_display  = ['pk', 'nombre', 'descripcion']
    search_fields = ['nombre']


@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    """Admin de productos con preview de imagen — W11."""

    list_display   = ['pk', 'imagen_preview', 'nombre', 'precio',
                      'stock', 'categoria', 'proveedor', 'activo']
    search_fields  = ['nombre', 'categoria__nombre', 'proveedor__nombre']
    list_filter    = ['activo', 'categoria']
    list_editable  = ['precio', 'stock', 'activo']
    readonly_fields = ['creado', 'imagen_preview_grande']
    date_hierarchy  = 'creado'
    ordering        = ['nombre']

    @admin.display(description='Imagen')
    def imagen_preview(self, obj: Producto) -> str:
        """Miniatura de la imagen en la lista del admin."""
        if obj.imagen:
            return format_html(
                '<img src="{}" style="height:48px;width:48px;'
                'object-fit:cover;border-radius:6px;">',
                obj.imagen.url
            )
        return '—'

    @admin.display(description='Vista previa')
    def imagen_preview_grande(self, obj: Producto) -> str:
        """Imagen ampliada en el formulario de edición del admin."""
        if obj.imagen:
            return format_html(
                '<img src="{}" style="max-height:200px;'
                'border-radius:8px;margin-top:.5rem;">',
                obj.imagen.url
            )
        return 'Sin imagen'
```

---

## PARTE 6 — Configurar `django-storages` para Producción (15 min)

### 6.1 ¿Qué hace `django-storages`?

En desarrollo, Django guarda archivos en `MEDIA_ROOT` (carpeta local).
En producción, el disco del servidor no es permanente (Render, Heroku
reinician el contenedor) → los archivos subidos se pierden en cada deploy.

`django-storages` con `S3Boto3Storage` redirige el `save()` de
`ImageField` hacia un bucket S3 externo, que persiste entre deploys.

### 6.2 Actualizar `core/settings_prod.py`

Agregar la configuración de S3 **solo en settings_prod.py** (producción).
En desarrollo (`settings.py`) se continúa usando el sistema de archivos local:

```python
# core/settings_prod.py — agregar al final, después de los SECURE_* headers:

# ── ALMACENAMIENTO DE ARCHIVOS MEDIA (producción) ─────────────────────────
# Usar django-storages con S3 para persistir archivos entre deploys.
# Configurar estas variables en el dashboard de Render:
#   AWS_ACCESS_KEY_ID       → Access Key del bucket
#   AWS_SECRET_ACCESS_KEY   → Secret Key del bucket
#   AWS_STORAGE_BUCKET_NAME → Nombre del bucket
#   AWS_S3_REGION_NAME      → Región (ej. us-east-1)
#   AWS_S3_CUSTOM_DOMAIN    → Dominio CDN opcional

_bucket = os.environ.get('AWS_STORAGE_BUCKET_NAME', '')

if _bucket:
    # Solo activa S3 si la variable de entorno está configurada
    DEFAULT_FILE_STORAGE  = 'storages.backends.s3boto3.S3Boto3Storage'
    AWS_ACCESS_KEY_ID     = os.environ.get('AWS_ACCESS_KEY_ID', '')
    AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY', '')
    AWS_STORAGE_BUCKET_NAME = _bucket
    AWS_S3_REGION_NAME    = os.environ.get('AWS_S3_REGION_NAME', 'us-east-1')
    AWS_DEFAULT_ACL       = None        # el bucket controla el acceso
    AWS_S3_FILE_OVERWRITE = False       # no sobreescribir si el nombre ya existe
    AWS_QUERYSTRING_AUTH  = False       # URLs públicas (sin firma)
    MEDIA_URL             = f'https://{_bucket}.s3.amazonaws.com/'
```

### 6.3 Actualizar `.env.example`

```bash
# .env.example — agregar variables S3 (opcionales para producción)
AWS_ACCESS_KEY_ID=TU_ACCESS_KEY_AQUI
AWS_SECRET_ACCESS_KEY=TU_SECRET_KEY_AQUI
AWS_STORAGE_BUCKET_NAME=erp-django-media
AWS_S3_REGION_NAME=us-east-1
```

> **Para el proyecto académico:** el bucket S3 es opcional.
> Render.com tiene un disco efímero que se reinicia con cada deploy.
> Para el MVP académico, las imágenes pueden subirse y mostrarse
> durante la sesión activa sin persistencia entre deploys.
> Para producción real: configurar S3 o usar MinIO local.

---

## PARTE 7 — Tests W11 (20 min)

### 7.1 Función auxiliar para crear imágenes de prueba

```python
# Función reutilizable que se usará dentro de los tests:
import io
from PIL import Image
from django.core.files.uploadedfile import SimpleUploadedFile


def _imagen_valida(nombre='test.jpg', formato='JPEG',
                   content_type='image/jpeg',
                   ancho=100, alto=100) -> SimpleUploadedFile:
    """Crea una imagen válida en memoria para tests.

    Args:
        nombre:       Nombre del archivo simulado.
        formato:      Formato Pillow ('JPEG', 'PNG', 'WEBP').
        content_type: MIME type del archivo.
        ancho, alto:  Dimensiones en píxeles.

    Returns:
        SimpleUploadedFile listo para incluir en request.FILES.
    """
    buf = io.BytesIO()
    img = Image.new('RGB', (ancho, alto), color='navy')
    img.save(buf, format=formato)
    buf.seek(0)
    return SimpleUploadedFile(
        name=nombre, content=buf.read(), content_type=content_type
    )


def _archivo_invalido(nombre='virus.exe') -> SimpleUploadedFile:
    """Crea un archivo que NO es imagen (contenido texto)."""
    return SimpleUploadedFile(
        name=nombre,
        content=b'Este no es una imagen. Es texto plano.',
        content_type='application/octet-stream'
    )
```

---

### 7.2 Crear `tests/test_w11_media.py`

```python
"""Suite de pruebas W11 — ImageField, validadores y API media.

Verifica: subida válida, validación MIME, tamaño máximo,
          URL en la API, imagen en formulario web.

Ejecutar con:
    python manage.py test tests.test_w11_media --verbosity=2

Resultado esperado:
    Ran 8 tests in X.XXXs
    OK
"""
import io
import os

from decimal import Decimal
from PIL import Image

from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase

from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient, APITestCase

from productos.models     import Categoria, Producto
from productos.validators import validar_imagen_producto


# ── Helpers ───────────────────────────────────────────────────────────────

def _imagen(nombre='img.jpg', formato='JPEG', content_type='image/jpeg',
             size=(100, 100)) -> SimpleUploadedFile:
    buf = io.BytesIO()
    Image.new('RGB', size, color='teal').save(buf, format=formato)
    buf.seek(0)
    return SimpleUploadedFile(
        nombre, buf.read(), content_type=content_type
    )


def _archivo_invalido() -> SimpleUploadedFile:
    return SimpleUploadedFile(
        'notimage.exe',
        b'\x00\x01fake binary content\xff\xfe',
        content_type='application/octet-stream'
    )


# ── BLOQUE 1: Validador de imagen ─────────────────────────────────────────

class ValidadorImagenTest(TestCase):
    """Tests del validador validar_imagen_producto."""

    def test_imagen_jpeg_valida_pasa(self):
        """Una imagen JPEG válida no debe lanzar ValidationError."""
        archivo = _imagen()
        try:
            validar_imagen_producto(archivo)
        except ValidationError as e:
            self.fail(f"Imagen JPEG válida lanzó ValidationError: {e}")

    def test_imagen_png_valida_pasa(self):
        """Una imagen PNG válida debe pasar el validador."""
        archivo = _imagen('img.png', 'PNG', 'image/png')
        try:
            validar_imagen_producto(archivo)
        except ValidationError as e:
            self.fail(f"Imagen PNG válida lanzó ValidationError: {e}")

    def test_archivo_no_imagen_lanza_error(self):
        """Un archivo binario no-imagen debe lanzar ValidationError."""
        archivo = _archivo_invalido()
        with self.assertRaises(ValidationError) as ctx:
            validar_imagen_producto(archivo)
        self.assertIn('no permitido', str(ctx.exception).lower())

    def test_imagen_muy_grande_lanza_error(self):
        """Una imagen mayor a 5 MB debe lanzar ValidationError."""
        # Crear un SimpleUploadedFile con size simulado > 5MB
        archivo = _imagen()
        archivo.size = 6 * 1024 * 1024   # simular 6MB
        with self.assertRaises(ValidationError) as ctx:
            validar_imagen_producto(archivo)
        self.assertIn('5 mb', str(ctx.exception).lower())


# ── BLOQUE 2: Modelo Producto con imagen ─────────────────────────────────

class ProductoImagenModelTest(TestCase):
    """Tests del ImageField en el modelo Producto."""

    def setUp(self):
        self.cat = Categoria.objects.create(nombre='Cat Media')

    def tearDown(self):
        """Eliminar archivos de imagen creados durante los tests."""
        for prod in Producto.objects.all():
            if prod.imagen:
                try:
                    os.remove(prod.imagen.path)
                except FileNotFoundError:
                    pass

    def test_producto_sin_imagen_es_valido(self):
        """Producto creado sin imagen debe ser válido (imagen es opcional)."""
        prod = Producto.objects.create(
            nombre='Sin imagen', precio=Decimal('100.00'),
            stock=5, categoria=self.cat
        )
        self.assertFalse(bool(prod.imagen))

    def test_producto_puede_guardarse_con_imagen(self):
        """Producto con imagen JPEG válida debe guardarse correctamente."""
        prod = Producto(
            nombre='Con imagen', precio=Decimal('200.00'),
            stock=3, categoria=self.cat,
            imagen=_imagen()
        )
        prod.save()
        self.assertTrue(bool(prod.imagen))
        self.assertIn('productos/', prod.imagen.name)


# ── BLOQUE 3: imagen_url en la API ────────────────────────────────────────

class ProductoAPIImagenTest(APITestCase):
    """Tests del campo imagen_url en el endpoint de la API."""

    def setUp(self):
        self.client  = APIClient()
        self.user    = User.objects.create_user('mediauser', password='pass')
        self.token   = Token.objects.create(user=self.user)
        self.cat     = Categoria.objects.create(nombre='Cat API')

    def tearDown(self):
        for prod in Producto.objects.all():
            if prod.imagen:
                try:
                    os.remove(prod.imagen.path)
                except FileNotFoundError:
                    pass

    def test_api_devuelve_imagen_url_none_sin_imagen(self):
        """Producto sin imagen → imagen_url debe ser None en el JSON."""
        prod = Producto.objects.create(
            nombre='Sin img API', precio=Decimal('100.00'),
            stock=5, categoria=self.cat
        )
        r = self.client.get(f'/api/productos/{prod.pk}/')
        self.assertEqual(r.status_code, 200)
        self.assertIsNone(r.json().get('imagen_url'))

    def test_api_devuelve_imagen_url_con_imagen(self):
        """Producto con imagen → imagen_url debe ser una URL no nula."""
        prod = Producto(
            nombre='Con img API', precio=Decimal('300.00'),
            stock=2, categoria=self.cat,
            imagen=_imagen()
        )
        prod.save()
        r = self.client.get(f'/api/productos/{prod.pk}/')
        self.assertEqual(r.status_code, 200)
        url = r.json().get('imagen_url')
        self.assertIsNotNone(url)
        self.assertIn('productos/', url)
```

### 7.3 Ejecutar los tests

```cmd
python manage.py test tests.test_w11_media --verbosity=2
```

**Resultado esperado:**
```
test_api_devuelve_imagen_url_con_imagen ... ok
test_api_devuelve_imagen_url_none_sin_imagen ... ok
test_archivo_no_imagen_lanza_error ... ok
test_imagen_jpeg_valida_pasa ... ok
test_imagen_muy_grande_lanza_error ... ok
test_imagen_png_valida_pasa ... ok
test_producto_puede_guardarse_con_imagen ... ok
test_producto_sin_imagen_es_valido ... ok

Ran 8 tests in X.XXXs
OK
```

### 7.4 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 115 tests in X.XXXs · OK` (107 + 8)

---

## CIERRE — Commit y Respaldo (10 min)

### Actualizar `sprint3_planning.md`

```markdown
## Sprint Backlog — actualización W11

| Tarea | Estado |
|---|---|
| Serializers + API Views + Token Auth | ✅ W10 |
| Pillow + filetype instalados | ✅ W11 |
| ImageField en Producto + migración 0002 | ✅ W11 |
| Validador custom (MIME + tamaño) | ✅ W11 |
| ProductoSerializer con imagen_url | ✅ W11 |
| ProductoForm con widget imagen | ✅ W11 |
| Templates crear/editar: enctype multipart | ✅ W11 |
| detalle.html muestra imagen | ✅ W11 |
| ProductoAdmin con preview de imagen | ✅ W11 |
| django-storages configurado para prod | ✅ W11 |
| 8 tests de media pasando | ✅ W11 |
| Generación PDF WeasyPrint | ⏳ W12 |
| Exportación Excel openpyxl | ⏳ W12 |
```

### Commit de cierre W11

```cmd
git add .
git status

:: Verificar que incluye:
::   productos/migrations/0002_imagen_producto.py
::   productos/models.py (con ImageField)
::   productos/validators.py (nuevo)
::   productos/serializers.py (con imagen_url)
::   productos/forms.py (con imagen)
::   productos/admin.py (con preview)
::   productos/templates/productos/detalle.html (con <img>)
::   productos/templates/productos/crear.html (enctype actualizado)
::   productos/templates/productos/editar.html (enctype actualizado)
::   core/settings_prod.py (con S3 config)
::   tests/test_w11_media.py
::   sprint3_planning.md

git commit -m "Sprint 3 W11: ImageField + validator MIME + storages + 115 tests OK"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W11

### Técnico

```
INSTALACIÓN
[ ] pip install Pillow django-storages filetype → sin errores
[ ] requirements.txt actualizado con los 3 paquetes

MODELO Y MIGRACIÓN
[ ] productos/models.py: ImageField con upload_to='productos/'
[ ] ImageField: null=True, blank=True (imagen opcional)
[ ] ImageField: validators=[validar_imagen_producto]
[ ] productos/migrations/0002_imagen_producto.py creada y aplicada
[ ] python manage.py showmigrations productos → [X] 0002

VALIDADOR
[ ] productos/validators.py: validar_imagen_producto()
[ ] Verifica tamaño máximo 5 MB
[ ] Verifica MIME con filetype (no solo extensión)
[ ] Verifica que Pillow puede abrir el archivo
[ ] archivo.seek(0) al inicio y al final del validador

SERIALIZER
[ ] imagen_url = SerializerMethodField()
[ ] get_imagen_url usa request.build_absolute_uri(obj.imagen.url)
[ ] imagen_url es None si el producto no tiene imagen
[ ] GET /api/productos/<id>/ → JSON incluye 'imagen_url'

FORMULARIO Y TEMPLATES
[ ] ProductoForm incluye 'imagen' en Meta.fields
[ ] Widget ClearableFileInput con accept=image/jpeg,image/png,image/webp
[ ] crear.html: enctype="multipart/form-data"
[ ] editar.html: enctype="multipart/form-data"
[ ] detalle.html: {% if producto.imagen %} <img> visible

ADMIN
[ ] imagen_preview en list_display de ProductoAdmin
[ ] imagen_preview_grande en readonly_fields del formulario
[ ] /admin/ → lista de productos muestra miniatura de imagen

ALMACENAMIENTO PRODUCCIÓN
[ ] core/settings_prod.py: DEFAULT_FILE_STORAGE con S3Boto3Storage
[ ] .env.example: variables AWS_* documentadas
[ ] En dev: FileSystemStorage (default) — sin cambios en settings.py

TESTS
[ ] test tests.test_w11_media → 8/8 OK
[ ] test tests → 115/115 OK acumulados
[ ] tearDown limpia archivos de imagen generados en tests
[ ] test JPEG válido → pasa sin error
[ ] test archivo no-imagen → ValidationError con "no permitido"
[ ] test > 5MB → ValidationError con "5 mb"
[ ] test API sin imagen → imagen_url es None
[ ] test API con imagen → imagen_url contiene 'productos/'

GIT
[ ] sprint3_planning.md actualizado
[ ] Commit con mensaje descriptivo
[ ] git push → GitHub con migración 0002 y validators.py
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Ciclo de vida de un archivo de imagen en el ERP

```
Usuario sube imagen en /productos/nuevo/
    │
    ▼
ProductoCreateView.post()
    │
    ├── ProductoForm(request.POST, request.FILES)
    │         ↓
    │   form.is_valid()
    │         ↓
    │   field.run_validators(archivo)
    │         │
    │         ├── validar_imagen_producto(archivo)
    │         │       ├── ¿tamaño > 5MB?   → ValidationError
    │         │       ├── ¿MIME permitido?  → filetype.guess()
    │         │       └── ¿Pillow puede abrir? → Image.open().verify()
    │         │
    │         └── ✅ válido → continuar
    │
    ├── form.save()
    │       ↓
    │   Producto.imagen.save('productos/foto.jpg', archivo)
    │       ↓ (dev)                  ↓ (prod con S3)
    │   MEDIA_ROOT/productos/     S3Boto3Storage.save()
    │   foto.jpg                  bucket/productos/foto.jpg
    │
    ▼
HTTP 302 → /productos/ + mensaje flash

GET /productos/<id>/
    ↓
detalle.html → <img src="{{ producto.imagen.url }}">
               (dev: /media/productos/foto.jpg)
               (prod: https://bucket.s3.amazonaws.com/productos/foto.jpg)

GET /api/productos/<id>/
    ↓
ProductoSerializer.get_imagen_url()
    → request.build_absolute_uri(obj.imagen.url)
    → "https://erp.onrender.com/media/productos/foto.jpg"
```

---

## HILO CONDUCTOR → W12

**¿Qué entrega W11?**
El modelo `Producto` con imagen validada y almacenada, la API con
`imagen_url` absoluta, y el sistema listo para producción con S3.
115 tests acumulados garantizan la estabilidad.

**¿Qué abre W12 / Hito M4?**
Con la API y los archivos funcionando, W12 cierra la Espiral 4
agregando **generación de PDFs** (facturas descargables) y
**exportación a Excel** (inventario). Sprint 3 Review + Retrospectiva
y declaración del Hito M4.

**¿Qué necesita W12 de W11?**

| Artefacto de W11 | Uso en W12 |
|---|---|
| `Producto.imagen` | La factura PDF puede incluir la imagen del producto |
| `ProductoSerializer` | W12 agrega endpoint de exportación que usa el mismo queryset |
| `django-storages` configurado | El PDF generado puede almacenarse en S3 si es grande |
| 115 tests pasando | W12 agrega tests de descarga PDF y Excel |

**Tarea de investigación para W12:**
> Lee la documentación de WeasyPrint:
> `https://doc.courtbouillon.org/weasyprint/stable/`
>
> ¿Cómo genera WeasyPrint un PDF desde un template HTML de Django?
> ¿Qué diferencia hay entre `render_to_string()` y `render()`
> en el contexto de generación de PDFs?

**Pregunta de reflexión:**
> "En W11 el validador usa `archivo.seek(0)` varias veces.
> ¿Por qué es necesario? ¿Qué pasaría si olvidamos el
> `seek(0)` final antes de que Django guarde el archivo?"

---

## Referencia rápida de comandos W11

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py makemigrations productos --name imagen_producto
python manage.py showmigrations productos
python manage.py migrate
python manage.py runserver

:: TESTS
python manage.py test tests.test_w11_media --verbosity=2
python manage.py test tests --verbosity=0   (115 tests)

:: VERIFICAR IMAGEN EN API (con servidor activo)
curl http://127.0.0.1:8000/api/productos/1/

:: GIT
git add .
git commit -m "Sprint 3 W11: ImageField + MIME validator + storages + 115 tests OK"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W11 · ERP Django*
*Espiral 4 · Sprint 3 Desarrollo · ImageField + Pillow + django-storages*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*