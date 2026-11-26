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

# W16: el entrypoint migra, arranca el worker de Celery (si está activado
# con CELERY_EMBEDDED_WORKER=1 y REDIS_URL) y por último Gunicorn.
CMD ["sh", "docker-entrypoint.sh"]