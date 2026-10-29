import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_prod')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

# Lee las credenciales de las variables de entorno de Render
username = os.environ.get('DJANGO_SUPERUSER_USERNAME')
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@example.com')

if username and password:
    if not User.objects.filter(username=username).exists():
        User.objects.create_superuser(username=username, email=email, password=password)
        print(f"Superusuario '{username}' creado exitosamente.")
    else:
        print(f"El superusuario '{username}' ya existe.")
else:
    print("No se creará superusuario: Faltan variables de entorno.")