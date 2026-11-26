# Sprint 5 Retrospective — ERP Django
## Semanas W16–W18 · Espiral 6: Celery e Integraciones

**Fecha:** ___/___/_____

## ¿Qué funcionó bien? (Keep)
1. El campo correo_enviado en Pedido resolvió elegantemente el
   problema de duplicados sin necesidad de un sistema externo de idempotencia.
2. @override_settings(EMAIL_BACKEND=locmem) hizo los tests de correo
   triviales: mail.outbox captura todo sin enviar nada.
3. Separar beat de worker como procesos independientes es la
   arquitectura correcta desde el inicio.

## ¿Qué mejorar? (Improve)
1. Documentar mejor el procedimiento de arranque de los 4 procesos.
2. Agregar health check a los servicios Celery en docker-compose.

## Acción de mejora (Kaizen) para Sprint 6
> "En el Sprint 6 (Dashboard), pre-calcularé los KPIs con annotate
>  desde el principio, sin iterar en Python."

## Velocidad del Sprint 5

| HU | Pts plan. | Pts ent. |
|---|---|---|
| HU-E6-01 Infraestructura Celery+Redis | 3 | 3 |
| HU-E6-02 Tareas sin bloquear HTTP | 2 | 2 |
| HU-E6-03 Correo confirmación post-pago | 5 | 5 |
| HU-E6-04 Alerta stock bajo | 3 | 3 |
| HU-E6-05 Reporte diario 8 AM | 3 | 3 |
| HU-E6-06 Monitorear con Flower | 2 | 2 |
| **Total** | **18** | **18** |

**Velocidad Sprint 5:** 18 puntos
**Velocidad acumulada (S0–S5):** 123 puntos