# ventas/urls.py
"""URLs de la app ventas — W08 (CRUD completo)."""
from django.urls import path
from . import views

app_name = 'ventas'

urlpatterns = [
    # Rutas de Lectura (W07)
    path('',                         views.VentaListView.as_view(),   name='lista'),
    path('<int:venta_id>/',          views.VentaDetailView.as_view(), name='detalle'),
    
    # Rutas de Escritura (W08)
    path('nueva/',                   views.crear_venta,               name='crear'),
    path('<int:venta_id>/eliminar/', views.VentaDeleteView.as_view(), name='eliminar'),
]