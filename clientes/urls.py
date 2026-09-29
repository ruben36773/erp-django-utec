# productos/urls.py
"""URLs de la app clientes — W01 (mínimo funcional)."""
from django.urls import path
from django.http import HttpResponse

app_name = 'clientes'


def bienvenida_clientes(request):
    """Vista temporal de bienvenida para la app clientes."""
    return HttpResponse(
        "<h2>📦 Módulo Clientes</h2>"
        "<p>En construcción — Espiral 2 (W04)</p>",
        content_type='text/html; charset=utf-8'
    )


urlpatterns = [
    path('', bienvenida_clientes, name='inicio'),
]