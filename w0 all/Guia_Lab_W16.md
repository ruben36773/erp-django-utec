# Guía de Laboratorio — W16
## ERP Django · Espiral 6 · Semana 16 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W16 de 24 |
| **Espiral** | E6 — Celery e Integraciones |
| **Sprint Scrum** | Sprint 5 — Planning |
| **Hito** | Sin hito propio · Avance hacia M6 (W18) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 4 — Funcionalidades Avanzadas |
| **Hilo conductor** | "W15 completó la venta. W16 la hace eficiente: tareas pesadas fuera del ciclo HTTP." |

---

> **📌 Escenario de esta guía (revisión 2026-11-19)**
>
> El laboratorio **no dispone de Docker Desktop**, por lo que Redis y el
> worker de Celery **se ejecutan solo en producción (Render.com)**:
>
> | Entorno | `REDIS_URL` | Cómo se ejecutan las tareas |
> |---|---|---|
> | Laboratorio (Windows, sin Docker) | *vacía* | Modo **EAGER**: `.delay()` ejecuta la tarea en el mismo proceso, sin broker ni worker |
> | Tests (`manage.py test`) | *vacía* | Modo **EAGER** (no se necesita Redis) |
> | Render (Free) | Internal Key Value URL | Redis + **worker embebido** en el contenedor web |
> | Docker Desktop (opcional) | `redis://redis:6379/0` | Servicios `celery_worker` y `flower` de `docker-compose.yml` |
>
> **Correcciones respecto a la versión anterior de la guía:**
> 1. `pip freeze > requirements.txt` en PowerShell genera UTF-16 → usar `Out-File -Encoding ascii`.
> 2. `settings.py` ya no usa `redis://localhost` por defecto: sin `REDIS_URL` activa modo EAGER.
> 3. Render Free **no tiene Background Workers** → el worker corre dentro del contenedor web
>    (`docker-entrypoint.sh` + `CELERY_EMBEDDED_WORKER=1`).
> 4. `docker-entrypoint.sh` ignoraba el `command:` de los servicios → ahora ejecuta `exec "$@"`.
> 5. La tarea se encola **solo desde el webhook** (antes también desde `pago_exitoso()` → correo duplicado en W17).
> 6. El `.delay()` del webhook va en `try/except`: si Redis falla, el pago queda registrado y Stripe recibe 200.
> 7. `docker-compose.yml`: el worker usa las mismas credenciales que el servicio `db` (`.env`), y Flower recibe sus variables.
> 8. Tests: 9 pruebas (la vista **no** encola · el webhook tolera la caída de Redis · modo EAGER sin `REDIS_URL`).

---

## Respuesta a la tarea de investigación de W15

> **¿Qué es un `broker` en Celery?**
> El broker es el intermediario de mensajes: Django escribe una tarea
> en una cola (el broker) y el worker de Celery la lee y ejecuta.
> Es como un buzón de correo: el remitente (Django) deja el mensaje
> y el cartero (worker) lo recoge y entrega.
>
> **¿Por qué Redis en lugar de PostgreSQL como broker?**
>
> | Aspecto | Redis | PostgreSQL |
> |---|---|---|
> | Velocidad | Microsegundos (en memoria) | Milisegundos (en disco) |
> | Propósito | Almacén de mensajes temporal | Base de datos relacional |
> | Persistencia | Opcional | Siempre persistente |
> | Uso ideal | Colas de tareas, caché | Datos transaccionales |
>
> Para colas de tareas que se procesan en segundos, la velocidad
> de Redis es esencial. PostgreSQL como broker añade latencia y
> carga a la BD principal del negocio.
>
> **¿Diferencia entre `.delay()` y `.apply_async()`?**
>
> ```python
> # .delay() — forma abreviada, equivale a apply_async sin opciones
> enviar_confirmacion_pedido.delay(pedido_id)
>
> # .apply_async() — forma completa con opciones adicionales
> enviar_confirmacion_pedido.apply_async(
>     args=[pedido_id],
>     countdown=30,       # esperar 30 segundos antes de ejecutar
>     retry=True,
>     retry_policy={'max_retries': 3, 'interval_start': 5},
>     queue='high_priority',
> )
> ```
>
> **¿Idempotencia del stock con el webhook?**
> El código actual garantiza idempotencia con `if pedido.estado != 'pagado'`
> antes de llamar a `_descontar_stock()`. Si llega el mismo webhook dos
> veces, la segunda vez el pedido ya está `'pagado'` → no se decrementa
> el stock de nuevo. El `F()` protege contra race conditions *simultáneas*;
> la condición `if` protege contra *reintentos* de Stripe.

---

## Objetivos de la sesión

Al terminar W16, el estudiante será capaz de:

1. Explicar el patrón productor-broker-consumidor de Celery
2. Crear y configurar la aplicación Celery en el proyecto Django
3. Definir tareas asíncronas con `@shared_task`
4. Conectar la tarea al webhook de Stripe (único disparo, tolerante a fallas)
5. Desplegar Redis (Key Value) y el worker de Celery en Render (plan gratuito)
6. Verificar la ejecución de tareas en los logs de Render (Flower: opcional con Docker)
7. Escribir tests que verifican la invocación de tareas asíncronas sin Redis

---

## Stack tecnológico de W16

| Herramienta | Novedad en W16 | Descripción |
|---|---|---|
| `celery` | ✅ Nuevo | Framework de tareas asíncronas distribuidas |
| `redis` (Python) | ✅ Nuevo | Cliente Python para Redis (broker de mensajes) |
| `flower` | ✅ Nuevo | Interfaz web para monitorear workers y tareas |
| `@shared_task` | ✅ Nuevo | Decorador para definir tareas portables entre apps |
| `core/celery.py` | ✅ Nuevo | Configuración central de la app Celery |
| `.delay()` | ✅ Nuevo | Envía una tarea al broker para ejecución asíncrona |
| Render Key Value | ✅ Nuevo | Redis administrado por Render (plan Free, 25 MB) |
| `CELERY_TASK_ALWAYS_EAGER` | ✅ Nuevo | Ejecuta tareas sin broker (laboratorio y tests) |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + Sprint 5 Planning + verificar W15 | 15 min |
| Parte 1 | Instalar paquetes + crear Key Value (Redis) en Render | 10 min |
| Parte 2 | `core/celery.py` + `core/__init__.py` | 15 min |
| Parte 3 | Configurar Celery en `settings.py` (Redis o EAGER) | 10 min |
| Parte 4 | Worker embebido: `docker-entrypoint.sh` + `render.yaml` | 15 min |
| Parte 5 | `ventas/tasks.py`: las 2 tareas placeholder | 20 min |
| Parte 6 | Conectar la tarea en el webhook | 15 min |
| Parte 7 | Tests W16 (9 pruebas, sin Redis) | 20 min |
| Parte 8 | Desplegar en Render y verificar en los logs | 15 min |
| Cierre | `finalizar_sesion.bat` · hilo → W17 | 10 min |
| Buffer | | 15 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum + Sprint 5 Planning (15 min)

```cmd
E:\iniciar_sesion.bat
```

### Daily Scrum

```
1. ¿Qué hice en W15?
   → Implementé el endpoint webhook con verificación de firma Stripe,
     actualicé el estado del pedido y decrementé el stock con F().
     Declaré el Hito M5.

2. ¿Qué haré en W16?
   → Instalaré Celery con Redis, crearé las tareas asíncronas
     y las conectaré al flujo de pago.

3. ¿Tengo algún impedimento?
   → (registrar aquí)
```

### Verificar estado

```cmd
python manage.py check
python manage.py test tests --verbosity=0
```

**Resultado esperado:** `System check identified no issues` · `Ran 147 tests … OK`

---

### Sprint 5 Planning

**Sprint Goal del Sprint 5:**
> *"Al finalizar el Sprint 5, el ERP enviará correos transaccionales
> de confirmación de pedido, notificaciones de stock bajo, y ejecutará
> reportes diarios automáticos, todo de forma asíncrona con Celery
> y Redis sin bloquear las peticiones HTTP."*

**Duración:** W16 (Celery setup) · W17 (SendGrid correo) · W18 (Celery Beat · M6)

Crear `sprint5_planning.md`:

```markdown
# Sprint 5 Planning — ERP Django
## Semanas W16–W18 · Espiral 6: Celery e Integraciones

**Sprint Goal:**
Al finalizar el Sprint 5, el ERP ejecutará tareas pesadas de forma
asíncrona con Celery+Redis: correos de confirmación, alertas de
stock bajo y reporte diario de ventas.

## HUs seleccionadas

| ID | Historia | Puntos | Semana |
|---|---|---|---|
| HU-E6-01 | Como dev, quiero infraestructura Celery+Redis funcional | 3 | W16 |
| HU-E6-02 | Como sistema, quiero ejecutar tareas sin bloquear HTTP | 2 | W16 |
| HU-E6-03 | Como cliente, quiero correo de confirmación post-pago | 5 | W17 |
| HU-E6-04 | Como admin, quiero correo cuando el stock es bajo | 3 | W17 |
| HU-E6-05 | Como admin, quiero reporte diario de ventas a las 8 AM | 3 | W18 |
| HU-E6-06 | Como dev, quiero monitorear tareas con Flower | 2 | W16 |

**Total Sprint 5:** 18 puntos

## DoD — Sprint 5
- Logs de Render: worker de Celery embebido "ready" y procesa tareas
- Webhook payment_intent.succeeded → tarea de correo en la cola (no espera)
- Correo de confirmación recibido en < 30 s (W17)
- Alerta de stock enviada cuando stock < umbral (W17)
- Reporte diario ejecutado a las 8:00 AM (W18)
- python manage.py test → ≥ 155 tests OK
```

---

## PARTE 1 — Instalar Celery, Redis y Flower (10 min)

### 1.1 Instalar paquetes

```cmd
pip install "celery==5.3.6" "redis==5.0.1" "flower==2.0.1"
```

Actualizar `requirements.txt` **según la terminal que uses**:

```powershell
# PowerShell (terminal por defecto de VS Code):
pip freeze | Out-File -Encoding ascii requirements.txt
```

```cmd
:: CMD clásico:
pip freeze > requirements.txt
```

> ⚠️ **No uses `pip freeze > requirements.txt` en PowerShell 5.1**: guarda
> el archivo en **UTF-16**. pip lo sigue leyendo, pero Git lo trata como
> binario (`Bin 1604 -> 2200 bytes`) y ya no puedes revisar los cambios.
> Comprobación: `git diff --stat requirements.txt` debe mostrar `+`/`-`, no `Bin`.

Verificar instalaciones:

```cmd
python -c "import celery; print('Celery', celery.__version__)"
python -c "import redis; print('redis', redis.__version__)"
python -c "import flower; print('flower OK')"
```

**Resultado esperado:**
```
Celery 5.3.6
redis 5.0.1
flower OK
```

### 1.2 Crear el broker Redis en Render (Key Value)

En el laboratorio no hay Docker, así que Redis vive **solo en Render**:

```
1. dashboard.render.com → New + → Key Value
2. Name:               erp-redis
3. Region:             Oregon (US West)   ← LA MISMA que el servicio web
4. Plan:               Free (25 MB)
5. Maxmemory Policy:   noeviction         ← recomendado para colas de tareas
6. Create Key Value
7. Copiar la "Internal Key Value URL":   redis://red-xxxxxxxxxxxx:6379
```

> **¿Por qué la URL interna?** Solo es accesible desde los servicios de
> Render de la misma región (sin salir a Internet, sin contraseña expuesta).
> Por eso **no puedes hacer `ping` desde el laboratorio**: es lo esperado.
> La URL se usará en la Parte 8 como variable `REDIS_URL` del servicio web.
>
> **¿Por qué `noeviction`?** Con 25 MB, una política como `allkeys-lru`
> podría borrar tareas pendientes de la cola cuando la memoria se llena.

---

## PARTE 2 — `core/celery.py` y `core/__init__.py` (15 min)

### 2.1 Crear `core/celery.py`

```python
# core/celery.py
"""Configuración de la aplicación Celery para el proyecto ERP Django.

Este archivo debe importarse ANTES de cualquier tarea (@shared_task)
para que Celery esté configurado correctamente.

Uso desde la línea de comandos:
    # Iniciar worker (procesa tareas)
    celery -A core worker -l info

    # Iniciar worker + Beat (procesa tareas + tareas programadas)
    celery -A core worker -B -l info

    # Monitorear con Flower
    celery -A core flower --port=5555
"""
import os

from celery import Celery

# Establecer el módulo de settings de Django antes de crear la app Celery
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Crear la aplicación Celery con el nombre del proyecto
app = Celery('core')

# Leer la configuración desde Django settings
# El prefijo CELERY_ distingue las variables de Celery de otras de Django
app.config_from_object('django.conf:settings', namespace='CELERY')

# Auto-descubrir tareas en todos los archivos tasks.py de las apps instaladas
# Django buscará: clientes/tasks.py, productos/tasks.py, ventas/tasks.py, etc.
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Tarea de diagnóstico — muestra el request de la tarea.

    Ejecutar para verificar que el worker está funcionando:
        from core.celery import debug_task
        debug_task.delay()
    """
    print(f'Request: {self.request!r}')
```

---

### 2.2 Actualizar `core/__init__.py`

Asegura que la app Celery se cargue cuando Django arranca,
lo que permite usar `@shared_task` en cualquier app:

```python
# core/__init__.py
"""Inicialización del paquete core del proyecto ERP Django.

Importa la app Celery para que se registre al arrancar Django.
Sin esta importación, @shared_task no encontraría la app Celery.
"""
from .celery import app as celery_app

__all__ = ('celery_app',)
```

### 2.3 Verificar que Celery puede importar el proyecto

Sin Redis en el laboratorio no tiene sentido `celery -A core inspect ping`
(no hay worker que responda). Basta con verificar que la app se importa:

```cmd
python -c "from core.celery import app; print('Celery app OK:', app)"
```

**Resultado esperado:** `Celery app OK: <Celery core at 0x...>`

---

## PARTE 3 — Configurar Celery en `settings.py` (10 min)

### 3.1 Variables de entorno: `.env` local vs. Render

**En el laboratorio NO agregues `REDIS_URL` al `.env`** (o déjala vacía).
Sin ella, `settings.py` activa el modo EAGER y todo funciona sin Redis.
`REDIS_URL` se define **solo en Render** (Parte 8).

### 3.2 Agregar configuración al final de `core/settings.py`

```python
# ── CELERY — Cola de tareas asíncronas (W16) ──────────────────────────────
# REDIS_URL definida (Render → Key Value):
#     las tareas se encolan en Redis y las procesa el worker.
# REDIS_URL vacía (laboratorio sin Docker / tests):
#     modo EAGER → .delay() ejecuta la tarea en el mismo proceso,
#     sin broker ni worker. El código de las vistas no cambia.
REDIS_URL = env('REDIS_URL', default='')

if REDIS_URL:
    # Broker: Redis almacena los mensajes de las tareas pendientes
    CELERY_BROKER_URL     = REDIS_URL
    # Backend: Redis almacena los resultados de las tareas
    CELERY_RESULT_BACKEND = REDIS_URL
    CELERY_TASK_ALWAYS_EAGER = False
else:
    CELERY_BROKER_URL        = 'memory://'
    CELERY_RESULT_BACKEND    = 'cache+memory://'
    CELERY_TASK_ALWAYS_EAGER = True

# Los resultados caducan en 1 hora (el Key Value gratuito tiene 25 MB)
CELERY_RESULT_EXPIRES = 3600

# Formato de serialización (JSON es seguro y portable)
CELERY_ACCEPT_CONTENT    = ['json']
CELERY_TASK_SERIALIZER   = 'json'
CELERY_RESULT_SERIALIZER = 'json'

# Zona horaria (heredar de Django)
CELERY_TIMEZONE = TIME_ZONE   # 'America/Mexico_City'

# Reintentos automáticos ante fallos de conexión al broker
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True

# Tiempo máximo que puede correr una tarea antes de ser terminada (segundos)
CELERY_TASK_SOFT_TIME_LIMIT = 300   # 5 minutos
CELERY_TASK_TIME_LIMIT       = 360  # 6 minutos (hard limit)

# Prefijo para las colas (útil si se comparte Redis entre proyectos)
CELERY_TASK_DEFAULT_QUEUE = 'erp_django'

# En modo EAGER, las excepciones de la tarea se propagan (útil en tests)
CELERY_TASK_EAGER_PROPAGATES = True
```

> **¿Por qué no `default='redis://localhost:6379/0'`?** Sin Redis local,
> cada `.delay()` intentaría conectarse, reintentaría varios segundos y
> terminaría en excepción → la vista respondería 500 y los tests de W14/W15
> fallarían. Con el modo EAGER el mismo código funciona en los tres entornos.

### 3.3 Actualizar `.env.example`

```bash
# W16 — Celery / Redis
# Vacía (laboratorio sin Docker): las tareas se ejecutan en modo EAGER,
# en el mismo proceso, sin Redis ni worker.
# Con Docker local:  REDIS_URL=redis://localhost:6379/0
# En Render: NO usar este archivo → REDIS_URL = Internal Key Value URL
#            y CELERY_EMBEDDED_WORKER=1 en Environment del servicio web.
REDIS_URL=
```

### 3.4 Verificar

```cmd
python manage.py check
python manage.py shell -c "from django.conf import settings; print('EAGER:', settings.CELERY_TASK_ALWAYS_EAGER)"
```

**Resultado esperado:**
```
System check identified no issues (0 silenced).
EAGER: True
```

---

## PARTE 4 — Worker de Celery en Render: opción gratuita (15 min)

### 4.1 El problema: Render Free no tiene Background Workers

Celery necesita **dos procesos**: Django (productor, Gunicorn) y el worker
(consumidor). En Render, el worker sería un *Background Worker*, que **no
tiene plan gratuito**. Opciones:

| Opción | Costo | Cuándo usarla |
|---|---|---|
| **A. Worker embebido** en el contenedor web | Gratis | Curso / prototipo ← **la que usamos** |
| B. Background Worker (Starter) | De pago | Producción real con tráfico |

En la opción A, `docker-entrypoint.sh` lanza el worker **en segundo plano**
y después arranca Gunicorn, ambos en el mismo contenedor (512 MB).

### 4.2 Actualizar `docker-entrypoint.sh`

Dos cambios:
1. **`exec "$@"`**: si el contenedor recibe un comando (`command:` de
   docker-compose o *Docker Command* de un Background Worker), se ejecuta
   tal cual. Antes el entrypoint lo ignoraba y **siempre** arrancaba Gunicorn.
2. **Worker embebido** controlado por `CELERY_EMBEDDED_WORKER=1`.

```sh
#!/bin/sh
# docker-entrypoint.sh
# Punto de entrada unificado para el contenedor ERP Django.
# Se ejecuta en LOCAL (docker-compose) y en PRODUCCIÓN (Render).
# IMPORTANTE: este archivo debe tener finales de línea LF (ver .gitattributes).
# ─────────────────────────────────────────────────────────────────
set -e   # detener si cualquier comando falla

# ── W16: si se recibe un comando, ejecutarlo tal cual ────────────────
# Ej.: docker-compose `command: celery -A core worker ...` o el
# "Docker Command" de un Background Worker en Render.
# Sin argumentos → flujo normal del servicio web (migrar + gunicorn).
if [ "$#" -gt 0 ]; then
    echo "==> [entrypoint] Ejecutando comando: $*"
    exec "$@"
fi

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

# ── W16: worker de Celery embebido (opción gratuita de Render) ───────
# Render Free no ofrece Background Workers: el worker corre en segundo
# plano dentro del mismo contenedor que Gunicorn.
#   --pool=solo           → un solo proceso (cabe en 512 MB)
#   --without-gossip/mingle/heartbeat → menos conexiones a Redis
# Se activa con CELERY_EMBEDDED_WORKER=1 y requiere REDIS_URL.
if [ "${CELERY_EMBEDDED_WORKER:-0}" = "1" ] && [ -n "${REDIS_URL:-}" ]; then
    echo "==> [entrypoint] Iniciando worker de Celery embebido (cola erp_django)..."
    celery -A core worker \
        --loglevel=info \
        --queues=erp_django \
        --pool=solo \
        --without-gossip --without-mingle --without-heartbeat &
else
    echo "==> [entrypoint] Worker de Celery embebido DESACTIVADO."
fi

echo "==> [entrypoint] Iniciando Gunicorn en 0.0.0.0:${PORT:-8000}..."
exec gunicorn core.wsgi \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers 2 \
    --timeout 120 \
    --log-file - \
    --access-logfile -
```

> **¿Por qué esos parámetros?**
> - `--pool=solo` → un solo proceso (prefork crearía uno por CPU y no
>   cabría en 512 MB junto con Gunicorn).
> - `--without-gossip --without-mingle --without-heartbeat` → el worker no
>   conversa con otros workers: menos conexiones y comandos al Key Value Free.
> - `&` → el worker queda en segundo plano y `exec gunicorn` toma el control.
>
> ⚠️ El archivo debe conservar finales de línea **LF** (`.gitattributes`
> ya lo garantiza con `*.sh text eol=lf`).

### 4.3 Actualizar `render.yaml` (blueprint)

Agregar al final de `envVars` del servicio web:

```yaml
      # W16: Celery + Redis (Key Value de Render)
      - key: REDIS_URL               # Internal Key Value URL (redis://red-...:6379)
        sync: false
      - key: CELERY_EMBEDDED_WORKER  # 1 = worker dentro del contenedor web
        value: "1"
```

> `sync: false` = el valor se captura en el dashboard (el Key Value se creó
> a mano en la Parte 1.2). No declares un `type: keyvalue` en el blueprint:
> Render crearía una **segunda** instancia.

### 4.4 `docker-compose.yml` (opcional — solo con Docker Desktop)

Render **no usa** este archivo. Se deja listo para cuando haya Docker:
servicio `redis`, y en `web` agregar `REDIS_URL: redis://redis:6379/0`,
`CELERY_EMBEDDED_WORKER: "0"` y `depends_on: redis`. Nuevos servicios:

```yaml
  # ── Worker de Celery — W16 ──────────────────────────────────────────
  celery_worker:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    command: celery -A core worker -l info -Q erp_django
    volumes:
      - .:/app
    depends_on:
      redis:
        condition: service_healthy
      db:
        condition: service_healthy
    env_file:
      - .env
    environment:
      DJANGO_SETTINGS_MODULE: core.settings_prod
      DATABASE_URL: postgresql://${POSTGRES_USER:-admin}:${POSTGRES_PASSWORD:-12345}@db:5432/${POSTGRES_DB:-erp_db}
      REDIS_URL: redis://redis:6379/0

  # ── Flower — Monitor de Celery — W16 (http://localhost:5555) ────────
  flower:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    command: celery -A core flower --port=5555
    ports:
      - "127.0.0.1:5555:5555"            # solo accesible desde este equipo
    depends_on:
      - redis
      - celery_worker
    env_file:
      - .env
    environment:
      DJANGO_SETTINGS_MODULE: core.settings_prod
      DATABASE_URL: postgresql://${POSTGRES_USER:-admin}:${POSTGRES_PASSWORD:-12345}@db:5432/${POSTGRES_DB:-erp_db}
      REDIS_URL: redis://redis:6379/0
```

> **Error frecuente:** copiar `DATABASE_URL: postgres://erp_user:erp_pass_local@...`
> de otra guía. El worker debe usar **las mismas credenciales que el servicio
> `db`** de tu compose (`.env` → `admin` / `12345` / `erp_db`).
> Flower también necesita `env_file` + `DJANGO_SETTINGS_MODULE`, porque
> `settings_prod` exige `SECRET_KEY`.

---

## PARTE 5 — `ventas/tasks.py`: Las 2 tareas placeholder (20 min)

### 5.1 ¿Por qué `@shared_task` y no `@app.task`?

```python
# @app.task — crea una dependencia directa a la instancia de Celery
from core.celery import app

@app.task
def mi_tarea():
    ...
# Problema: si ventas importa core.celery e core importa ventas,
# podría haber una importación circular.

# @shared_task — desacoplado de la instancia de Celery
from celery import shared_task

@shared_task
def mi_tarea():
    ...
# Ventaja: ventas/tasks.py no importa nada de core/
# La app Celery se asigna automáticamente cuando Django arranca
```

---

### 5.2 Crear `ventas/tasks.py`

```python
# ventas/tasks.py
"""Tareas asíncronas de la app ventas — W16.

Las tareas con @shared_task son descubiertas automáticamente
por celery.autodiscover_tasks() definido en core/celery.py.

Estado de implementación:
    W16: Estructura base — las tareas solo registran en el log.
    W17: Se agrega SendGrid para envío real de correos.
    W18: Se agregan tareas programadas con Celery Beat.

Uso:
    # Desde una vista (asíncrono — no bloquea la respuesta HTTP):
    enviar_confirmacion_pedido.delay(pedido_id)

    # Desde la línea de comandos (síncrono — para depuración):
    python manage.py shell
    >>> from ventas.tasks import enviar_confirmacion_pedido
    >>> result = enviar_confirmacion_pedido.apply(args=[1])
    >>> result.get()
"""
import logging

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)


@shared_task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,      # esperar 60s antes de reintentar
    name='ventas.enviar_confirmacion_pedido',
)
def enviar_confirmacion_pedido(self, pedido_id: int) -> dict:
    """Envía el correo de confirmación de pedido al cliente.

    W16: Solo registra en el log (placeholder).
    W17: Enviará correo real con SendGrid.

    Args:
        pedido_id: ID del Pedido confirmado.

    Returns:
        dict con estado y pedido_id procesado.
    """
    from ventas.models import Pedido   # import local evita circularidad

    try:
        pedido = Pedido.objects.select_related('cliente').get(pk=pedido_id)
    except Pedido.DoesNotExist:
        logger.error(
            f'[Tarea enviar_confirmacion] Pedido {pedido_id} no existe.'
        )
        return {'estado': 'error', 'pedido_id': pedido_id}

    # W16: Placeholder — solo registra en el log
    logger.info(
        f'[Tarea enviar_confirmacion] Procesando pedido '
        f'{pedido.numero_pedido} para {pedido.cliente.correo}. '
        f'Total: ${pedido.total_pagado}. '
        f'Timestamp: {timezone.now().isoformat()}'
    )

    # W17 implementará aquí:
    #   from django.core.mail import send_mail
    #   o envío via SendGrid API

    return {
        'estado':    'ok',
        'pedido_id': pedido_id,
        'numero':    pedido.numero_pedido,
        'cliente':   pedido.cliente.correo,
    }


@shared_task(
    bind=True,
    max_retries=1,
    name='ventas.verificar_stock_bajo',
)
def verificar_stock_bajo(self, umbral: int = 5) -> dict:
    """Verifica productos con stock por debajo del umbral.

    W16: Solo registra en el log (placeholder).
    W17: Enviará alerta por correo al administrador.
    W18: Se programa para ejecutarse automáticamente cada hora.

    Args:
        umbral: cantidad mínima de stock antes de alertar (default: 5).

    Returns:
        dict con lista de productos con stock bajo.
    """
    from productos.models import Producto   # import local

    productos_bajos = list(
        Producto.objects
        .filter(activo=True, stock__lt=umbral)
        .values('pk', 'nombre', 'stock')
        .order_by('stock')
    )

    if productos_bajos:
        logger.warning(
            f'[Tarea verificar_stock] {len(productos_bajos)} producto(s) '
            f'con stock < {umbral}: '
            f'{[p["nombre"] for p in productos_bajos]}'
        )
    else:
        logger.info(
            f'[Tarea verificar_stock] Todos los productos tienen '
            f'stock >= {umbral}. OK.'
        )

    return {
        'umbral':          umbral,
        'productos_bajos': productos_bajos,
        'total':           len(productos_bajos),
    }
```

---

## PARTE 6 — Conectar la Tarea al Webhook (15 min)

### 6.1 ¿Dónde se dispara la tarea? Solo en el webhook

| Punto | ¿Siempre ocurre? | ¿Una sola vez? | Decisión |
|---|---|---|---|
| `pago_exitoso()` (redirección del navegador) | ❌ No, si el cliente cierra la pestaña | ❌ Recargar = otra vez | **No encola** |
| Webhook `payment_intent.succeeded` | ✅ Stripe reintenta hasta 3 días | ✅ `if estado != 'pagado'` | **Único disparo** |

Si se encolara en ambos lugares, en W17 el cliente recibiría **dos correos**.

`pago_exitoso()` queda como vista de presentación (sin import de la tarea):

```python
# catalogo/views.py
def pago_exitoso(request, pedido_id: int):
    """Vista de confirmación post-pago exitoso.

    Vacía el carrito de la sesión y muestra el número de pedido.
    Stripe redirige aquí después de `stripe.confirmCardPayment` exitoso.

    W16: esta vista NO encola la tarea de correo. La encola el webhook
    (catalogo/webhook_views.py), que Stripe envía aunque el cliente
    cierre el navegador y que es idempotente → un solo correo por pedido.
    """
    from django.shortcuts import get_object_or_404
    pedido = get_object_or_404(Pedido, pk=pedido_id)

    # Vaciar el carrito al confirmar el pago
    _guardar_carrito(request, {})

    messages.success(
        request,
        f'¡Pago exitoso! Tu pedido {pedido.numero_pedido} '
        f'está confirmado. Total: ${pedido.total_pagado}. '
        f'Recibirás un correo de confirmación pronto.'
    )

    return render(request, 'catalogo/pago_exitoso.html', {
        'pedido': pedido,
    })
```

> Ojo con los f-strings partidos en varias líneas: Python los une **sin
> espacio**. `f'Total: ${x}'` + `f'Recibirás…'` produce `Total: $150.00Recibirás…`.

---

### 6.2 Actualizar el webhook en `catalogo/webhook_views.py`

```python
# catalogo/webhook_views.py — junto a los demás imports:
from ventas.tasks     import enviar_confirmacion_pedido   # W16


# En _manejar_pago_exitoso(), después de _descontar_stock():
def _manejar_pago_exitoso(payment_intent: dict) -> None:
    pedido_id = _extraer_pedido_id(payment_intent)
    if pedido_id is None:
        return

    try:
        pedido = Pedido.objects.get(pk=pedido_id)
    except Pedido.DoesNotExist:
        logger.error(f'Webhook: Pedido {pedido_id} no encontrado en BD.')
        return

    if pedido.estado != 'pagado':
        pedido.estado = 'pagado'
        pedido.save(update_fields=['estado'])
        logger.info(
            f'Pedido {pedido.numero_pedido} actualizado a "pagado".'
        )
        _descontar_stock(pedido)

        # ── W16: encolar la tarea de confirmación ─────────────────────
        # El webhook es el ÚNICO punto que dispara el correo: se ejecuta
        # aunque el usuario cierre el navegador y solo una vez por pedido.
        # Si Redis no responde, el pago ya quedó registrado: se deja
        # constancia en el log y se responde 200 a Stripe igualmente.
        try:
            enviar_confirmacion_pedido.delay(pedido.pk)
        except Exception:
            logger.exception(
                f'Webhook: no se pudo encolar la confirmación del '
                f'pedido {pedido.numero_pedido} (¿Redis disponible?).'
            )
        # ─────────────────────────────────────────────────────────────
    else:
        logger.info(
            f'Pedido {pedido.numero_pedido} ya estaba pagado — '
            f'idempotente, sin cambios.'
        )
```

> **¿Por qué el `try/except`?** Sin él, si Redis falla, `.delay()` lanza
> una excepción → el webhook responde **500** → Stripe reintenta, pero en
> el reintento el pedido ya está `'pagado'` y entra a la rama idempotente:
> **el correo nunca se encola** y Stripe acumula errores en el panel.
> Con el `try/except`, lo crítico (pago + stock) queda registrado, el fallo
> queda en los logs y Stripe recibe 200.

---

## PARTE 7 — Tests W16 (20 min)

> Todos los tests corren **sin Redis ni Docker**: sin `REDIS_URL`,
> `settings.py` activa el modo EAGER.

### 7.1 Estrategia para tests de Celery

```python
# OPCIÓN A — CELERY_TASK_ALWAYS_EAGER (ejecuta sin worker)
# Las tareas se ejecutan sincrónicamente en el mismo proceso
# Útil para verificar la LÓGICA de la tarea

@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
def test_tarea_registra_en_log(self):
    enviar_confirmacion_pedido.delay(pedido_id)
    # La tarea se ejecutó sincrónicamente

# OPCIÓN B — Mock del método .delay()
# Verifica que la tarea SE LLAMA (no que se ejecuta)
# Útil para tests de integración de vistas

@patch('catalogo.webhook_views.enviar_confirmacion_pedido.delay')
def test_webhook_dispara_tarea(self, mock_delay):
    self.client.post(url_webhook, ...)
    mock_delay.assert_called_once_with(pedido_id)

# Con side_effect se simula que Redis está caído:
@patch('catalogo.webhook_views.enviar_confirmacion_pedido.delay',
       side_effect=ConnectionError('Redis caído'))
```

Usaremos **ambas opciones** en los tests de W16.

---

### 7.2 Crear `tests/test_w16_celery.py`

```python
"""Suite de pruebas W16 — Celery worker y tareas asíncronas.

Verifica la configuración de Celery, la definición de las tareas
y su invocación desde las vistas.

Ejecutar con:
    python manage.py test tests.test_w16_celery --verbosity=2

No requiere Redis ni Docker: sin REDIS_URL, settings.py activa el
modo EAGER (las tareas se ejecutan en el mismo proceso).

Resultado esperado:
    Ran 9 tests in X.XXXs
    OK
"""
from decimal import Decimal
from unittest.mock import patch

from django.contrib.auth.models import User
from django.test import TestCase, override_settings
from django.urls import reverse

from clientes.models      import Cliente
from configuracion.models import ConfiguracionERP
from productos.models     import Categoria, Producto
from ventas.models        import Pedido
from ventas.tasks         import (
    enviar_confirmacion_pedido,
    verificar_stock_bajo,
)


class CeleryConfigTest(TestCase):
    """Verifica que Celery está correctamente configurado."""

    def test_celery_app_importable(self):
        """La app Celery debe poder importarse sin errores."""
        from core.celery import app as celery_app
        self.assertIsNotNone(celery_app)
        self.assertEqual(celery_app.main, 'core')

    def test_tareas_registradas_en_celery(self):
        """Las tareas de ventas deben estar registradas en Celery."""
        from core.celery import app as celery_app
        tareas = celery_app.tasks.keys()
        self.assertIn('ventas.enviar_confirmacion_pedido', tareas)
        self.assertIn('ventas.verificar_stock_bajo', tareas)

    def test_sin_redis_url_usa_modo_eager(self):
        """Sin REDIS_URL (laboratorio sin Docker) las tareas son EAGER."""
        from django.conf import settings
        if settings.REDIS_URL:
            self.skipTest('REDIS_URL definida: entorno con Redis.')
        self.assertTrue(settings.CELERY_TASK_ALWAYS_EAGER)
        self.assertEqual(settings.CELERY_BROKER_URL, 'memory://')


class EnviarConfirmacionTareaTest(TestCase):
    """Tests de la tarea enviar_confirmacion_pedido."""

    def setUp(self):
        ConfiguracionERP.get_instance()
        cat         = Categoria.objects.create(nombre='Cat')
        prod        = Producto.objects.create(
            nombre='P', precio=Decimal('100.00'), stock=5, categoria=cat
        )
        cli         = Cliente.objects.create(nombre='C', correo='c@t.com')
        self.pedido = Pedido.objects.create(
            numero_pedido = 'PED-2025-0001',
            cliente       = cli,
            estado        = 'pagado',
            total_pagado  = Decimal('116.00'),
        )

    @override_settings(CELERY_TASK_ALWAYS_EAGER=True)
    def test_tarea_ejecuta_y_retorna_ok(self):
        """La tarea debe ejecutarse y retornar estado 'ok'."""
        resultado = enviar_confirmacion_pedido.delay(self.pedido.pk)
        data = resultado.get()
        self.assertEqual(data['estado'], 'ok')
        self.assertEqual(data['pedido_id'], self.pedido.pk)

    @override_settings(CELERY_TASK_ALWAYS_EAGER=True)
    def test_tarea_con_pedido_inexistente_retorna_error(self):
        """La tarea con pedido inexistente debe retornar estado 'error'."""
        resultado = enviar_confirmacion_pedido.delay(9999)
        data = resultado.get()
        self.assertEqual(data['estado'], 'error')

    @override_settings(CELERY_TASK_ALWAYS_EAGER=True)
    def test_verificar_stock_bajo_detecta_productos(self):
        """verificar_stock_bajo debe detectar productos con stock < umbral."""
        Producto.objects.filter(nombre='P').update(stock=3)
        resultado = verificar_stock_bajo.delay(umbral=5)
        data = resultado.get()
        self.assertGreaterEqual(data['total'], 1)
        nombres = [p['nombre'] for p in data['productos_bajos']]
        self.assertIn('P', nombres)


class TareaInvocadaDesdeVistaTest(TestCase):
    """Verifica qué vistas encolan la tarea con .delay()."""

    def setUp(self):
        ConfiguracionERP.get_instance()
        cat  = Categoria.objects.create(nombre='Cat')
        cli  = Cliente.objects.create(nombre='C', correo='test@test.com')
        self.pedido = Pedido.objects.create(
            numero_pedido = 'PED-2025-VISTA',
            cliente       = cli,
            estado        = 'pendiente',
            total_pagado  = Decimal('100.00'),
        )
        self.user = User.objects.create_user('viewer', password='pass')

    @patch('ventas.tasks.enviar_confirmacion_pedido.delay')
    def test_pago_exitoso_no_encola_tarea(self, mock_delay):
        """pago_exitoso() NO encola: el webhook es el único disparo."""
        self.client.force_login(self.user)
        r = self.client.get(
            reverse('catalogo:pago_exitoso', args=[self.pedido.pk])
        )
        self.assertEqual(r.status_code, 200)
        mock_delay.assert_not_called()

    @patch('catalogo.webhook_views.enviar_confirmacion_pedido.delay')
    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_webhook_succeeded_llama_a_delay(
        self, mock_event, mock_delay
    ):
        """El webhook payment_intent.succeeded debe llamar a .delay()."""
        mock_event.return_value = self._evento_succeeded()
        self._post_webhook()
        mock_delay.assert_called_once_with(self.pedido.pk)

    @patch('catalogo.webhook_views.enviar_confirmacion_pedido.delay',
           side_effect=ConnectionError('Redis caído'))
    @patch('catalogo.webhook_views.stripe.Webhook.construct_event')
    def test_webhook_responde_200_aunque_redis_falle(
        self, mock_event, mock_delay
    ):
        """Si Redis falla, el pago se registra y Stripe recibe 200."""
        mock_event.return_value = self._evento_succeeded()
        with self.assertLogs('catalogo.webhook_views', level='ERROR'):
            r = self._post_webhook()
        self.assertEqual(r.status_code, 200)
        self.pedido.refresh_from_db()
        self.assertEqual(self.pedido.estado, 'pagado')

    # ── helpers ────────────────────────────────────────────────────────
    def _evento_succeeded(self):
        return {
            'type': 'payment_intent.succeeded',
            'data': {
                'object': {
                    'id': 'pi_test',
                    'metadata': {'pedido_id': str(self.pedido.pk)},
                }
            }
        }

    def _post_webhook(self):
        self.pedido.items_snapshot = []
        self.pedido.save()
        return self.client.post(
            reverse('catalogo:webhook'),
            data=b'{}',
            content_type='application/json',
            HTTP_STRIPE_SIGNATURE='t=1,v1=ok'
        )
```

### 7.3 Ejecutar los tests

```cmd
python manage.py test tests.test_w16_celery --verbosity=2
```

**Resultado esperado:**
```
test_celery_app_importable ... ok
test_sin_redis_url_usa_modo_eager ... ok
test_tareas_registradas_en_celery ... ok
test_tarea_con_pedido_inexistente_retorna_error ... ok
test_tarea_ejecuta_y_retorna_ok ... ok
test_verificar_stock_bajo_detecta_productos ... ok
test_pago_exitoso_no_encola_tarea ... ok
test_webhook_responde_200_aunque_redis_falle ... ok
test_webhook_succeeded_llama_a_delay ... ok

Ran 9 tests in X.XXXs
OK
```

### 7.4 Suite acumulada

```cmd
python manage.py test tests.test_w13_ecommerce tests.test_w14_checkout tests.test_w15_webhooks tests.test_w16_celery
python manage.py test --verbosity=0
```

**Resultado esperado:** W13–W16 → `OK`. La suite completa suma las pruebas
previas + 9 de W16. Los tests de W14/W15 que pasan por el webhook ya **no**
intentan conectarse a Redis (modo EAGER).

---

## PARTE 8 — Desplegar en Render y Verificar (15 min)

### 8.1 Variables de entorno del servicio web

`dashboard.render.com` → servicio **erp-django-utec** → **Environment**:

| Key | Value |
|---|---|
| `REDIS_URL` | Internal Key Value URL de la Parte 1.2 (`redis://red-xxxx:6379`) |
| `CELERY_EMBEDDED_WORKER` | `1` |

> Verifica que el Key Value y el servicio web estén en la **misma región**
> (Oregon); si no, la URL interna no resuelve.

### 8.2 Commit y push → despliegue automático

Antes del commit, actualizar `sprint5_planning.md` (ver Cierre) y revisar:

```cmd
git status
git diff --stat
```

```
Debe incluir:
  core/celery.py (nuevo) · core/__init__.py · core/settings.py
  ventas/tasks.py (nuevo) · catalogo/views.py · catalogo/webhook_views.py
  docker-entrypoint.sh · render.yaml · docker-compose.yml · .env.example
  requirements.txt (texto, NO "Bin") · tests/test_w16_celery.py
  sprint5_planning.md
NO debe incluir: .env
```

```cmd
git add .
git commit -m "Sprint 5 W16: Celery+Redis en Render (worker embebido) + tests OK"
git push origin main
```

Render detecta el push y reconstruye la imagen Docker (≈ 5–10 min).

### 8.3 Verificar en los Logs de Render

Servicio web → **Logs**. Deben aparecer, en este orden:

```
==> [entrypoint] Ejecutando migraciones de base de datos...
==> [entrypoint] Iniciando worker de Celery embebido (cola erp_django)...
==> [entrypoint] Iniciando Gunicorn en 0.0.0.0:10000...
 -------------- celery@srv-xxxx v5.3.6 (emerald-rush)
- ** ---------- .> transport:   redis://red-xxxx:6379//
- ** ---------- .> results:     redis://red-xxxx:6379/
- *** --- * --- .> concurrency: 1 (solo)
 -------------- [queues]
                .> erp_django       exchange=erp_django(direct) key=erp_django
[tasks]
  . core.celery.debug_task
  . ventas.enviar_confirmacion_pedido
  . ventas.verificar_stock_bajo
[INFO/MainProcess] Connected to redis://red-xxxx:6379//
[INFO/MainProcess] celery@srv-xxxx ready.
```

> Si ves `Worker de Celery embebido DESACTIVADO.` → falta
> `CELERY_EMBEDDED_WORKER=1` o `REDIS_URL` en Environment.
> Si ves `Cannot connect to redis://...` → revisa la región y la URL interna.

### 8.4 Prueba de extremo a extremo

Con el endpoint de webhook de W15 apuntando a tu URL de Render:

```
1. https://<tu-servicio>.onrender.com/catalogo/ → comprar con tarjeta 4242 4242 4242 4242
2. Stripe envía payment_intent.succeeded al webhook de Render
3. En los Logs aparece UNA sola vez:
   Pedido PED-2026-XXXX actualizado a "pagado".
   Task ventas.enviar_confirmacion_pedido[<id>] received
   [Tarea enviar_confirmacion] Procesando pedido PED-2026-XXXX para cliente@... Total: $...
   Task ventas.enviar_confirmacion_pedido[<id>] succeeded in 0.0Xs: {'estado': 'ok', ...}
4. Stripe Dashboard → Webhooks → el evento muestra 200 OK
```

### 8.5 Limitaciones del plan gratuito (conocerlas evita sorpresas)

| Limitación | Efecto | Mitigación |
|---|---|---|
| El servicio web se suspende tras 15 min sin tráfico | El worker también se suspende | Las tareas esperan en Redis y se procesan al despertar |
| Key Value Free sin persistencia | Un reinicio del Key Value pierde tareas pendientes | Aceptable en el curso; en producción usar plan con persistencia |
| Sin *Shell* en instancias Free | No se puede ejecutar `debug_task.delay()` en Render | Verificar con la compra de 8.4 y los logs |
| Worker y Gunicorn comparten 512 MB / 0.1 CPU | Tareas pesadas pueden ralentizar la web | `--pool=solo`; en producción → opción B |
| Si el worker se cae, nadie lo reinicia | Las tareas quedan en cola | Revisar logs; **Manual Deploy → Restart** |

> **Opción B (producción real):** crear un *Background Worker* (Docker,
> mismo repo) con Docker Command `celery -A core worker -l info -Q erp_django`,
> las mismas variables de entorno, y poner `CELERY_EMBEDDED_WORKER=0` en el
> servicio web. Gracias al `exec "$@"` del entrypoint no hay que cambiar código.
>
> **Flower** no se despliega en Render (requeriría otro servicio y
> autenticación). Se usa localmente con `docker-compose up flower` cuando
> haya Docker Desktop → `http://localhost:5555`.

---

## CIERRE — Sprint Backlog y Respaldo (10 min)

### Actualizar `sprint5_planning.md` (antes del commit de la Parte 8.2)

```markdown
## Sprint Backlog — actualización W16

| Tarea | Estado |
|---|---|
| pip install celery redis flower (requirements.txt en UTF-8) | ✅ W16 |
| core/celery.py + core/__init__.py | ✅ W16 |
| CELERY_* en settings.py (Redis en Render · EAGER sin REDIS_URL) | ✅ W16 |
| Key Value (Redis) Free en Render · noeviction | ✅ W16 |
| docker-entrypoint.sh: exec "$@" + worker embebido | ✅ W16 |
| render.yaml: REDIS_URL + CELERY_EMBEDDED_WORKER | ✅ W16 |
| docker-compose.yml con worker + flower (opcional, sin Docker en aula) | ✅ W16 |
| ventas/tasks.py (2 tareas placeholder) | ✅ W16 |
| webhook: .delay() con try/except (único disparo) | ✅ W16 |
| Worker embebido "ready" en logs de Render | ✅ W16 |
| SendGrid correo transaccional real | ⏳ W17 |
| Alerta de stock bajo por correo | ⏳ W17 |
| Celery Beat + tareas programadas | ⏳ W18 |
```

### Ejecutar `finalizar_sesion.bat`

```cmd
:: Detener el servidor Django (Ctrl+C)
E:\finalizar_sesion.bat
```

---

## CHECKLIST FINAL W16

### Técnico

```
INSTALACIÓN
[ ] pip install celery redis flower → sin errores
[ ] requirements.txt actualizado con los 3 paquetes y en UTF-8 (git diff no dice "Bin")

CELERY APP
[ ] core/celery.py: os.environ.setdefault antes de Celery('core')
[ ] core/celery.py: app.config_from_object con namespace='CELERY'
[ ] core/celery.py: app.autodiscover_tasks() registra ventas/tasks.py
[ ] core/__init__.py: from .celery import app as celery_app

SETTINGS
[ ] REDIS_URL = env('REDIS_URL', default='')  (sin redis://localhost)
[ ] Con REDIS_URL → BROKER y RESULT_BACKEND = REDIS_URL, EAGER = False
[ ] Sin REDIS_URL → broker memory://, EAGER = True
[ ] CELERY_ACCEPT_CONTENT = ['json'] · CELERY_TASK_SERIALIZER = 'json'
[ ] CELERY_RESULT_EXPIRES = 3600
[ ] python manage.py check → 0 issues · EAGER: True en el laboratorio

RENDER
[ ] Key Value Free creado en la misma región que el servicio web (Oregon)
[ ] Maxmemory policy = noeviction
[ ] Environment: REDIS_URL (Internal URL) + CELERY_EMBEDDED_WORKER=1
[ ] docker-entrypoint.sh: exec "$@" + worker embebido --pool=solo (LF)
[ ] render.yaml: REDIS_URL (sync: false) + CELERY_EMBEDDED_WORKER
[ ] Logs: "celery@srv-... ready" con las 3 tareas en [tasks]

DOCKER COMPOSE (opcional, solo con Docker Desktop)
[ ] celery_worker y flower con env_file: .env y las credenciales del servicio db
[ ] web con REDIS_URL y depends_on redis (service_healthy)

TAREAS
[ ] ventas/tasks.py: @shared_task (no @app.task)
[ ] enviar_confirmacion_pedido: max_retries=3, import local de Pedido
[ ] verificar_stock_bajo: umbral configurable, import local de Producto
[ ] Las tareas reciben IDs (int), no objetos (no JSON serializable)

CONEXIÓN EN VISTAS
[ ] pago_exitoso(): NO encola (sin import de la tarea) · mensaje con espacios correctos
[ ] webhook _manejar_pago_exitoso(): .delay() dentro de try/except, después de _descontar_stock()

VERIFICACIÓN EN PRODUCCIÓN
[ ] Compra 4242 en Render → en logs: received + succeeded UNA sola vez
[ ] Stripe Dashboard → webhook 200 OK

TESTS
[ ] test tests.test_w16_celery → 9/9 OK (sin Redis)
[ ] tests W13–W16 → OK
[ ] @override_settings(CELERY_TASK_ALWAYS_EAGER=True) en tests de tarea
[ ] @patch('...delay') para verificar invocación desde el webhook
[ ] side_effect=ConnectionError → el webhook responde 200

GIT
[ ] sprint5_planning.md con 6 HUs, Sprint Goal y backlog W16
[ ] Commit con mensaje descriptivo (sin .env)
[ ] git push → Render despliega automáticamente
[ ] finalizar_sesion.bat → archivos en USB
```

---

## DIAGRAMA: Patrón productor-broker-consumidor (W16 en Render Free)

```
Stripe ──POST /catalogo/webhook/──┐
                                  ▼
┌──────────── Contenedor web (Render Free, 512 MB) ─────────────┐
│                                                               │
│  Gunicorn → Django (Productor)        Worker Celery (Consumidor)
│  ─────────────────────────────        --pool=solo, en 2º plano│
│  _manejar_pago_exitoso()                         ▲            │
│     ├─ estado = 'pagado'                         │            │
│     ├─ _descontar_stock()  (F())                 │            │
│     └─ try: enviar_confirmacion_pedido           │            │
│              .delay(pedido_id)                   │            │
│              │                                   │            │
└──────────────┼───────────────────────────────────┼────────────┘
               │      Render Key Value (Redis)     │
               │   ┌──────────────────────────────┐│
               └──►│ Cola: erp_django             ││
                   │ {"task": "ventas.enviar...", ├┘ Worker lee
                   │  "args": [42]}               │   el mensaje
                   └──────────────────────────────┘
                                  │
                                  ▼
                   enviar_confirmacion_pedido(42)
                      ├─ Pedido.objects.get(pk=42)
                      ├─ logger.info("Procesando...")   → Logs de Render
                      └─ return {'estado': 'ok', ...}

Stripe recibe 200 inmediato ✅  (incluso si Redis falla: try/except)
Usuario no espera el correo ✅  (se enviará en < 30 s en W17)
pago_exitoso() solo muestra la confirmación (no encola) ✅

Laboratorio sin Docker: REDIS_URL vacía → modo EAGER
    .delay() ejecuta la tarea en el mismo proceso, sin Redis ni worker.
```

---

## HILO CONDUCTOR → W17

**¿Qué entrega W16?**
La infraestructura completa de Celery en producción: Key Value en Render,
worker embebido en el contenedor web, tareas registradas y disparadas
desde el webhook. Las tareas aún son placeholders que solo registran en el log.

**¿Qué abre W17?**
Con la infraestructura en su lugar, W17 reemplaza los `logger.info()`
de las tareas con envíos reales de correo usando **SendGrid**.
El correo de confirmación de pedido llegará al cliente en < 30 segundos.

**¿Qué necesita W17 de W16?**

| Artefacto de W16 | Uso en W17 |
|---|---|
| `ventas/tasks.py` con placeholder | W17 reemplaza `logger.info()` con `send_mail()` + SendGrid |
| `max_retries=3` en la tarea | Si SendGrid falla, Celery reintenta automáticamente |
| `.delay()` solo en el webhook | W17 no toca las vistas — solo modifica la tarea |
| Worker embebido en Render | W17 agrega `SENDGRID_API_KEY` en Environment del servicio web (el worker la hereda) |
| Modo EAGER en el laboratorio | En W17 usar `EMAIL_BACKEND` de consola en local para no enviar correos reales |

**Tarea de investigación para W17:**
> Lee la documentación de SendGrid para Python:
> `https://github.com/sendgrid/sendgrid-python`
>
> ¿Qué es un `Dynamic Template` de SendGrid?
> ¿Cómo se envía un correo con `send_mail()` de Django usando
> el backend `AnymailBackend` de `django-anymail`?
> ¿Qué diferencia hay entre `EMAIL_BACKEND` y el SDK de SendGrid directo?

**Pregunta de reflexión:**
> "En W16 la tarea se dispara solo desde el webhook. Si Stripe reenvía el
> mismo evento, ¿por qué el cliente no recibe dos correos? ¿Y si la tarea
> falla a mitad del envío y Celery la reintenta (`max_retries=3`)? ¿Cómo
> harías la tarea idempotente en W17 (pista: un campo `correo_enviado`)?"

---

## Referencia rápida de comandos W16

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: REQUIREMENTS (PowerShell → UTF-8/ASCII, nunca ">" en PowerShell 5.1)
pip freeze | Out-File -Encoding ascii requirements.txt

:: DJANGO EN EL LABORATORIO (modo EAGER, sin Redis)
python manage.py check
python manage.py shell -c "from django.conf import settings; print('EAGER:', settings.CELERY_TASK_ALWAYS_EAGER)"
python manage.py runserver

:: DEPURACIÓN DE TAREA (shell de Django, síncrono)
python manage.py shell
>>> from ventas.tasks import enviar_confirmacion_pedido
>>> result = enviar_confirmacion_pedido.apply(args=[1])
>>> print(result.get())

:: TESTS
python manage.py test tests.test_w16_celery --verbosity=2
python manage.py test --verbosity=0

:: GIT → despliegue automático en Render
git add .
git commit -m "Sprint 5 W16: Celery+Redis en Render (worker embebido) + tests OK"
git push origin main

:: RENDER (dashboard)
::   Key Value Free (Oregon, noeviction) → copiar Internal URL
::   Servicio web → Environment: REDIS_URL, CELERY_EMBEDDED_WORKER=1
::   Servicio web → Logs: "celery@srv-... ready"

:: SOLO CON DOCKER DESKTOP (opcional)
docker-compose up -d redis celery_worker flower
:: → Flower en http://localhost:5555
```

---

*Guía de Laboratorio W16 · ERP Django*
*Espiral 6 · Sprint 5 Planning · Celery + Redis (Render) + Tareas Asíncronas*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*