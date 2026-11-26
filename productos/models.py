"""Modelos de la app productos."""
from decimal import Decimal
from django.db import models
from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator

from proveedores.models import Proveedor
from .validators import validar_imagen_producto


class Categoria(models.Model):
    """Categoría para clasificar productos del catálogo."""

    nombre = models.CharField(
        max_length=100, unique=True, verbose_name='Nombre'
    )
    descripcion = models.TextField(
        blank=True, verbose_name='Descripción'
    )

    class Meta:
        verbose_name = 'Categoría'
        verbose_name_plural = 'Categorías'
        ordering = ['nombre']

    def __str__(self) -> str:
        return self.nombre


class Producto(models.Model):
    """Artículo del inventario del ERP."""

    nombre = models.CharField(
        max_length=200, verbose_name='Nombre'
    )
    precio = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name='Precio ($)',
        help_text='El precio no puede ser negativo.'
    )
    stock = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        verbose_name='Stock disponible'
    )
    categoria = models.ForeignKey(
        Categoria,
        on_delete=models.PROTECT,
        related_name='productos',
        verbose_name='Categoría'
    )
    proveedor = models.ForeignKey(
        Proveedor,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='productos',
        verbose_name='Proveedor'
    )
    activo = models.BooleanField(
        default=True, verbose_name='Activo'
    )
    imagen = models.ImageField(
        upload_to='productos/',
        null=True,
        blank=True,
        verbose_name='Imagen del producto',
        help_text='Formatos permitidos: JPEG, PNG, WEBP.',
        validators=[validar_imagen_producto],
    )
    creado = models.DateTimeField(
        auto_now_add=True, verbose_name='Fecha de registro'
    )
    def clean(self) -> None:
        """Validaciones de negocio cruzadas para Producto."""
        errors = {}

        if self.precio is not None and self.precio < 0:
            errors['precio'] = f'El precio no puede ser negativo. Valor recibido: {self.precio}'

        if self.stock is not None and self.stock < 0:
            errors['stock'] = f'El stock no puede ser negativo. Valor recibido: {self.stock}'

        if errors:
            raise ValidationError(errors)

    class Meta:
        verbose_name = 'Producto'
        verbose_name_plural = 'Productos'
        ordering = ['nombre']

    def __str__(self) -> str:
        return f"{self.nombre} (${self.precio:.2f})"