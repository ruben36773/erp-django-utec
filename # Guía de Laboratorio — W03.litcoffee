# Guía de Laboratorio — W03
## ERP Django · Espiral 1 · Semana 3 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W03 de 24 |
| **Espiral** | E1 — Infraestructura y Configuración Base |
| **Sprint Scrum** | Sprint 0 — Review + Retrospectiva |
| **Hito** | **★ M1: URL pública en Render.com + repositorio Git estable** |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 1 — Fundamentos |
| **Hilo conductor** | "W01 arrancó el motor. W02 puso la carrocería. W03 saca el auto a la calle." |

---

## Conexión con la Espiral 1

| Semana | Entregó | W03 lo usa para |
|---|---|---|
| W01 | Proyecto Django en GitHub, 23 tests OK | Render lee el repo directamente desde GitHub |
| W02 | `settings_prod.py` skeleton, `gunicorn` en requirements | Completar config prod y crear `Procfile` |
| W02 | WhiteNoise + `collectstatic` configurado | El build de Render ejecuta `collectstatic` automáticamente |
| W02 | `.env.example` en el repo | Referencia para configurar variables en Render Dashboard |

---

## Objetivos de la sesión

Al terminar W03, el estudiante será capaz de:

1. Completar `settings_prod.py` con conexión a PostgreSQL via `dj-database-url`
2. Crear `Procfile`, `Dockerfile` y `docker-compose.yml` para entornos locales y PaaS
3. Crear `render.yaml` con configuración declarativa de despliegue
4. Desplegar el ERP en Render.com y obtener una URL pública funcional
5. Crear el superusuario en producción desde la consola de Render
6. Ejecutar el Sprint 0 Review ante el asesor con demo en vivo
7. Completar la ficha Schmelkes E1 (cierre de la Espiral 1)

---

## Stack tecnológico de W03

| Herramienta | Novedad en W03 | Descripción |
|---|---|---|
| `dj-database-url` | ✅ Activo (instalado W02) | Lee `DATABASE_URL` del entorno y configura `DATABASES` |
| `gunicorn` | ✅ Activo (instalado W02) | Servidor WSGI de producción; reemplaza `runserver` |
| Docker Desktop | ✅ Nuevo (opcional) | Contenedores para simular producción en local |
| `docker-compose` | ✅ Nuevo (opcional) | Orquesta Django + PostgreSQL + Redis en local |
| Render.com | ✅ Nuevo | PaaS para despliegue gratuito; lee desde GitHub |
| PostgreSQL 15 | ✅ Nuevo (producción) | BD en Render; SQLite solo en desarrollo |
| `python-dotenv` | ya incluido vía `django-environ` | Lee `.env` localmente |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + revisión W02 + `iniciar_sesion.bat` | 10 min |
| Parte 1 | Completar `settings_prod.py` con PostgreSQL | 20 min |
| Parte 2 | `Procfile` + `Dockerfile` + `docker-compose.yml` | 25 min |
| Parte 3 | `render.yaml` + `fichas/` (estructura Schmelkes) | 15 min |
| Parte 4 | Despliegue en Render.com paso a paso | 40 min |
| Parte 5 | Tests W03 (10 pruebas) | 15 min |
| Parte 6 | Sprint 0 Review + Retrospectiva + Ficha Schmelkes E1 | 30 min |
| Cierre | Commit final · `finalizar_sesion.bat` · hilo → W04 | 15 min |
| **Total** | | **170 min** |

---

## ARRANQUE — Daily Scrum (10 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W02?
   → Creé templates/base.html con Fable 5 AzulERP, migré
     las vistas a views.py con render() y configuré WhiteNoise.

2. ¿Qué haré en W03?
   → Completaré settings_prod.py, crearé Procfile y Dockerfile,
     desplegaré en Render.com y cerraré el Sprint 0.

3. ¿Tengo algún impedimento?
   → (registrar aquí cualquier problema pendiente)
```

### Verificar estado de W02

```cmd
python manage.py check
python manage.py test tests --verbosity=0
git log --oneline
```

**Resultado esperado:**
```
System check identified no issues (0 silenced).
......... (23 puntos = 23 tests OK)
abc1234 Sprint 0 W02 CIERRE: MVT completo + Fable5 + WhiteNoise + 23 tests OK
```

> Si la suite muestra FAIL, resolver antes de continuar. W03 no puede
> desplegarse sobre una base rota.

---

## PARTE 1 — Completar `core/settings_prod.py` (20 min)

### 1.1 ¿Qué faltó en el skeleton de W02?

El `settings_prod.py` de W02 tenía `DEBUG=False` y los headers HTTPS,
pero faltaba:

- Conexión a PostgreSQL via `DATABASE_URL`
- Manejo del hostname de Render en `ALLOWED_HOSTS`
- `CSRF_TRUSTED_ORIGINS` para el dominio de Render

### 1.2 Reemplazar `core/settings_prod.py`

```python
# core/settings_prod.py
"""Configuración de producción — Render.com (versión final W03).

Hereda settings.py y sobreescribe todo lo necesario para producción.

Variables de entorno requeridas en Render Dashboard:
    SECRET_KEY              → clave aleatoria de ≥ 50 caracteres
    DATABASE_URL            → proporcionada automáticamente por Render PostgreSQL
    DJANGO_SETTINGS_MODULE  → core.settings_prod
    ALLOWED_HOSTS           → tu-app.onrender.com (o dejar vacío para auto)

Uso local con Docker:
    export DJANGO_SETTINGS_MODULE=core.settings_prod
    export SECRET_KEY=dev-clave-temporal
    export DATABASE_URL=postgres://erp_user:erp_pass@db:5432/erp_db
    gunicorn core.wsgi --bind 0.0.0.0:8000
"""
from .settings import *   # hereda toda la configuración base
import os
import dj_database_url

# ── SEGURIDAD BÁSICA ───────────────────────────────────────────────────────
DEBUG      = False
SECRET_KEY = os.environ['SECRET_KEY']   # falla intencionalmente si no existe

# ── HOSTS PERMITIDOS ────────────────────────────────────────────────────────
# Render inyecta RENDER_EXTERNAL_HOSTNAME automáticamente
_render_host = os.environ.get('RENDER_EXTERNAL_HOSTNAME', '')
_extra_hosts  = os.environ.get('ALLOWED_HOSTS', '').split(',')

ALLOWED_HOSTS = ['localhost', '127.0.0.1'] + (
    [_render_host] if _render_host else []
) + [h for h in _extra_hosts if h]

# ── BASE DE DATOS: PostgreSQL via DATABASE_URL ─────────────────────────────
DATABASES = {
    'default': dj_database_url.config(
        conn_max_age=600,          # conexiones persistentes 10 min
        conn_health_checks=True,   # verifica conexión antes de usarla
        ssl_require=True,          # Render requiere SSL en PostgreSQL
    )
}

# ── CSRF: dominios de confianza ────────────────────────────────────────────
CSRF_TRUSTED_ORIGINS = []
if _render_host:
    CSRF_TRUSTED_ORIGINS.append(f'https://{_render_host}')

# ── HEADERS HTTP SEGUROS ───────────────────────────────────────────────────
SECURE_SSL_REDIRECT            = True
SECURE_HSTS_SECONDS            = 31536000    # 1 año
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD            = True
SESSION_COOKIE_SECURE          = True
CSRF_COOKIE_SECURE             = True
X_FRAME_OPTIONS                = 'DENY'
SECURE_CONTENT_TYPE_NOSNIFF    = True
SECURE_REFERRER_POLICY         = 'same-origin'

# ── ARCHIVOS ESTÁTICOS ─────────────────────────────────────────────────────
# WhiteNoise ya configurado en settings.py; solo confirmar almacenamiento
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# ── LOGGING: solo WARNING y superiores en producción ──────────────────────
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'simple': {'format': '[%(levelname)s] %(name)s: %(message)s'},
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
    'loggers': {
        'django.security': {
            'handlers': ['console'],
            'level': 'ERROR',
            'propagate': False,
        },
    },
}
```

### 1.3 Verificación de Parte 1

```cmd
python manage.py check
```

```
[ ] core/settings_prod.py reemplazado completamente
[ ] Contiene import dj_database_url
[ ] Contiene CSRF_TRUSTED_ORIGINS
[ ] manage.py check → 0 issues (con settings de desarrollo)
```

---

## PARTE 2 — Procfile, Dockerfile y docker-compose.yml (25 min)

### 2.1 Crear `Procfile`

El `Procfile` (sin extensión) le dice a Render cómo iniciar la app.

```
web: gunicorn core.wsgi --workers 2 --timeout 120 --log-file -
```

> **Reglas críticas del Procfile:**
> - Sin extensión de archivo (no `.txt`, no `.bat`)
> - Sin espacios al inicio ni al final de la línea
> - Sin BOM (guardar en VS Code como UTF-8 sin BOM)
> - `--log-file -` redirige logs a stdout (Render los captura)
> - `--workers 2` es suficiente para el plan gratuito de Render

Crear desde CMD:
```cmd
echo web: gunicorn core.wsgi --workers 2 --timeout 120 --log-file - > Procfile
```

Verificar en VS Code que el archivo no tiene extensión y la línea es exacta.

---

### 2.2 Crear `Dockerfile`

```dockerfile
# Dockerfile
# Imagen base: Python 3.11 mínima (slim = sin paquetes innecesarios)
FROM python:3.11-slim

# Variables de entorno para Python en contenedor
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Instalar dependencias del sistema necesarias para psycopg2
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependencias Python primero (aprovecha caché de Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente
COPY . .

# Recolectar archivos estáticos durante el build
RUN python manage.py collectstatic --no-input \
    --settings=core.settings \
    || echo "collectstatic con settings base"

# Exponer el puerto
EXPOSE $PORT

# Comando por defecto: iniciar Gunicorn
CMD gunicorn core.wsgi \
    --bind 0.0.0.0:$PORT \
    --workers 2 \
    --timeout 120 \
    --log-file -
```

---

### 2.3 Crear `docker-compose.yml`

Permite simular el entorno de producción localmente con PostgreSQL y Redis.

```yaml
# docker-compose.yml
# Uso: docker-compose up --build
# Requiere Docker Desktop instalado en la PC

version: '3.9'

services:

  # ── Base de datos PostgreSQL ────────────────────────────────────────
  db:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB:       erp_db
      POSTGRES_USER:     erp_user
      POSTGRES_PASSWORD: erp_pass_local
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U erp_user -d erp_db"]
      interval: 5s
      timeout: 5s
      retries: 5

  # ── Cache Redis (preparado para Celery en W16) ─────────────────────
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - "6379:6379"

  # ── Aplicación Django ───────────────────────────────────────────────
  web:
    build: .
    restart: unless-stopped
    command: >
      sh -c "python manage.py migrate &&
             python manage.py collectstatic --no-input &&
             gunicorn core.wsgi --bind 0.0.0.0:8000 --workers 2 --log-file -"
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "8000:8000"
    depends_on:
      db:
        condition: service_healthy
    environment:
      DJANGO_SETTINGS_MODULE: core.settings_prod
      SECRET_KEY:             dev-clave-docker-no-usar-en-produccion
      DEBUG:                  "False"
      DATABASE_URL:           postgres://erp_user:erp_pass_local@db:5432/erp_db
      REDIS_URL:              redis://redis:6379/0
      ALLOWED_HOSTS:          localhost,127.0.0.1

volumes:
  postgres_data:
  static_volume:
  media_volume:
```

### 2.4 Crear `.dockerignore`

```
# .dockerignore — excluir archivos innecesarios de la imagen Docker
env_erp/
venv/
__pycache__/
*.pyc
*.pyo
.env
.git/
.gitignore
db.sqlite3
staticfiles/
media/
*.md
.vscode/
tests/
```

### 2.5 Prueba local con Docker (opcional — si Docker está disponible)

```cmd
:: Construir e iniciar los servicios
docker-compose up --build

:: En otra terminal: verificar que Django responde
:: Abrir http://localhost:8000/ en el navegador

:: Crear superusuario en el contenedor
docker-compose exec web python manage.py createsuperuser

:: Detener
docker-compose down
```

### 2.6 Verificación de Parte 2

```
[ ] Procfile existe en la raíz (sin extensión, sin espacios extra)
[ ] Procfile contiene exactamente: web: gunicorn core.wsgi --workers 2 --timeout 120 --log-file -
[ ] Dockerfile existe en la raíz
[ ] docker-compose.yml existe en la raíz
[ ] .dockerignore existe en la raíz
[ ] (Opcional) docker-compose up --build → web responde en localhost:8000
```

---

## PARTE 3 — `render.yaml` y Estructura de Fichas (15 min)

### 3.1 Crear `render.yaml`

Render.com puede usar este archivo para crear el servicio automáticamente:

```yaml
# render.yaml
# Documentación: https://render.com/docs/infrastructure-as-code

services:
  - type: web
    name: erp-django-utec
    env: python
    plan: free                     # plan gratuito para desarrollo académico
    region: oregon                 # us-west región gratuita de Render
    branch: main
    buildCommand: |
      pip install -r requirements.txt
      python manage.py collectstatic --no-input
      python manage.py migrate
    startCommand: gunicorn core.wsgi --workers 2 --timeout 120 --log-file -
    healthCheckPath: /
    envVars:
      - key: DJANGO_SETTINGS_MODULE
        value: core.settings_prod
      - key: SECRET_KEY
        generateValue: true        # Render genera una clave aleatoria segura
      - key: DATABASE_URL
        fromDatabase:
          name: erp-django-db
          property: connectionString
      - key: PYTHON_VERSION
        value: "3.11.9"

databases:
  - name: erp-django-db
    databaseName: erp_db
    user: erp_user
    plan: free                     # PostgreSQL gratuito en Render (90 días)
    region: oregon
```

> **Nota:** El plan PostgreSQL gratuito de Render expira a los 90 días.
> Para proyectos en producción real, usar el plan pagado o migrar a
> Railway / Supabase (alternativas gratuitas sin límite de tiempo).

---

### 3.2 Crear estructura de fichas Schmelkes

```cmd
mkdir fichas
```

Crear `fichas/espiral_01_infra.md` (se completará al final de la sesión en Parte 6):

```markdown
# Ficha de Sistematización — Espiral 1
## ERP Django · Espiral E1: Infraestructura y Configuración Base
## UTEC Celaya · Técnico en Programación (SEP 3061300006-23)

| Campo | Contenido |
|---|---|
| **Número de espiral** | 1 |
| **Nombre del ciclo** | Infraestructura y Configuración Base |
| **Semanas** | W01 – W03 |
| **Fecha de inicio** | ___/___/_____ |
| **Fecha de cierre** | ___/___/_____ |
| **Responsable** | [Nombre del estudiante] |
| **Asesor** | MC. Román Fernando López González |

---

## 1. Objetivo del ciclo

Establecer el entorno de desarrollo portable en USB y desplegar el
proyecto Django base en Render.com, de modo que cualquier avance
posterior tenga una URL pública verificable desde el inicio del proyecto.

---

## 2. Tareas realizadas

| # | Tarea | Estado | Tiempo invertido |
|---|---|---|---|
| 1 | Configurar Python 3.11 embeddable en USB | ✅ | h:mm |
| 2 | Instalar pip y virtualenv | ✅ | h:mm |
| 3 | Configurar Git Portable | ✅ | h:mm |
| 4 | Crear scripts iniciar/finalizar sesión | ✅ | h:mm |
| 5 | Crear proyecto Django con 5 apps | ✅ | h:mm |
| 6 | Sistema de templates Fable 5 AzulERP | ✅ | h:mm |
| 7 | Configurar WhiteNoise y estáticos | ✅ | h:mm |
| 8 | Completar settings_prod.py con PostgreSQL | ✅ | h:mm |
| 9 | Crear Procfile, Dockerfile, docker-compose.yml | ✅ | h:mm |
| 10 | Crear render.yaml | ✅ | h:mm |
| 11 | Desplegar en Render.com → URL pública | ✅ | h:mm |
| 12 | Ejecutar Sprint 0 Review y Retrospectiva | ✅ | h:mm |

---

## 3. Evidencias generadas

- [ ] Repositorio GitHub: `https://github.com/tu-usuario/erp-django-utec`
- [ ] URL pública Render: `https://erp-django-utec.onrender.com`
- [ ] Captura de pantalla: `evidencias/espiral_01/render_url.png`
- [ ] Captura de pantalla: `evidencias/espiral_01/manage_check.png`
- [ ] Resultado de tests: `Ran 33 tests in X.XXXs — OK`
- [ ] Commit de cierre:
```
[pegar aquí el resultado de: git log --oneline -5]
```

---

## 4. Criterios de aceptación verificados

| Criterio | ¿Cumplido? | Evidencia |
|---|---|---|
| `manage.py check --deploy` sin warnings críticos | ✅ / ❌ | Captura de terminal |
| URL pública `https://…onrender.com/` → HTTP 200 | ✅ / ❌ | Captura del navegador |
| Repositorio con ≥ 6 commits en rama `main` | ✅ / ❌ | `git log --oneline` |
| 33 tests pasando (W01 + W02 + W03) | ✅ / ❌ | Resultado pytest |
| Ficha Schmelkes E1 completa | ✅ / ❌ | Este documento |

---

## 5. Problemas encontrados y soluciones

| Problema | Causa | Solución aplicada |
|---|---|---|
| | | |
| | | |

---

## 6. Lecciones aprendidas

1.
2.
3.

---

## 7. Tiempo total invertido

| Categoría | Horas |
|---|---|
| Diseño / planeación | |
| Implementación | |
| Pruebas | |
| Despliegue | |
| Documentación | |
| **Total Espiral 1** | |

---

## 8. Conexión con el trabajo recepcional

> Esta espiral aporta evidencia para el **Capítulo 4** (Desarrollo),
> sección 4.1 "Espiral 1: Infraestructura", y para el
> **Capítulo 3** (Metodología), subsección "Ciclos del modelo espiral".
```

### 3.3 Crear carpeta de evidencias

```cmd
mkdir evidencias
mkdir evidencias\espiral_01
```

---

## PARTE 4 — Despliegue en Render.com paso a paso (40 min)

### 4.1 Preparar el repositorio antes del deploy

```cmd
:: Commit con todos los archivos de W03
git add .
git status

:: Verificar que NO aparecen:
::   env_erp/    .env    staticfiles/    db.sqlite3
::   __pycache__/

git commit -m "Sprint 0 W03: settings_prod + Procfile + Dockerfile + render.yaml"
git push origin main
```

---

### 4.2 Crear cuenta y conectar repositorio en Render.com

1. Ir a `https://render.com` → registrarse con la cuenta de **GitHub**
   (permite acceso directo al repositorio)
2. En el dashboard → **New +** → **Web Service**
3. Seleccionar el repositorio `erp-django-utec`
4. Render detectará el `render.yaml` automáticamente

---

### 4.3 Configurar el Web Service (si no usa render.yaml automático)

| Campo | Valor |
|---|---|
| **Name** | `erp-django-utec` |
| **Region** | `Oregon (US West)` |
| **Branch** | `main` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt && python manage.py collectstatic --no-input && python manage.py migrate` |
| **Start Command** | `gunicorn core.wsgi --workers 2 --timeout 120 --log-file -` |
| **Plan** | `Free` |

---

### 4.4 Crear la base de datos PostgreSQL en Render

1. En el dashboard → **New +** → **PostgreSQL**
2. Configurar:

| Campo | Valor |
|---|---|
| **Name** | `erp-django-db` |
| **Database** | `erp_db` |
| **User** | `erp_user` |
| **Region** | `Oregon (US West)` |
| **Plan** | `Free` |

3. Render muestra la **Internal Database URL** → copiar para el paso siguiente

---

### 4.5 Configurar variables de entorno en Render

En el Web Service → **Environment** → agregar:

| Variable | Valor |
|---|---|
| `DJANGO_SETTINGS_MODULE` | `core.settings_prod` |
| `SECRET_KEY` | (click en "Generate" — Render genera una clave segura) |
| `DATABASE_URL` | (pegar la Internal Database URL de PostgreSQL) |
| `PYTHON_VERSION` | `3.11.9` |

> **Importante:** `DATABASE_URL` debe ser la URL **interna** (no la externa)
> para que la conexión sea dentro de la red de Render y sin latencia.

---

### 4.6 Primer deploy

1. Click en **Create Web Service** (o **Manual Deploy** → **Deploy latest commit**)
2. Observar los logs de build en tiempo real:

```
==> Cloning from https://github.com/tu-usuario/erp-django-utec
==> Running build command: pip install -r requirements.txt ...
==> Collecting django==4.2...
==> Successfully installed Django-4.2.x ...
==> Running: python manage.py collectstatic --no-input
    133 static files copied to '/app/staticfiles'.
==> Running: python manage.py migrate
    Applying auth.0001_initial... OK
    Applying admin.0001_initial... OK
    ...
==> Build successful
==> Starting service: gunicorn core.wsgi --workers 2 ...
```

3. Al terminar → aparece la URL: `https://erp-django-utec.onrender.com`

---

### 4.7 Crear superusuario en producción

Una vez el servicio está activo, desde el dashboard de Render:

1. Web Service → **Shell** (pestaña en el menú superior)
2. Ejecutar:

```bash
python manage.py createsuperuser
# → Username: admin
# → Email: admin@erp-utec.com
# → Password: (elegir contraseña segura)
```

---

### 4.8 Verificar el despliegue

Abrir en el navegador:

| URL | Resultado esperado |
|---|---|
| `https://erp-django-utec.onrender.com/` | Bienvenida ERP con tarjetas de módulos |
| `https://erp-django-utec.onrender.com/admin/` | Panel Django Admin (login con superusuario) |
| `https://erp-django-utec.onrender.com/productos/` | Template productos/index.html |

### 4.9 Verificación de Parte 4

```
[ ] URL pública responde HTTP 200 en el navegador
[ ] Panel /admin/ accesible con el superusuario creado
[ ] Los 5 módulos muestran sus templates Fable 5 AzulERP
[ ] Toggle modo noche funciona en la URL pública
[ ] Logs de Render no muestran errores 500
[ ] Captura de pantalla guardada en evidencias/espiral_01/render_url.png
```

---

## PARTE 5 — Tests W03 (15 min)

### 5.1 Crear `tests/test_w03_deploy.py`

```python
"""Suite de pruebas W03 — Archivos de despliegue y configuración.

Verifica la existencia y contenido mínimo de los artefactos
necesarios para desplegar en Render.com.

Ejecutar con:
    python manage.py test tests.test_w03_deploy --verbosity=2

Resultado esperado:
    Ran 10 tests in X.XXXs
    OK
"""
import os
from pathlib import Path

from django.conf import settings
from django.test import TestCase

# Ruta raíz del proyecto (donde está manage.py)
BASE_DIR = Path(settings.BASE_DIR)


class ArchivosDesplieguTest(TestCase):
    """Verifica que los archivos de despliegue existen en el repositorio."""

    def test_procfile_existe(self):
        """Procfile debe existir en la raíz del proyecto."""
        self.assertTrue(
            (BASE_DIR / 'Procfile').exists(),
            "Procfile no encontrado en la raíz del proyecto"
        )

    def test_procfile_contiene_gunicorn(self):
        """Procfile debe iniciar Gunicorn, no runserver."""
        procfile = BASE_DIR / 'Procfile'
        if procfile.exists():
            content = procfile.read_text(encoding='utf-8')
            self.assertIn(
                'gunicorn', content,
                "Procfile debe usar gunicorn, no python manage.py runserver"
            )

    def test_dockerfile_existe(self):
        """Dockerfile debe existir en la raíz del proyecto."""
        self.assertTrue(
            (BASE_DIR / 'Dockerfile').exists(),
            "Dockerfile no encontrado"
        )

    def test_render_yaml_existe(self):
        """render.yaml debe existir en la raíz del proyecto."""
        self.assertTrue(
            (BASE_DIR / 'render.yaml').exists(),
            "render.yaml no encontrado"
        )

    def test_docker_compose_existe(self):
        """docker-compose.yml debe existir en la raíz."""
        self.assertTrue(
            (BASE_DIR / 'docker-compose.yml').exists(),
            "docker-compose.yml no encontrado"
        )

    def test_ficha_schmelkes_e1_existe(self):
        """La ficha Schmelkes de la Espiral 1 debe existir."""
        self.assertTrue(
            (BASE_DIR / 'fichas' / 'espiral_01_infra.md').exists(),
            "fichas/espiral_01_infra.md no encontrado"
        )


class RequirementsProduccionTest(TestCase):
    """Verifica que requirements.txt incluye dependencias de producción."""

    def _leer_requirements(self):
        req_path = BASE_DIR / 'requirements.txt'
        if not req_path.exists():
            self.fail("requirements.txt no encontrado")
        return req_path.read_text(encoding='utf-8').lower()

    def test_gunicorn_en_requirements(self):
        """gunicorn debe estar en requirements.txt."""
        self.assertIn('gunicorn', self._leer_requirements(),
                      "gunicorn falta en requirements.txt")

    def test_psycopg2_en_requirements(self):
        """psycopg2-binary debe estar en requirements.txt."""
        self.assertIn('psycopg2', self._leer_requirements(),
                      "psycopg2-binary falta en requirements.txt")

    def test_dj_database_url_en_requirements(self):
        """dj-database-url debe estar en requirements.txt."""
        self.assertIn('dj-database-url', self._leer_requirements(),
                      "dj-database-url falta en requirements.txt")


class SettingsProdTest(TestCase):
    """Verifica el contenido de settings_prod.py leyendo el archivo."""

    def _leer_settings_prod(self):
        path = BASE_DIR / 'core' / 'settings_prod.py'
        if not path.exists():
            self.fail("core/settings_prod.py no encontrado")
        return path.read_text(encoding='utf-8')

    def test_settings_prod_tiene_debug_false(self):
        """settings_prod.py debe tener DEBUG = False."""
        content = self._leer_settings_prod()
        self.assertIn(
            'DEBUG = False', content,
            "settings_prod.py debe contener 'DEBUG = False'"
        )

    def test_settings_prod_importa_dj_database_url(self):
        """settings_prod.py debe importar dj_database_url."""
        content = self._leer_settings_prod()
        self.assertIn(
            'dj_database_url', content,
            "settings_prod.py debe importar dj_database_url"
        )
```

### 5.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w03_deploy --verbosity=2
```

**Resultado esperado:**
```
test_dj_database_url_en_requirements ... ok
test_docker_compose_existe ... ok
test_dockerfile_existe ... ok
test_ficha_schmelkes_e1_existe ... ok
test_gunicorn_en_requirements ... ok
test_procfile_contiene_gunicorn ... ok
test_procfile_existe ... ok
test_psycopg2_en_requirements ... ok
test_render_yaml_existe ... ok
test_settings_prod_importa_dj_database_url ... ok
test_settings_prod_tiene_debug_false ... ok

Ran 10 tests in X.XXXs
OK
```

### 5.3 Suite acumulada W01 + W02 + W03

```cmd
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `Ran 33 tests in X.XXXs · OK`

---

## PARTE 6 — Sprint 0 Review + Retrospectiva (30 min)

### 6.1 Sprint 0 Review (≤ 15 min)

El **Sprint Review** es una demostración del incremento de software
ante el Product Owner (el asesor). No es una presentación de diapositivas;
es una **demo en vivo**.

**Formato de la demo (guión de 3 minutos):**

```
1. Mostrar la URL pública en el navegador:
   → https://erp-django-utec.onrender.com/

2. Demostrar el toggle de modo noche (🌙 → ☀️).

3. Navegar a /admin/ y hacer login con el superusuario.

4. Mostrar el repositorio en GitHub:
   → Número de commits, estructura de carpetas, Procfile visible.

5. Ejecutar en la terminal:
   → python manage.py test tests --verbosity=0
   → Resultado: Ran 33 tests ... OK

6. Declarar el Sprint Goal verificado:
   "Al finalizar el Sprint 0, existe un proyecto Django 4.2
    desplegado en Render.com con URL pública funcional y
    repositorio en GitHub con historial de commits."
   → Estado: ✅ COMPLETADO
```

**Tabla de verificación del Sprint Goal:**

| Criterio del Sprint Goal | Estado |
|---|---|
| Proyecto Django 4.2 funcional | ✅ |
| URL pública en Render.com | ✅ |
| Repositorio GitHub con ≥ 6 commits | ✅ |
| 33 tests pasando | ✅ |
| `manage.py check` sin errores | ✅ |

---

### 6.2 Sprint 0 Retrospectiva (≤ 15 min)

La **Retrospectiva** analiza el proceso, no el producto.
Responder estas preguntas y registrar en `sprint0_retrospective.md`:

```markdown
# Sprint 0 Retrospective — ERP Django
## Semanas W01–W03 · Espiral 1

**Fecha:** ___/___/_____
**Facilitador/Scrum Master:** [Nombre]

## ¿Qué funcionó bien? (Keep)
1.
2.
3.

## ¿Qué mejorar? (Improve)
1.
2.

## ¿Qué eliminar? (Drop)
1.

## Acción de mejora (Kaizen) para Sprint 1
> Una sola acción concreta y medible:
> "En el Sprint 1, voy a ____________ para mejorar ____________."

## Velocidad del Sprint 0

| HU | Planificado (pts) | Entregado (pts) |
|---|---|---|
| HU-E1-01 Entorno portable | 3 | |
| HU-E1-02 Scripts sincronización | 2 | |
| HU-E1-03 Repositorio GitHub | 2 | |
| HU-E1-04 Despliegue Render.com | 3 | |
| **Total** | **10** | |

**Velocidad real del equipo:** ___ puntos / sprint
```

---

### 6.3 Completar la Ficha Schmelkes E1

Abrir `fichas/espiral_01_infra.md` y completar los campos vacíos:

```
[ ] Fechas de inicio y cierre correctas
[ ] Tabla de tareas con estados y tiempos reales
[ ] URL pública pegada en evidencias
[ ] Resultado de "git log --oneline -5" pegado
[ ] Todos los criterios de aceptación marcados
[ ] Problemas encontrados documentados (al menos 1)
[ ] 3 lecciones aprendidas redactadas
[ ] Tiempo total invertido calculado
[ ] Campo "Conexión con trabajo recepcional" completado
```

---

## CIERRE — Commit Final y Respaldo (15 min)

### Actualizar `sprint0_planning.md`

```markdown
## Sprint 0 — Estado final W03

| HU | Estado | Puntos entregados |
|---|---|---|
| HU-E1-01 Entorno portable USB | ✅ Completada | 3 |
| HU-E1-02 Scripts sincronización | ✅ Completada | 2 |
| HU-E1-03 Repositorio GitHub | ✅ Completada | 2 |
| HU-E1-04 Despliegue Render.com | ✅ Completada | 3 |
| **Total entregado** | | **10 / 10** |

## Hito M1 — ALCANZADO ✅
- URL pública: https://erp-django-utec.onrender.com
- Tests: Ran 33 tests → OK
- Commits: ≥ 6 en rama main
- Fecha: ___/___/_____
```

---

### Commit final de la Espiral 1

```cmd
git add .
git status

:: Verificar que incluye:
::   fichas/espiral_01_infra.md
::   tests/test_w03_deploy.py
::   Procfile  Dockerfile  docker-compose.yml  render.yaml
::   sprint0_retrospective.md
::   sprint0_planning.md (actualizado)

git commit -m "Sprint 0 CIERRE [M1]: Render.com desplegado + 33 tests OK + Ficha Schmelkes E1"
git push origin main
```

---

### Ejecutar `finalizar_sesion.bat`

```cmd
:: Detener cualquier servidor activo (Ctrl+C)
E:\finalizar_sesion.bat
```

Verificar en `E:\WorkSpace_ERP\`:

```
[ ] Procfile
[ ] Dockerfile
[ ] docker-compose.yml
[ ] .dockerignore
[ ] render.yaml
[ ] core/settings_prod.py (versión final con dj-database-url)
[ ] fichas/espiral_01_infra.md (completa)
[ ] sprint0_retrospective.md
[ ] tests/test_w03_deploy.py
[ ] evidencias/espiral_01/ (con capturas de pantalla)
```

---

## CHECKLIST FINAL W03 — HITO M1

### Técnico

```
ARCHIVOS DE DESPLIEGUE
[ ] Procfile: "web: gunicorn core.wsgi --workers 2 --timeout 120 --log-file -"
[ ] Dockerfile: FROM python:3.11-slim, collectstatic en build
[ ] docker-compose.yml: servicios web + db (postgres:15) + redis
[ ] .dockerignore: excluye env_erp/, .env, staticfiles/, db.sqlite3
[ ] render.yaml: buildCommand con migrate incluido

SETTINGS DE PRODUCCIÓN
[ ] settings_prod.py: import dj_database_url
[ ] settings_prod.py: DATABASES = {dj_database_url.config(...)}
[ ] settings_prod.py: CSRF_TRUSTED_ORIGINS con hostname de Render
[ ] settings_prod.py: todos los SECURE_* activados

RENDER.COM
[ ] Web Service creado y en estado "Live"
[ ] PostgreSQL creado y conectado via DATABASE_URL
[ ] SECRET_KEY generada por Render (no hardcodeada)
[ ] URL pública responde HTTP 200
[ ] /admin/ accesible con superusuario
[ ] Los 5 módulos muestran sus templates

TESTS
[ ] test tests.test_w03_deploy → 10/10 OK
[ ] test tests → 33/33 OK (W01 + W02 + W03 acumulados)

SCRUM / SCHMELKES
[ ] sprint0_planning.md: 10/10 puntos entregados
[ ] sprint0_retrospective.md: 3 secciones completadas + Kaizen
[ ] fichas/espiral_01_infra.md: todos los campos completos
[ ] URL pública en la ficha de evidencias
[ ] Tiempo total de la Espiral 1 registrado

GIT
[ ] ≥ 6 commits en rama main con mensajes descriptivos
[ ] Commit de cierre con mensaje "[M1]"
[ ] git push → GitHub actualizado
[ ] finalizar_sesion.bat → archivos en USB verificados
```

---

## DIAGRAMA: Arquitectura de despliegue al cerrar Espiral 1

```
USB (Caja fuerte)                    GitHub (Respaldo nube)
┌─────────────────┐    git push      ┌──────────────────────┐
│ WorkSpace_ERP/  │ ──────────────► │ erp-django-utec repo │
│  .git/          │                  │  main branch         │
│  Procfile       │                  └──────────┬───────────┘
│  Dockerfile     │                             │ Auto-deploy
│  render.yaml    │                             ▼
└─────────────────┘               ┌─────────────────────────┐
                                  │ Render.com              │
PC taller (volátil)               │  Web Service (Gunicorn) │
┌─────────────────┐               │  PostgreSQL 15          │
│ C:\Temp_ERP\    │               │  Estáticos (WhiteNoise) │
│  env_erp/       │               └─────────────────────────┘
│  staticfiles/   │                             │
│  db.sqlite3     │               https://erp-django-utec.onrender.com
└─────────────────┘                             │
       ▲                                        ▼
       │  finalizar_sesion.bat        ┌─────────────────┐
       └──────────────────────────────│ Navegador       │
                                      │ (Fable 5 ERP)   │
                                      └─────────────────┘
```

---

## HILO CONDUCTOR → W04

**¿Qué cierra W03?**
La Espiral 1 completa: entorno portable funcional, sistema de templates,
despliegue en producción con PostgreSQL, suite de 33 tests y
documentación Schmelkes de la infraestructura.

**¿Qué abre W04?**
Con el proyecto en producción, la siguiente pregunta es:
*¿Qué datos va a manejar este ERP?* W04 comienza la Espiral 2 con el
diseño del modelo Entidad-Relación (ER) antes de escribir una sola
línea de código de modelo.

**¿Qué necesita W04 de W03?**

| Artefacto de W03 | Uso en W04 |
|---|---|
| URL pública de Render | Se verifica que cada nuevo modelo no rompe el deploy |
| `fichas/espiral_01_infra.md` | Plantilla para abrir `fichas/espiral_02_modelos.md` |
| `sprint0_retrospective.md` | El Kaizen se aplica en el Sprint 1 Planning de W04 |
| Suite de 33 tests | W04 la amplía con tests de modelo (≥ 15 nuevos) |

**Tarea de investigación para W04:**
> ¿Qué es la Tercera Forma Normal (3FN) en diseño de bases de datos?
> Diseña en papel un esquema ER mínimo para un ERP con las entidades:
> Cliente, Producto, Venta y DetalleVenta. ¿Cuántas tablas necesitas?

**Pregunta de reflexión:**
> "¿Por qué es mejor diseñar el modelo ER en papel ANTES de crear
> los modelos Django? ¿Qué pasaría si se modifica la relación entre
> Venta y Producto después de tener datos reales en la BD?"

---

## Referencia rápida de comandos W03

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py check --deploy   (con env vars de prod configuradas)
python manage.py collectstatic --no-input
python manage.py runserver

:: TESTS
python manage.py test tests.test_w03_deploy --verbosity=2
python manage.py test tests --verbosity=0   (suite completa 33 tests)

:: GIT
git add .
git commit -m "Sprint 0 CIERRE [M1]: mensaje descriptivo"
git push origin main
git log --oneline

:: DOCKER (si está disponible)
docker-compose up --build
docker-compose exec web python manage.py createsuperuser
docker-compose down

:: RENDER (desde la Shell del dashboard)
python manage.py createsuperuser
python manage.py migrate
python manage.py check --deploy
```

---

*Guía de Laboratorio W03 · ERP Django*
*Espiral 1 — Cierre · Sprint 0 Review + Retrospectiva · Hito M1*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*