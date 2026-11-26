# ventas/tasks.py
"""Tareas asíncronas de la app ventas — W17.

W17 implementa el envío real de correos con django-anymail + SendGrid.

Idempotencia:
    Pedido.correo_enviado=True previene envíos duplicados si la tarea
    se llama más de una vez para el mismo pedido.
"""
import logging
from decimal import Decimal, InvalidOperation

from celery import shared_task
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils import timezone

logger = logging.getLogger(__name__)


def _sitio_base() -> str:
    """URL pública del sitio, sin diagonal final.

    Se puede cambiar con SITE_URL en settings o en las variables de entorno;
    por defecto apunta al servicio de Render de este proyecto.
    """
    return getattr(
        settings, 'SITE_URL',
        'https://erp-django-utec-1-o234.onrender.com',
    ).rstrip('/')


@shared_task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,
    name='ventas.enviar_confirmacion_pedido',
)
def enviar_confirmacion_pedido(self, pedido_id: int) -> dict:
    """Envía el correo de confirmación de pedido al cliente.

    Garantías:
        - Idempotente: si correo_enviado=True, aborta sin error.
        - Retry automático hasta 3 veces en caso de fallo de SendGrid.

    Args:
        pedido_id: ID del Pedido confirmado.

    Returns:
        dict con estado, pedido_id y correo del destinatario.
    """
    from configuracion.models import ConfiguracionERP  # import local
    from ventas.models        import Pedido             # import local

    try:
        pedido = Pedido.objects.select_related('cliente').get(pk=pedido_id)
    except Pedido.DoesNotExist:
        logger.error(
            f'[correo_confirmacion] Pedido {pedido_id} no existe.'
        )
        return {'estado': 'error', 'razon': 'Pedido no encontrado'}

    # ── Verificación de idempotencia ────────────────────────────────────
    if pedido.correo_enviado:
        logger.info(
            f'[correo_confirmacion] Pedido {pedido.numero_pedido}: '
            f'correo ya enviado anteriormente — skip.'
        )
        return {
            'estado':    'skip',
            'pedido_id': pedido_id,
            'razon':     'correo ya enviado',
        }

    config = ConfiguracionERP.get_instance()

    # ── Construir contexto del correo ───────────────────────────────────
    # Subtotal por línea calculado aquí (precio × cantidad) para que el
    # template solo lo muestre; así no dependemos de {% widthratio %},
    # que solo acepta enteros y falla con precios como '100.00'.
    items = []
    for it in (pedido.items_snapshot or []):
        try:
            precio   = Decimal(str(it.get('precio', '0')))
            cantidad = int(it.get('cantidad', 0))
        except (InvalidOperation, ValueError, TypeError):
            precio, cantidad = Decimal('0'), 0
        items.append({
            **it,
            'precio':   precio,
            'cantidad': cantidad,
            'subtotal': (precio * cantidad).quantize(Decimal('0.01')),
        })
    url_pedido = f"{_sitio_base()}/ventas/{pedido.pk}/"

    contexto = {
        'pedido':     pedido,
        'config':     config,
        'items':      items,
        'url_pedido': url_pedido,
    }

    # ── Renderizar templates ────────────────────────────────────────────
    # render_to_string sin request (las tareas Celery no tienen request)
    asunto     = (
        f'Confirmación de pedido {pedido.numero_pedido} '
        f'— {config.nombre_empresa}'
    )
    texto_plano = render_to_string(
        'emails/confirmacion_pedido.txt', contexto
    )
    html_body   = render_to_string(
        'emails/confirmacion_pedido.html', contexto
    )

    # ── Construir el correo ────────────────────────────────────────────
    correo_destino = pedido.cliente.correo
    correo_origen  = settings.DEFAULT_FROM_EMAIL

    mensaje = EmailMultiAlternatives(
        subject      = asunto,
        body         = texto_plano,      # versión texto plano (fallback)
        from_email   = correo_origen,
        to           = [correo_destino],
    )
    mensaje.attach_alternative(html_body, 'text/html')

    # ── Enviar y manejar errores ───────────────────────────────────────
    try:
        mensaje.send()
        logger.info(
            f'[correo_confirmacion] Correo enviado a {correo_destino} '
            f'para pedido {pedido.numero_pedido}.'
        )

        # Marcar como enviado para evitar duplicados
        pedido.correo_enviado = True
        pedido.save(update_fields=['correo_enviado'])

        return {
            'estado':    'ok',
            'pedido_id': pedido_id,
            'correo':    correo_destino,
        }

    except Exception as exc:
        logger.error(
            f'[correo_confirmacion] Error al enviar correo para pedido '
            f'{pedido.numero_pedido}: {exc}'
        )
        # Reintento automático con Celery (hasta max_retries=3)
        raise self.retry(exc=exc, countdown=60 * (self.request.retries + 1))


@shared_task(
    bind=True,
    max_retries=1,
    name='ventas.verificar_stock_bajo',
)
def verificar_stock_bajo(self, umbral: int = 5) -> dict:
    """Verifica productos con stock bajo y envía alerta al admin.

    W17: Si hay productos bajo el umbral, envía correo a ADMINS[0].

    Args:
        umbral: cantidad mínima antes de alertar (default: 5).

    Returns:
        dict con conteo y lista de productos con stock bajo.
    """
    from productos.models import Producto   # import local

    productos_bajos = list(
        Producto.objects
        .select_related('categoria')
        .filter(activo=True, stock__lt=umbral)
        .values('pk', 'nombre', 'stock', 'categoria__nombre')
        .order_by('stock')
    )

    if not productos_bajos:
        logger.info(
            f'[stock_bajo] Todos los productos tienen stock ≥ {umbral}. OK.'
        )
        return {'umbral': umbral, 'total': 0, 'productos_bajos': []}

    logger.warning(
        f'[stock_bajo] {len(productos_bajos)} producto(s) con stock < {umbral}.'
    )

    # Enviar alerta por correo si hay administradores configurados
    if settings.ADMINS:
        _enviar_alerta_stock(productos_bajos, umbral)

    return {
        'umbral':          umbral,
        'total':           len(productos_bajos),
        'productos_bajos': productos_bajos,
    }


def _enviar_alerta_stock(productos_bajos: list, umbral: int) -> None:
    """Envía el correo de alerta de stock al primer administrador.

    Args:
        productos_bajos: lista de dicts con nombre, stock y categoría.
        umbral:          umbral mínimo configurado.
    """
    from configuracion.models import ConfiguracionERP   # import local

    config = ConfiguracionERP.get_instance()
    fecha  = timezone.now().strftime('%d/%m/%Y %H:%M')

    url_admin = f"{_sitio_base()}/admin/productos/producto/"

    contexto = {
        'productos_bajos':  productos_bajos,
        'total_productos':  len(productos_bajos),
        'umbral':           umbral,
        'fecha':            fecha,
        'url_admin':        url_admin,
        'config':           config,
    }

    asunto      = (
        f'[ALERTA] {len(productos_bajos)} producto(s) con stock < {umbral}'
    )
    texto_plano = render_to_string('emails/alerta_stock.txt',  contexto)
    html_body   = render_to_string('emails/alerta_stock.html', contexto)

    admin_nombre, admin_correo = settings.ADMINS[0]

    mensaje = EmailMultiAlternatives(
        subject    = asunto,
        body       = texto_plano,
        from_email = settings.DEFAULT_FROM_EMAIL,
        to         = [admin_correo],
    )
    mensaje.attach_alternative(html_body, 'text/html')

    try:
        mensaje.send()
        logger.info(
            f'[stock_bajo] Alerta enviada a {admin_correo}. '
            f'{len(productos_bajos)} productos.'
        )
    except Exception as exc:
        logger.error(f'[stock_bajo] Error al enviar alerta: {exc}')

# ventas/tasks.py — agregar al final del archivo

@shared_task(
    bind=True,
    max_retries=2,
    name='ventas.reporte_ventas_diario',
)
def reporte_ventas_diario(self) -> dict:
    """Genera y envía el reporte diario de ventas al administrador.

    Se ejecuta automáticamente a las 8:00 AM todos los días
    mediante Celery Beat (configurado en CELERY_BEAT_SCHEDULE).

    Cálculos realizados en SQL (no en Python) para máxima eficiencia:
        - Total de pedidos pagados hoy
        - Total facturado (suma de total_pagado)
        - Top 5 productos por ingreso del día

    Returns:
        dict con total_pedidos, total_facturado y top_productos.
    """
    from decimal import Decimal

    from django.db.models import (
        DecimalField, ExpressionWrapper, F, Sum,
    )
    from django.utils import timezone

    from configuracion.models import ConfiguracionERP   # import local
    from ventas.models        import DetalleVenta, Pedido  # import local

    hoy    = timezone.localdate()
    config = ConfiguracionERP.get_instance()

    # ── 1. KPIs del día ───────────────────────────────────────────────
    pedidos_hoy = Pedido.objects.filter(
        fecha_pedido__date=hoy,
        estado='pagado'
    )
    total_pedidos   = pedidos_hoy.count()
    total_facturado = pedidos_hoy.aggregate(
        total=Sum('total_pagado')
    )['total'] or Decimal('0.00')

    # ── 2. Top 5 productos por ingreso del día ─────────────────────────
    top_productos = list(
        DetalleVenta.objects
        .filter(venta__fecha__date=hoy)
        .values(nombre=F('producto__nombre'))
        .annotate(
            unidades=Sum('cantidad'),
            ingreso=Sum(
                ExpressionWrapper(
                    F('cantidad') * F('precio_unitario'),
                    output_field=DecimalField(max_digits=12, decimal_places=2)
                )
            )
        )
        .order_by('-ingreso')[:5]
    )

    # Si no hay ventas internas, calcular el Top 5 con los pedidos de la tienda
    if not top_productos:
        from collections import defaultdict
        acumulado = defaultdict(lambda: {'unidades': 0, 'ingreso': Decimal('0.00')})
        for ped in pedidos_hoy:
            for it in (ped.items_snapshot or []):
                try:
                    cant   = int(it.get('cantidad', 0))
                    precio = Decimal(str(it.get('precio', '0')))
                except (ValueError, ArithmeticError):
                    continue
                dato = acumulado[it.get('nombre', 'Producto')]
                dato['unidades'] += cant
                dato['ingreso']  += precio * cant
        top_productos = sorted(
            ({'nombre': n, **d} for n, d in acumulado.items()),
            key=lambda x: x['ingreso'], reverse=True,
        )[:5]

    logger.info(
        f'[reporte_diario] {hoy}: {total_pedidos} pedidos, '
        f'${total_facturado} facturados, '
        f'{len(top_productos)} productos top.'
    )

    # ── 3. Enviar correo al admin si está configurado ──────────────────
    if settings.ADMINS:
        _enviar_reporte_ventas(
            hoy, total_pedidos, total_facturado, top_productos, config
        )

    return {
        'fecha':           str(hoy),
        'total_pedidos':   total_pedidos,
        'total_facturado': str(total_facturado),
        'top_productos':   top_productos,
    }


def _enviar_reporte_ventas(
    fecha, total_pedidos, total_facturado, top_productos, config
) -> None:
    """Envía el reporte diario al primer administrador configurado.

    Args:
        fecha:           Objeto date del día reportado.
        total_pedidos:   Número de pedidos pagados.
        total_facturado: Decimal con la suma total.
        top_productos:   Lista de dicts con nombre, unidades, ingreso.
        config:          Instancia de ConfiguracionERP.
    """
    url_admin = f"{_sitio_base()}/admin/ventas/venta/"

    fecha_str = fecha.strftime('%d/%m/%Y')

    contexto = {
        'fecha':           fecha_str,
        'config':          config,
        'total_pedidos':   total_pedidos,
        'total_facturado': total_facturado,
        'top_productos':   top_productos,
        'url_admin':       url_admin,
    }

    asunto      = f'Reporte de ventas del {fecha_str} — {config.nombre_empresa}'
    texto_plano = render_to_string('emails/reporte_ventas.txt',  contexto)
    html_body   = render_to_string('emails/reporte_ventas.html', contexto)

    admin_nombre, admin_correo = settings.ADMINS[0]

    mensaje = EmailMultiAlternatives(
        subject    = asunto,
        body       = texto_plano,
        from_email = settings.DEFAULT_FROM_EMAIL,
        to         = [admin_correo],
    )
    mensaje.attach_alternative(html_body, 'text/html')

    try:
        mensaje.send()
        logger.info(f'[reporte_diario] Reporte enviado a {admin_correo}.')
    except Exception as exc:
        logger.error(f'[reporte_diario] Error al enviar reporte: {exc}')