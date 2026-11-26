# Sprint 5 Planning — ERP Django
## Semanas W16–W18 · Espiral 6: Celery e Integraciones

**Sprint Goal:**
Al finalizar el Sprint 5, el ERP ejecutará tareas pesadas de forma
asíncrona con Celery+Redis: correos de confirmación, alertas de
stock bajo y reporte diario de ventas.

## HUs seleccionadas

| ID | Historia | Puntos | Semana |
|---|---|---|---|
| HU-E6-01 | Como dev, quiero infraestructura Celery+Redis funcional | 3 | W16 |
| HU-E6-02 | Como sistema, quiero ejecutar tareas sin bloquear HTTP | 2 | W16 |
| HU-E6-03 | Como cliente, quiero correo de confirmación post-pago | 5 | W17 |
| HU-E6-04 | Como admin, quiero correo cuando el stock es bajo | 3 | W17 |
| HU-E6-05 | Como admin, quiero reporte diario de ventas a las 8 AM | 3 | W18 |
| HU-E6-06 | Como dev, quiero monitorear tareas con Flower | 2 | W16 |

**Total Sprint 5:** 18 puntos

## DoD — Sprint 5
- Logs de Render: worker de Celery embebido "ready" y procesa tareas
- Webhook payment_intent.succeeded → tarea de correo en la cola (no espera)
- Correo de confirmación recibido en < 30 s (W17)
- Alerta de stock enviada cuando stock < umbral (W17)
- Reporte diario ejecutado a las 8:00 AM (W18)
- python manage.py test → ≥ 155 tests OK

## Sprint Backlog — actualización W16

| Tarea | Estado |
|---|---|
| pip install celery redis flower (requirements.txt en UTF-8) | ✅ W16 |
| core/celery.py + core/__init__.py | ✅ W16 |
| CELERY_* en settings.py (Redis en Render · EAGER sin REDIS_URL) | ✅ W16 |
| Key Value (Redis) Free en Render · noeviction | ✅ W16 |
| docker-entrypoint.sh: exec "$@" + worker embebido | ✅ W16 |
| render.yaml: REDIS_URL + CELERY_EMBEDDED_WORKER | ✅ W16 |
| docker-compose.yml con worker + flower (opcional, sin Docker en aula) | ✅ W16 |
| ventas/tasks.py (2 tareas placeholder) | ✅ W16 |
| webhook: .delay() con try/except (único disparo) | ✅ W16 |
| Worker embebido "ready" en logs de Render | ✅ W16 |
| SendGrid correo transaccional real | ⏳ W17 |
| Alerta de stock bajo por correo | ⏳ W17 |
| Celery Beat + tareas programadas | ⏳ W18 |

## Sprint Backlog — actualización W17

| Tarea | Estado |
|---|---|
| pip install celery redis flower | ✅ W16 |
| core/celery.py + tareas placeholder | ✅ W16 |
| pip install django-anymail | ✅ W17 |
| EMAIL_BACKEND configurado (console dev / anymail prod) | ✅ W17 |
| correo_enviado en Pedido + migración 0004 | ✅ W17 |
| Template confirmacion_pedido.html + .txt | ✅ W17 |
| Template alerta_stock.html + .txt | ✅ W17 |
| enviar_confirmacion_pedido: correo real + idempotencia | ✅ W17 |
| verificar_stock_bajo: alerta al admin | ✅ W17 |
| 8 tests con mail.outbox | ✅ W17 |
| Celery Beat + tareas programadas | ⏳ W18 |

## Sprint 5 — Estado final W18

| HU | Estado | Pts |
|---|---|---|
| HU-E6-01 a HU-E6-06 | ✅ Completadas | 18/18 |

## Hito M6 — ALCANZADO ✅
- Worker: celery -A core worker → tareas procesadas
- Beat: celery -A core beat → schedule activo
- Correo: enviar_confirmacion_pedido → enviado post-pago
- Alerta: verificar_stock_bajo → correo al admin
- Reporte: crontab(8,0) → 8:00 AM diario
- Tests: Ran 171 tests → OK
- Fecha: ___/___/_____