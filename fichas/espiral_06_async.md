# Ficha de Sistematización — Espiral 6
## ERP Django · Espiral E6: Celery e Integraciones

| Campo | Contenido |
|---|---|
| **Número de espiral** | 6 |
| **Nombre del ciclo** | Celery e Integraciones |
| **Semanas** | W16 – W18 |
| **Fecha de inicio** | ___/___/_____ |
| **Fecha de cierre** | ___/___/_____ |
| **Responsable** | [Nombre del estudiante] |
| **Asesor** | MC. Román Fernando López González |

## 1. Objetivo del ciclo
Implementar procesamiento asíncrono con Celery y Redis para:
correos transaccionales de confirmación de pedido, alertas de
stock bajo y reportes diarios automáticos vía Celery Beat.

## 2. Tareas realizadas

| # | Tarea | Estado | Semana |
|---|---|---|---|
| 1 | pip install celery redis flower | ✅ | W16 |
| 2 | core/celery.py + core/__init__.py | ✅ | W16 |
| 3 | CELERY_* en settings.py | ✅ | W16 |
| 4 | docker-compose: worker + flower | ✅ | W16 |
| 5 | ventas/tasks.py (2 tareas placeholder) | ✅ | W16 |
| 6 | pip install django-anymail | ✅ | W17 |
| 7 | Template confirmacion_pedido.html + .txt | ✅ | W17 |
| 8 | Template alerta_stock.html + .txt | ✅ | W17 |
| 9 | enviar_confirmacion_pedido: correo real + idempotencia | ✅ | W17 |
| 10 | verificar_stock_bajo: alerta al admin | ✅ | W17 |
| 11 | Template reporte_ventas.html + .txt | ✅ | W18 |
| 12 | reporte_ventas_diario con annotate + Sum(F()) | ✅ | W18 |
| 13 | CELERY_BEAT_SCHEDULE (crontab + timedelta) | ✅ | W18 |
| 14 | docker-compose: celery_beat | ✅ | W18 |

## 3. Evidencias
- Worker activo: `celery -A core worker` → tasks registradas
- Beat activo: `celery -A core beat` → schedule configurado
- Flower: http://localhost:5555 → workers online
- Tests: Ran 171 tests → OK
- Correo confirmación: enviado tras pago (idempotente)
- Alerta stock: enviada cuando stock < umbral
- Reporte: programado crontab(hour=8, minute=0)

## 4. Criterios de aceptación

| Criterio | Estado |
|---|---|
| Worker procesa enviar_confirmacion_pedido | ✅ |
| correo_enviado=True previene duplicados | ✅ |
| Alerta de stock enviada al admin | ✅ |
| reporte_ventas_diario en BEAT_SCHEDULE | ✅ |
| verificar_stock_bajo en BEAT_SCHEDULE | ✅ |
| 171 tests OK | ✅ |

## 5. Problemas encontrados
(completar durante la sesión)

## 6. Lecciones aprendidas
1.
2.
3.

## 7. Tiempo total invertido

| Categoría | Horas |
|---|---|
| Diseño | |
| Implementación | |
| Pruebas | |
| Documentación | |
| **Total Espiral 6** | |