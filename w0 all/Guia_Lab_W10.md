# Guía de Laboratorio — W10
## ERP Django · Espiral 4 · Semana 10 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W10 de 24 |
| **Espiral** | E4 — API REST y Media |
| **Sprint Scrum** | Sprint 3 — Planning |
| **Hito** | Sin hito propio · Avance hacia M4 (W12) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 3 — Infraestructura |
| **Hilo conductor** | "W09 protegió el sistema. W10 lo abre hacia el mundo exterior: la API REST." |

---

## Respuesta a la tarea de investigación de W09

> **¿Diferencia entre `Serializer` y `ModelSerializer`?**
>
> | Aspecto | `Serializer` | `ModelSerializer` |
> |---|---|---|
> | Definición de campos | Manual — cada campo declarado | Automática desde `Meta.model` |
> | Método `save()` | No existe por defecto | Genera `create()` y `update()` |
> | Validación de unicidad | Manual | Automática desde restricciones del modelo |
> | Caso de uso | Formularios sin modelo, APIs especiales | CRUD sobre modelos Django |
>
> **¿Qué hace `read_only_fields`?**
> ```python
> class ProductoSerializer(serializers.ModelSerializer):
>     class Meta:
>         model            = Producto
>         fields           = '__all__'
>         read_only_fields = ['id', 'creado']
> ```
> Los campos en `read_only_fields` se incluyen en la respuesta JSON
> pero se ignoran en peticiones POST/PUT/PATCH. El cliente no puede
> sobrescribirlos — Django los genera automáticamente.
>
> **¿Los grupos Django se reusan en DRF?**
> Sí. DRF usa `request.user.has_perm()` internamente, que lee
> los mismos grupos y permisos del modelo `auth.Permission`.
> Con `DjangoModelPermissions` como clase de permiso, DRF mapea
> automáticamente los métodos HTTP a permisos Django:
> GET → `view_`, POST → `add_`, PUT/PATCH → `change_`, DELETE → `delete_`.

---

## Objetivos de la sesión

Al terminar W10, el estudiante será capaz de:

1. Configurar `rest_framework.authtoken` y obtener tokens por usuario
2. Crear `ModelSerializer` con campos calculados para 5 entidades
3. Implementar `ListCreateAPIView` y `RetrieveUpdateDestroyAPIView`
4. Organizar las URLs de la API bajo el prefijo `/api/`
5. Probar la API con el navegador DRF y con `cURL`
6. Escribir 7 tests con `APIClient` que verifican autenticación y respuestas JSON

---

## Stack tecnológico de W10

| Herramienta | Novedad en W10 | Descripción |
|---|---|---|
| `rest_framework.authtoken` | ✅ Nuevo | Tokens de autenticación por usuario |
| `ModelSerializer` | ✅ Nuevo | Serializer generado desde modelo Django |
| `SerializerMethodField` | ✅ Nuevo | Campo calculado en el serializer |
| `ListCreateAPIView` | ✅ Nuevo | Vista API para GET lista + POST crear |
| `RetrieveUpdateDestroyAPIView` | ✅ Nuevo | Vista API para GET/PUT/PATCH/DELETE por ID |
| `APIClient` | ✅ Nuevo | Cliente HTTP para tests de API DRF |
| `obtain_auth_token` | ✅ Nuevo | Endpoint que devuelve token dado username/password |
| `drf-spectacular` | ✅ Instalado | Generador de documentación OpenAPI (se usa en W23) |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + Sprint 3 Planning + verificar W09 | 15 min |
| Parte 1 | Configurar `authtoken` + actualizar `REST_FRAMEWORK` | 15 min |
| Parte 2 | Serializers × 5 entidades | 30 min |
| Parte 3 | API Views × 5 entidades | 20 min |
| Parte 4 | `api_urls.py` × apps + `/api/` en `core/urls.py` | 15 min |
| Parte 5 | Verificar con navegador DRF y `cURL` | 15 min |
| Parte 6 | Tests W10 (7 pruebas con `APIClient`) | 20 min |
| Cierre | Commit · `finalizar_sesion.bat` · hilo → W11 | 10 min |
| Buffer | | 20 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum + Sprint 3 Planning (15 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W09?
   → Instalé allauth, creé 3 grupos RBAC con PermissionRequired
     y cerré el Sprint 2 con M3 declarado.

2. ¿Qué haré en W10?
   → Crearé los serializers y las vistas de API REST con DRF,
     configuraré la autenticación por token y probaré los endpoints.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado acumulado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 100 tests … OK`

---

### Sprint 3 Planning

**Sprint Goal del Sprint 3:**
> *"Al finalizar el Sprint 3, el ERP expondrá una API REST completa
> con DRF que permita leer y modificar datos de las entidades principales,
> gestionar imágenes de productos y generar PDFs de facturas."*

**Duración:** W10 (DRF base) · W11 (media/Pillow) · W12 (PDF/Excel · M4)

Crear `sprint3_planning.md`:

```markdown
# Sprint 3 Planning — ERP Django
## Semanas W10–W12 · Espiral 4: API REST y Media

**Sprint Goal:**
Al finalizar el Sprint 3, el ERP expondrá una API REST completa
con autenticación por token, gestión de imágenes de productos
y generación de PDFs de facturas.

## HUs seleccionadas

| ID | Historia | Puntos | Semana |
|---|---|---|---|
| HU-E4-01 | Como dev externo, quiero listar productos via API sin auth | 2 | W10 |
| HU-E4-02 | Como dev, quiero crear productos via API con token | 3 | W10 |
| HU-E4-03 | Como dev, quiero API para clientes, proveedores y ventas | 3 | W10 |
| HU-E4-04 | Como admin, quiero subir imagen de producto | 3 | W11 |
| HU-E4-05 | Como dev, quiero que la imagen aparezca en la API | 2 | W11 |
| HU-E4-06 | Como cliente, quiero descargar la factura en PDF | 5 | W12 |
| HU-E4-07 | Como admin, quiero exportar inventario a Excel | 3 | W12 |

**Total Sprint 3:** 21 puntos

## DoD — Sprint 3
- GET /api/productos/ → JSON 200 sin autenticación
- POST /api/productos/ sin token → 403
- POST /api/productos/ con token válido → 201
- Imagen de producto visible en /media/
- GET /ventas/<id>/pdf/ → descarga PDF con líneas de detalle
- GET /productos/exportar-excel/ → archivo .xlsx descargable
- python manage.py test tests → ≥ 107 tests OK
```

---

## PARTE 1 — Configurar `authtoken` y `REST_FRAMEWORK` (15 min)

### 1.1 Agregar `rest_framework.authtoken` a `INSTALLED_APPS`

```python
# core/settings.py — actualizar INSTALLED_APPS (terceros):
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
    'rest_framework.authtoken',    # ← agregar
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

### 1.2 Actualizar `REST_FRAMEWORK` en `settings.py`

```python
# core/settings.py — reemplazar la configuración REST_FRAMEWORK de W01:
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',   # para el navegador
        'rest_framework.authentication.TokenAuthentication',     # para clientes externos
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}
```

### 1.3 Migrar la tabla de tokens

```cmd
python manage.py migrate
```

**Resultado esperado:**
```
Applying authtoken.0001_initial... OK
Applying authtoken.0002_auto_...  OK
```

### 1.4 Verificar

```cmd
python manage.py check
```

---

## PARTE 2 — Serializers × 5 entidades (30 min)

Crear un archivo `serializers.py` en cada app relevante.

### 2.1 `productos/serializers.py`

```python
# productos/serializers.py
"""Serializers de la app productos — W10.

Expone Categoria y Producto como recursos JSON para la API REST.
"""
from rest_framework import serializers

from .models import Categoria, Producto


class CategoriaSerializer(serializers.ModelSerializer):
    """Serializer de Categoria — campos completos."""

    class Meta:
        model            = Categoria
        fields           = ['id', 'nombre', 'descripcion']
        read_only_fields = ['id']


class ProductoSerializer(serializers.ModelSerializer):
    """Serializer de Producto con nombre de categoría y proveedor.

    Campos adicionales:
        categoria_nombre: nombre legible de la FK categoria.
        proveedor_nombre: nombre legible de la FK proveedor (nullable).
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

    class Meta:
        model  = Producto
        fields = [
            'id', 'nombre', 'precio', 'stock',
            'categoria', 'categoria_nombre',
            'proveedor', 'proveedor_nombre',
            'activo', 'creado',
        ]
        read_only_fields = ['id', 'creado', 'categoria_nombre', 'proveedor_nombre']
```

---

### 2.2 `clientes/serializers.py`

```python
# clientes/serializers.py
"""Serializers de la app clientes — W10."""
from rest_framework import serializers

from .models import Cliente


class ClienteSerializer(serializers.ModelSerializer):
    """Serializer de Cliente — todos los campos públicos."""

    class Meta:
        model  = Cliente
        fields = ['id', 'nombre', 'correo', 'telefono', 'activo', 'creado']
        read_only_fields = ['id', 'creado']
```

---

### 2.3 `proveedores/serializers.py`

```python
# proveedores/serializers.py
"""Serializers de la app proveedores — W10."""
from rest_framework import serializers

from .models import Proveedor


class ProveedorSerializer(serializers.ModelSerializer):
    """Serializer de Proveedor — todos los campos."""

    class Meta:
        model  = Proveedor
        fields = ['id', 'nombre', 'contacto', 'correo',
                  'telefono', 'activo', 'creado']
        read_only_fields = ['id', 'creado']
```

---

### 2.4 `ventas/serializers.py`

```python
# ventas/serializers.py
"""Serializers de la app ventas — W10.

Nota sobre Venta.total:
    Es una @property calculada en tiempo de ejecución.
    No existe como campo en la BD.
    Se expone en la API como SerializerMethodField (solo lectura).
"""
from decimal import Decimal

from rest_framework import serializers

from .models import DetalleVenta, Venta


class DetalleVentaSerializer(serializers.ModelSerializer):
    """Serializer de línea de detalle con subtotal calculado."""

    subtotal = serializers.SerializerMethodField()

    class Meta:
        model  = DetalleVenta
        fields = ['id', 'producto', 'cantidad',
                  'precio_unitario', 'subtotal']
        read_only_fields = ['id', 'subtotal']

    def get_subtotal(self, obj: DetalleVenta) -> Decimal:
        """Calcula el subtotal: cantidad × precio_unitario."""
        return obj.subtotal


class VentaSerializer(serializers.ModelSerializer):
    """Serializer de Venta con detalles anidados y total calculado.

    detalles: lista de líneas de detalle (solo lectura en este serializer).
    total:    propiedad calculada, no campo de BD (D-04).
    """

    detalles      = DetalleVentaSerializer(many=True, read_only=True)
    total         = serializers.SerializerMethodField()
    cliente_nombre = serializers.CharField(
        source='cliente.nombre',
        read_only=True
    )

    class Meta:
        model  = Venta
        fields = ['id', 'cliente', 'cliente_nombre',
                  'fecha', 'detalles', 'total']
        read_only_fields = ['id', 'fecha', 'detalles',
                            'total', 'cliente_nombre']

    def get_total(self, obj: Venta) -> Decimal:
        """Devuelve el total calculado de la venta."""
        return obj.total
```

---

## PARTE 3 — API Views × 5 entidades (20 min)

### 3.1 `productos/api_views.py`

```python
# productos/api_views.py
"""Vistas de la API REST para la app productos — W10.

Usa vistas genéricas de DRF:
    ListCreateAPIView            → GET lista + POST crear
    RetrieveUpdateDestroyAPIView → GET/PUT/PATCH/DELETE por ID
"""
from rest_framework.generics import (
    ListCreateAPIView,
    RetrieveUpdateDestroyAPIView,
)

from .models       import Categoria, Producto
from .serializers  import CategoriaSerializer, ProductoSerializer


# ── Categoria ──────────────────────────────────────────────────────────────

class CategoriaListCreateAPIView(ListCreateAPIView):
    """GET /api/categorias/ · POST /api/categorias/"""

    queryset         = Categoria.objects.all().order_by('nombre')
    serializer_class = CategoriaSerializer


class CategoriaDetailAPIView(RetrieveUpdateDestroyAPIView):
    """GET/PUT/PATCH/DELETE /api/categorias/<id>/"""

    queryset         = Categoria.objects.all()
    serializer_class = CategoriaSerializer


# ── Producto ───────────────────────────────────────────────────────────────

class ProductoListCreateAPIView(ListCreateAPIView):
    """GET /api/productos/ · POST /api/productos/

    GET sin autenticación → 200 (IsAuthenticatedOrReadOnly).
    POST sin token → 403.
    POST con token → 201.
    """

    serializer_class = ProductoSerializer

    def get_queryset(self):
        """Solo productos activos con FKs pre-cargadas."""
        return (
            Producto.objects
            .select_related('categoria', 'proveedor')
            .filter(activo=True)
            .order_by('nombre')
        )


class ProductoDetailAPIView(RetrieveUpdateDestroyAPIView):
    """GET/PUT/PATCH/DELETE /api/productos/<id>/"""

    serializer_class = ProductoSerializer

    def get_queryset(self):
        return Producto.objects.select_related('categoria', 'proveedor')
```

---

### 3.2 `clientes/api_views.py`

```python
# clientes/api_views.py
"""Vistas de la API REST para clientes — W10."""
from rest_framework.generics import (
    ListCreateAPIView,
    RetrieveUpdateDestroyAPIView,
)

from .models      import Cliente
from .serializers import ClienteSerializer


class ClienteListCreateAPIView(ListCreateAPIView):
    """GET /api/clientes/ · POST /api/clientes/"""

    queryset         = Cliente.objects.filter(activo=True).order_by('nombre')
    serializer_class = ClienteSerializer


class ClienteDetailAPIView(RetrieveUpdateDestroyAPIView):
    """GET/PUT/PATCH/DELETE /api/clientes/<id>/"""

    queryset         = Cliente.objects.all()
    serializer_class = ClienteSerializer
```

---

### 3.3 `proveedores/api_views.py`

```python
# proveedores/api_views.py
"""Vistas de la API REST para proveedores — W10."""
from rest_framework.generics import (
    ListCreateAPIView,
    RetrieveUpdateDestroyAPIView,
)

from .models      import Proveedor
from .serializers import ProveedorSerializer


class ProveedorListCreateAPIView(ListCreateAPIView):
    """GET /api/proveedores/ · POST /api/proveedores/"""

    queryset         = Proveedor.objects.filter(activo=True).order_by('nombre')
    serializer_class = ProveedorSerializer


class ProveedorDetailAPIView(RetrieveUpdateDestroyAPIView):
    """GET/PUT/PATCH/DELETE /api/proveedores/<id>/"""

    queryset         = Proveedor.objects.all()
    serializer_class = ProveedorSerializer
```

---

### 3.4 `ventas/api_views.py`

```python
# ventas/api_views.py
"""Vistas de la API REST para ventas — W10."""
from rest_framework.generics import (
    ListCreateAPIView,
    RetrieveUpdateDestroyAPIView,
)

from .models      import Venta
from .serializers import VentaSerializer


class VentaListCreateAPIView(ListCreateAPIView):
    """GET /api/ventas/ · POST /api/ventas/"""

    serializer_class = VentaSerializer

    def get_queryset(self):
        return (
            Venta.objects
            .select_related('cliente')
            .prefetch_related('detalles__producto')
            .order_by('-fecha')
        )


class VentaDetailAPIView(RetrieveUpdateDestroyAPIView):
    """GET/PUT/PATCH/DELETE /api/ventas/<id>/"""

    serializer_class = VentaSerializer

    def get_queryset(self):
        return (
            Venta.objects
            .select_related('cliente')
            .prefetch_related('detalles__producto')
        )
```

---

## PARTE 4 — `api_urls.py` + `/api/` en `core/urls.py` (15 min)

### 4.1 `productos/api_urls.py`

```python
# productos/api_urls.py
"""URLs de la API REST para la app productos — W10."""
from django.urls import path
from . import api_views

urlpatterns = [
    path('categorias/',      api_views.CategoriaListCreateAPIView.as_view()),
    path('categorias/<int:pk>/', api_views.CategoriaDetailAPIView.as_view()),
    path('productos/',       api_views.ProductoListCreateAPIView.as_view()),
    path('productos/<int:pk>/',  api_views.ProductoDetailAPIView.as_view()),
]
```

### 4.2 `clientes/api_urls.py`

```python
# clientes/api_urls.py
from django.urls import path
from . import api_views

urlpatterns = [
    path('clientes/',          api_views.ClienteListCreateAPIView.as_view()),
    path('clientes/<int:pk>/', api_views.ClienteDetailAPIView.as_view()),
]
```

### 4.3 `proveedores/api_urls.py`

```python
# proveedores/api_urls.py
from django.urls import path
from . import api_views

urlpatterns = [
    path('proveedores/',          api_views.ProveedorListCreateAPIView.as_view()),
    path('proveedores/<int:pk>/', api_views.ProveedorDetailAPIView.as_view()),
]
```

### 4.4 `ventas/api_urls.py`

```python
# ventas/api_urls.py
from django.urls import path
from . import api_views

urlpatterns = [
    path('ventas/',          api_views.VentaListCreateAPIView.as_view()),
    path('ventas/<int:pk>/', api_views.VentaDetailAPIView.as_view()),
]
```

### 4.5 Actualizar `core/urls.py`

```python
# core/urls.py — agregar las rutas de API y token
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.authtoken.views import obtain_auth_token
from . import views

# Importar y combinar todas las URLs de la API
from productos.api_urls   import urlpatterns as productos_api
from clientes.api_urls    import urlpatterns as clientes_api
from proveedores.api_urls import urlpatterns as proveedores_api
from ventas.api_urls      import urlpatterns as ventas_api

api_urlpatterns = (
    productos_api +
    clientes_api  +
    proveedores_api +
    ventas_api
)

urlpatterns = [
    path('admin/',      admin.site.urls),
    path('',            views.bienvenida,             name='inicio'),
    path('accounts/',   include('allauth.urls')),
    # API REST
    path('api/',        include((api_urlpatterns, 'api'))),
    path('api/auth/token/', obtain_auth_token, name='api_token'),
    # Apps del ERP (interfaz web)
    path('clientes/',    include('clientes.urls',    namespace='clientes')),
    path('proveedores/', include('proveedores.urls', namespace='proveedores')),
    path('productos/',   include('productos.urls',   namespace='productos')),
    path('ventas/',      include('ventas.urls',       namespace='ventas')),
    path('reportes/',    include('reportes.urls',     namespace='reportes')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

### 4.6 Verificar

```cmd
python manage.py check
python manage.py runserver
```

Abrir en el navegador:

| URL | Resultado esperado |
|---|---|
| `http://127.0.0.1:8000/api/productos/` | JSON con lista de productos (Browsable API) |
| `http://127.0.0.1:8000/api/clientes/` | JSON con lista de clientes |
| `http://127.0.0.1:8000/api/ventas/` | JSON con lista de ventas + detalles anidados |

---

## PARTE 5 — Verificar con Browsable API y cURL (15 min)

### 5.1 Obtener un token desde el navegador

```cmd
:: En una terminal con el servidor activo (otra terminal):
curl -X POST http://127.0.0.1:8000/api/auth/token/ ^
     -H "Content-Type: application/json" ^
     -d "{\"username\": \"admin\", \"password\": \"tu-password\"}"
```

**Resultado esperado:**
```json
{"token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"}
```

### 5.2 Usar el token para crear un producto

```cmd
:: GET lista (sin auth → 200 porque IsAuthenticatedOrReadOnly)
curl http://127.0.0.1:8000/api/productos/

:: POST sin auth → 403
curl -X POST http://127.0.0.1:8000/api/productos/ ^
     -H "Content-Type: application/json" ^
     -d "{\"nombre\": \"Monitor\", \"precio\": \"5000\", \"stock\": 3, \"categoria\": 1}"

:: POST con token → 201
curl -X POST http://127.0.0.1:8000/api/productos/ ^
     -H "Content-Type: application/json" ^
     -H "Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b" ^
     -d "{\"nombre\": \"Monitor 4K\", \"precio\": \"6500\", \"stock\": 3, \"categoria\": 1}"
```

### 5.3 Verificación en el Browsable API

```
[ ] /api/productos/ → muestra formulario de POST en el navegador (si está autenticado)
[ ] /api/productos/1/ → muestra el detalle con botones PUT/PATCH/DELETE
[ ] /api/ventas/1/ → muestra detalles anidados y campo total calculado
[ ] /api/auth/token/ → formulario para obtener token
```

---

## PARTE 6 — Tests W10 con `APIClient` (20 min)

### 6.1 Diferencia entre `TestCase.client` y `APIClient`

```python
# TestCase.client (usado en W07-W09):
#   → envía peticiones HTTP simples
#   → no tiene métodos para headers de autorización
#   → adecuado para vistas HTML

# APIClient (DRF):
#   → tiene .credentials(HTTP_AUTHORIZATION='Token xxx')
#   → tiene .force_authenticate(user=user)
#   → adecuado para vistas API que devuelven JSON
from rest_framework.test import APIClient
```

---

### 6.2 Crear `tests/test_w10_api.py`

```python
"""Suite de pruebas W10 — API REST con DRF y autenticación por token.

Verifica: GET sin auth → 200, POST sin auth → 403,
          POST con token → 201, GET detalle → JSON correcto,
          DELETE con token → 204.

Ejecutar con:
    python manage.py test tests.test_w10_api --verbosity=2

Resultado esperado:
    Ran 7 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient, APITestCase

from clientes.models    import Cliente
from productos.models   import Categoria, Producto
from proveedores.models import Proveedor
from ventas.models      import DetalleVenta, Venta


class ProductoAPITest(APITestCase):
    """Tests de los endpoints /api/productos/."""

    def setUp(self):
        self.client   = APIClient()
        self.user     = User.objects.create_user('apiuser', password='pass')
        self.token    = Token.objects.create(user=self.user)
        self.cat      = Categoria.objects.create(nombre='Cat API')
        self.producto = Producto.objects.create(
            nombre='Teclado API', precio=Decimal('450.00'),
            stock=10, categoria=self.cat
        )

    def test_get_lista_sin_auth_devuelve_200(self):
        """GET /api/productos/ sin token → 200 (lectura pública)."""
        r = self.client.get('/api/productos/')
        self.assertEqual(r.status_code, 200)

    def test_get_lista_devuelve_json_con_productos(self):
        """La respuesta debe ser JSON con el campo 'results'."""
        r = self.client.get('/api/productos/')
        self.assertEqual(r.status_code, 200)
        data = r.json()
        # Con paginación, DRF devuelve {'count':..., 'results':[...]}
        self.assertIn('results', data)
        nombres = [p['nombre'] for p in data['results']]
        self.assertIn('Teclado API', nombres)

    def test_post_sin_auth_devuelve_403(self):
        """POST /api/productos/ sin token → 403 Forbidden."""
        r = self.client.post('/api/productos/', {
            'nombre':    'Sin Auth',
            'precio':    '100.00',
            'stock':     1,
            'categoria': self.cat.pk,
        }, format='json')
        self.assertEqual(r.status_code, 403)

    def test_post_con_token_crea_producto_201(self):
        """POST /api/productos/ con token válido → 201 Created."""
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Token {self.token.key}'
        )
        r = self.client.post('/api/productos/', {
            'nombre':    'Monitor API',
            'precio':    '5500.00',
            'stock':     3,
            'categoria': self.cat.pk,
        }, format='json')
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.json()['nombre'], 'Monitor API')
        self.assertTrue(
            Producto.objects.filter(nombre='Monitor API').exists()
        )

    def test_get_detalle_producto_devuelve_nombre(self):
        """GET /api/productos/<id>/ → JSON con nombre y precio."""
        r = self.client.get(f'/api/productos/{self.producto.pk}/')
        self.assertEqual(r.status_code, 200)
        data = r.json()
        self.assertEqual(data['nombre'], 'Teclado API')
        self.assertIn('categoria_nombre', data)

    def test_get_detalle_404_id_inexistente(self):
        """GET /api/productos/9999/ → 404 Not Found."""
        r = self.client.get('/api/productos/9999/')
        self.assertEqual(r.status_code, 404)

    def test_venta_api_incluye_total_y_detalles(self):
        """GET /api/ventas/<id>/ → JSON con campo 'total' y 'detalles'."""
        cli   = Cliente.objects.create(nombre='CLI', correo='c@t.com')
        venta = Venta.objects.create(cliente=cli)
        DetalleVenta.objects.create(
            venta=venta, producto=self.producto,
            cantidad=2, precio_unitario=Decimal('450.00')
        )
        r = self.client.get(f'/api/ventas/{venta.pk}/')
        self.assertEqual(r.status_code, 200)
        data = r.json()
        self.assertIn('total', data)
        self.assertIn('detalles', data)
        self.assertEqual(len(data['detalles']), 1)
        self.assertEqual(data['detalles'][0]['cantidad'], 2)
```

### 6.3 Ejecutar los tests

```cmd
python manage.py test tests.test_w10_api --verbosity=2
```

**Resultado esperado:**
```
test_get_detalle_404_id_inexistente ... ok
test_get_detalle_producto_devuelve_nombre ... ok
test_get_lista_devuelve_json_con_productos ... ok
test_get_lista_sin_auth_devuelve_200 ... ok
test_post_con_token_crea_producto_201 ... ok
test_post_sin_auth_devuelve_403 ... ok
test_venta_api_incluye_total_y_detalles ... ok

Ran 7 tests in X.XXXs
OK
```

### 6.4 Suite acumulada

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 107 tests in X.XXXs · OK` (100 + 7)

---

## CIERRE — Commit y Respaldo (10 min)

### Actualizar `sprint3_planning.md`

```markdown
## Sprint Backlog — actualización W10

| Tarea | Estado |
|---|---|
| rest_framework.authtoken instalado | ✅ W10 |
| Serializers × 5 entidades | ✅ W10 |
| ListCreateAPIView + RetrieveUpdateDestroyAPIView × 5 | ✅ W10 |
| api_urls.py × 4 apps + /api/ en core/urls.py | ✅ W10 |
| Token endpoint /api/auth/token/ | ✅ W10 |
| 7 tests APIClient pasando | ✅ W10 |
| ImageField + Pillow + MEDIA_ROOT | ⏳ W11 |
| django-storages + S3/MinIO | ⏳ W11 |
| Generación PDF WeasyPrint | ⏳ W12 |
| Exportación Excel openpyxl | ⏳ W12 |
```

### Commit de cierre W10

```cmd
git add .
git status

:: Verificar que incluye:
::   */serializers.py × 4 apps
::   */api_views.py × 4 apps
::   */api_urls.py × 4 apps
::   core/urls.py (con /api/ y token)
::   core/settings.py (authtoken + REST_FRAMEWORK actualizado)
::   tests/test_w10_api.py
::   sprint3_planning.md

git commit -m "Sprint 3 W10: DRF Serializers + API Views + Token Auth + 107 tests OK"
git push origin main
```

### Ejecutar `finalizar_sesion.bat`

```cmd
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W10

### Técnico

```
CONFIGURACIÓN DRF
[ ] 'rest_framework.authtoken' en INSTALLED_APPS
[ ] python manage.py migrate → authtoken tables OK
[ ] REST_FRAMEWORK: SessionAuthentication + TokenAuthentication
[ ] REST_FRAMEWORK: IsAuthenticatedOrReadOnly
[ ] REST_FRAMEWORK: PageNumberPagination, PAGE_SIZE=20

SERIALIZERS (4 archivos nuevos)
[ ] productos/serializers.py: CategoriaSerializer + ProductoSerializer
[ ] ProductoSerializer: categoria_nombre + proveedor_nombre (read_only)
[ ] clientes/serializers.py: ClienteSerializer
[ ] proveedores/serializers.py: ProveedorSerializer
[ ] ventas/serializers.py: DetalleVentaSerializer (subtotal como SerializerMethodField)
[ ] VentaSerializer: detalles anidados (many=True, read_only) + total como SerializerMethodField

API VIEWS (4 archivos nuevos)
[ ] productos/api_views.py: Categoria + Producto (List/Create + Retrieve/Update/Destroy)
[ ] clientes/api_views.py: Cliente
[ ] proveedores/api_views.py: Proveedor
[ ] ventas/api_views.py: Venta con prefetch_related

URLS
[ ] productos/api_urls.py + clientes/api_urls.py
[ ] proveedores/api_urls.py + ventas/api_urls.py
[ ] core/urls.py: path('api/', include(...)) + obtain_auth_token
[ ] /api/productos/ → 200 JSON en navegador
[ ] /api/auth/token/ → devuelve token con POST credenciales válidas

TESTS
[ ] test tests.test_w10_api → 7/7 OK
[ ] test tests → 107/107 OK acumulados
[ ] test_get_lista_sin_auth → 200 (lectura pública)
[ ] test_post_sin_auth → 403
[ ] test_post_con_token → 201 + objeto creado en BD
[ ] test_venta_api → JSON con 'total' y 'detalles' anidados

GIT
[ ] sprint3_planning.md creado con Sprint Goal y 7 HUs
[ ] Commit con mensaje descriptivo
[ ] git push → GitHub actualizado
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Arquitectura de la API al cerrar W10

```
Cliente externo (app móvil, SPA, curl)
    │
    │ POST /api/auth/token/
    │ {"username": "...", "password": "..."}
    │ ← {"token": "9944b09..."}
    │
    │ GET  /api/productos/            → 200 JSON (sin token)
    │ POST /api/productos/            → 403 (sin token)
    │ POST /api/productos/ + Token    → 201 Created
    │ GET  /api/ventas/1/             → JSON con detalles anidados
    │
    ▼
Django core/urls.py
    path('api/', include(api_urlpatterns))
    │
    ├── /api/productos/  → ProductoListCreateAPIView
    │       GET  → queryset + ProductoSerializer → JSON paginado
    │       POST → ProductoSerializer.save() → Producto creado
    │
    ├── /api/ventas/<id>/ → VentaDetailAPIView
    │       GET  → VentaSerializer (detalles=[...], total=@property)
    │
    └── /api/auth/token/ → obtain_auth_token
            POST → {"token": "..."}

Autenticación:
    SessionAuthentication → navegador Browsable API
    TokenAuthentication   → clientes externos con header Authorization
```

---

## HILO CONDUCTOR → W11

**¿Qué entrega W10?**
La API REST completa con serializers, vistas genéricas, paginación y
autenticación por token. El Browsable API permite probar los endpoints
directamente desde el navegador.

**¿Qué abre W11?**
Con la API funcionando, W11 agrega **gestión de archivos**: `ImageField`
en `Producto`, validación de tipo MIME, almacenamiento en `MEDIA_ROOT`
y configuración de `django-storages` para producción en S3/MinIO.
La imagen de producto aparecerá en la respuesta JSON de la API.

**¿Qué necesita W11 de W10?**

| Artefacto de W10 | Uso en W11 |
|---|---|
| `ProductoSerializer` | W11 agrega campo `imagen` con URL completa |
| `ProductoListCreateAPIView` | W11 habilita `multipart/form-data` para subida de archivos |
| `REST_FRAMEWORK` con autenticación | W11 protege el endpoint de subida de imagen |
| 107 tests pasando | W11 agrega tests de subida y validación de archivos |

**Tarea de investigación para W11:**
> ¿Qué diferencia hay entre `MEDIA_ROOT` y `STATIC_ROOT` en Django?
> ¿Por qué no se deben servir archivos de media con Gunicorn en producción?
> ¿Qué es `django-storages` y para qué sirve el backend `S3Boto3Storage`?

**Pregunta de reflexión:**
> "La API devuelve el campo `categoria` como un entero (el ID de la FK).
> ¿Cómo cambiarías el serializer para que devuelva el objeto `Categoria`
> completo en lugar del ID? ¿Qué ventaja y qué desventaja tendría eso?"

---

## Referencia rápida de comandos W10

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py migrate
python manage.py runserver

:: TESTS
python manage.py test tests.test_w10_api --verbosity=2
python manage.py test tests --verbosity=0   (107 tests)

:: TOKEN (en terminal separada con servidor activo)
curl -X POST http://127.0.0.1:8000/api/auth/token/ ^
     -H "Content-Type: application/json" ^
     -d "{\"username\":\"admin\",\"password\":\"tu-password\"}"

:: API con token
curl http://127.0.0.1:8000/api/productos/
curl -H "Authorization: Token TU_TOKEN" ^
     -X POST http://127.0.0.1:8000/api/productos/ ^
     -H "Content-Type: application/json" ^
     -d "{\"nombre\":\"Test\",\"precio\":\"100\",\"stock\":1,\"categoria\":1}"

:: GIT
git add .
git commit -m "Sprint 3 W10: descripción"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W10 · ERP Django*
*Espiral 4 · Sprint 3 Planning · DRF Serializers + Token Auth + API REST*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*