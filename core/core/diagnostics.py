# core/diagnostics.py

def obtener_contexto_diagnostico():
    """Retorna un contexto básico de diagnóstico para la vista principal."""
    return {
        'status': 'OK',
        'diagnostico': 'Sistema operativo correctamente'
    }