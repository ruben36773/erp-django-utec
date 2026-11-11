# Guía de Laboratorio — W02
## ERP Django · Espiral 1 · Semana 2 de 24
### Técnico en Programación (SEP 3061300006-23) · UTEC Celaya
### Asesor: MC. Román Fernando López González

---

| Campo | Detalle |
|---|---|
| **Semana** | W02 de 24 |
| **Espiral** | E1 — Infraestructura y Configuración Base |
| **Sprint Scrum** | Sprint 0 — Desarrollo (día 2) |
| **Hito** | Sin hito propio · Avance hacia M1 (W03) |
| **Horario** | 16:45 – 19:45 (180 min) |
| **Nivel Schmelkes** | 1 — Fundamentos |
| **Hilo conductor** | "W01 puso el motor. W02 pone la carrocería: templates, estáticos y estructura MVT real." |

---

## Conexión con W01

| W01 entregó | W02 construye sobre eso |
|---|---|
| Proyecto Django `core` con 5 apps | Agrega templates HTML reales a cada app |
| Vistas inline con `HttpResponse` en `urls.py` | Las migra a `views.py` usando `render()` |
| `settings.py` base con `django-environ` | Agrega `STATIC_ROOT`, WhiteNoise y crea `settings_prod.py` |
| `requirements.txt` básico | Lo actualiza con `gunicorn` y `psycopg2-binary` |
| `.gitignore` y primer commit | Genera 2 commits nuevos con progreso documentado |

---

## Objetivos de la sesión

Al terminar W02, el estudiante será capaz de:

1. Explicar el patrón MVT: **Modelo** (sin datos aún) · **Vista** `render()` · **Template** HTML con DTL
2. Crear un sistema de diseño en `templates/base.html` con Fable 5 AzulERP (modo claro/oscuro)
3. Construir plantillas por app que extiendan `base.html` con `{% extends %}`
4. Migrar vistas de `urls.py` a `views.py` separando responsabilidades
5. Configurar archivos estáticos con WhiteNoise para producción
6. Crear la configuración de producción `settings_prod.py`

---

## Stack tecnológico de W02

| Herramienta / Concepto | Novedad en W02 | Descripción |
|---|---|---|
| Django Template Language (DTL) | ✅ Nuevo | Motor de plantillas: `{% %}`, `{{ }}`, `{% block %}`, `{% extends %}` |
| `render()` de `django.shortcuts` | ✅ Nuevo | Reemplaza a `HttpResponse`; recibe request + template + contexto |
| WhiteNoise 6.x | ✅ Nuevo | Middleware que sirve estáticos sin Nginx en producción |
| Bootstrap 5.3 CDN | ✅ Nuevo | Framework CSS via CDN (sin archivos locales en W02) |
| Google Fonts CDN | ✅ Nuevo | Playfair Display + Inter (tipografía Fable 5 AzulERP) |
| `collectstatic` | ✅ Nuevo | Comando Django para recolectar estáticos antes del deploy |
| `core/settings_prod.py` | ✅ Nuevo | Configuración separada con `DEBUG=False` para Render.com |
| `gunicorn` 21.x | ✅ Nuevo | Servidor WSGI de producción (usado en W03 con Docker/Render) |

---

## Mapa de tiempo (180 min)

| Parte | Actividad | Tiempo |
|---|---|---|
| Arranque | Daily Scrum + revisión M0 + `iniciar_sesion.bat` | 15 min |
| Parte 1 | `templates/base.html` — Fable 5 AzulERP completo | 40 min |
| Parte 2 | 5 plantillas `index.html` por app | 20 min |
| Parte 3 | Refactorizar vistas: `urls.py` → `views.py` con `render()` | 30 min |
| Parte 4 | Archivos estáticos y WhiteNoise | 15 min |
| Parte 5 | `settings_prod.py` + `requirements.txt` actualizado | 15 min |
| Parte 6 | Tests W02 (12 pruebas ejecutables) | 20 min |
| Cierre | Commit · `finalizar_sesion.bat` · checklist · hilo → W03 | 15 min |
| **Total** | | **180 min** |

---

## ARRANQUE — Daily Scrum (15 min)

### Ejecutar la sesión

```cmd
E:\iniciar_sesion.bat
```

La terminal se abre en `C:\Temp_Workspace_ERP` con `env_erp` activo.

### Daily Scrum (≤ 15 min · 3 preguntas)

```
1. ¿Qué hice en W01?
   → Configuré el entorno portable USB, creé el proyecto Django
     con 5 apps y realicé el primer commit en GitHub.

2. ¿Qué haré en W02?
   → Crearé el sistema de templates Fable 5 AzulERP, migraré
     las vistas a views.py y configuraré los archivos estáticos.

3. ¿Tengo algún impedimento?
   → (registrar aquí cualquier problema técnico pendiente de W01)
```

### Verificar estado de W01 antes de continuar

```cmd
python manage.py check
git log --oneline
```

**Resultado esperado:**
```
System check identified no issues (0 silenced).
abc1234 Sprint 0 W01: suite de tests de entorno (11 tests OK)
def5678 Sprint 0 W01: entorno portable + proyecto Django base + 5 apps
```

> Si `manage.py check` muestra errores, resolverlos antes de avanzar.

---

## PARTE 1 — Sistema de Templates Fable 5 AzulERP (40 min)

### 1.1 Verificar estructura de carpetas

```cmd
dir templates\
```

Si `templates\` no existe (debería existir de W01):
```cmd
mkdir templates
mkdir templates\registration
```

---

### 1.2 Crear `templates/base.html`

Abrir VS Code → nuevo archivo → guardar como `templates\base.html`.
Este archivo es la plantilla madre de todo el ERP:

```html
<!DOCTYPE html>
<html lang="es" data-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="theme-color" content="#0A2342">
    <title>{% block title %}ERP Django{% endblock %} · UTEC Celaya</title>

    <!-- Google Fonts: Playfair Display + Inter + JetBrains Mono -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Inter:wght@300;400;500;600&family=JetBrains+Mono:wght@400;500&display=swap"
          rel="stylesheet">

    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
          rel="stylesheet">

    <!-- Fable 5 AzulERP — Design System -->
    <style>
        /* TOKENS MODO DÍA */
        :root, [data-theme="light"] {
            --clr-navy   : #0A2342;
            --clr-royal  : #1B4F8A;
            --clr-sky    : #4A90D9;
            --clr-ice    : #E8F0FB;
            --clr-gold   : #B8860B;
            --clr-amber  : #D4A017;
            --clr-cream  : #FDF8E8;
            --clr-bg     : #F5F7FA;
            --clr-surface: #FFFFFF;
            --clr-text   : #1A1A2E;
            --clr-muted  : #5A6A7E;
            --clr-border : #C8D8EC;
            --clr-danger : #C0392B;
            --clr-ok     : #1A7A4A;
            --shadow-sm  : 0 1px 4px rgba(10,35,66,.08);
            --shadow-md  : 0 4px 16px rgba(10,35,66,.12);
        }
        /* TOKENS MODO NOCHE */
        [data-theme="dark"] {
            --clr-navy   : #1E3A5F;
            --clr-royal  : #2E5F9E;
            --clr-sky    : #6BAEE8;
            --clr-ice    : #1A2A3A;
            --clr-gold   : #D4AF37;
            --clr-amber  : #E8C547;
            --clr-cream  : #2A2510;
            --clr-bg     : #0D1B2A;
            --clr-surface: #142033;
            --clr-text   : #E2EAF4;
            --clr-muted  : #8AA0B8;
            --clr-border : #2A3F58;
            --clr-danger : #E74C3C;
            --clr-ok     : #2ECC71;
            --shadow-sm  : 0 1px 4px rgba(0,0,0,.3);
            --shadow-md  : 0 4px 16px rgba(0,0,0,.4);
        }
        /* BASE */
        *, *::before, *::after { box-sizing: border-box; }
        body {
            font-family: 'Inter','Segoe UI',sans-serif;
            font-size: 15px;
            background: var(--clr-bg);
            color: var(--clr-text);
            line-height: 1.6;
            transition: background .25s, color .25s;
            margin: 0;
        }
        /* NAVBAR */
        .erp-navbar {
            background: var(--clr-navy);
            border-bottom: 3px solid var(--clr-gold);
            padding: .65rem 1.5rem;
            display: flex; align-items: center;
            justify-content: space-between; flex-wrap: wrap; gap: .5rem;
            box-shadow: var(--shadow-md);
        }
        .erp-brand {
            font-family: 'Playfair Display',Georgia,serif;
            font-size: 1.3rem; font-weight: 700;
            color: var(--clr-gold) !important;
            text-decoration: none; letter-spacing: .04em;
        }
        .erp-brand span { color: rgba(255,255,255,.7); font-weight: 300; font-size: .85em; }
        .erp-nav-links { display: flex; align-items: center; gap: .25rem; flex-wrap: wrap; }
        .erp-nav-link {
            color: rgba(255,255,255,.82) !important;
            font-size: .88rem; font-weight: 500;
            padding: .35rem .75rem; border-radius: 6px;
            text-decoration: none;
            transition: background .2s, color .2s;
        }
        .erp-nav-link:hover, .erp-nav-link.active {
            background: var(--clr-royal); color: #FFF !important;
        }
        .theme-toggle {
            background: var(--clr-gold); color: var(--clr-navy);
            border: none; border-radius: 50%;
            width: 32px; height: 32px; font-size: .9rem;
            cursor: pointer; transition: transform .2s;
        }
        .theme-toggle:hover { transform: rotate(20deg); }
        /* CONTENIDO */
        .erp-main { padding: 2rem 0; min-height: calc(100vh - 110px); }
        /* CARDS */
        .erp-card {
            background: var(--clr-surface);
            border: 1px solid var(--clr-border);
            border-radius: 12px; box-shadow: var(--shadow-sm);
            padding: 1.5rem; margin-bottom: 1.5rem;
            transition: box-shadow .2s;
        }
        .erp-card:hover { box-shadow: var(--shadow-md); }
        .erp-card-header {
            background: var(--clr-navy); color: #FFF;
            border-radius: 10px 10px 0 0;
            padding: .85rem 1.25rem;
            border-left: 5px solid var(--clr-gold);
            font-family: 'Playfair Display',serif;
            font-size: 1.05rem; letter-spacing: .03em;
            margin: -1.5rem -1.5rem 1.5rem;
        }
        /* TABLAS */
        .erp-table {
            width: 100%; border-collapse: separate; border-spacing: 0;
            border-radius: 10px; overflow: hidden; box-shadow: var(--shadow-sm);
        }
        .erp-table thead th {
            background: var(--clr-navy); color: #FFF;
            font-weight: 600; font-size: .82rem;
            text-transform: uppercase; letter-spacing: .06em;
            padding: .75rem 1rem; border-bottom: 3px solid var(--clr-gold);
        }
        .erp-table tbody td {
            background: var(--clr-surface); padding: .65rem 1rem;
            border-bottom: 1px solid var(--clr-border); font-size: .9rem;
        }
        .erp-table tbody tr:nth-child(even) td { background: var(--clr-ice); }
        .erp-table tbody tr:hover td { background: rgba(74,144,217,.08); }
        .erp-table tfoot td {
            background: var(--clr-cream); color: var(--clr-gold);
            font-weight: 700; border-top: 2px solid var(--clr-gold);
        }
        /* BOTONES */
        .btn-erp-primary {
            background: var(--clr-navy); color: #FFF;
            border: 2px solid var(--clr-gold); border-radius: 8px;
            padding: .45rem 1.2rem; font-weight: 600; font-size: .88rem;
            cursor: pointer; text-decoration: none; display: inline-block;
            transition: background .2s, color .2s;
        }
        .btn-erp-primary:hover { background: var(--clr-gold); color: var(--clr-navy); }
        .btn-erp-gold {
            background: var(--clr-gold); color: var(--clr-navy);
            border: 2px solid var(--clr-navy); border-radius: 8px;
            padding: .45rem 1.2rem; font-weight: 700;
            cursor: pointer; text-decoration: none; display: inline-block;
            transition: background .2s;
        }
        .btn-erp-gold:hover { background: var(--clr-amber); }
        .btn-erp-danger {
            background: var(--clr-danger); color: #FFF; border: none;
            border-radius: 8px; padding: .4rem 1rem;
            font-weight: 600; font-size: .85rem;
            cursor: pointer; text-decoration: none; display: inline-block;
        }
        .btn-erp-sm { padding: .25rem .7rem; font-size: .8rem; }
        /* FORMULARIOS */
        .erp-label {
            font-size: .83rem; font-weight: 600; color: var(--clr-muted);
            text-transform: uppercase; letter-spacing: .05em;
            display: block; margin-bottom: .3rem;
        }
        .erp-input {
            background: var(--clr-surface); border: 1.5px solid var(--clr-border);
            border-radius: 8px; color: var(--clr-text);
            padding: .5rem .85rem; width: 100%; font-size: .93rem;
            transition: border-color .2s, box-shadow .2s;
        }
        .erp-input:focus {
            outline: none; border-color: var(--clr-sky);
            box-shadow: 0 0 0 3px rgba(74,144,217,.18);
        }
        /* BADGES */
        .badge-erp-active {
            background: rgba(26,122,74,.12); color: var(--clr-ok);
            border: 1px solid currentColor;
            font-size: .75rem; padding: .2rem .6rem;
            border-radius: 20px; font-weight: 600;
        }
        .badge-erp-inactive {
            background: rgba(192,57,43,.1); color: var(--clr-danger);
            border: 1px solid currentColor;
            font-size: .75rem; padding: .2rem .6rem; border-radius: 20px;
        }
        .badge-erp-gold {
            background: var(--clr-cream); color: var(--clr-gold);
            border: 1px solid var(--clr-gold);
            font-size: .75rem; padding: .2rem .7rem;
            border-radius: 20px; font-weight: 700;
        }
        /* ALERTAS */
        .erp-alert-danger {
            background: rgba(192,57,43,.08); border: 1px solid rgba(192,57,43,.3);
            border-left: 5px solid var(--clr-danger); border-radius: 8px;
            padding: 1rem 1.25rem;
        }
        .erp-alert-info {
            background: var(--clr-ice); border: 1px solid var(--clr-border);
            border-left: 5px solid var(--clr-sky); border-radius: 8px;
            padding: 1rem 1.25rem;
        }
        .erp-alert-success {
            background: rgba(26,122,74,.08); border: 1px solid rgba(26,122,74,.3);
            border-left: 5px solid var(--clr-ok); border-radius: 8px;
            padding: 1rem 1.25rem;
        }
        /* TÍTULO DE PÁGINA */
        .erp-page-title {
            display: flex; align-items: center; gap: 1rem;
            margin-bottom: 1.5rem; padding-bottom: .75rem;
            border-bottom: 2px solid var(--clr-border);
        }
        .erp-page-title h2 {
            font-family: 'Playfair Display',serif;
            font-size: 1.6rem; color: var(--clr-navy); margin: 0;
        }
        [data-theme="dark"] .erp-page-title h2 { color: var(--clr-sky); }
        /* CÓDIGO */
        code, .mono {
            font-family: 'JetBrains Mono',Consolas,monospace;
            font-size: .85em; color: var(--clr-royal);
            background: var(--clr-ice); padding: .1em .4em; border-radius: 4px;
        }
        [data-theme="dark"] code,
        [data-theme="dark"] .mono {
            color: var(--clr-sky); background: rgba(74,144,217,.12);
        }
        /* FOOTER */
        .erp-footer {
            background: var(--clr-navy); color: rgba(255,255,255,.6);
            text-align: center; font-size: .78rem;
            padding: .75rem; border-top: 2px solid var(--clr-gold);
        }
    </style>
    {% block extra_css %}{% endblock %}
</head>

<body>

<!-- NAVBAR -->
<nav class="erp-navbar">
    <a class="erp-brand" href="/">📦 ERP Django <span>· UTEC Celaya</span></a>
    <div class="erp-nav-links">
        <a href="{% url 'productos:inicio' %}"
           class="erp-nav-link {% block nav_productos %}{% endblock %}">Productos</a>
        <a href="{% url 'clientes:inicio' %}"
           class="erp-nav-link {% block nav_clientes %}{% endblock %}">Clientes</a>
        <a href="{% url 'proveedores:inicio' %}"
           class="erp-nav-link {% block nav_proveedores %}{% endblock %}">Proveedores</a>
        <a href="{% url 'ventas:inicio' %}"
           class="erp-nav-link {% block nav_ventas %}{% endblock %}">Ventas</a>
        <a href="{% url 'reportes:inicio' %}"
           class="erp-nav-link {% block nav_reportes %}{% endblock %}">Reportes</a>
        <a href="/admin/" class="erp-nav-link">Admin</a>
        {% if user.is_authenticated %}
            <a href="/accounts/logout/" class="erp-nav-link">
                Salir ({{ user.username }})
            </a>
        {% else %}
            <a href="/accounts/login/" class="erp-nav-link">Entrar</a>
        {% endif %}
        <button class="theme-toggle" id="themeBtn" title="Modo claro/oscuro">🌙</button>
    </div>
</nav>

<!-- MENSAJES FLASH -->
{% if messages %}
<div class="container mt-3">
    {% for m in messages %}
    <div class="erp-alert-{% if m.tags == 'error' %}danger{% elif m.tags == 'success' %}success{% else %}info{% endif %} d-flex justify-content-between align-items-center mb-2"
         role="alert">
        <span>{{ m }}</span>
        <button onclick="this.parentElement.style.display='none'"
                style="background:none;border:none;cursor:pointer;font-size:1.1rem;color:inherit;">×</button>
    </div>
    {% endfor %}
</div>
{% endif %}

<!-- CONTENIDO PRINCIPAL -->
<main class="erp-main">
    <div class="container">
        {% block content %}{% endblock %}
    </div>
</main>

<!-- FOOTER -->
<footer class="erp-footer">
    ERP Django · Django 4.2 LTS · Fable 5 AzulERP · UTEC Celaya · Espiral 1
</footer>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js">
</script>

<!-- Toggle modo noche -->
<script>
(function () {
    var btn  = document.getElementById('themeBtn');
    var html = document.documentElement;
    var icons = { light: '🌙', dark: '☀️' };
    var saved = localStorage.getItem('erpTheme') || 'light';
    html.setAttribute('data-theme', saved);
    if (btn) btn.textContent = icons[saved];
    if (btn) {
        btn.addEventListener('click', function () {
            var current = html.getAttribute('data-theme');
            var next    = current === 'light' ? 'dark' : 'light';
            html.setAttribute('data-theme', next);
            btn.textContent = icons[next];
            localStorage.setItem('erpTheme', next);
        });
    }
})();
</script>
{% block extra_js %}{% endblock %}
</body>
</html>
```

### 1.3 Verificación de Parte 1

```cmd
python manage.py check
```

```
[ ] templates/base.html creado (verificar con: dir templates\base.html)
[ ] Contiene los 2 bloques de tokens CSS (modo día y noche)
[ ] Contiene {% block content %} y {% block title %}
[ ] manage.py check → 0 issues
```

---

## PARTE 2 — Plantillas por App (20 min)

### 2.1 Crear carpetas de templates

```cmd
for %a in (clientes proveedores productos ventas reportes) do (
    mkdir %a\templates\%a
)
```

---

### 2.2 Plantilla de bienvenida actualizada

Reemplazar `templates/bienvenida.html` con versión que hereda de `base.html`:

```html
{% extends "base.html" %}
{% block title %}Inicio{% endblock %}

{% block content %}
<div class="text-center py-4">
    <h1 style="font-family:'Playfair Display',serif;
               color:var(--clr-navy);font-size:2.2rem;">
        📦 ERP Django
    </h1>
    <p style="color:var(--clr-muted);font-size:1.05rem;">
        Sistema de gestión empresarial · UTEC Celaya · Espiral 1 W02
    </p>
    <div class="d-flex justify-content-center gap-2 mt-2 flex-wrap">
        <span class="badge-erp-gold">Django 4.2 LTS</span>
        <span class="badge-erp-gold">Python 3.11</span>
        <span class="badge-erp-gold">Fable 5 AzulERP</span>
    </div>
</div>

<div class="row g-3 mt-2">
    {% for m in modulos %}
    <div class="col-md-4">
        <div class="erp-card text-center"
             style="cursor:pointer;" onclick="window.location='{{ m.url }}'">
            <div style="font-size:2rem;margin-bottom:.4rem;">{{ m.icono }}</div>
            <strong style="color:var(--clr-navy);">{{ m.nombre }}</strong>
            <p style="color:var(--clr-muted);font-size:.85rem;margin:.3rem 0 0;">
                {{ m.descripcion }}
            </p>
        </div>
    </div>
    {% endfor %}
</div>
{% endblock %}
```

---

### 2.3 `productos/templates/productos/index.html`

```html
{% extends "base.html" %}
{% block title %}Productos{% endblock %}
{% block nav_productos %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>📦 Productos</h2>
    <span class="badge-erp-gold ms-auto">Espiral 2 · W05</span>
</div>
<div class="erp-card">
    <div class="erp-card-header">Módulo de Inventario y Productos</div>
    <p>Gestión de catálogo de productos, precios y stock disponible.</p>
    <div class="erp-alert-info">
        <strong>Estado W02:</strong> Módulo en construcción.
        CRUD completo disponible en
        <span class="badge-erp-gold">Espiral 2 · W05–W06</span>
    </div>
    <br>
    <a href="/" class="btn-erp-primary">← Inicio</a>
</div>
{% endblock %}
```

---

### 2.4 `clientes/templates/clientes/index.html`

```html
{% extends "base.html" %}
{% block title %}Clientes{% endblock %}
{% block nav_clientes %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>👥 Clientes</h2>
    <span class="badge-erp-gold ms-auto">Espiral 2 · W04</span>
</div>
<div class="erp-card">
    <div class="erp-card-header">Módulo de Clientes</div>
    <p>Gestión de cartera de clientes y datos de contacto.</p>
    <div class="erp-alert-info">
        <strong>Estado W02:</strong> Módulo en construcción.
        CRUD completo en <span class="badge-erp-gold">Espiral 2 · W04–W06</span>
    </div>
    <br>
    <a href="/" class="btn-erp-primary">← Inicio</a>
</div>
{% endblock %}
```

---

### 2.5 `proveedores/templates/proveedores/index.html`

```html
{% extends "base.html" %}
{% block title %}Proveedores{% endblock %}
{% block nav_proveedores %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>🏭 Proveedores</h2>
    <span class="badge-erp-gold ms-auto">Espiral 2 · W04</span>
</div>
<div class="erp-card">
    <div class="erp-card-header">Módulo de Proveedores</div>
    <p>Red de proveedores y relación con productos del catálogo.</p>
    <div class="erp-alert-info">
        <strong>Estado W02:</strong> Módulo en construcción.
        Implementación en <span class="badge-erp-gold">Espiral 2 · W04–W06</span>
    </div>
    <br>
    <a href="/" class="btn-erp-primary">← Inicio</a>
</div>
{% endblock %}
```

---

### 2.6 `ventas/templates/ventas/index.html`

```html
{% extends "base.html" %}
{% block title %}Ventas{% endblock %}
{% block nav_ventas %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>💰 Ventas</h2>
    <span class="badge-erp-gold ms-auto">Espiral 3 · W07</span>
</div>
<div class="erp-card">
    <div class="erp-card-header">Módulo de Ventas y Pedidos</div>
    <p>Ciclo de ventas, pedidos, facturación y seguimiento.</p>
    <div class="erp-alert-info">
        <strong>Estado W02:</strong> Módulo en construcción.
        CRUD + API en <span class="badge-erp-gold">Espiral 3 · W07–W09</span>
    </div>
    <br>
    <a href="/" class="btn-erp-primary">← Inicio</a>
</div>
{% endblock %}
```

---

### 2.7 `reportes/templates/reportes/index.html`

```html
{% extends "base.html" %}
{% block title %}Reportes{% endblock %}
{% block nav_reportes %}active{% endblock %}

{% block content %}
<div class="erp-page-title">
    <h2>📊 Reportes y Dashboard</h2>
    <span class="badge-erp-gold ms-auto">Espiral 7 · W19</span>
</div>
<div class="erp-card">
    <div class="erp-card-header">Módulo de Analítica</div>
    <p>KPIs, gráficas de ventas y exportación de datos.</p>
    <div class="erp-alert-info">
        <strong>Estado W02:</strong> Módulo en construcción.
        Dashboard en <span class="badge-erp-gold">Espiral 7 · W19–W21</span>
    </div>
    <br>
    <a href="/" class="btn-erp-primary">← Inicio</a>
</div>
{% endblock %}
```

### 2.8 Verificación de Parte 2

```cmd
python manage.py runserver
```

Abrir en el navegador y verificar cada URL:

```
[ ] http://127.0.0.1:8000/           → bienvenida.html + navbar AzulERP visible
[ ] http://127.0.0.1:8000/productos/ → navbar, título "📦 Productos", badge dorado
[ ] http://127.0.0.1:8000/clientes/  → enlace "Clientes" en navbar resaltado (active)
[ ] http://127.0.0.1:8000/ventas/    → página visible sin errores
[ ] Toggle 🌙 → fondo cambia a azul oscuro (#0D1B2A)
[ ] Recargar en modo oscuro → mantiene el modo (localStorage)
```

---

## PARTE 3 — Refactorizar Vistas: `urls.py` → `views.py` (30 min)

### 3.1 Por qué separar vistas de rutas

```
ANTES (W01 — provisional):          DESPUÉS (W02 — patrón MVT correcto):
────────────────────────────        ────────────────────────────────────
productos/urls.py                   productos/views.py
  def vista_temp(request):            def index(request):
    return HttpResponse(...)              return render(request,
                                              'productos/index.html',
                                              context)
                                    productos/urls.py
                                      path('', views.index, name='inicio')
```

**Regla MVT:** `urls.py` solo declara rutas. La lógica va en `views.py`.

---

### 3.2 Actualizar `core/views.py`

```python
# core/views.py
"""Vistas principales del proyecto ERP — W02.

Migración: HttpResponse → render() con templates y contexto.
"""
from django.shortcuts import render
from django.urls import reverse


def bienvenida(request):
    """Página de inicio del ERP con tarjetas de módulos.

    Context:
        modulos (list): Lista de dicts con icono, nombre, url y descripcion.

    Returns:
        HttpResponse con template bienvenida.html.
    """
    modulos = [
        {
            'nombre': 'Productos',
            'icono': '📦',
            'url': reverse('productos:inicio'),
            'descripcion': 'Inventario, precios y stock',
        },
        {
            'nombre': 'Clientes',
            'icono': '👥',
            'url': reverse('clientes:inicio'),
            'descripcion': 'Cartera y gestión de clientes',
        },
        {
            'nombre': 'Proveedores',
            'icono': '🏭',
            'url': reverse('proveedores:inicio'),
            'descripcion': 'Red de proveedores',
        },
        {
            'nombre': 'Ventas',
            'icono': '💰',
            'url': reverse('ventas:inicio'),
            'descripcion': 'Pedidos, facturas y cobros',
        },
        {
            'nombre': 'Reportes',
            'icono': '📊',
            'url': reverse('reportes:inicio'),
            'descripcion': 'Dashboard y analítica',
        },
        {
            'nombre': 'Admin',
            'icono': '⚙️',
            'url': '/admin/',
            'descripcion': 'Panel de administración Django',
        },
    ]
    return render(request, 'bienvenida.html', {'modulos': modulos})
```

---

### 3.3 `views.py` para cada app

Crear o reemplazar el contenido de `views.py` en cada app.
El patrón es idéntico; solo cambian `titulo`, `descripcion` y `espiral`.

**`productos/views.py`**

```python
# productos/views.py
"""Vistas de la app productos — W02 (placeholder).

CRUD completo se implementa en Espiral 2 (W05-W06).
"""
from django.shortcuts import render


def index(request):
    """Vista de índice de productos.

    Returns:
        HttpResponse con template productos/index.html.
    """
    context = {
        'titulo': 'Productos',
        'descripcion': 'Gestión de inventario y catálogo de productos.',
        'espiral': 'Espiral 2 · W05',
    }
    return render(request, 'productos/index.html', context)
```

**`clientes/views.py`**

```python
# clientes/views.py
"""Vistas de la app clientes — W02 (placeholder)."""
from django.shortcuts import render


def index(request):
    """Vista de índice de clientes."""
    context = {
        'titulo': 'Clientes',
        'descripcion': 'Gestión de cartera de clientes.',
        'espiral': 'Espiral 2 · W04',
    }
    return render(request, 'clientes/index.html', context)
```

**`proveedores/views.py`**

```python
# proveedores/views.py
"""Vistas de la app proveedores — W02 (placeholder)."""
from django.shortcuts import render


def index(request):
    """Vista de índice de proveedores."""
    context = {
        'titulo': 'Proveedores',
        'descripcion': 'Red de proveedores de mercancía.',
        'espiral': 'Espiral 2 · W04',
    }
    return render(request, 'proveedores/index.html', context)
```

**`ventas/views.py`**

```python
# ventas/views.py
"""Vistas de la app ventas — W02 (placeholder)."""
from django.shortcuts import render


def index(request):
    """Vista de índice de ventas."""
    context = {
        'titulo': 'Ventas',
        'descripcion': 'Ciclo de ventas, pedidos y facturación.',
        'espiral': 'Espiral 3 · W07',
    }
    return render(request, 'ventas/index.html', context)
```

**`reportes/views.py`**

```python
# reportes/views.py
"""Vistas de la app reportes — W02 (placeholder)."""
from django.shortcuts import render


def index(request):
    """Vista de índice de reportes."""
    context = {
        'titulo': 'Reportes',
        'descripcion': 'Dashboard, KPIs y exportación de datos.',
        'espiral': 'Espiral 7 · W19',
    }
    return render(request, 'reportes/index.html', context)
```

---

### 3.4 Actualizar `urls.py` de cada app

Eliminar las funciones inline de W01. Cada `urls.py` solo importa y referencia.

**`productos/urls.py`**

```python
# productos/urls.py
"""URLs de la app productos — W02."""
from django.urls import path
from . import views

app_name = 'productos'

urlpatterns = [
    path('', views.index, name='inicio'),
    # Espiral 2 W05:
    # path('lista/',          views.ProductoListView.as_view(),   name='lista'),
    # path('nuevo/',          views.ProductoCreateView.as_view(), name='crear'),
    # path('<int:pk>/',       views.ProductoDetailView.as_view(), name='detalle'),
    # path('<int:pk>/editar/',views.ProductoUpdateView.as_view(), name='editar'),
]
```

Aplicar el mismo patrón a `clientes/urls.py`, `proveedores/urls.py`,
`ventas/urls.py` y `reportes/urls.py` — solo cambia el `app_name`.

---

### 3.5 Verificar las 6 rutas con templates

```cmd
python manage.py check
python manage.py runserver
```

| URL | Template renderizado | Navbar activo |
|---|---|---|
| `/` | `bienvenida.html` → 6 tarjetas | — |
| `/productos/` | `productos/index.html` | "Productos" resaltado |
| `/clientes/` | `clientes/index.html` | "Clientes" resaltado |
| `/proveedores/` | `proveedores/index.html` | "Proveedores" resaltado |
| `/ventas/` | `ventas/index.html` | "Ventas" resaltado |
| `/reportes/` | `reportes/index.html` | "Reportes" resaltado |

### COMMIT PARCIAL — punto de control seguro

```cmd
git add .
git commit -m "Sprint 0 W02: render() + templates Fable5 AzulERP x6 vistas"
```

---

## PARTE 4 — Archivos Estáticos y WhiteNoise (15 min)

### 4.1 Respuesta a la tarea de investigación de W01

> **¿Qué es WhiteNoise?**
> Middleware que permite a Django servir archivos estáticos directamente
> desde el proceso WSGI (Gunicorn) en producción, sin necesidad de Nginx.
> Agrega compresión gzip, headers de caché larga duración y sirve archivos
> desde `STATIC_ROOT` de forma eficiente y segura.

---

### 4.2 Crear `static/erp_custom.css`

```cmd
mkdir static
```

Crear `static/erp_custom.css`:

```css
/* static/erp_custom.css
   Utilidades adicionales de Fable 5 AzulERP.
   Las variables CSS principales están definidas en base.html.
*/

/* Tarjetas clicables en la bienvenida */
.erp-module-card {
    transition: transform .2s, box-shadow .2s;
    cursor: pointer;
}
.erp-module-card:hover {
    transform: translateY(-3px);
    box-shadow: var(--shadow-md);
}

/* Utilidades de color */
.text-gold   { color: var(--clr-gold)  !important; }
.text-navy   { color: var(--clr-navy)  !important; }
.bg-navy     { background: var(--clr-navy) !important; }
.border-gold { border-color: var(--clr-gold) !important; }

/* Código monoespaciado */
.font-mono {
    font-family: 'JetBrains Mono', Consolas, monospace !important;
    font-size: .9em;
}
```

---

### 4.3 Verificar configuración en `settings.py`

Confirmar que estas líneas están presentes y correctas:

```python
# settings.py — sección de estáticos (verificar, no duplicar)
STATIC_URL  = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'   # destino de collectstatic

# STATICFILES_DIRS ≠ STATIC_ROOT (error frecuente)
STATICFILES_DIRS = [BASE_DIR / 'static']  # fuentes adicionales

STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
```

> **Error frecuente:** si `STATICFILES_DIRS` incluye el mismo path que
> `STATIC_ROOT`, `collectstatic` falla con `ValueError`.
> Son carpetas **distintas** con propósitos distintos.

Verificar que WhiteNoise está en MIDDLEWARE **después** de SecurityMiddleware:

```python
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',    # ← posición 0
    'whitenoise.middleware.WhiteNoiseMiddleware',       # ← posición 1
    ...
]
```

---

### 4.4 Ejecutar `collectstatic`

```cmd
python manage.py collectstatic --no-input
```

**Resultado esperado:**
```
133 static files copied to 'C:\Temp_Workspace_ERP\staticfiles'.
```

```
[ ] staticfiles/ creada con archivos dentro
[ ] python manage.py check → 0 issues
[ ] staticfiles/ está en .gitignore (no se sube a GitHub)
```

---

## PARTE 5 — `settings_prod.py` y `requirements.txt` (15 min)

### 5.1 Crear `core/settings_prod.py`

```python
# core/settings_prod.py
"""Configuración de producción — Render.com (borrador W02).

Hereda settings.py y sobreescribe valores críticos para producción.
W03 completará: DATABASE_URL con PostgreSQL, variables de Render.

Uso:
    DJANGO_SETTINGS_MODULE=core.settings_prod gunicorn core.wsgi
"""
from .settings import *   # hereda toda la configuración base
import os

# Seguridad básica
DEBUG      = False
SECRET_KEY = os.environ['SECRET_KEY']   # obligatorio; sin default en prod

ALLOWED_HOSTS = os.environ.get(
    'ALLOWED_HOSTS', 'localhost'
).split(',')

# HTTPS y cookies seguras
SECURE_SSL_REDIRECT            = True
SECURE_HSTS_SECONDS            = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SESSION_COOKIE_SECURE          = True
CSRF_COOKIE_SECURE             = True
X_FRAME_OPTIONS                = 'DENY'
SECURE_CONTENT_TYPE_NOSNIFF    = True

# Logging mínimo en producción
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {'console': {'class': 'logging.StreamHandler'}},
    'root': {'handlers': ['console'], 'level': 'WARNING'},
}

# W03 agregará:
# import dj_database_url
# DATABASES = {'default': dj_database_url.config(conn_max_age=600)}
```

---

### 5.2 Actualizar `requirements.txt`

```cmd
pip install gunicorn "psycopg2-binary==2.9.9" "dj-database-url==2.1.0"
pip freeze > requirements.txt
```

Verificar que el archivo contiene al menos:

```
Django==4.2.x
djangorestframework==3.14.x
whitenoise==6.x.x
gunicorn==21.x.x
psycopg2-binary==2.9.9
dj-database-url==2.1.0
django-environ==0.11.x
```

---

### 5.3 Crear `.env.example`

```bash
# .env.example — plantilla pública sin valores reales
# Copiar a .env y completar con datos reales (NUNCA subir .env a Git)
SECRET_KEY=cambiar-por-clave-aleatoria-segura-min-50-chars
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=postgres://user:password@localhost:5432/erp_db
REDIS_URL=redis://localhost:6379/0
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxx
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxxxxx
```

---

## PARTE 6 — Tests W02 (20 min)

### 6.1 Crear `tests/test_w02_mvt.py`

```python
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
    """Verifica que las vistas usan render() y los templates correctos."""

    def test_bienvenida_usa_template_correcto(self):
        """La vista de inicio debe renderizar bienvenida.html."""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, 'bienvenida.html')

    def test_bienvenida_extiende_base(self):
        """La página de inicio debe extender base.html."""
        response = self.client.get('/')
        self.assertTemplateUsed(response, 'base.html')

    def test_productos_usa_template_correcto(self):
        """La vista de productos debe usar productos/index.html."""
        response = self.client.get(reverse('productos:inicio'))
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, 'productos/index.html')

    def test_clientes_usa_template_correcto(self):
        """La vista de clientes debe usar clientes/index.html."""
        response = self.client.get(reverse('clientes:inicio'))
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, 'clientes/index.html')

    def test_proveedores_usa_template_correcto(self):
        """La vista de proveedores debe usar proveedores/index.html."""
        response = self.client.get(reverse('proveedores:inicio'))
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, 'proveedores/index.html')

    def test_ventas_usa_template_correcto(self):
        """La vista de ventas debe usar ventas/index.html."""
        response = self.client.get(reverse('ventas:inicio'))
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, 'ventas/index.html')

    def test_reportes_usa_template_correcto(self):
        """La vista de reportes debe usar reportes/index.html."""
        response = self.client.get(reverse('reportes:inicio'))
        self.assertEqual(response.status_code, 200)
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
```

---

### 6.2 Ejecutar los tests

```cmd
python manage.py test tests.test_w02_mvt --verbosity=2
```

**Resultado esperado:**
```
test_bienvenida_extiende_base ... ok
test_bienvenida_usa_template_correcto ... ok
test_clientes_usa_template_correcto ... ok
test_contexto_contiene_modulos ... ok
test_contexto_tiene_seis_modulos ... ok
test_productos_usa_template_correcto ... ok
test_proveedores_usa_template_correcto ... ok
test_reportes_usa_template_correcto ... ok
test_static_root_configurado ... ok
test_static_url_es_slash_static ... ok
test_ventas_usa_template_correcto ... ok
test_whitenoise_despues_de_security ... ok
test_whitenoise_en_middleware ... ok

Ran 12 tests in X.XXXs
OK
```

### 6.3 Suite acumulada W01 + W02

```cmd
python manage.py test tests --verbosity=2
```

**Resultado esperado:** `Ran 23 tests in X.XXXs · OK`

---

## CIERRE — Commit, Respaldo y Scrum (15 min)

### Actualizar `sprint0_planning.md`

```markdown
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
```

---

### Commit de cierre W02

```cmd
git add .
git status
```

Verificar que **NO** aparecen en staging:
- `env_erp/`
- `.env`
- `staticfiles/`
- `db.sqlite3`

```cmd
git commit -m "Sprint 0 W02 CIERRE: MVT completo + Fable5 + WhiteNoise + 23 tests OK"
git push origin main
```

---

### Ejecutar `finalizar_sesion.bat`

```cmd
:: 1. Detener el servidor (Ctrl+C)
:: 2. Cerrar la terminal
:: 3. Ejecutar el respaldo
E:\finalizar_sesion.bat
```

Verificar en `E:\WorkSpace_ERP\` que existen:

```
[ ] templates\base.html
[ ] templates\bienvenida.html
[ ] productos\templates\productos\index.html  (y los otros 4)
[ ] core\settings_prod.py
[ ] requirements.txt (actualizado con gunicorn)
[ ] tests\test_w02_mvt.py
[ ] .env.example
```

---

## CHECKLIST FINAL W02

### Técnico

```
TEMPLATES
[ ] templates/base.html con tokens CSS día y noche completos
[ ] Toggle 🌙 funciona y persiste en localStorage
[ ] 5 plantillas app/templates/app/index.html creadas
[ ] templates/bienvenida.html usa {% extends "base.html" %}
[ ] Enlace activo en navbar se resalta en cada módulo

VISTAS
[ ] core/views.py: bienvenida() usa render() con contexto 'modulos'
[ ] 5 apps: views.py con función index() que usa render()
[ ] 5 apps: urls.py sin código de vista inline (solo path())
[ ] app_name definido en todos los urls.py

ESTÁTICOS
[ ] static/erp_custom.css creado
[ ] STATICFILES_DIRS != STATIC_ROOT (carpetas distintas)
[ ] collectstatic → sin errores
[ ] WhiteNoise en MIDDLEWARE en posición 1 (después de Security)

PRODUCCIÓN
[ ] core/settings_prod.py con DEBUG=False y SECURE_* activados
[ ] .env.example en el repositorio (sin valores reales)
[ ] requirements.txt: gunicorn + psycopg2-binary + dj-database-url

TESTS
[ ] test tests.test_w02_mvt → 12/12 OK
[ ] test tests → 23/23 OK (W01 + W02 acumulados)

GIT / SCRUM
[ ] sprint0_planning.md con estados actualizados
[ ] 2 commits en W02 con mensajes descriptivos
[ ] git push → GitHub con ≥ 4 commits totales
[ ] finalizar_sesion.bat → archivos en USB verificados
```

---

## DIAGRAMA DE FLUJO — Petición GET en W02

```
Navegador: GET /productos/
      │
      ▼
core/urls.py
  path('productos/', include('productos.urls', namespace='productos'))
      │
      ▼
productos/urls.py
  path('', views.index, name='inicio')
      │
      ▼
productos/views.py
  def index(request):
      context = {'titulo': 'Productos', ...}
      return render(request, 'productos/index.html', context)
      │
      ▼
Django Template Engine
  productos/templates/productos/index.html
  ├── {% extends "base.html" %}
  │       ├── tokens CSS día/noche
  │       ├── navbar Fable 5 AzulERP
  │       ├── messages flash
  │       └── footer
  └── {% block content %}
          └── erp-page-title + erp-card + badge-erp-gold
      │
      ▼
HTML final → Navegador (con modo oscuro opcional)
```

---

## HILO CONDUCTOR → W03

**¿Qué entrega W02?**
Sistema MVT completo con 6 vistas que usan `render()`, sistema de templates
Fable 5 AzulERP con modo claro/oscuro persistente, WhiteNoise configurado,
`settings_prod.py` listo como base, y `requirements.txt` con `gunicorn`.

**¿Qué necesita W03 de W02?**

| Artefacto de W02 | Uso en W03 |
|---|---|
| `settings_prod.py` | W03 agrega `DATABASE_URL`, `ALLOWED_HOSTS` de Render, `dj-database-url` |
| `requirements.txt` con `gunicorn` | W03 lo usa en `Procfile`: `web: gunicorn core.wsgi` |
| `collectstatic` configurado | Render ejecuta `python manage.py collectstatic` en el build |
| Proyecto en GitHub | W03 conecta el repo directamente a Render.com |

**Pregunta de reflexión:**
> "¿Cuál es la diferencia entre `STATIC_ROOT` y `STATICFILES_DIRS`?
> ¿Por qué no pueden apuntar a la misma carpeta?"

**Tarea de investigación para W03:**
> ¿Qué es un `Procfile` y qué diferencia hay entre
> `gunicorn core.wsgi` y `python manage.py runserver`
> en términos de seguridad y rendimiento en producción?

---

## Referencia rápida de comandos W02

```cmd
:: SESIÓN
E:\iniciar_sesion.bat
E:\finalizar_sesion.bat

:: DJANGO
python manage.py check
python manage.py collectstatic --no-input
python manage.py runserver

:: TESTS
python manage.py test tests.test_w02_mvt --verbosity=2
python manage.py test tests --verbosity=2

:: GIT
git add .
git commit -m "Sprint 0 W02: descripción"
git push origin main
git log --oneline
```

---

*Guía de Laboratorio W02 · ERP Django*
*Espiral 1 · Sprint 0 · MVT + Fable 5 AzulERP + WhiteNoise*
*SEP 3061300006-23 · UTEC Celaya · MC. Román Fernando López González*