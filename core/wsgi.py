"""
WSGI config for core project.
"""

import os
from django.core.wsgi import get_wsgi_application

os.environ['DJANGO_SETTINGS_MODULE'] = 'core.settings_prod'

application = get_wsgi_application()

# Ejecutar migraciones automáticas en PostgreSQL
from django.core.management import call_command
call_command('migrate', interactive=False)

# Crear superusuario automáticamente leyendo las variables de Render
try:
    import create_admin
except Exception as e:
    print(f"Error creando superusuario: {e}")