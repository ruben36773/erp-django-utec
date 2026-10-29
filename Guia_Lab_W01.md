# Guía de Laboratorio — W01
## ERP Django · Espiral 1 · Semana 1 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W01 de 24 |
| **Espiral** | E1 — Infraestructura y Configuración Base |
| **Sprint Scrum** | Sprint 0 — Planning + Desarrollo inicial |
| **Hito** | M0: Entorno USB funcional · M1 parcial: proyecto Django en GitHub |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 1 — Fundamentos |
| **Hilo conductor** | "Sin entorno portable, no hay proyecto. W01 es el cimiento de las 24 semanas." |

---

## Objetivos de la sesión

Al terminar W01, el estudiante será capaz de:

1. Configurar Python 3.11 embeddable en USB sin instalar nada en el sistema anfitrión
2. Instalar y verificar Django 4.2 LTS dentro de un entorno virtual portable
3. Crear scripts de sesión que sincronicen USB ↔ PC automáticamente
4. Inicializar un proyecto Django con estructura base del ERP
5. Ejecutar el Sprint 0 Planning con Product Backlog inicial
6. Hacer el primer commit y push a GitHub

---

## Stack tecnológico de W01

| Herramienta | Versión | Rol en el proyecto | Instalación |
|---|---|---|---|
| Python | 3.11.9 embeddable | Intérprete portable (sin instalación) | `.zip` descomprimido en USB |
| pip | ≥ 23.x | Gestor de paquetes | `get-pip.py` (descarga manual) |
| virtualenv | ≥ 20.x | Entorno virtual (reemplaza `venv`) | `pip install virtualenv` |
| Django | 4.2 LTS | Framework web principal | `pip install "django==4.2"` |
| Git | 2.4x.x Portable | Control de versiones | `.exe` portátil en USB |
| VS Code | Última | Editor + terminal CMD | Instalado en la PC del aula |
| GitHub | — | Repositorio remoto | Cuenta gratuita |

> **¿Por qué `virtualenv` y no `venv`?**
> Python 3.11 embeddable no incluye el módulo `venv` ni `ensurepip`.
> `virtualenv` se instala vía pip y funciona correctamente con el embeddable.

---

## Prerrequisitos antes de la sesión

```
[ ] USB con ≥ 4 GB de espacio disponible
[ ] Cuenta creada en github.com
[ ] VS Code instalado en la PC del aula
[ ] Acceso a internet para descargar Python y get-pip.py
[ ] Archivo python-3.11.9-embed-amd64.zip descargado (si no hay internet en aula)
[ ] Archivo get-pip.py descargado de https://bootstrap.pypa.io/get-pip.py
```

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Parte 1 | Preparar la USB (estructura + Python + pip + virtualenv) | 35 min |
| Parte 2 | Git Portable: instalación y configuración | 15 min |
| Parte 3 | Scripts de sesión `iniciar_sesion.bat` / `finalizar_sesion.bat` | 20 min |
| Parte 4 | Proyecto Django base (proyecto + apps + vista bienvenida) | 45 min |
| Parte 5 | Sprint 0 Planning (Scrum) | 20 min |
| Parte 6 | Git — primer commit y push | 15 min |
| Parte 7 | Tests de verificación del entorno | 15 min |
| Cierre | Checklist + hilo conductor hacia W02 | 15 min |
| **Total** | | **180 min** |

---

## PARTE 1 — Preparar la USB (35 min)

### 1.1 Estructura de carpetas

Abrir el Explorador de Windows y crear esta estructura en la USB:

```
USB_Drive:\
├── Python_Portable\        ← aquí va el contenido del .zip embeddable
├── Git_Portable\           ← aquí va Git for Windows Portable
├── WorkSpace_ERP\          ← carpeta de respaldo del proyecto
├── iniciar_sesion.bat      ← (crearemos en Parte 3)
└── finalizar_sesion.bat    ← (crearemos en Parte 3)
```

En CMD desde la USB:
```cmd
:: Sustituir E: por la letra de tu USB
E:
mkdir Python_Portable
mkdir Git_Portable
mkdir WorkSpace_ERP
```

---

### 1.2 Instalar Python 3.11 embeddable

```cmd
:: Descomprimir el .zip en Python_Portable\
:: (Usar el Explorador de Windows o 7-Zip)
:: Verificar que existe python.exe:
dir E:\Python_Portable\python.exe
```

**Resultado esperado:**
```
01/15/2025  ...   python.exe
```

---

### 1.3 Habilitar site-packages (paso crítico)

Abrir con el Bloc de notas el archivo:
```
E:\Python_Portable\python311._pth
```

Buscar la línea:
```
python311.zip
.
# Uncomment to run site.main() automatically
#import site
```

Cambiarla a:
```
python311.zip
.
Scripts
# Uncomment to run site.main() automatically
import site
```

Guardar y cerrar. **Sin este cambio, pip no puede encontrar los paquetes instalados.**

---

### 1.4 Instalar pip

```cmd
:: Ir a la carpeta Python_Portable
cd /d E:\Python_Portable

:: Instalar pip usando el script descargado previamente
python.exe get-pip.py

:: Verificar instalación
python.exe -m pip --version
```

**Resultado esperado:**
```
pip 24.x.x from E:\Python_Portable\Lib\site-packages\pip (python 3.11)
```

---

### 1.5 Instalar virtualenv

```cmd
:: Desde E:\Python_Portable\
python.exe -m pip install virtualenv

:: Verificar
python.exe -m virtualenv --version
```

**Resultado esperado:**
```
virtualenv 20.x.x from ...
```

---

### 1.6 Verificación de la Parte 1

```
[ ] python.exe --version → Python 3.11.9
[ ] python311._pth contiene "import site" (sin #)
[ ] python.exe -m pip --version → pip 24.x.x
[ ] python.exe -m virtualenv --version → 20.x.x
```

---

## PARTE 2 — Git Portable (15 min)

### 2.1 Instalar Git Portable

Si tienes el `.exe` de Git Portable:
```cmd
:: Ejecutar el instalador y apuntar a la carpeta de la USB:
:: Destino: E:\Git_Portable\
```

Si ya está descomprimido, verificar:
```cmd
E:\Git_Portable\bin\git.exe --version
```

**Resultado esperado:** `git version 2.4x.x.windows.x`

---

### 2.2 Configuración global de Git

```cmd
:: Agregar Git al PATH temporalmente
SET PATH=E:\Git_Portable\bin;%PATH%

:: Configurar identidad (usar tus datos reales)
git config --global user.name "Tu Nombre Completo"
git config --global user.email "tu-correo@ejemplo.com"
git config --global core.autocrlf true

:: Verificar configuración
git config --list
```

---

### 2.3 Verificación de la Parte 2

```
[ ] git --version → git version 2.x (desde Git_Portable)
[ ] git config user.name → muestra tu nombre
[ ] git config user.email → muestra tu correo
```

---

## PARTE 3 — Scripts de Sesión (20 min)

### 3.1 Crear `iniciar_sesion.bat` (en la raíz de la USB)

Abrir VS Code → Archivo Nuevo → guardar como `E:\iniciar_sesion.bat`.
Pegar el siguiente contenido **exacto**:

```bat
@echo off
TITLE ERP Django - Iniciando Sesion
COLOR 0A

:: ── 1. RUTAS DINÁMICAS ────────────────────────────────────────────────────
SET USB_PATH=%~dp0
SET PC_WORK=C:\Temp_Workspace_ERP

:: ── 2. CREAR TALLER EN DISCO LOCAL ────────────────────────────────────────
echo ======================================================
echo  ERP DJANGO :: USB ^-^> PC
echo  USB: %USB_PATH%
echo  PC:  %PC_WORK%
echo ======================================================
if not exist "%PC_WORK%" (
    mkdir "%PC_WORK%"
    echo [OK] Carpeta creada: %PC_WORK%
)

:: ── 3. SINCRONIZAR USB → PC (solo archivos nuevos o modificados) ───────────
echo Sincronizando proyecto a la PC...
xcopy /s /e /y /d "%USB_PATH%WorkSpace_ERP" "%PC_WORK%" >nul 2>&1
echo [OK] Sincronizacion completada.

:: ── 4. CONFIGURAR PATH TEMPORAL ───────────────────────────────────────────
SET PATH=%USB_PATH%Python_Portable;%USB_PATH%Python_Portable\Scripts;%USB_PATH%Git_Portable\bin;%PATH%

:: ── 5. RECREAR ENTORNO VIRTUAL SI NO EXISTE EN PC ─────────────────────────
if not exist "%PC_WORK%\env_erp" (
    echo Creando entorno virtual en la PC...
    python -m virtualenv "%PC_WORK%\env_erp"
    if exist "%PC_WORK%\requirements.txt" (
        echo Instalando dependencias desde requirements.txt...
        "%PC_WORK%\env_erp\Scripts\python.exe" -m pip install -r "%PC_WORK%\requirements.txt" --quiet
    )
    echo [OK] Entorno virtual creado.
)

:: ── 6. ACTIVAR ENTORNO VIRTUAL ────────────────────────────────────────────
SET PATH=%PC_WORK%\env_erp\Scripts;%PATH%
echo [OK] Entorno virtual activo.

:: ── 7. IR A LA CARPETA DE TRABAJO ─────────────────────────────────────────
cd /d "%PC_WORK%"
echo.
echo VERSIONES ACTIVAS:
python --version
git --version
echo.
echo --- RECUERDA EJECUTAR finalizar_sesion.bat AL TERMINAR ---
cmd /k "echo ERP listo en %PC_WORK%"
```

---

### 3.2 Crear `finalizar_sesion.bat` (en la raíz de la USB)

Guardar como `E:\finalizar_sesion.bat`:

```bat
@echo off
TITLE ERP Django - Guardando Sesion
COLOR 0E

:: ── 1. RUTAS ──────────────────────────────────────────────────────────────
SET PC_WORK=C:\Temp_Workspace_ERP
SET USB_PATH=%~dp0

echo ======================================================
echo  ERP DJANGO :: PC ^-^> USB (RESPALDO)
echo ======================================================

:: ── 2. VERIFICAR QUE EXISTE EL TALLER ────────────────────────────────────
if not exist "%PC_WORK%" (
    echo [ERROR] No existe %PC_WORK%
    echo Ejecuta primero iniciar_sesion.bat
    pause & exit /b 1
)

:: ── 3. SINCRONIZAR PC → USB (solo archivos nuevos o modificados) ──────────
echo Guardando cambios en la USB...
xcopy /s /e /y /d "%PC_WORK%" "%USB_PATH%WorkSpace_ERP" >nul 2>&1

echo.
echo ======================================================
echo  RESPALDO COMPLETADO.
echo  Guardado en: %USB_PATH%WorkSpace_ERP
echo  Incluye: codigo .py, templates, db.sqlite3, .git
echo ======================================================
echo  Es seguro retirar la USB.
pause
```

---

### 3.3 Prueba de sincronización

```cmd
:: 1. Ejecutar el script de inicio
E:\iniciar_sesion.bat

:: 2. En la terminal que se abre, crear un archivo de prueba
echo "test de sincronizacion W01" > prueba_sync.txt

:: 3. Ejecutar el cierre
E:\finalizar_sesion.bat

:: 4. Verificar que el archivo llegó a la USB
dir E:\WorkSpace_ERP\prueba_sync.txt
```

**Resultado esperado:** el archivo aparece en la USB.

### 3.4 Verificación de la Parte 3

```
[ ] iniciar_sesion.bat ejecuta sin errores
[ ] "Entorno virtual activo" aparece en la consola
[ ] python --version → 3.11.x (desde la USB)
[ ] git --version → 2.x.x (desde la USB)
[ ] finalizar_sesion.bat copia archivos a la USB correctamente
[ ] prueba_sync.txt existe en E:\WorkSpace_ERP\
```

---

## PARTE 4 — Proyecto Django Base (45 min)

Desde la terminal abierta por `iniciar_sesion.bat` (ya en `C:\Temp_Workspace_ERP` con env activo):

### 4.1 Instalar Django y dependencias base

```cmd
:: Instalar stack base del ERP
pip install "django==4.2" djangorestframework whitenoise "django-environ==0.11"
python.exe -m pip install "django-environ>=0.11.2"

:: Verificar
python -m django --version
```

**Resultado esperado:** `4.2.x`

---

### 4.2 Crear el proyecto Django

```cmd
:: El punto crea el proyecto en la carpeta actual (sin subcarpeta extra)
django-admin startproject core .

:: Crear las 5 apps del ERP
python manage.py startapp clientes
python manage.py startapp proveedores
python manage.py startapp productos
python manage.py startapp ventas
python manage.py startapp reportes
```

**Árbol resultante:**
```
C:\Temp_Workspace_ERP\
├── core\
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── clientes\    proveedores\    productos\    ventas\    reportes\
├── manage.py
└── env_erp\     (no se respalda en USB)
```

---

### 4.3 Configurar `core/settings.py`

Abrir `core/settings.py` en VS Code y realizar estos cambios:

```python
# core/settings.py
import environ
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# ── Variables de entorno ──────────────────────────────────────────────────
env = environ.Env(DEBUG=(bool, True))
environ.Env.read_env(BASE_DIR / '.env')

SECRET_KEY  = env('SECRET_KEY', default='dev-key-insegura-solo-para-desarrollo')
DEBUG       = env('DEBUG', default=True)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['localhost', '127.0.0.1'])

# ── Apps instaladas ───────────────────────────────────────────────────────
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
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'

# ── Templates ─────────────────────────────────────────────────────────────
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],       # carpeta global de templates
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# ── Base de datos ─────────────────────────────────────────────────────────
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# ── Internacionalización ──────────────────────────────────────────────────
LANGUAGE_CODE = 'es-mx'
TIME_ZONE     = 'America/Mexico_City'
USE_I18N      = True
USE_TZ        = True

# ── Archivos estáticos ────────────────────────────────────────────────────
STATIC_URL  = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# ── Archivos media ────────────────────────────────────────────────────────
MEDIA_URL  = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# ── Autenticación ─────────────────────────────────────────────────────────
LOGIN_URL           = '/accounts/login/'
LOGIN_REDIRECT_URL  = '/productos/'
LOGOUT_REDIRECT_URL = '/'

# ── DRF ──────────────────────────────────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ],
}

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
```

---

### 4.4 Crear archivo `.env`

```cmd
:: En C:\Temp_Workspace_ERP\
echo SECRET_KEY=dev-clave-segura-para-desarrollo-w01 > .env
echo DEBUG=True >> .env
echo ALLOWED_HOSTS=localhost,127.0.0.1 >> .env
```

---

### 4.5 Vista de bienvenida del ERP

Crear `templates/` en la raíz:
```cmd
mkdir templates
```

Crear `templates/bienvenida.html`:

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>ERP Django · UTEC Celaya</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif;
               background: #0A2342; color: #E2EAF4;
               display: flex; justify-content: center;
               align-items: center; height: 100vh; margin: 0; }
        .card { background: #142033; border: 1px solid #2A3F58;
                border-left: 5px solid #D4AF37;
                padding: 2rem 3rem; border-radius: 12px;
                text-align: center; max-width: 480px; }
        h1 { color: #D4AF37; font-size: 1.8rem; margin-bottom: .5rem; }
        p  { color: #8AA0B8; font-size: .95rem; }
        .badge { background: rgba(212,175,55,.1); color: #D4AF37;
                 border: 1px solid #D4AF37; padding: .3rem .8rem;
                 border-radius: 20px; font-size: .8rem; margin: .2rem; }
    </style>
</head>
<body>
    <div class="card">
        <h1>📦 Mini ERP</h1>
        <p>Sistema de gestión empresarial</p>
        <p>UTEC Celaya · Módulo II · W01</p>
        <br>
        <span class="badge">Django 4.2 LTS</span>
        <span class="badge">Python 3.11</span>
        <span class="badge">Espiral 1</span>
        <br><br>
        <p>Estado: <strong style="color:#2ECC71">✅ Operativo</strong></p>
    </div>
</body>
</html>
```

Crear `core/views.py`:

```python
# core/views.py
"""Vistas de la configuración central del ERP — W01."""
from django.shortcuts import render


def bienvenida(request):
    """Página de inicio del ERP.

    Returns:
        HttpResponse con la plantilla de bienvenida.
    """
    return render(request, 'bienvenida.html')
```

---

### 4.6 Configurar URLs

```python
# core/urls.py
"""Enrutador principal del ERP Django — W01."""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from . import views

urlpatterns = [
    path('admin/',       admin.site.urls),
    path('',             views.bienvenida,             name='inicio'),
    path('clientes/',    include('clientes.urls',    namespace='clientes')),
    path('proveedores/', include('proveedores.urls', namespace='proveedores')),
    path('productos/',   include('productos.urls',   namespace='productos')),
    path('ventas/',      include('ventas.urls',       namespace='ventas')),
    path('reportes/',    include('reportes.urls',     namespace='reportes')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

Crear `urls.py` mínimo en cada app. Ejemplo para `productos/urls.py`:

```python
# productos/urls.py
"""URLs de la app productos — W01 (mínimo funcional)."""
from django.urls import path
from django.http import HttpResponse

app_name = 'productos'


def bienvenida_productos(request):
    """Vista temporal de bienvenida para la app productos."""
    return HttpResponse(
        "<h2>📦 Módulo Productos</h2>"
        "<p>En construcción — Espiral 2 (W04)</p>",
        content_type='text/html; charset=utf-8'
    )


urlpatterns = [
    path('', bienvenida_productos, name='inicio'),
]
```

> Repetir el mismo patrón para `clientes/urls.py`, `proveedores/urls.py`,
> `ventas/urls.py` y `reportes/urls.py` cambiando el nombre del módulo.

---

### 4.7 Migración inicial y verificación

```cmd
:: Verificar configuración
python manage.py check

:: Crear tablas internas (sesiones, admin, auth)
python manage.py migrate

:: Crear superusuario para el admin
python manage.py createsuperuser
:: → username: admin
:: → email: admin@erp.com
:: → password: (elige una segura)

:: Generar requirements.txt
pip freeze > requirements.txt

:: Levantar servidor
python manage.py runserver
```

Abrir en el navegador:
- `http://127.0.0.1:8000/` → página de bienvenida del ERP
- `http://127.0.0.1:8000/admin/` → panel de administración
- `http://127.0.0.1:8000/productos/` → mensaje "En construcción"

### 4.8 Verificación de la Parte 4

```
[ ] python manage.py check → "System check identified no issues (0 silenced)"
[ ] python manage.py migrate → "OK" en todas las migraciones
[ ] http://127.0.0.1:8000/ → página de bienvenida visible (fondo azul oscuro, título dorado)
[ ] http://127.0.0.1:8000/admin/ → panel de admin accesible con superusuario
[ ] http://127.0.0.1:8000/productos/ → responde HTTP 200
[ ] requirements.txt contiene django==4.2
```

---

## PARTE 5 — Sprint 0 Planning (Scrum) (20 min)

### 5.1 Evento Scrum: Sprint Planning

El Sprint 0 es el sprint de infraestructura. No entrega funcionalidades de negocio, sino el entorno técnico base. Duración: W01–W03 (3 semanas).

**Sprint Goal del Sprint 0:**
> *"Al finalizar el Sprint 0, existirá un proyecto Django 4.2 con estructura de apps del ERP, desplegado en Render.com con URL pública funcional y repositorio en GitHub."*

---

### 5.2 Crear `product_backlog.md`

Guardar en la raíz de `C:\Temp_Workspace_ERP\`:

```markdown
# Product Backlog — ERP Django
## UTEC Celaya · Módulo II · Asesor: MC. Román F. López González

## Roles del equipo
- **Product Owner:** MC. Román Fernando López González
- **Scrum Master / Equipo:** [Tu nombre]

## Backlog completo (extracto W01–W06)

| ID | Historia de Usuario | Espiral | Prioridad | Puntos |
|---|---|---|---|---|
| HU-E1-01 | Como dev, quiero un entorno portable en USB para trabajar en cualquier aula | E1 | Alta | 3 |
| HU-E1-02 | Como dev, quiero scripts de sincronización para no perder trabajo al retirar la USB | E1 | Alta | 2 |
| HU-E1-03 | Como dev, quiero el proyecto en GitHub para tener respaldo en la nube | E1 | Alta | 2 |
| HU-E1-04 | Como dev, quiero el proyecto desplegado en Render.com para demos al asesor | E1 | Alta | 3 |
| HU-E2-01 | Como admin, quiero registrar clientes con nombre, correo y teléfono | E2 | Alta | 2 |
| HU-E2-02 | Como admin, quiero registrar productos con precio, stock y categoría | E2 | Alta | 3 |
| HU-E2-03 | Como admin, quiero registrar ventas con detalles de productos y totales | E2 | Alta | 5 |
| HU-E2-04 | Como admin, quiero registrar proveedores y asignarlos a productos | E2 | Media | 2 |
| HU-E3-01 | Como vendedor, quiero ver la lista de productos para consultar el inventario | E3 | Alta | 2 |
| HU-E3-02 | Como gerente, quiero acceder a todos los módulos con un solo login | E3 | Alta | 3 |

## Total de puntos en este extracto: 27
```

---

### 5.3 Crear `sprint0_planning.md`

```markdown
# Sprint 0 Planning — ERP Django
## Semanas W01–W03 · Espiral 1: Infraestructura

**Sprint Goal:**
Al finalizar el Sprint 0, existirá un proyecto Django 4.2 con estructura
de 5 apps del ERP, desplegado en Render.com con URL pública funcional
y repositorio en GitHub con al menos 10 commits.

## HUs seleccionadas para este sprint

| ID | Historia | Puntos | Estado |
|---|---|---|---|
| HU-E1-01 | Entorno portable USB | 3 | 🔄 En progreso |
| HU-E1-02 | Scripts de sincronización | 2 | 🔄 En progreso |
| HU-E1-03 | Repositorio en GitHub | 2 | ⏳ Pendiente |
| HU-E1-04 | Despliegue en Render.com | 3 | ⏳ Pendiente |

**Total de puntos del sprint:** 10

## Sprint Backlog — Tareas técnicas W01

| Tarea | Responsable | Estado | Horas est. |
|---|---|---|---|
| Configurar Python 3.11 embeddable en USB | Dev | ✅ | 0.5 h |
| Instalar pip y virtualenv | Dev | ✅ | 0.3 h |
| Configurar Git Portable | Dev | ✅ | 0.3 h |
| Crear scripts .bat de sesión | Dev | ✅ | 0.5 h |
| Crear proyecto Django `core` | Dev | ✅ | 0.5 h |
| Crear 5 apps y urls mínimas | Dev | ✅ | 1.0 h |
| Configurar settings.py base | Dev | ✅ | 0.5 h |
| Crear vista de bienvenida | Dev | ✅ | 0.3 h |
| product_backlog.md + sprint0_planning.md | Dev | ✅ | 0.5 h |
| Primer commit en GitHub | Dev | ⏳ | 0.3 h |

## Criterios de aceptación del Sprint 0
- python manage.py check → 0 issues
- http://127.0.0.1:8000/ → HTTP 200 (W01)
- URL pública en Render → HTTP 200 (W03)
- Repositorio con rama main + historial de commits
- Ficha Schmelkes E1 completa (W03)
```

---

## PARTE 6 — Git: Primer Commit y Push (15 min)

### 6.1 Crear `.gitignore`

```cmd
:: En C:\Temp_Workspace_ERP\
type nul > .gitignore
```

Abrir `.gitignore` en VS Code y pegar:

```gitignore
# Entorno virtual (NO se sube — se recrea con requirements.txt)
env_erp/
venv/
__pycache__/
*.pyc
*.pyo
*.pyd

# Base de datos local
db.sqlite3

# Variables de entorno (NUNCA subir)
.env

# Archivos estáticos colectados
staticfiles/

# Media subida por usuarios
media/

# VS Code
.vscode/

# Sistema operativo
Thumbs.db
.DS_Store
```

---

### 6.2 Inicializar y primer commit

```cmd
:: Desde C:\Temp_Workspace_ERP\
git init
git add .
git status

:: Verificar que .env NO aparece en los archivos a commitear
:: Si aparece, el .gitignore no está funcionando

git commit -m "Sprint 0 W01: entorno portable + proyecto Django base + 5 apps"
```

---

### 6.3 Conectar con GitHub y push

```cmd
:: 1. Crear repositorio VACÍO en github.com (sin README, sin .gitignore)
::    Nombre sugerido: erp-django-utec

:: 2. Conectar el repositorio local con GitHub (sustituir tu-usuario)
git remote add origin https://github.com/tu-usuario/erp-django-utec.git

:: 3. Renombrar rama principal
git branch -M main

:: 4. Subir (autenticarse con token de GitHub si pide credenciales)
git push -u origin main

:: 5. Verificar
git log --oneline
```

**Resultado esperado:** un commit visible en `github.com/tu-usuario/erp-django-utec`

### 6.4 Verificación de la Parte 6

```
[ ] git log --oneline → al menos 1 commit con mensaje descriptivo
[ ] .env NO aparece en el repositorio de GitHub
[ ] env_erp/ NO aparece en el repositorio de GitHub
[ ] github.com/tu-usuario/erp-django-utec → repositorio visible
[ ] Rama principal se llama "main"
```

---

## PARTE 7 — Tests de Verificación del Entorno (15 min)

### 7.1 Crear `tests/test_w01_entorno.py`

```cmd
mkdir tests
type nul > tests\__init__.py
```

Crear `tests/test_w01_entorno.py`:

```python
"""Suite de pruebas W01 — Verificación del entorno ERP Django.

Ejecutar con:
    python manage.py test tests.test_w01_entorno --verbosity=2

Resultado esperado:
    Ran 8 tests in X.XXXs
    OK
"""
import sys
from django.test import TestCase
from django.urls import reverse, NoReverseMatch


class PythonVersionTest(TestCase):
    """Verifica que el intérprete sea Python 3.11+."""

    def test_python_mayor_igual_3(self):
        """Python major version debe ser 3."""
        self.assertEqual(sys.version_info.major, 3)

    def test_python_minor_igual_11(self):
        """Python minor version debe ser 11 o superior."""
        self.assertGreaterEqual(sys.version_info.minor, 11)


class DjangoVersionTest(TestCase):
    """Verifica que Django sea la versión 4.2 LTS."""

    def test_django_version_4_2(self):
        """Django debe ser exactamente la versión 4.2.x."""
        import django
        major, minor = django.VERSION[0], django.VERSION[1]
        self.assertEqual(major, 4, "Django major debe ser 4")
        self.assertEqual(minor, 2, "Django minor debe ser 2 (LTS)")


class VistasBienvenidaTest(TestCase):
    """Verifica que las vistas de bienvenida respondan correctamente."""

    def test_inicio_http_200(self):
        """La página de inicio debe devolver HTTP 200."""
        response = self.client.get('/')
        self.assertEqual(
            response.status_code, 200,
            "La vista de inicio no devolvió HTTP 200"
        )

    def test_admin_login_accesible(self):
        """El panel de admin debe ser accesible sin autenticación."""
        response = self.client.get('/admin/login/')
        self.assertEqual(
            response.status_code, 200,
            "El admin no está accesible — verificar urls.py"
        )

    def test_productos_app_responde(self):
        """La app productos debe devolver HTTP 200."""
        response = self.client.get('/productos/')
        self.assertEqual(response.status_code, 200)

    def test_clientes_app_responde(self):
        """La app clientes debe devolver HTTP 200."""
        response = self.client.get('/clientes/')
        self.assertEqual(response.status_code, 200)

    def test_ventas_app_responde(self):
        """La app ventas debe devolver HTTP 200."""
        response = self.client.get('/ventas/')
        self.assertEqual(response.status_code, 200)


class ConfiguracionDjangoTest(TestCase):
    """Verifica la configuración de settings.py."""

    def test_installed_apps_contiene_erp_apps(self):
        """Las 5 apps del ERP deben estar en INSTALLED_APPS."""
        from django.conf import settings
        apps_requeridas = [
            'clientes', 'proveedores', 'productos', 'ventas', 'reportes'
        ]
        for app in apps_requeridas:
            self.assertIn(
                app, settings.INSTALLED_APPS,
                f"La app '{app}' no está en INSTALLED_APPS"
            )

    def test_language_code_es_mx(self):
        """El idioma debe configurarse en español mexicano."""
        from django.conf import settings
        self.assertEqual(settings.LANGUAGE_CODE, 'es-mx')

    def test_media_root_configurado(self):
        """MEDIA_ROOT debe estar configurado."""
        from django.conf import settings
        self.assertTrue(
            bool(settings.MEDIA_ROOT),
            "MEDIA_ROOT no está configurado en settings.py"
        )
```

---

### 7.2 Ejecutar los tests

```cmd
:: Desde C:\Temp_Workspace_ERP\ con env activo
python manage.py test tests.test_w01_entorno --verbosity=2
```

**Resultado esperado:**
```
test_admin_login_accesible ... ok
test_clientes_app_responde ... ok
test_django_version_4_2 ... ok
test_inicio_http_200 ... ok
test_installed_apps_contiene_erp_apps ... ok
test_language_code_es_mx ... ok
test_media_root_configurado ... ok
test_productos_app_responde ... ok
test_python_mayor_igual_3 ... ok
test_python_minor_igual_11 ... ok
test_ventas_app_responde ... ok

Ran 11 tests in X.XXXs
OK
```

---

### 7.3 Commit con los tests

```cmd
git add tests/
git add tests/__init__.py
git add tests/test_w01_entorno.py
git commit -m "Sprint 0 W01: suite de tests de entorno (11 tests OK)"
git push origin main
```

---

## CHECKLIST FINAL W01

### Checklist técnico

```
ENTORNO USB
[ ] E:\Python_Portable\python.exe → 3.11.x
[ ] python311._pth tiene "import site" (sin #)
[ ] pip instalado y funcional
[ ] virtualenv instalado y funcional
[ ] Git Portable funcional (git --version desde USB)
[ ] iniciar_sesion.bat ejecuta sin errores
[ ] finalizar_sesion.bat sincroniza correctamente
[ ] Prueba de sincronización: archivo creado en PC aparece en USB

PROYECTO DJANGO
[ ] Proyecto "core" creado con manage.py en la raíz
[ ] 5 apps creadas: clientes, proveedores, productos, ventas, reportes
[ ] Todas las apps en INSTALLED_APPS
[ ] LANGUAGE_CODE = 'es-mx'
[ ] MEDIA_ROOT configurado
[ ] python manage.py check → "0 issues (0 silenced)"
[ ] python manage.py migrate → todas las migraciones en "OK"
[ ] http://127.0.0.1:8000/ → página de bienvenida visible
[ ] http://127.0.0.1:8000/admin/ → panel accesible
[ ] http://127.0.0.1:8000/productos/ → HTTP 200

SCRUM
[ ] product_backlog.md con ≥ 10 HUs en la raíz
[ ] sprint0_planning.md con Sprint Goal + tareas
[ ] Sprint Goal claramente redactado en una oración

GIT
[ ] .gitignore excluye env_erp/, .env, db.sqlite3
[ ] Al menos 2 commits con mensajes descriptivos
[ ] git push → repositorio visible en GitHub
[ ] .env NO está en el repositorio

TESTS
[ ] python manage.py test tests.test_w01_entorno --verbosity=2 → Ran 11 tests OK
[ ] Ningún test en estado FAIL o ERROR
```

### Checklist Scrum / Schmelkes

```
[ ] Sprint Goal de Sprint 0 redactado y visible en sprint0_planning.md
[ ] HUs E1-01 a E1-04 asignadas al Sprint 0
[ ] Ficha Schmelkes fichas/espiral_01_infra.md creada (aunque sea vacía)
[ ] Tiempo invertido en W01 registrado en la ficha (aproximado)
```

---

## HITO M0 — Declaración de Entorno Funcional

> **M0 se considera alcanzado cuando:**
> - `python manage.py check` devuelve 0 issues
> - Los 11 tests de `test_w01_entorno` pasan en estado OK
> - El proyecto está visible en GitHub con al menos 2 commits
> - `iniciar_sesion.bat` abre una terminal lista para trabajar en < 30 segundos

**Firma de hito:**

| Campo | Contenido |
|---|---|
| Semana | W01 |
| Fecha | \_\_\_\_\_\_\_\_\_\_ |
| Desarrollador | \_\_\_\_\_\_\_\_\_\_ |
| Asesor | MC. Román Fernando López González |
| Estado | ⏳ En progreso / ✅ Alcanzado |

---

## HILO CONDUCTOR → W02

**¿Qué entrega W01?**
Un proyecto Django vacío pero funcional con 5 apps registradas, scripts de sincronización verificados, y el primer commit en GitHub.

**¿Qué necesita W02 de W01?**
W02 comienza con este proyecto ya en `C:\Temp_Workspace_ERP` (sincronizado por `iniciar_sesion.bat`) y sobre él crea:
- `templates/base.html` con Fable 5 AzulERP completo
- `core/settings_prod.py` para el despliegue
- `requirements.txt` actualizado con todas las dependencias

**Pregunta de reflexión para la libreta:**
> "¿Por qué es mejor tener un entorno portable en USB que confiar en que las PCs del aula tengan Python instalado? ¿Qué riesgos elimina esta arquitectura?"

**Tarea de investigación para W02:**
> Investigar: ¿Qué es `whitenoise` y por qué se necesita para servir archivos estáticos en Render.com sin Nginx? Traer un ejemplo mínimo de configuración en `settings.py`.

---

## Referencia rápida de comandos W01

```cmd
:: ── SESIÓN ──────────────────────────────────────────────────────────
E:\iniciar_sesion.bat          :: Iniciar sesión (USB → PC)
E:\finalizar_sesion.bat        :: Cerrar sesión (PC → USB)

:: ── DJANGO ──────────────────────────────────────────────────────────
python manage.py check         :: Verificar configuración
python manage.py migrate       :: Aplicar migraciones
python manage.py runserver     :: Servidor de desarrollo
python manage.py createsuperuser :: Crear usuario admin

:: ── TESTS ───────────────────────────────────────────────────────────
python manage.py test tests.test_w01_entorno --verbosity=2

:: ── GIT ─────────────────────────────────────────────────────────────
git status                     :: Ver archivos modificados
git add .                      :: Agregar todos los cambios
git commit -m "mensaje"        :: Crear punto de restauración
git push origin main           :: Subir a GitHub
git log --oneline              :: Ver historial de commits
```

---

*Guía de Laboratorio W01 · ERP Django*
*Espiral 1 · Sprint 0 · Hito M0*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*