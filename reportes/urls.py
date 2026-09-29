# productos/urls.py
"""URLs de la app productos — W01 (mínimo funcional)."""
from django.urls import path
from django.http import HttpResponse

app_name = 'reportes'


def bienvenida_reportes(request):
    """Vista temporal de bienvenida para la app productos."""
    return HttpResponse(
        "<h2>📦 Módulo reportes</h2>"
        "<p>En construcción — Espiral 2 (W04)</p>",
        content_type='text/html; charset=utf-8'
    )


urlpatterns = [
    path('', bienvenida_reportes, name='inicio'),
]