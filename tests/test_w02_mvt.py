"""Suite de pruebas W02 — Patrón MVT: templates, vistas y estáticos.

Ejecutar con:
    python manage.py test tests.test_w02_mvt --verbosity=2

Resultado esperado:
    Ran 12 tests in X.XXXs
    OK
"""
from django.test import TestCase
from django.urls import reverse


class TemplatesRenderTest(TestCase):
    """Verifica que las vistas usen los templates correspondientes actualizados a W07."""

    def test_productos_usa_template_correcto(self):
        response = self.client.get(reverse('productos:lista'))
        self.assertTemplateUsed(response, 'productos/lista.html')

    def test_clientes_usa_template_correcto(self):
        response = self.client.get(reverse('clientes:lista'))
        self.assertTemplateUsed(response, 'clientes/lista.html')

    def test_proveedores_usa_template_correcto(self):
        response = self.client.get(reverse('proveedores:lista'))
        self.assertTemplateUsed(response, 'proveedores/lista.html')

    def test_ventas_usa_template_correcto(self):
        response = self.client.get(reverse('ventas:lista'))
        self.assertTemplateUsed(response, 'ventas/lista.html')

    def test_reportes_usa_template_correcto(self):
        response = self.client.get(reverse('reportes:inicio'))
        self.assertTemplateUsed(response, 'reportes/index.html')


class ContextoBienvenidaTest(TestCase):
    """Verifica el contexto de la vista de bienvenida."""

    def test_contexto_contiene_modulos(self):
        """La vista de inicio debe pasar 'modulos' en el contexto."""
        response = self.client.get('/')
        self.assertIn('modulos', response.context,
                      "El contexto debe incluir la lista 'modulos'")

    def test_contexto_tiene_seis_modulos(self):
        """El contexto debe contener exactamente 6 módulos."""
        response = self.client.get('/')
        modulos = response.context.get('modulos', [])
        self.assertEqual(
            len(modulos), 6,
            f"Se esperaban 6 módulos, se encontraron {len(modulos)}"
        )


class StaticFilesConfigTest(TestCase):
    """Verifica la configuración de archivos estáticos y WhiteNoise."""

    def test_static_url_es_slash_static(self):
        """STATIC_URL debe ser '/static/'."""
        from django.conf import settings
        self.assertEqual(settings.STATIC_URL, '/static/')

    def test_static_root_configurado(self):
        """STATIC_ROOT debe estar definido."""
        from django.conf import settings
        self.assertTrue(bool(settings.STATIC_ROOT),
                        "STATIC_ROOT no está configurado")

    def test_whitenoise_en_middleware(self):
        """WhiteNoise debe estar en MIDDLEWARE."""
        from django.conf import settings
        self.assertIn(
            'whitenoise.middleware.WhiteNoiseMiddleware',
            settings.MIDDLEWARE,
            "WhiteNoise no está en MIDDLEWARE"
        )

    def test_whitenoise_despues_de_security(self):
        """WhiteNoise debe ir DESPUÉS de SecurityMiddleware."""
        from django.conf import settings
        m = settings.MIDDLEWARE
        idx_sec  = m.index('django.middleware.security.SecurityMiddleware')
        idx_wn   = m.index('whitenoise.middleware.WhiteNoiseMiddleware')
        self.assertLess(idx_sec, idx_wn,
                        "SecurityMiddleware debe ir ANTES que WhiteNoise")