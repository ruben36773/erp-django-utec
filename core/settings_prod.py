# core/settings_prod.py
"""Configuración de producción — Render.com (borrador W02).

Hereda settings.py y sobreescribe valores críticos para producción.
W03 completará: DATABASE_URL con PostgreSQL, variables de Render.

Uso:
    DJANGO_SETTINGS_MODULE=core.settings_prod gunicorn core.wsgi
"""
from .settings import *   # hereda toda la configuración base
import os

# Seguridad básica
DEBUG      = False
SECRET_KEY = os.environ['SECRET_KEY']   # obligatorio; sin default en prod

ALLOWED_HOSTS = os.environ.get(
    'ALLOWED_HOSTS', 'localhost'
).split(',')

# HTTPS y cookies seguras
SECURE_SSL_REDIRECT            = True
SECURE_HSTS_SECONDS            = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SESSION_COOKIE_SECURE          = True
CSRF_COOKIE_SECURE             = True
X_FRAME_OPTIONS                = 'DENY'
SECURE_CONTENT_TYPE_NOSNIFF    = True

# Logging mínimo en producción
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {'console': {'class': 'logging.StreamHandler'}},
    'root': {'handlers': ['console'], 'level': 'WARNING'},
}

# W03 agregará:
# import dj_database_url
# DATABASES = {'default': dj_database_url.config(conn_max_age=600)}