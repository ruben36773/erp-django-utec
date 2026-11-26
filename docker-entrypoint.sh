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

# Superusuario: se crea solo si no existe, usando las variables de entorno
# DJANGO_SUPERUSER_USERNAME y DJANGO_SUPERUSER_PASSWORD definidas en Render.
# (Ya no se usa un usuario fijo con contraseña conocida.)
echo "==> [entrypoint] Verificando superusuario..."
python manage.py shell -c "import os; from django.contrib.auth import get_user_model; U = get_user_model(); u = os.environ.get('DJANGO_SUPERUSER_USERNAME'); p = os.environ.get('DJANGO_SUPERUSER_PASSWORD'); (u and p and not U.objects.filter(username=u).exists()) and U.objects.create_superuser(u, 'admin@email.com', p)"

# ── W16: worker de Celery embebido (opción gratuita de Render) ───────
# Render Free no ofrece Background Workers: el worker corre en segundo
# plano dentro del mismo contenedor que Gunicorn.
#   --pool=solo           → un solo proceso (cabe en 512 MB)
#   --without-gossip/mingle/heartbeat → menos conexiones a Redis
# Se activa con CELERY_EMBEDDED_WORKER=1 y requiere REDIS_URL.
if [ "${CELERY_EMBEDDED_WORKER:-0}" = "1" ] && [ -n "${REDIS_URL:-}" ]; then
    # W18: Beat embebido (tareas programadas) dentro del mismo proceso worker.
    # Se activa con CELERY_EMBEDDED_BEAT=1. Solo debe haber UN proceso así.
    BEAT_FLAGS=""
    if [ "${CELERY_EMBEDDED_BEAT:-0}" = "1" ]; then
        BEAT_FLAGS="-B -s /tmp/celerybeat-schedule"
        echo "==> [entrypoint] Beat embebido ACTIVADO (reporte diario y revisión de stock)."
    fi
    echo "==> [entrypoint] Iniciando worker de Celery embebido (cola erp_django)..."
    celery -A core worker \
        --loglevel=info \
        --queues=erp_django \
        --pool=solo \
        --without-gossip --without-mingle --without-heartbeat \
        $BEAT_FLAGS &
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