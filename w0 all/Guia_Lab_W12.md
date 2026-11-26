# Guía de Laboratorio — W12
## ERP Django · Espiral 4 · Semana 12 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

> **Nota de versión (v2):** esta guía **sustituye de forma definitiva** a la
> versión anterior de W12 basada en `xhtml2pdf`. WeasyPrint vía Docker
> es ahora el motor de PDF oficial del programa a partir de la Semana 12.
> Esta revisión corrige errores de instalación de Docker Desktop + WSL2
> detectados durante la implementación real en aula (síntoma: contenedores
> corriendo sin errores visibles, pero `http://127.0.0.1:8000` no responde
> en el navegador). Ver Sección 2 (Prerrequisitos, reescrita por completo)
> y Sección 8.5 (Diagnóstico de conectividad WSL2 ↔ Windows, nueva).

---

| Campo | Detalle |
|---|---|
| **Semana** | W12 de 24 |
| **Motor de PDF** | **WeasyPrint vía Docker** (reemplaza a xhtml2pdf como estándar del programa) |
| **Espiral** | E4 — API REST y Media |
| **Sprint Scrum** | Sprint 3 — Review + Retrospectiva |
| **Hito** | **★ M4: DRF completo + PDF de alta calidad + imágenes + Excel funcionales** |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 3 — Infraestructura |
| **Hilo conductor** | "xhtml2pdf fue el aperitivo. WeasyPrint es el platillo principal: PDFs con imágenes, encabezados y pie de página en cada hoja." |

---

## 1. ¿Por qué WeasyPrint es ahora el estándar del programa?

La **Guía Lab W12 original** usaba `xhtml2pdf` como motor de PDF —
la elección correcta para el entorno USB del aula porque no requería
librerías de sistema y funcionaba directamente con el Python portable.
Esa versión queda documentada solo como referencia histórica; a partir
de esta revisión, **WeasyPrint vía Docker es el motor de PDF oficial**
del programa.

**WeasyPrint** produce PDFs de calidad significativamente superior:

| Característica | xhtml2pdf (anterior) | WeasyPrint (oficial) |
|---|---|---|
| Calidad de tipografía | ★★★☆☆ | ★★★★★ |
| Imágenes (logo, fotos) | Soporte limitado | Soporte completo |
| CSS moderno (`flexbox`, `grid`) | No compatible | Compatible |
| `@page` (encabezados/pies por página) | Parcial | Completo |
| `counter(page)` (número de página) | No | Sí |
| Tablas multipágina | Corta filas | Respeta `thead` en cada página |
| Instalación en Windows sin Docker | Compleja (requiere GTK3 runtime) | **Requiere Docker** |
| Instalación en Linux/macOS | `pip install weasyprint` | `pip install weasyprint` |

**Por qué se requiere Docker (y por tanto WSL2 en Windows):**
WeasyPrint depende de `libpango-1.0`, `libcairo2` y `libgdk-pixbuf-2.0`
— librerías nativas del sistema operativo que NO pueden instalarse en
el entorno USB portable de Windows sin permisos de administrador.
Docker empaqueta esas librerías dentro del contenedor, resolviendo el
problema de dependencias para el aula y producción con el mismo artefacto.
Esto hace que, a partir de esta semana, **Docker deje de ser opcional**
y se convierta en un requisito de infraestructura del proyecto — de ahí
que la Sección 2 de esta guía cubra la instalación de WSL2 con detalle
exhaustivo: es la base sobre la que corre todo lo demás.

> **Alternativa nativa en Windows (NO recomendada):**
> Se puede instalar GTK3 runtime para Windows desde `https://github.com/tschoonj/GTK-for-Windows-Runtime-Environment-Installer`.
> Requiere reiniciar, configurar el PATH manualmente y ejecutar como
> administrador. Demasiado frágil para el entorno de aula; Docker
> es la vía confiable y es la que se documenta y soporta en este programa.

---

## 2. Prerrequisitos — Instalación Completa de WSL2 + Docker Desktop

> **Por qué esta sección se reescribió:** la versión anterior de esta guía
> asumía "Docker Desktop instalado" sin verificar que WSL2 estuviera
> correctamente habilitado y configurado como backend. Esto produce
> exactamente el síntoma más reportado en aula: **los contenedores se
> ven "corriendo" (`docker-compose ps` muestra `Up`), pero
> `http://127.0.0.1:8000` no carga en el navegador.** La causa casi
> siempre es que WSL2 no quedó correctamente instalado/activado ANTES
> de instalar Docker Desktop, o que el reenvío de `localhost`
> (localhost forwarding) entre WSL2 y Windows no está funcionando.
> Esta sección se sigue **en orden y sin saltarse pasos**.

### 2.1 Requisitos del equipo

```
[ ] Windows 10 versión 2004 (build 19041) o superior — o Windows 11
[ ] Virtualización habilitada en BIOS/UEFI (Intel VT-x / AMD-V)
[ ] Cuenta con privilegios de Administrador en Windows
[ ] Al menos 4 GB de RAM libres (WSL2 + Docker consumen memoria)
```

Verificar la versión de Windows:

```cmd
winver
```

Verificar si la virtualización está habilitada (Administrador de tareas):
```
Ctrl+Shift+Esc → pestaña Rendimiento → CPU
→ "Virtualización: Habilitada"
```

Si dice "Deshabilitada", debe activarse en el BIOS/UEFI del equipo
(la tecla de acceso varía: F2, F10, F12, Supr según el fabricante)
buscando la opción `Intel VT-x`, `AMD-V` o `SVM Mode`.

---

### 2.2 Habilitar las características de Windows para WSL2

Abrir **PowerShell como Administrador** (clic derecho → "Ejecutar como administrador")
y ejecutar, **una línea a la vez**:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

**Reiniciar el equipo** después de ejecutar ambos comandos:

```powershell
Restart-Computer
```

> **Error común #1:** ejecutar `docker-compose up` sin haber reiniciado
> después de habilitar estas dos características. Windows necesita el
> reinicio para activar el hipervisor — sin él, Docker Desktop arranca
> "a medias" y el backend WSL2 queda en un estado inconsistente que
> parece funcionar (los contenedores arrancan) pero no enruta correctamente
> la red hacia Windows.

---

### 2.3 Instalar/actualizar el kernel de Linux de WSL2

Después de reiniciar, abrir **PowerShell como Administrador** de nuevo:

```powershell
wsl --install --no-distribution
```

> `--no-distribution` instala solo el motor WSL2 y su kernel, sin
> forzar la instalación de una distribución Linux completa (Ubuntu, etc.).
> Docker Desktop crea sus propias distribuciones internas
> (`docker-desktop` y `docker-desktop-data`) y no necesita que instales
> Ubuntu manualmente — instalarlo es opcional y solo se recomienda si
> además quieres una terminal Linux para otros usos.

Establecer WSL2 como versión por defecto:

```powershell
wsl --set-default-version 2
```

Verificar la versión de WSL instalada:

```powershell
wsl --version
```

**Resultado esperado (mínimo):**
```
Versión de WSL: 2.x.x.x
Versión de kernel: 5.15.x.x
...
```

> **Error común #2:** tener una versión de WSL2 desactualizada.
> Si `wsl --version` falla con "no reconocido" o muestra una versión
> de kernel muy antigua (antes de 5.10), actualizar manualmente desde:
> `https://aka.ms/wsl2kernel` → ejecutar el instalador `.msi` → reiniciar.

---

### 2.4 Instalar Docker Desktop

1. Descargar desde `https://www.docker.com/products/docker-desktop/`
2. Ejecutar el instalador `Docker Desktop Installer.exe`
3. **Marcar la casilla "Use WSL 2 instead of Hyper-V"** durante la instalación
   (en versiones recientes esta es la única opción y no aparece la casilla —
   eso es correcto, significa que WSL2 ya es el único backend soportado)
4. Finalizar instalación → reiniciar si se solicita
5. Abrir Docker Desktop → aceptar los términos de servicio
6. Esperar a que el ícono de Docker (ballena) en la bandeja del sistema
   deje de animarse y quede fijo — esto indica que el motor arrancó

---

### 2.5 Verificar que Docker Desktop usa el backend WSL2 (paso crítico)

Abrir Docker Desktop → ícono de engrane (**Settings**) → **General**:

```
[ ] "Use the WSL 2 based engine" debe estar MARCADO (✓)
```

Ir a **Settings → Resources → WSL Integration**:

```
[ ] "Enable integration with my default WSL distro" → activado
[ ] Si instalaste Ubuntu u otra distro adicional, su toggle también
    debe estar en verde/activado
```

Aplicar cambios (**Apply & Restart** si Docker lo solicita).

---

### 2.6 Verificar desde PowerShell que las distribuciones de Docker existen

```powershell
wsl -l -v
```

**Resultado esperado:**
```
  NAME                   STATE           VERSION
* docker-desktop         Running         2
  docker-desktop-data    Running         2
```

> **Error común #3 (el más frecuente en aula):** si `docker-desktop` o
> `docker-desktop-data` no aparecen, o aparecen con `VERSION 1` en vez
> de `2`, Docker Desktop está usando el motor legacy o estas
> distribuciones internas se corrompieron. Solución:
> ```powershell
> wsl --shutdown
> ```
> Cerrar Docker Desktop por completo (clic derecho en la ballena de
> la bandeja → **Quit Docker Desktop**, no solo cerrar la ventana) y
> volver a abrirlo. Verificar `wsl -l -v` de nuevo.

---

### 2.7 Verificación final: Docker responde y el reenvío de red funciona

```cmd
docker --version
docker-compose --version
```

**Resultado esperado:**
```
Docker version 25.x.x, build xxxxxxx
Docker Compose version v2.x.x
```

**Prueba de humo de Docker (antes de tocar el proyecto):**

```cmd
docker run --rm -p 8080:80 nginx:alpine
```

Dejar la terminal abierta y, en el navegador, abrir:
```
http://localhost:8080
```

```
[ ] Debe aparecer la página de bienvenida de Nginx ("Welcome to nginx!")
```

**Si esta página NO aparece, el problema es de infraestructura
WSL2/Docker Desktop — NO del proyecto Django.** No continuar con el
resto de esta guía hasta resolverlo (ver Sección 2.8 más abajo).
Detener la prueba con `Ctrl+C` en la terminal.

Si SÍ aparece, Docker y WSL2 están correctamente configurados y se
puede continuar con el resto de la guía con confianza.

---

### 2.8 Si la prueba de Nginx falla — Checklist de causas comunes

```
[ ] ¿Reiniciaste Windows después de habilitar las características (2.2)?
[ ] ¿wsl -l -v muestra docker-desktop y docker-desktop-data en VERSION 2?
[ ] ¿Hay un archivo %UserProfile%\.wslconfig con localhostForwarding=false?
    → Abrir el archivo (si existe) y verificar que NO contenga esa línea,
      o que diga localhostForwarding=true. Si se edita, ejecutar:
      wsl --shutdown
      y reabrir Docker Desktop.
[ ] ¿Algún antivirus o VPN corporativa está activo? Desactivar
    temporalmente y reintentar la prueba de Nginx.
[ ] ¿El puerto 8080 ya está en uso por otro proceso?
    netstat -ano | findstr :8080
    → Si aparece un proceso, usar otro puerto de prueba (8081, 8082...)
[ ] ¿El Firewall de Windows está bloqueando Docker Desktop?
    Panel de Control → Firewall de Windows Defender →
    "Permitir una aplicación..." → verificar que Docker Desktop
    tenga permiso en redes Privadas.
```

Si después de revisar todo lo anterior el problema persiste, ejecutar
el restablecimiento completo de WSL2:

```powershell
wsl --shutdown
```

Cerrar Docker Desktop completamente (Quit, no solo cerrar ventana),
esperar 15 segundos, y volver a abrirlo. Repetir la prueba de Nginx
de la Sección 2.7.

---

### 2.9 Estado del proyecto

```cmd
:: Verificar que el proyecto tiene los archivos base de Docker
dir Dockerfile
dir docker-compose.yml
dir docker-entrypoint.sh
```

Si `docker-entrypoint.sh` y `Dockerfile` no existen aún, esta guía
los crea completos en las Partes 5 y 6.

---

## 3. Dependencias de Sistema de WeasyPrint

WeasyPrint necesita estas librerías nativas instaladas en el sistema
operativo (en Ubuntu/Debian, que es lo que usa el contenedor Docker):

| Librería | Propósito |
|---|---|
| `libpango-1.0-0` | Motor de composición tipográfica |
| `libpangoft2-1.0-0` | Soporte FreeType para Pango |
| `libpangocairo-1.0-0` | Puente entre Pango y Cairo |
| `libcairo2` | Motor de renderizado 2D (PDF, PNG, SVG) |
| `libcairo-gobject2` | Binding GObject de Cairo |
| `libgdk-pixbuf-2.0-0` | Manejo de imágenes (PNG, JPEG, WebP) |
| `libffi-dev` | Interfaz de funciones externas (requerido por cffi) |
| `shared-mime-info` | Base de datos de tipos MIME |
| `fonts-liberation` | Fuentes Liberation (equivalentes a Times, Arial, Courier) |

**¿Por qué tantas librerías?**
WeasyPrint convierte HTML+CSS a PDF usando la misma pila de renderizado
que usa el navegador GTK (WebKitGTK). Cairo genera el PDF; Pango hace
el layout de texto; GDK-PixBuf maneja las imágenes incrustadas.

---

## 4. `requirements.txt` Actualizado

Agregar `weasyprint` al archivo. Se **mantiene** `xhtml2pdf` como
dependencia opcional (para fallback o reportes secundarios):

```txt
# requirements.txt — agregar:

# Motor de PDF de alta calidad (requiere Docker o Linux)
weasyprint==60.2
# pydyf 0.11+ cambió la API de PDF() y rompe WeasyPrint 60.x:
#   TypeError: PDF.__init__() takes 1 positional argument but 3 were given
# Mantener fijo mientras se use weasyprint==60.2.
pydyf==0.10.0

# Motor de PDF alternativo sin dependencias nativas (fallback)
# xhtml2pdf==0.2.15   ← mantener comentado, disponible si se necesita

# (El resto de requirements existentes permanecen igual)
```

> **Nota sobre versiones:** WeasyPrint 60.x es estable en Python 3.11.
> Versiones 62+ requieren Python 3.9+ pero pueden cambiar el API de
> `weasyprint.HTML()`. Si se actualiza, revisar el parámetro `string`
> vs `filename` en la llamada.
>
> **Importante — `pydyf`:** WeasyPrint 60.2 depende de `pydyf` sin límite
> superior de versión. Si no se fija, `pip` instala la más reciente
> (0.11 o posterior) y **todas** las facturas fallan con
> `TypeError: PDF.__init__() takes 1 positional argument but 3 were given`.
> Por eso se fija `pydyf==0.10.0`.
>
> **Codificación:** guardar `requirements.txt` en **UTF-8**. Si se genera con
> `pip freeze > requirements.txt` en PowerShell 5.1, queda en UTF-16 y los
> tests de W03 no pueden leerlo. Usar
> `pip freeze | Out-File -Encoding utf8 requirements.txt`.

---

## 5. `docker-entrypoint.sh` — Punto de entrada unificado

Este script se ejecuta **siempre** al arrancar el contenedor, tanto
en local (docker-compose) como en Render. Centraliza las tareas de
inicialización que antes estaban dispersas en el `command` del
docker-compose y en el `buildCommand` de render.yaml.

```bash
#!/bin/sh
# docker-entrypoint.sh
# Punto de entrada unificado para el contenedor ERP Django.
# Se ejecuta en LOCAL (docker-compose) y en PRODUCCIÓN (Render).
# IMPORTANTE: este archivo debe tener finales de línea LF (ver .gitattributes).
# ─────────────────────────────────────────────────────────────────
set -e   # detener si cualquier comando falla

echo "==> [entrypoint] Ejecutando migraciones de base de datos..."
python manage.py migrate --noinput

echo "==> [entrypoint] Recolectando archivos estáticos..."
python manage.py collectstatic --noinput --clear

echo "==> [entrypoint] Verificando la configuración de Django..."
python manage.py check --deploy 2>/dev/null || python manage.py check

# Superusuario de prácticas (fines educativos): se crea solo si no existe,
# es decir, la primera vez que arranca con una base de datos nueva.
echo "==> [entrypoint] Verificando y creando superusuario..."
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@email.com', '12345')"

echo "==> [entrypoint] Iniciando Gunicorn en 0.0.0.0:${PORT:-8000}..."
exec gunicorn core.wsgi \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers 2 \
    --timeout 120 \
    --log-file - \
    --access-logfile -
```

Dar permisos de ejecución:

```cmd
:: En Windows (Git Bash o WSL):
chmod +x docker-entrypoint.sh

:: Verificar el atributo en git para que se preserve en Linux:
git add docker-entrypoint.sh
git update-index --chmod=+x docker-entrypoint.sh
```

> **`$PORT`:** Render indica el puerto con la variable `PORT`. Por eso
> Gunicorn usa `--bind 0.0.0.0:${PORT:-8000}`: en Render escucha en el
> puerto que Render asigna y en local usa 8000.

**Finales de línea (Windows → Linux).** Git en Windows suele convertir los
archivos a CRLF. Un `docker-entrypoint.sh` con CRLF falla en el contenedor
con `/bin/sh^M: not found` o `exec format error`. Crear `.gitattributes`
en la raíz del proyecto:

```gitattributes
# Normaliza finales de línea en el repositorio.
* text=auto
# Scripts de shell y archivos que lee Linux: siempre LF (si no, falla en Docker/Render)
*.sh            text eol=lf
Dockerfile      text eol=lf
*.yml           text eol=lf
*.yaml          text eol=lf
requirements.txt text eol=lf
# Binarios
*.png  binary
*.jpg  binary
*.jpeg binary
*.webp binary
*.pdf  binary
*.docx binary
*.sqlite3 binary
```

---

## 6. `Dockerfile` Completo y Actualizado

```dockerfile
# Dockerfile
# ERP Django con WeasyPrint
# Base: Python 3.11 sobre Debian Bookworm slim
# ─────────────────────────────────────────────────────────────────

# ── ETAPA 1: imagen base ─────────────────────────────────────────
FROM python:3.11-slim-bookworm AS base

# Evitar archivos .pyc y que Python bufferice la salida
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# ── ETAPA 2: dependencias de sistema ─────────────────────────────
FROM base AS system-deps

RUN apt-get update && apt-get install -y --no-install-recommends \
    # ── Dependencias de WeasyPrint ──────────────────────────────
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libpangocairo-1.0-0 \
    libcairo2 \
    libcairo-gobject2 \
    libgdk-pixbuf-2.0-0 \
    libffi-dev \
    shared-mime-info \
    fonts-liberation \
    # ── Fuentes adicionales para mejor tipografía ───────────────
    fonts-dejavu-core \
    # ── Dependencias para Pillow (imágenes en Django) ───────────
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    zlib1g-dev \
    # ── Cliente PostgreSQL (psycopg2) ───────────────────────────
    libpq-dev \
    gcc \
    # ── Herramientas de diagnóstico (se pueden eliminar en prod) ─
    curl \
 && rm -rf /var/lib/apt/lists/*    # limpiar caché de apt → imagen más pequeña

# ── ETAPA 3: dependencias Python ─────────────────────────────────
FROM system-deps AS python-deps

WORKDIR /app

# Copiar solo requirements primero para aprovechar la caché de capas Docker.
# Si el código cambia pero requirements.txt no, esta capa NO se reconstruye.
COPY requirements.txt .
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# ── ETAPA 4: código de la aplicación ─────────────────────────────
FROM python-deps AS app

WORKDIR /app

# Copiar el código fuente
COPY . .

# Dar permisos de ejecución al entrypoint
RUN chmod +x docker-entrypoint.sh

# Puerto que expone el contenedor (Gunicorn escucha en 8000)
EXPOSE 8000

# Punto de entrada: siempre ejecuta el entrypoint al arrancar
ENTRYPOINT ["./docker-entrypoint.sh"]
```

> **Detalle clave: imagen multicapa.**
> El orden de `COPY requirements.txt` → `pip install` → `COPY . .`
> no es accidental. Docker cachea cada capa. Si modificas el código
> Python pero no `requirements.txt`, la capa de `pip install` no se
> repite, acelerando el build de ~3 minutos a ~10 segundos.

---

## 7. `docker-compose.yml` — Stack de W12 (web + base de datos)

En W12 el stack tiene solo **web** y **db**. Redis, el worker de Celery,
Beat y Flower se agregan en W16–W18, cuando exista su código: si se
declaran antes, esos contenedores no arrancan porque `celery` todavía
no está en `requirements.txt`.

```yaml
# docker-compose.yml — Stack local ERP Django (alcance W12)
# Celery worker/beat, Flower y Redis se agregan en W16+ (aún no hay código).
services:

  db:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB:       ${POSTGRES_DB:-erp_db}
      POSTGRES_USER:     ${POSTGRES_USER:-erp_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-erp_pass_local}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-erp_user}"]
      interval: 5s
      timeout: 5s
      retries: 10

  web:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "8000:8000"
    depends_on:
      db:
        condition: service_healthy
    env_file:
      - .env
    environment:
      DJANGO_SETTINGS_MODULE: core.settings_prod
      DATABASE_URL: postgresql://${POSTGRES_USER:-erp_user}:${POSTGRES_PASSWORD:-erp_pass_local}@db:5432/${POSTGRES_DB:-erp_db}

volumes:
  postgres_data:
  static_volume:
  media_volume:
```

---

## 8. Build y Arranque Local — Verificar WeasyPrint en el Contenedor

### 8.1 Construir la imagen

```cmd
:: Desde la raíz del proyecto (donde está el Dockerfile)
docker-compose build --no-cache web
```

**El build tarda ~3-5 minutos la primera vez** (descarga la imagen base,
instala las librerías nativas y los paquetes Python). En builds
subsecuentes, Docker usa el caché y tarda ~10-30 segundos.

Salida esperada al final:
```
 => [app 4/4] COPY . .
 => exporting to image
 => => writing image sha256:abc123...
 => => naming to docker.io/library/erp_web
✓ Built
```

### 8.2 Arrancar todos los servicios

```cmd
docker-compose up -d
```

Verificar que todos los servicios están saludables:

```cmd
docker-compose ps
```

**Resultado esperado:**
```
NAME        SERVICE   STATUS    PORTS
erp-db-1    db        running   0.0.0.0:5432->5432/tcp
erp-web-1   web       running   0.0.0.0:8000->8000/tcp
```

### 8.3 Verificar que WeasyPrint tiene acceso a todas sus librerías

```cmd
docker-compose exec web python -c "
import weasyprint
print('WeasyPrint version:', weasyprint.__version__)

# Verificar que puede generar un PDF mínimo
from weasyprint import HTML
pdf = HTML(string='<h1>Prueba WeasyPrint</h1><p>ERP Django UTEC</p>').write_pdf()
print('PDF generado:', len(pdf), 'bytes')
print('Primeros bytes (debe ser %PDF):', pdf[:4])
"
```

**Resultado esperado:**
```
WeasyPrint version: 60.2
PDF generado: 1423 bytes
Primeros bytes (debe ser %PDF): b'%PDF'
```

Si ves este resultado, WeasyPrint está completamente funcional dentro
del contenedor con todas sus dependencias nativas disponibles.

### 8.4 Ver los logs del contenedor web

```cmd
docker-compose logs -f web
```

Buscar estas líneas que confirman la inicialización:
```
==> [entrypoint] Ejecutando migraciones de base de datos...
Operations to perform: Apply all migrations...
...OK
==> [entrypoint] Recolectando archivos estáticos...
...
==> [entrypoint] Verificando y creando superusuario...
==> [entrypoint] Iniciando Gunicorn en 0.0.0.0:10000...
[INFO] Listening at: http://0.0.0.0:10000      ← el puerto lo asigna Render ($PORT)
```

---

### 8.5 Diagnóstico: los contenedores corren pero `http://127.0.0.1:8000` no responde

> **Este es el síntoma más reportado al implementar esta guía en aula:**
> `docker-compose ps` muestra todos los servicios en `Up`/`running`,
> los logs de `web` muestran `Listening at: http://0.0.0.0:8000` sin
> errores, pero el navegador no carga la página (se queda cargando
> indefinidamente, o muestra "No se puede acceder a este sitio web" /
> "ERR_CONNECTION_REFUSED"). Esto **no es un error de Django ni de
> WeasyPrint** — es un problema de red entre WSL2 y Windows. Seguir
> este diagnóstico en el orden exacto en que aparece.

---

**Paso 1 — Confirmar que el contenedor sigue arriba (no se reinició)**

```cmd
docker-compose ps
```

Ver la columna `STATUS`. Debe decir `Up X minutes`, no `Restarting`
ni `Exited`. Si dice `Restarting`, el contenedor se está cayendo
después de arrancar — ese es un problema distinto (ver los logs
completos con `docker-compose logs web` para encontrar el traceback
de Python, generalmente relacionado con una variable de entorno
faltante o un error de migración).

---

**Paso 2 — Probar la conexión DESDE DENTRO del contenedor**

```cmd
docker-compose exec web curl -I http://localhost:8000/
```

**Si esto responde** (por ejemplo `HTTP/1.1 200 OK` o `302 Found`),
Gunicorn está funcionando correctamente **dentro** del contenedor.
El problema está 100% confirmado como de red WSL2 ↔ Windows —
saltar directo al **Paso 4**.

**Si esto NO responde** (curl se queda colgado o da error de conexión),
el problema es que Gunicorn no está escuchando correctamente. Ir al
**Paso 3**.

---

**Paso 3 — Verificar que Gunicorn escucha en `0.0.0.0`, no en `127.0.0.1`**

```cmd
docker-compose exec web cat docker-entrypoint.sh
```

Confirmar que la última línea usa exactamente:
```bash
exec gunicorn core.wsgi --bind 0.0.0.0:${PORT:-8000} ...
```

> **Error común #4:** cambiar `--bind 0.0.0.0:8000` por
> `--bind 127.0.0.1:8000` (por ejemplo, copiando instrucciones de un
> tutorial genérico). Dentro de un contenedor Docker, `127.0.0.1`
> solo es visible **dentro** del propio contenedor — Docker no puede
> reenviar el puerto hacia Windows si Gunicorn no escucha en todas
> las interfaces (`0.0.0.0`). Si el archivo local difiere del que
> aparece en esta guía (Parte 5), corregirlo, guardar, y reconstruir:
> ```cmd
> docker-compose build --no-cache web
> docker-compose up -d web
> ```

---

**Paso 4 — Probar con `localhost` en lugar de `127.0.0.1` (o viceversa)**

```
http://localhost:8000/
```

En algunos equipos con Windows, el navegador resuelve `127.0.0.1`
por IPv4 y `localhost` puede resolver primero por IPv6 (`::1`) —
Docker Desktop en WSL2 no siempre reenvía ambos protocolos por igual.
Probar la URL alternativa (`localhost` si estabas usando `127.0.0.1`,
o viceversa) antes de continuar con pasos más invasivos.

---

**Paso 5 — Reiniciar la red de WSL2 (soluciona la mayoría de los casos)**

Cerrar Docker Desktop completamente:
```
Clic derecho en el ícono de la ballena (bandeja del sistema) → Quit Docker Desktop
```

En PowerShell (no necesita ser Administrador):
```powershell
wsl --shutdown
```

Esperar 15 segundos. Volver a abrir Docker Desktop y esperar a que
el ícono de la ballena quede fijo (no animado). Luego:

```cmd
docker-compose up -d
```

Probar de nuevo `http://localhost:8000/` en el navegador.

> Este paso resuelve el problema en la gran mayoría de los casos
> reportados en aula. El reinicio de `wsl --shutdown` fuerza a
> Windows a reconstruir el puente de red (`vEthernet (WSL)`) que
> Docker Desktop usa para reenviar los puertos.

---

**Paso 6 — Verificar el archivo `.wslconfig`**

```powershell
notepad $env:USERPROFILE\.wslconfig
```

Si el archivo existe y contiene la línea:
```ini
[wsl2]
localhostForwarding=false
```

**esto es la causa exacta del problema.** Cambiarla a `true` o
eliminar la línea completa (el valor por defecto ya es `true`),
guardar, y repetir el Paso 5 (`wsl --shutdown` + reabrir Docker Desktop).

Si el archivo no existe, no es necesario crearlo — el valor por
defecto de Windows ya tiene el reenvío de `localhost` activado.

---

**Paso 7 — Verificar que el puerto 8000 no está ocupado en Windows**

```cmd
netstat -ano | findstr :8000
```

Si aparece una línea con un PID que **no** corresponde a Docker,
otro proceso de Windows (otro servidor Django corriendo con
`runserver`, otro contenedor, IIS, etc.) está usando el puerto 8000.

Solución A — cerrar ese proceso:
```cmd
taskkill /PID <numero_de_pid> /F
```

Solución B — usar otro puerto para este proyecto, editando
`docker-compose.yml`:
```yaml
services:
  web:
    ports:
      - "8080:8000"   # host:contenedor — usar 8080 en el navegador
```
Y luego acceder a `http://localhost:8080/` en su lugar.

---

**Paso 8 — Verificar el Firewall de Windows**

```
Panel de Control → Sistema y seguridad → Firewall de Windows Defender
→ "Permitir una aplicación a través del firewall"
→ Buscar "Docker Desktop Backend" → verificar casillas en
  "Privada" y "Pública" marcadas
```

Si Docker Desktop no aparece en la lista, hacer clic en
"Cambiar configuración" → "Permitir otra aplicación" → buscar
`Docker Desktop.exe` (usualmente en
`C:\Program Files\Docker\Docker\Docker Desktop.exe`) → Agregar.

---

**Paso 9 — Restablecimiento completo (último recurso)**

Si ninguno de los pasos anteriores resolvió el problema:

```cmd
docker-compose down -v
```

Docker Desktop → Settings → **Troubleshoot** → **Clean / Purge data**
(esto borra imágenes y contenedores locales, no el código del proyecto).

Reiniciar Windows completamente (no solo Docker Desktop).

Al volver a arrancar:
```cmd
docker-compose build --no-cache
docker-compose up -d
```

Repetir la prueba de humo de Nginx de la **Sección 2.7** antes de
continuar con el proyecto. Si Nginx tampoco responde en este punto,
el problema es de la instalación de WSL2/Docker Desktop en el
equipo, no del proyecto — repasar la Sección 2 completa desde el inicio.

---

### 8.6 Checklist rápido de la Sección 8

```
[ ] docker-compose ps → todos los servicios en "Up", ninguno "Restarting"
[ ] docker-compose exec web curl -I http://localhost:8000/ → responde 200/302
[ ] docker-entrypoint.sh usa --bind 0.0.0.0:${PORT:-8000} (no 127.0.0.1)
[ ] Probado tanto http://localhost:8000 como http://127.0.0.1:8000
[ ] wsl -l -v muestra docker-desktop y docker-desktop-data en VERSION 2
[ ] wsl --shutdown + reabrir Docker Desktop ejecutado al menos una vez
[ ] .wslconfig no tiene localhostForwarding=false
[ ] Puerto 8000 no está ocupado por otro proceso de Windows
[ ] Docker Desktop tiene permiso en el Firewall de Windows
[ ] La prueba de humo de Nginx (Sección 2.7) responde correctamente
```

---

## 9. Template `factura_pdf.html` Mejorado con WeasyPrint

### 9.1 Ventajas de CSS que SOLO WeasyPrint soporta

```css
/* @page: controla el tamaño y los márgenes de CADA página del PDF */
@page {
    size: A4 portrait;
    margin: 2.5cm 2cm 3cm;  /* top right bottom — bottom mayor para pie de página */

    /* running element: el encabezado se repite en CADA página */
    @top-center { content: element(encabezado-pdf); }

    /* pie de página con número de página */
    @bottom-right {
        content: "Página " counter(page) " de " counter(pages);
        font-size: 9pt;
        color: #5A6A7E;
    }
    @bottom-left {
        content: string(nombre-empresa);
        font-size: 9pt;
        color: #5A6A7E;
    }
}
```

Nada de esto funciona en xhtml2pdf. En WeasyPrint funciona
de fábrica cuando el HTML está dentro de un contenedor Docker
con las librerías correctas.

---

### 9.2 Reemplazar `ventas/templates/ventas/factura_pdf.html`

> **Limitaciones de WeasyPrint 60.x que afectan a esta plantilla:**
> - `var(--color)` dentro de propiedades abreviadas (`border`, `background`)
>   se descarta con el aviso `Ignored ... invalid value`: la factura sale sin
>   colores ni bordes. Por eso los colores van escritos directamente.
> - `gap` no se reconoce (`unknown property`); se usan márgenes.
> - La imagen Docker no trae fuente de emojis; no usar emojis en el PDF.
> - `{% widthratio %}` redondea a entero: el IVA y el TOTAL se calculan en
>   la vista con `Decimal` (Sección 10.2).

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Factura {{ pedido.numero_pedido|default:venta.pk }}</title>
    <style>
        /* ── Paleta Fable 5 AzulERP ─────────────────────────────────
           WeasyPrint 60.x no resuelve var() dentro de propiedades
           abreviadas (border, background), así que los colores van fijos:
           navy #0A2342 · gold #B8860B · sky #4A90D9 · ice #E8F0FB
           muted #5A6A7E · text #1A1A2E                              */

        /* ── Configuración de página ──────────────────────────────── */
        @page {
            size: A4 portrait;
            margin: 2cm 2cm 3cm 2cm;

            /* Encabezado de empresa en cada página (excepto la primera) */
            @top-left {
                content: element(header-running);
                margin-top: .5cm;
            }

            /* Número de página en el pie */
            @bottom-right {
                content: "Página " counter(page) " de " counter(pages);
                font-family: Arial, sans-serif;
                font-size: 8.5pt;
                color: #5A6A7E;
                border-top: 1px solid #C8D8EC;
                padding-top: .3cm;
            }

            /* Nombre de empresa en el pie izquierdo */
            @bottom-left {
                content: string(empresa-nombre);
                font-family: Arial, sans-serif;
                font-size: 8.5pt;
                color: #5A6A7E;
                border-top: 1px solid #C8D8EC;
                padding-top: .3cm;
            }
        }

        /* Primera página: sin encabezado (ya tiene el bloque header completo) */
        @page :first {
            @top-left { content: none; }
        }

        /* ── Reset base ─────────────────────────────────────────── */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: Arial, Helvetica, sans-serif;
            font-size: 10.5pt;
            color: #1A1A2E;
            line-height: 1.5;
        }

        /* ── Elemento de running (encabezado en páginas 2+) ───────── */
        #header-running {
            position: running(header-running);
            display: flex;
            align-items: center;
            border-bottom: 2px solid #B8860B;
            padding-bottom: .3cm;
        }
        #header-running .empresa { font-weight: bold; margin-right: 12px; color: #0A2342; }
        #header-running .folio   { margin-left: auto; color: #B8860B; font-weight: bold; }

        /* String para el pie izquierdo */
        #empresa-string { string-set: empresa-nombre content(); }

        /* ── ENCABEZADO (primera página) ───────────────────────────── */
        .header {
            background: #0A2342;
            color: #FFFFFF;
            padding: 18px 24px;
            border-bottom: 4px solid #B8860B;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
        }
        .header-logo {
            width: 64px;
            height: 64px;
            object-fit: contain;
            margin-right: 16px;
            border-radius: 8px;
            background: rgba(255,255,255,.08);
        }
        .header-logo-placeholder {
            width: 64px;
            height: 64px;
            border-radius: 8px;
            background: rgba(255,255,255,.12);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            margin-right: 16px;
        }
        .header-title { font-size: 22pt; font-weight: bold; color: #B8860B; }
        .header-empresa { color: rgba(255,255,255,.78); font-size: 10pt; margin-top: 2px; }
        .header-folio {
            margin-left: auto;
            text-align: right;
        }
        .header-folio .folio-num { font-size: 15pt; font-weight: bold; color: #B8860B; }
        .header-folio .folio-fech { color: rgba(255,255,255,.68); font-size: 9pt; }

        /* ── SECCIÓN DE DATOS DEL CLIENTE ──────────────────────────── */
        .datos-section { margin-bottom: 18px; }
        .datos-tabla {
            width: 100%;
            border-collapse: collapse;
        }
        .datos-tabla td {
            padding: 5px 9px;
            font-size: 9.5pt;
            border: 1px solid #E8F0FB;
        }
        .datos-tabla .lbl {
            background: #E8F0FB;
            font-weight: bold;
            color: #0A2342;
            width: 28%;
        }

        /* ── TABLA DE PRODUCTOS ─────────────────────────────────────── */
        .productos-tabla {
            width: 100%;
            border-collapse: collapse;
            margin: 18px 0;
            /* WeasyPrint: repetir thead en cada nueva página */
            border-spacing: 0;
        }
        /* La propiedad que hace que WeasyPrint repita la cabecera */
        thead { display: table-header-group; }
        tfoot { display: table-footer-group; }

        .productos-tabla thead th {
            background: #0A2342;
            color: #FFFFFF;
            padding: 8px 11px;
            font-size: 9pt;
            text-align: left;
            text-transform: uppercase;
            letter-spacing: .04em;
            border-bottom: 3px solid #B8860B;
        }
        .productos-tabla thead th.num { text-align: right; }
        .productos-tabla tbody td {
            padding: 7px 11px;
            font-size: 9.5pt;
            border-bottom: 1px solid #E8F0FB;
            /* Evitar cortar una fila entre dos páginas */
            page-break-inside: avoid;
        }
        .productos-tabla tbody td.num { text-align: right; }
        .productos-tabla tbody tr:nth-child(even) td { background: #F8FAFD; }

        /* ── TOTALES ───────────────────────────────────────────────── */
        .total-section { margin-top: 12px; }
        .total-tabla { width: 50%; margin-left: 50%; border-collapse: collapse; }
        .total-tabla td {
            padding: 6px 10px;
            font-size: 9.5pt;
            border: 1px solid #E8F0FB;
        }
        .total-tabla .lbl {
            background: #E8F0FB;
            font-weight: bold;
            color: #0A2342;
        }
        .total-tabla .val { text-align: right; }
        .total-tabla tr.final td {
            background: #FDF8E8;
            border-top: 2px solid #B8860B;
            font-weight: bold;
            font-size: 11.5pt;
        }
        .total-tabla .val.gold { color: #B8860B; font-size: 12.5pt; }

        /* ── NOTA LEGAL / PIE ─────────────────────────────────────── */
        .nota {
            margin-top: 24px;
            padding: 12px 16px;
            border-left: 4px solid #4A90D9;
            background: #F5F9FF;
            font-size: 8.5pt;
            color: #5A6A7E;
            /* No cortar la nota entre páginas */
            page-break-inside: avoid;
        }
    </style>
</head>
<body>

<!--
    Elemento de running: aparece en el encabezado de las páginas 2, 3, ...
    WeasyPrint lo extrae del flujo normal y lo repite en @top-left de @page.
-->
<div id="header-running">
    <span class="empresa">{{ config.nombre_empresa }}</span>
    {% if config.rfc %}<span style="color:#5A6A7E;font-size:8.5pt;">RFC: {{ config.rfc }}</span>{% endif %}
    <span class="folio">Factura #{{ venta.pk|stringformat:"05d" }}</span>
</div>

<!-- String invisible para el pie de página izquierdo -->
<span id="empresa-string">{{ config.nombre_empresa }}</span>

<!-- ── ENCABEZADO PRIMERA PÁGINA ───────────────────────────────── -->
<div class="header">
    {% if config.logo %}
        <!--
            base_url en weasyprint.HTML() resuelve esta URL relativa.
            Sin base_url, WeasyPrint no encontraría el archivo de imagen.
        -->
        <img class="header-logo" src="{{ config.logo.url }}" alt="Logo">
    {% else %}
        <div class="header-logo-placeholder">ERP</div>
    {% endif %}

    <div>
        <div class="header-title">FACTURA</div>
        <div class="header-empresa">{{ config.nombre_empresa }}</div>
        {% if config.rfc %}
        <div class="header-empresa" style="font-size:9pt;">RFC: {{ config.rfc }}</div>
        {% endif %}
    </div>

    <div class="header-folio">
        <div class="folio-num"># {{ venta.pk|stringformat:"05d" }}</div>
        <div class="folio-fech"> {{ venta.fecha|date:"d/m/Y" }}</div>
    </div>
</div>

<!-- ── DATOS DEL CLIENTE ────────────────────────────────────────── -->
<div class="datos-section">
    <table class="datos-tabla">
        <tr>
            <td class="lbl">Cliente</td>
            <td>{{ venta.cliente.nombre }}</td>
            <td class="lbl">Correo</td>
            <td>{{ venta.cliente.correo }}</td>
        </tr>
        <tr>
            <td class="lbl">Teléfono</td>
            <td>{{ venta.cliente.telefono|default:"—" }}</td>
            <td class="lbl">Moneda</td>
            <td>{{ config.moneda }}</td>
        </tr>
        <tr>
            <td class="lbl">Fecha de emisión</td>
            <td>{{ venta.fecha|date:"d/m/Y" }}</td>
            <td class="lbl">IVA</td>
            <td>{{ config.iva_porcentaje }}%</td>
        </tr>
    </table>
</div>

<!-- ── TABLA DE PRODUCTOS ────────────────────────────────────────── -->
<table class="productos-tabla">
    <thead>
        <tr>
            <th style="width:4%">#</th>
            <th style="width:40%">Producto</th>
            <th class="num" style="width:16%">Precio unit.</th>
            <th class="num" style="width:10%">Cant.</th>
            <th class="num" style="width:14%">Subtotal</th>
        </tr>
    </thead>
    <tbody>
        {% for detalle in venta.detalles.all %}
        <tr>
            <td>{{ forloop.counter }}</td>
            <td>{{ detalle.producto.nombre }}</td>
            <td class="num">${{ detalle.precio_unitario }}</td>
            <td class="num">{{ detalle.cantidad }}</td>
            <td class="num">${{ detalle.subtotal }}</td>
        </tr>
        {% empty %}
        <tr>
            <td colspan="5" style="text-align:center;padding:16px;color:#5A6A7E;">
                Sin líneas de detalle registradas.
            </td>
        </tr>
        {% endfor %}
    </tbody>
</table>

<!-- ── TOTALES ───────────────────────────────────────────────────── -->
<div class="total-section">
    <table class="total-tabla">
        {# subtotal, iva y total_con_iva vienen calculados desde la vista #}
        <tr>
            <td class="lbl">Subtotal (sin IVA)</td>
            <td class="val">${{ subtotal }}</td>
        </tr>
        <tr>
            <td class="lbl">IVA ({{ config.iva_porcentaje }}%)</td>
            <td class="val">${{ iva }}</td>
        </tr>
        <tr class="final">
            <td class="lbl" style="font-size:11.5pt;">TOTAL</td>
            <td class="val gold">${{ total_con_iva }}</td>
        </tr>
    </table>
</div>

<!-- ── NOTA LEGAL ─────────────────────────────────────────────────── -->
<div class="nota">
    <strong>Nota:</strong> Este documento es una representación de la factura generada por
    el sistema ERP Django de {{ config.nombre_empresa }}.
    {% if config.rfc %}RFC: {{ config.rfc }}.{% endif %}
    Generado el {{ hoy|date:"d/m/Y" }}.
</div>

</body>
</html>
```

---

## 10. Actualizar `venta_pdf()` en `ventas/views.py`

### 10.1 Diferencia crítica: `base_url` en WeasyPrint

```python
# xhtml2pdf — no necesita base_url, busca archivos en el sistema de archivos
pisa.CreatePDF(src=html_string, dest=buffer)

# WeasyPrint — NECESITA base_url para resolver rutas de imágenes
# Sin base_url, los <img src="/media/productos/logo.jpg"> no se encuentran
weasyprint.HTML(
    string=html_string,
    base_url=request.build_absolute_uri('/'),  # → 'https://mi-app.onrender.com/'
    url_fetcher=_url_fetcher_local,            # lee /static/ y /media/ desde disco
).write_pdf()
```

`request.build_absolute_uri('/')` devuelve la URL raíz del servidor
(ej: `http://localhost:8000/`). WeasyPrint la usa como base para
resolver todas las rutas relativas de imágenes en el HTML.

Sin `url_fetcher`, WeasyPrint **descarga por HTTP** cada imagen desde el
mismo servidor que está generando el PDF. Con 2 workers de Gunicorn eso es
lento y puede bloquearse, y si el logo se perdió (el disco de Render se
borra en cada deploy) la petición falla. `_url_fetcher_local` lee esos
archivos directamente del disco y, si no existen, WeasyPrint solo omite
la imagen.

---

### 10.2 Reemplazar la vista `venta_pdf` en `ventas/views.py`

```python
# ventas/views.py — imports necesarios (además de los existentes):
import mimetypes
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path
from urllib.parse import unquote, urlparse

from django.contrib.auth.decorators import login_required
from django.contrib.staticfiles import finders
from django.http.request import validate_host
from django.utils import timezone

import weasyprint


# ventas/views.py — agregar las funciones auxiliares y reemplazar venta_pdf:

def _ruta_local(url_path: str) -> Path | None:
    """Traduce /static/... o /media/... a un archivo en disco (o None)."""
    static_prefix = "/" + settings.STATIC_URL.lstrip("/")
    media_prefix = "/" + settings.MEDIA_URL.lstrip("/")

    if url_path.startswith(static_prefix):
        relativa = url_path[len(static_prefix):]
        candidata = Path(settings.STATIC_ROOT) / relativa
        if candidata.is_file():
            return candidata
        encontrada = finders.find(relativa)  # útil en desarrollo, sin collectstatic
        return Path(encontrada) if encontrada else None

    if url_path.startswith(media_prefix):
        raiz = Path(settings.MEDIA_ROOT).resolve()
        candidata = (raiz / url_path[len(media_prefix):]).resolve()
        # Evita salir de MEDIA_ROOT con rutas tipo ../
        if raiz in candidata.parents and candidata.is_file():
            return candidata
    return None


def _url_fetcher_local(url: str, timeout: int = 10, ssl_context=None):
    """url_fetcher de WeasyPrint que lee /static/ y /media/ desde disco.

    Evita que WeasyPrint haga peticiones HTTP al propio servidor (lento y
    puede bloquear a los workers de Gunicorn). Si el archivo no existe
    (p. ej. un logo perdido por el disco efímero de Render), se lanza
    FileNotFoundError: WeasyPrint solo registra un aviso y omite la imagen.
    Las URLs externas (p. ej. media en S3) usan el fetcher por defecto.
    """
    parsed = urlparse(url)
    if parsed.scheme in ("http", "https", "file"):
        ruta = _ruta_local(unquote(parsed.path))
        if ruta is not None:
            return {
                "string": ruta.read_bytes(),
                "mime_type": mimetypes.guess_type(ruta.name)[0],
                "filename": ruta.name,
            }
        propio = validate_host(
            parsed.hostname or "", ["localhost", "127.0.0.1", *settings.ALLOWED_HOSTS]
        )
        if parsed.scheme == "file" or propio:
            raise FileNotFoundError(url)
    return weasyprint.default_url_fetcher(url, timeout=timeout, ssl_context=ssl_context)


def calcular_totales(subtotal, iva_porcentaje) -> dict:
    """Subtotal, IVA y total con 2 decimales (redondeo comercial).

    Venta.total es la suma de las líneas SIN IVA; el IVA se suma aparte.
    Ejemplo: calcular_totales(Decimal("3000"), Decimal("16"))
             -> subtotal 3000.00, iva 480.00, total 3480.00
    """
    centavos = Decimal("0.01")
    subtotal = Decimal(subtotal).quantize(centavos, ROUND_HALF_UP)
    iva = (subtotal * Decimal(iva_porcentaje) / 100).quantize(centavos, ROUND_HALF_UP)
    return {"subtotal": subtotal, "iva": iva, "total_con_iva": subtotal + iva}


@login_required
def venta_pdf(request, venta_id: int) -> HttpResponse:
    """Genera y descarga la factura de una venta en formato PDF.

    Motor: WeasyPrint (requiere entorno Linux o contenedor Docker).

    Args:
        request: HttpRequest de Django.
        venta_id: ID de la venta a generar.

    Returns:
        HttpResponse con Content-Type application/pdf y descarga directa.
    """

    venta = get_object_or_404(
        Venta.objects.select_related("cliente").prefetch_related(
            "detalles__producto__categoria"
        ),
        pk=venta_id,
    )
    config = ConfiguracionERP.get_instance()
    context = {
        "venta": venta,
        "config": config,
        "hoy": timezone.localdate(),  # fecha en TIME_ZONE (America/Mexico_City)
        **calcular_totales(venta.total, config.iva_porcentaje),
    }

    html_string = render_to_string("ventas/factura_pdf.html", context, request=request)

    # ── WeasyPrint: conversión HTML → PDF ─────────────────────────────
    # base_url resuelve rutas relativas como /media/... o /static/...
    # y _url_fetcher_local las lee del disco en vez de pedirlas por HTTP.
    pdf_bytes = weasyprint.HTML(
        string=html_string,
        base_url=request.build_absolute_uri("/"),
        url_fetcher=_url_fetcher_local,
    ).write_pdf()

    response = HttpResponse(pdf_bytes, content_type="application/pdf")
    response["Content-Disposition"] = (
        f'attachment; filename="factura_{venta.pk:05d}.pdf"'
    )
    return response
```

---

## 11. Probar el PDF en Local vía Docker

### 11.1 Acceder a la aplicación

Con todos los contenedores arriba:

```
http://localhost:8000/admin/   → crear datos de prueba si no existen
http://localhost:8000/ventas/  → lista de ventas
http://localhost:8000/ventas/1/pdf/ → descargar factura en PDF
```

### 11.2 Prueba directa desde el contenedor (sin navegador)

```cmd
docker-compose exec web python manage.py shell -c "
import weasyprint

# Generar un PDF de prueba con logo embebido
html = '''
<html>
<head>
<style>
@page { size: A4; margin: 2cm; }
body { font-family: Arial; }
h1 { color: #0A2342; border-bottom: 3px solid #B8860B; padding-bottom: .5rem; }
p.num::after { content: counter(page) ' de ' counter(pages); }
</style>
</head>
<body>
<h1>ERP Django — UTEC Celaya</h1>
<p>Prueba de generación PDF con WeasyPrint 60.x</p>
<p>Página: <span class=num></span></p>
</body>
</html>
'''
pdf = weasyprint.HTML(string=html).write_pdf()
with open('/tmp/prueba_weasyprint.pdf', 'wb') as f:
    f.write(pdf)
print('PDF guardado en /tmp/prueba_weasyprint.pdf')
print('Tamaño:', len(pdf), 'bytes')
"
```

Para copiar el PDF al host y abrirlo:

```cmd
docker cp erp-web-1:/tmp/prueba_weasyprint.pdf C:\Temp\prueba_weasyprint.pdf
start C:\Temp\prueba_weasyprint.pdf
```

---

## 12. Despliegue a Render con Docker

### 12.1 Migrar `render.yaml` de Buildpack a Docker

El `render.yaml` original usaba el buildpack de Python. Para usar el
Dockerfile con las dependencias nativas, se migra a `runtime: docker`
(`env: docker` es el nombre anterior de la misma opción).

En W12 el Blueprint declara solo el servicio web y PostgreSQL. Redis y
los workers de Celery se agregan en W16+; Render no ofrece plan gratuito
para *background workers*.

```yaml
# render.yaml — Blueprint de Render (alcance W12: web Docker + PostgreSQL)
# Documentación: https://render.com/docs/blueprint-spec
#
# Fuera de alcance hasta su semana (no tienen código todavía):
#   W13+  Stripe / SendGrid (variables de entorno)
#   W16+  Redis, Celery worker/beat, Flower
#         Nota: Render NO tiene plan gratuito para background workers.

services:
  - type: web
    name: erp-django-utec            # debe coincidir con el servicio en Render
    runtime: docker                 # imagen con Pango/Cairo para WeasyPrint
    dockerfilePath: ./Dockerfile
    dockerContext: .
    plan: free
    region: oregon
    healthCheckPath: /              # pública; responde sin login
    # El ENTRYPOINT del Dockerfile migra, recolecta estáticos y arranca
    # Gunicorn en 0.0.0.0:$PORT, así que no hace falta startCommand.
    envVars:
      - key: DJANGO_SETTINGS_MODULE
        value: core.settings_prod
      - key: SECRET_KEY
        generateValue: true
      - key: DEBUG
        value: "False"
      - key: ALLOWED_HOSTS
        value: ".onrender.com"
      - key: DATABASE_URL
        fromDatabase:
          name: erp-django-db
          property: connectionString
      # Media en S3 (W11, opcional). Sin bucket se usa el disco efímero.
      - key: AWS_ACCESS_KEY_ID
        sync: false
      - key: AWS_SECRET_ACCESS_KEY
        sync: false
      - key: AWS_STORAGE_BUCKET_NAME
        sync: false

databases:
  - name: erp-django-db
    plan: free
    region: oregon
    databaseName: erp_db
    user: erp_user
```

---

> **Proxy HTTPS de Render.** Render recibe HTTPS y reenvía la petición al
> contenedor por HTTP con la cabecera `X-Forwarded-Proto`. Agregar en
> `core/settings_prod.py`, junto a `SECURE_SSL_REDIRECT`:
>
> ```python
> SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
> ```

### 12.2 Push y despliegue automático

```cmd
git add .
git commit -m "W12-WeasyPrint: Dockerfile + entrypoint + render.yaml docker + factura_pdf mejorada"
git push origin main
```

Render detecta el push automáticamente y:
1. **Build:** ejecuta `docker build` con el `Dockerfile`
2. **Start:** ejecuta el `ENTRYPOINT` (docker-entrypoint.sh)
3. Dentro del entrypoint: `migrate` → `collectstatic` → `gunicorn`

### 12.3 Monitorear el despliegue en Render

1. Ir a `dashboard.render.com`
2. Seleccionar el servicio `erp-django-utec`
3. Pestaña **Logs** → seguir el despliegue en tiempo real

**Líneas clave que buscar:**
```
==> Building Docker image...
Step X: RUN apt-get install -y ... libpango-1.0-0 libcairo2 ...
Step X: RUN pip install ... weasyprint==60.2 ... pydyf-0.10.0
==> Build successful

==> Starting service with Dockerfile entrypoint...
==> [entrypoint] Ejecutando migraciones de base de datos...
...OK
==> [entrypoint] Recolectando archivos estáticos...
...
==> [entrypoint] Iniciando Gunicorn...
[INFO] Listening at: http://0.0.0.0:8000
```

---

## 13. Verificación en Producción + Troubleshooting

### 13.1 Verificar el PDF en producción

```
[ ] https://erp-django-utec.onrender.com/accounts/login/ → login
[ ] https://erp-django-utec.onrender.com/ventas/1/pdf/ → descarga PDF
[ ] Abrir PDF → encabezado con logo (si está configurado)
[ ] Abrir PDF → número de página en el pie ("Página 1 de 1")
[ ] Si hay muchas líneas → verificar que el thead se repite en página 2
```

---

### 13.2 Troubleshooting — Errores Comunes de WeasyPrint en Docker

> **Antes de continuar:** los errores de esta sección son específicos
> de la **generación del PDF** (el sitio carga, el login funciona, pero
> al pedir la factura algo falla). Si en cambio el problema es que
> **el sitio completo no carga** (`http://127.0.0.1:8000` no responde,
> aunque `docker-compose ps` muestre los contenedores como `Up`), ese
> es un problema de red WSL2 ↔ Windows, no de WeasyPrint — volver a la
> **Sección 8.5** de esta guía, que cubre exactamente ese síntoma.

---

**Error 1: `OSError: no library called "cairo" was found`**

```
OSError: no library called "cairo" was found
```

**Causa:** `libcairo2` no está instalado en el contenedor o el entorno Python
no puede encontrar las librerías compartidas del sistema.

**Solución:** verificar que el `Dockerfile` incluye `libcairo2` y `libcairo-gobject2`:
```dockerfile
RUN apt-get install -y --no-install-recommends libcairo2 libcairo-gobject2 ...
```

Luego reconstruir la imagen:
```cmd
docker-compose build --no-cache web
docker-compose up -d web
```

---

**Error 2: `OSError: no library called "pango-1.0" was found`**

**Causa:** `libpango-1.0-0` no está instalado.

**Solución:** mismo procedimiento, verificar el `apt-get install` en el `Dockerfile`.

---

**Error 3: `libgdk_pixbuf-2.0.so.0: cannot open shared object file`**

**Causa:** En Debian Bookworm (versión más nueva), el nombre del paquete
cambió ligeramente en algunas configuraciones.

**Solución:** instalar las dos variantes del nombre:
```dockerfile
libgdk-pixbuf-2.0-0 \
libgdk-pixbuf2.0-0 \
```
Una de las dos existirá según la versión exacta de Debian.

---

**Error 4: `fontconfig: No writable cache directories`**

```
Fontconfig warning: "/etc/fonts/fonts.conf", line X: ...
Fontconfig error: No writable cache directories
```

**Causa:** el proceso no tiene permisos para escribir el caché de fuentes.

**Solución:** agregar al Dockerfile, después de instalar las fuentes:
```dockerfile
RUN fc-cache -f -v 2>/dev/null && chmod -R 777 /var/cache/fontconfig 2>/dev/null || true
```

---

**Error 5: Imágenes en blanco (logo no aparece) en producción**

**Causa:** en producción con S3, la URL del logo es absoluta
(`https://bucket.s3.amazonaws.com/...`) y WeasyPrint necesita acceso
a Internet para descargarla.

**Solución en producción:** verificar que el worker de Render tiene acceso
a la URL del bucket S3. En desarrollo local con Docker, la URL es
relativa (`/media/...`) y se resuelve via `base_url='http://web:8000/'`.

Para la red interna de Docker:
```python
# En vista venta_pdf, dentro del contenedor Docker:
base_url = 'http://web:8000/'   # nombre del servicio en docker-compose
# En lugar de request.build_absolute_uri('/') que daría http://localhost:8000/
```

Solución definitiva (funciona en todos los entornos):
```python
# Usar BASE_URL de settings para tener consistencia
base_url = getattr(settings, 'SITE_DOMAIN', request.build_absolute_uri('/'))
```

---

**Error 6: `django.core.exceptions.ImproperlyConfigured: WeasyPrint is not available`**

**Causa:** se intenta importar WeasyPrint fuera del contenedor (en el
entorno USB/Windows nativo de aula).

**Solución:** asegurarse de ejecutar la generación de PDF siempre dentro
del contenedor Docker, no desde el entorno virtual nativo de Windows.
Ver la sección 8.3 de esta guía.

---

**Error 7: PDF genera pero está en blanco o con CSS incorrecto**

**Causa:** el template usa clases CSS de Bootstrap que se cargan vía CDN.
WeasyPrint intenta descargar el CSS del CDN durante la generación
del PDF; si no hay Internet o el CDN falla, el CSS se ignora.

**Solución:** el template `factura_pdf.html` de esta guía usa EXCLUSIVAMENTE
CSS inline en la etiqueta `<style>`, sin importar nada del CDN.
Verificar que no se heredó base.html (que sí carga Bootstrap del CDN).

---

**Error 8: `TypeError: PDF.__init__() takes 1 positional argument but 3 were given`**

```
File ".../weasyprint/pdf/__init__.py", line 127, in generate_pdf
    pdf = pydyf.PDF((version or '1.7'), identifier)
TypeError: PDF.__init__() takes 1 positional argument but 3 were given
```

**Causa:** se instaló `pydyf` 0.11 o posterior, que cambió la API usada
por WeasyPrint 60.x. Ocurre si `requirements.txt` no fija `pydyf`.

**Diagnóstico:**
```cmd
docker-compose exec web pip show pydyf
```

**Solución:** agregar `pydyf==0.10.0` a `requirements.txt` (Sección 4) y
reconstruir con `docker-compose build web`. En Render basta con hacer push.

---

**Error 9: logs llenos de `weasyprint: Ignored ... var(--gold) ... invalid value`**

**Causa:** WeasyPrint 60.x no resuelve `var()` dentro de propiedades
abreviadas como `border` o `background`; las reglas se descartan y la
factura sale sin colores ni bordes.

**Solución:** escribir los colores directamente (plantilla de la Sección 9.2).

---

## 14. Tests del PDF — Ejecutados dentro del Contenedor Docker

### 14.1 ¿Por qué ejecutar los tests dentro del contenedor?

WeasyPrint NO está disponible fuera del contenedor en el entorno
de aula (USB Windows). Ejecutar los tests en el host fallaría con
`ImportError: No module named 'weasyprint'` o
`OSError: no library called "cairo" was found`.

La solución es ejecutar los tests **dentro** del contenedor.

> **Usar `core.settings` para los tests.** El servicio `web` arranca con
> `core.settings_prod`, que activa `SECURE_SSL_REDIRECT`: el cliente de
> pruebas usa HTTP y casi todas las vistas responderían 301 en lugar de
> 200/302. Por eso cada comando agrega
> `-e DJANGO_SETTINGS_MODULE=core.settings`.

> **Pruebas de regresión del PDF.** `tests/test_w12_pdf.py` cubre el
> comportamiento esperado de `/ventas/<id>/pdf/`: 302 sin login, 404 si la
> venta no existe, 200 con `application/pdf` y contenido que empieza con
> `%PDF`, un logo inexistente que no rompe el PDF, y el TOTAL con IVA.



```cmd
:: Ejecutar tests específicos de PDF dentro del contenedor web
docker-compose exec -e DJANGO_SETTINGS_MODULE=core.settings web python manage.py test tests.test_w12_documentos tests.test_w12_pdf --verbosity=2
```

### 14.2 Actualizar `tests/test_w12_documentos.py`

```python
"""Suite de pruebas W12 — WeasyPrint PDF y exportación Excel.

IMPORTANTE: Estos tests deben ejecutarse dentro del contenedor Docker
donde WeasyPrint y sus dependencias nativas están disponibles.

Ejecutar con:
    docker-compose exec -e DJANGO_SETTINGS_MODULE=core.settings web python manage.py test tests.test_w12_documentos tests.test_w12_pdf --verbosity=2

NO ejecutar directamente en el host Windows (faltarán las librerías nativas).

Resultado esperado:
    Ran 8 tests in X.XXXs
    OK
"""
from decimal import Decimal

from django.contrib.auth.models import User
from django.test import TestCase
from django.urls import reverse

from clientes.models      import Cliente
from configuracion.models import ConfiguracionERP
from productos.models     import Categoria, Producto
from ventas.models        import DetalleVenta, Venta


class VentaPDFWeasyPrintTest(TestCase):
    """Tests de la vista venta_pdf — motor WeasyPrint."""

    def setUp(self):
        ConfiguracionERP.get_instance()
        self.user = User.objects.create_user('pdfuser', password='pass')
        cat        = Categoria.objects.create(nombre='Cat PDF')
        prod       = Producto.objects.create(
            nombre='Producto PDF', precio=Decimal('500.00'),
            stock=5, categoria=cat
        )
        cli        = Cliente.objects.create(
            nombre='Cliente PDF', correo='pdf@test.com'
        )
        self.venta = Venta.objects.create(cliente=cli)
        DetalleVenta.objects.create(
            venta=self.venta, producto=prod,
            cantidad=2, precio_unitario=Decimal('500.00')
        )

    def test_pdf_sin_auth_redirige_a_login(self):
        """GET /ventas/<id>/pdf/ sin login → 302 al login."""
        r = self.client.get(
            reverse('ventas:pdf', args=[self.venta.pk])
        )
        self.assertEqual(r.status_code, 302)
        self.assertIn('/accounts/login/', r['Location'])

    def test_pdf_con_auth_devuelve_200(self):
        """GET /ventas/<id>/pdf/ con login → 200."""
        self.client.force_login(self.user)
        r = self.client.get(
            reverse('ventas:pdf', args=[self.venta.pk])
        )
        self.assertEqual(r.status_code, 200)

    def test_pdf_content_type_application_pdf(self):
        """La respuesta debe tener Content-Type application/pdf."""
        self.client.force_login(self.user)
        r = self.client.get(
            reverse('ventas:pdf', args=[self.venta.pk])
        )
        self.assertIn('application/pdf', r.get('Content-Type', ''))

    def test_pdf_empieza_con_header_pdf(self):
        """El contenido del PDF debe empezar con '%PDF' (PDF válido)."""
        self.client.force_login(self.user)
        r = self.client.get(
            reverse('ventas:pdf', args=[self.venta.pk])
        )
        # Los primeros 4 bytes deben ser '%PDF' para un PDF válido
        self.assertTrue(
            r.content[:4] == b'%PDF',
            "La respuesta no es un PDF válido (no empieza con %PDF)"
        )

    def test_pdf_content_disposition_attachment(self):
        """La respuesta debe ser descarga directa (attachment)."""
        self.client.force_login(self.user)
        r = self.client.get(
            reverse('ventas:pdf', args=[self.venta.pk])
        )
        disposition = r.get('Content-Disposition', '')
        self.assertIn('attachment', disposition)
        self.assertIn('.pdf', disposition)

    def test_pdf_venta_inexistente_devuelve_404(self):
        """GET /ventas/9999/pdf/ → 404 Not Found."""
        self.client.force_login(self.user)
        r = self.client.get(
            reverse('ventas:pdf', args=[9999])
        )
        self.assertEqual(r.status_code, 404)

    def test_pdf_es_mayor_que_1kb(self):
        """Un PDF real de WeasyPrint debe tener al menos 1 KB."""
        self.client.force_login(self.user)
        r = self.client.get(
            reverse('ventas:pdf', args=[self.venta.pk])
        )
        self.assertGreater(
            len(r.content), 1024,
            "El PDF parece demasiado pequeño para ser real"
        )

    def test_pdf_excel_exportacion_tambien_funciona(self):
        """La exportación de Excel (openpyxl) debe seguir funcionando."""
        self.client.force_login(self.user)
        r = self.client.get(reverse('productos:exportar_excel'))
        self.assertEqual(r.status_code, 200)
        self.assertIn('spreadsheetml', r.get('Content-Type', ''))
```

### 14.3 Ejecutar los tests completos dentro del contenedor

```cmd
:: Suite completa
docker-compose exec -e DJANGO_SETTINGS_MODULE=core.settings web python manage.py test tests --verbosity=0

:: Solo los tests de PDF
docker-compose exec -e DJANGO_SETTINGS_MODULE=core.settings web python manage.py test tests.test_w12_documentos tests.test_w12_pdf --verbosity=2

:: Con cobertura de código (si coverage está instalado)
docker-compose exec -e DJANGO_SETTINGS_MODULE=core.settings web coverage run manage.py test tests
docker-compose exec web coverage report
```

**Resultado esperado de la suite completa:** `Ran 123 tests in X.XXXs · OK`
(115 acumulados de W11 + 8 de esta semana). Este acumulado de **123 tests**
es uno de los criterios formales del **Hito M4** y es el punto de partida
que la Guía W13 verifica en su arranque.

---

## CHECKLIST FINAL — Versión WeasyPrint (M4)

### WSL2 + Docker Desktop (verificar ANTES de todo lo demás)

```
[ ] winver → Windows 10 build ≥19041 o Windows 11
[ ] Virtualización habilitada en BIOS (Administrador de tareas → Rendimiento → CPU)
[ ] Windows reiniciado después de habilitar Microsoft-Windows-Subsystem-Linux
[ ] Windows reiniciado después de habilitar VirtualMachinePlatform
[ ] wsl --set-default-version 2 ejecutado
[ ] wsl --version → kernel ≥ 5.10
[ ] Docker Desktop instalado con backend WSL2 (no Hyper-V)
[ ] Settings → General → "Use the WSL 2 based engine" ✓ marcado
[ ] Settings → Resources → WSL Integration → distro por defecto activada
[ ] wsl -l -v → docker-desktop y docker-desktop-data en VERSION 2 y Running
[ ] Prueba de humo: docker run --rm -p 8080:80 nginx:alpine
    → http://localhost:8080 muestra "Welcome to nginx!"
[ ] Si la prueba de Nginx falla: Sección 2.8 revisada completa ANTES
    de continuar con el resto del proyecto
```

### Infraestructura Docker

```
[ ] docker-entrypoint.sh creado con chmod +x y git update-index --chmod=+x
[ ] .gitattributes con *.sh text eol=lf (entrypoint con LF, no CRLF)
[ ] requirements.txt en UTF-8 con weasyprint==60.2 y pydyf==0.10.0
[ ] Dockerfile multicapa: base → system-deps → python-deps → app
[ ] apt-get instala los 8+ paquetes requeridos por WeasyPrint
[ ] libpango-1.0-0 + libpangoft2 + libpangocairo + libcairo2 + libgdk-pixbuf
[ ] fonts-liberation + fonts-dejavu-core para tipografía PDF
[ ] libjpeg, libpng, libwebp para Pillow (imágenes en Django)
[ ] docker-compose.yml: servicios web + db (Redis/Celery/Flower llegan en W16+)
[ ] docker-compose build --no-cache web → build exitoso sin errores
[ ] docker-compose up -d → todos los servicios en STATUS: running (no Restarting)
[ ] docker-compose exec web curl -I http://localhost:8000/ → responde 200/302
[ ] http://localhost:8000/ Y http://127.0.0.1:8000/ ambos cargan en el navegador
[ ] docker-compose exec web python -c "import weasyprint; print(weasyprint.__version__)" → 60.2
```

### WeasyPrint en Local

```
[ ] Verificación: PDF de prueba generado dentro del contenedor
[ ] Primeros bytes del PDF: b'%PDF'
[ ] base_url correctamente configurado en venta_pdf()
[ ] factura_pdf.html: usa solo CSS inline (sin CDN de Bootstrap)
[ ] factura_pdf.html: @page con @bottom-right counter(page)
[ ] factura_pdf.html: thead con display:table-header-group
  (se repite en cada página si la factura tiene muchas líneas)
[ ] factura_pdf.html: encabezado running element para páginas 2+
[ ] factura_pdf.html: logo visible si config.logo existe
[ ] http://localhost:8000/ventas/1/pdf/ → PDF descargable
[ ] PDF descargado: abrir en Adobe Reader o Preview
[ ] PDF: número de página visible en el pie
[ ] PDF: encabezado de empresa visible en páginas 2, 3...
```

### Despliegue a Render

```
[ ] render.yaml migrado del buildpack de Python a runtime: docker
[ ] dockerfilePath: ./Dockerfile
[ ] healthCheckPath: / y solo web + PostgreSQL en render.yaml (W12)
[ ] SECURE_PROXY_SSL_HEADER en core/settings_prod.py
[ ] Logs de Render: sin "TypeError: PDF.__init__()" ni "weasyprint: Ignored"
[ ] /ventas/1/pdf/ sin sesión → 302 a /accounts/login/
[ ] git push main → build Docker automático en Render
[ ] Logs de Render: "apt-get install ... libpango-1.0-0 ... OK"
[ ] Logs de Render: "pip install ... weasyprint==60.2 ... OK"
[ ] Logs de Render: "entrypoint → migrate → collectstatic → gunicorn"
[ ] https://erp-django-utec.onrender.com/ventas/1/pdf/ → PDF en producción
[ ] PDF en producción: logo visible (si S3 configurado y accesible)
```

### Tests dentro del contenedor

```
[ ] docker-compose exec web python manage.py test tests.test_w12_documentos
  → 8/8 tests OK
[ ] test_pdf_empieza_con_header_pdf → content[:4] == b'%PDF'
[ ] test_pdf_es_mayor_que_1kb → len(content) > 1024
[ ] docker-compose exec web python manage.py test tests --verbosity=0
  → todos los tests OK
```

---

## DIAGRAMA: Arquitectura de generación PDF con WeasyPrint

```
ENTORNO LOCAL (Docker Desktop)
─────────────────────────────────────────────────────────
Browser → GET /ventas/1/pdf/
    │
    ▼
Docker Container: erp-web-1
    │  (Ubuntu/Debian con libpango + libcairo + libgdk-pixbuf)
    │
    ├─ ventas/views.py → venta_pdf(request, venta_id=1)
    │       │
    │       ├─ Venta.objects.get(pk=1) [PostgreSQL en container erp-db-1]
    │       ├─ ConfiguracionERP.get_instance()
    │       │
    │       ├─ render_to_string('ventas/factura_pdf.html', context, request)
    │       │       → HTML string con CSS inline + @page rules
    │       │
    │       └─ weasyprint.HTML(
    │               string=html_string,
    │               base_url='http://localhost:8000/'
    │           ).write_pdf()
    │               │
    │               ├─ Pango: layout del texto (fuentes, párrafos)
    │               ├─ Cairo: renderiza cada elemento a primitivas PDF
    │               ├─ GDK-PixBuf: decodifica imágenes (logo.jpg → RGB)
    │               └─ → bytes PDF (b'%PDF...')
    │
    └─ HttpResponse(pdf_bytes, content_type='application/pdf')
       Content-Disposition: attachment; filename="factura_00001.pdf"
           │
           ▼
Browser → descarga factura_00001.pdf ✅

─────────────────────────────────────────────────────────
PRODUCCIÓN (Render.com — Docker)
─────────────────────────────────────────────────────────
Browser → GET https://erp-django-utec.onrender.com/ventas/1/pdf/
    │
    ▼
Render: servicio erp-django-utec (Docker)
    │  MISMO Dockerfile → MISMAS librerías de sistema
    │
    ├─ render.yaml: env=docker, dockerfilePath=./Dockerfile
    ├─ build: apt-get instala libpango, libcairo, libgdk-pixbuf
    ├─ deploy: ENTRYPOINT ./docker-entrypoint.sh
    │
    └─ [mismo flujo que en local]
            │
            ▼
       factura_00001.pdf ✅ con calidad idéntica al entorno local
```

---

## Comparativa Final: xhtml2pdf vs WeasyPrint

| Aspecto | xhtml2pdf | WeasyPrint |
|---|---|---|
| **Calidad del PDF** | Aceptable para reportes simples | Profesional — idéntica a imprimir desde un navegador |
| **@page (encabezados/pies)** | Soporte mínimo | Completo: running headers, counter(page), @top/@bottom |
| **thead en multipágina** | Se pierde en páginas 2+ | Se repite en cada página con `thead { display: table-header-group }` |
| **Imágenes (logo)** | Limitado, ruta relativa compleja | Completo con `base_url` |
| **CSS Grid / Flexbox** | No compatible | Compatible |
| **Entorno sin Docker (Windows)** | ✅ Funciona con pip install | ❌ Requiere GTK3 runtime (complejo) |
| **Entorno Docker / Linux** | ✅ pip install | ✅ pip install + 8 libs de sistema |
| **Render.com (Docker)** | ✅ Sin cambios en Dockerfile | ✅ Con libs en Dockerfile |
| **Velocidad de generación** | ~0.2s para facturas pequeñas | ~0.8s para facturas pequeñas |
| **Tests en CI/CD** | Desde el host | Debe ejecutarse dentro del contenedor |
| **Caso de uso ideal** | Aula sin Docker, reportes rápidos | Producción, PDFs profesionales |

**Recomendación final:**
- **Estándar oficial del programa a partir de W12:** WeasyPrint vía Docker (esta guía).
- **Si un equipo específico no logra estabilizar WSL2/Docker** después de agotar
  la Sección 2.8 y la Sección 8.5 completas, `xhtml2pdf` queda documentado como
  fallback de emergencia (código conservado en `requirements.txt`, comentado).
- **Proyecto final de carrera o portafolio profesional:** WeasyPrint siempre.

---

*Guía de Laboratorio W12 — ERP Django (v2, corregida)*
*Espiral 4 Cierre · Sprint 3 Review · Hito M4*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*