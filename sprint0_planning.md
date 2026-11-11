# Sprint 0 Planning — ERP Django
## Semanas W01–W03 · Espiral 1: Infraestructura

**Sprint Goal:**
Al finalizar el Sprint 0, existirá un proyecto Django 4.2 con estructura
de 5 apps del ERP, desplegado en Render.com con URL pública funcional
y repositorio en GitHub con al menos 10 commits.

## HUs seleccionadas para este sprint

| ID | Historia | Puntos | Estado |
|---|---|---|---|
| HU-E1-01 | Entorno portable USB | 3 | 🔄 En progreso |
| HU-E1-02 | Scripts de sincronización | 2 | 🔄 En progreso |
| HU-E1-03 | Repositorio en GitHub | 2 | ⏳ Pendiente |
| HU-E1-04 | Despliegue en Render.com | 3 | ⏳ Pendiente |

**Total de puntos del sprint:** 10

## Sprint Backlog — Tareas técnicas W01

| Tarea | Responsable | Estado | Horas est. |
|---|---|---|---|
| Configurar Python 3.11 embeddable en USB | Dev | ✅ | 0.5 h |
| Instalar pip y virtualenv | Dev | ✅ | 0.3 h |
| Configurar Git Portable | Dev | ✅ | 0.3 h |
| Crear scripts .bat de sesión | Dev | ✅ | 0.5 h |
| Crear proyecto Django `core` | Dev | ✅ | 0.5 h |
| Crear 5 apps y urls mínimas | Dev | ✅ | 1.0 h |
| Configurar settings.py base | Dev | ✅ | 0.5 h |
| Crear vista de bienvenida | Dev | ✅ | 0.3 h |
| product_backlog.md + sprint0_planning.md | Dev | ✅ | 0.5 h |
| Primer commit en GitHub | Dev | ⏳ | 0.3 h |

## Sprint Backlog — W02 (actualización de estados)

| Tarea | Estado |
|---|---|
| Crear templates/base.html con Fable 5 AzulERP | ✅ |
| Crear 5 plantillas index.html por app | ✅ |
| Migrar vistas a views.py con render() | ✅ |
| Configurar WhiteNoise y STATIC_ROOT | ✅ |
| Crear core/settings_prod.py borrador | ✅ |
| Actualizar requirements.txt (gunicorn, psycopg2) | ✅ |
| Crear tests/test_w02_mvt.py — 12 tests OK | ✅ |
| HU-E1-03 Repositorio GitHub: avance W02 commiteado | ✅ |

## Criterios de aceptación del Sprint 0
- python manage.py check → 0 issues
- http://127.0.0.1:8000/ → HTTP 200 (W01)
- URL pública en Render → HTTP 200 (W03)
- Repositorio con rama main + historial de commits
- Ficha Schmelkes E1 completa (W03)