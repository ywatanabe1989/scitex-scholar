---
description: Detailed development patterns for SciTeX apps — views.py, urls.py, templates (AJAX partial), CSS scoping, React bridge, and Django AppConfig.
---

# App Development Patterns

Detailed patterns for Step 2 of the [app lifecycle](app-lifecycle.md).

---

## views.py — Complete Pattern

```python
# my_awesome_app/views.py
from django.shortcuts import render
from django.http import JsonResponse
from apps.infra.project_app.services.project_utils import get_current_project


def build_my_awesome_app_context(request, current_project=None):
    """
    Context builder — called by workspace registry for AJAX partial loads.
    Must accept (request, current_project=None) signature.
    Returns a dict that becomes the template context.
    """
    return {
        "current_project": current_project,
        "app_name": "My Awesome App",
        # Add any data your template needs here
    }


def index_view(request):
    """Full-page view — used in standalone mode and direct URL access."""
    current_project = (
        get_current_project(request) if request.user.is_authenticated else None
    )
    context = build_my_awesome_app_context(request, current_project=current_project)
    return render(request, "my_awesome_app/index.html", context)


def partial_view(request):
    """AJAX partial view — workspace loads this into the sidebar pane."""
    current_project = (
        get_current_project(request) if request.user.is_authenticated else None
    )
    context = build_my_awesome_app_context(request, current_project=current_project)
    return render(request, "my_awesome_app/index_partial.html", context)


def api_view(request):
    """Optional API endpoint for AJAX calls from your app's JS."""
    if request.method == "POST":
        import json
        data = json.loads(request.body)
        # process data["action"] etc.
        return JsonResponse({"status": "ok"})
    return JsonResponse({"error": "Method not allowed"}, status=405)
```

---

## urls.py — Complete Pattern

```python
# my_awesome_app/urls.py
from django.urls import path
from . import views

app_name = "my_awesome_app"

urlpatterns = [
    path("", views.index_view, name="index"),
    path("partial/", views.partial_view, name="partial"),
    path("api/", views.api_view, name="api"),
]
```

---

## apps.py — Django AppConfig

```python
# my_awesome_app/apps.py
from django.apps import AppConfig


class MyAwesomeAppConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "my_awesome_app"
    label = "my_awesome_app"
    verbose_name = "My Awesome App"
```

Alternatively, use `ScitexAppConfig` from the SDK for auto manifest loading:

```python
from scitex_app._django import ScitexAppConfig

class MyAwesomeAppConfig(ScitexAppConfig):
    name = "my_awesome_app._django"  # or just "my_awesome_app"
    label = "my_awesome_app"
    verbose_name = "My Awesome App"

# Properties available after startup:
# config.manifest        -> dict (raw manifest)
# config.app_slug        -> str  (manifest["slug"])
# config.app_version     -> str  (manifest["version"])
# config.app_icon        -> str  (manifest["icon"])
# config.is_standalone   -> bool
# config.frontend_type   -> str  ("html" or "react")
# config.validate_manifest() -> List[str]  (empty = valid)
```

---

## index_partial.html — AJAX Partial Template

The partial template is loaded into the workspace pane via AJAX. It must be
self-contained — no `<html>`, `<head>`, or `<body>` tags.

```html
<!-- templates/my_awesome_app/index_partial.html -->
<div class="my-awesome-app-container">
    <div class="my-awesome-app-header">
        <h2>My Awesome App</h2>
        {% if current_project %}
            <span class="my-awesome-app-project">{{ current_project.name }}</span>
        {% endif %}
    </div>

    <div class="my-awesome-app-body">
        <button id="my-awesome-app-run-btn" class="my-awesome-app-btn">
            Run
        </button>
        <div id="my-awesome-app-output" class="my-awesome-app-output"></div>
    </div>
</div>

<script>
// Always wrap in IIFE to avoid namespace collisions with workspace JS
(function() {
    const btn = document.getElementById('my-awesome-app-run-btn');
    if (!btn) return;

    btn.addEventListener('click', function() {
        fetch('{% url "my_awesome_app:api" %}', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '',
            },
            body: JSON.stringify({ action: 'run' }),
        })
        .then(r => r.json())
        .then(data => {
            document.getElementById('my-awesome-app-output').textContent =
                JSON.stringify(data, null, 2);
        })
        .catch(err => console.error('my-awesome-app error:', err));
    });
})();
</script>
```

### Template tags available in partials

```html
{% load static %}
{% static 'my_awesome_app/css/my_awesome_app.css' %}
{% url "my_awesome_app:api" %}
{{ current_project.name }}
{{ request.user.username }}
```

---

## CSS Scoping Rule

All CSS must be scoped to the app's own prefix. Never target reserved shell selectors —
validation rejects them.

```css
/* my_awesome_app/static/my_awesome_app/css/my_awesome_app.css */

/* Correct — scoped to app prefix */
.my-awesome-app-container { padding: 1rem; }
.my-awesome-app-header    { font-size: 1.2rem; font-weight: bold; }
.my-awesome-app-btn       { background: #0066cc; color: white; padding: 0.5rem 1rem; }
.my-awesome-app-output    { font-family: monospace; margin-top: 1rem; }

/* Forbidden — validation error (these target workspace shell) */
/* #scitex-ai-panel { ... }         */
/* .workspace-sidebar { ... }       */
/* #main-content { ... }            */
/* .ws-module-pane { ... }          */
/* .workspace-header { ... }        */
/* .stx-shell-anything { ... }      */
/* #workspace-container { ... }     */
/* .ws-app-sidebar { ... }          */
```

---

## React Frontend Pattern

If scaffolded with `--frontend react`, additional files are generated:

```
src/
    bridge/
        bridge-init.ts       # Connects React app to workspace AJAX machinery
    components/
        App.tsx              # Root React component
    store/
        index.ts             # Zustand state store
package.json
vite.config.js
```

### Build before dev-install

```bash
npm install
npm run build   # outputs to static/my_awesome_app/dist/
```

### Partial template for React apps

```html
<!-- templates/my_awesome_app/index_partial.html -->
{% load static %}
<div id="my-awesome-app-root"></div>
<script type="module" src="{% static 'my_awesome_app/dist/index.js' %}"></script>
```

### Bridge init pattern

```typescript
// src/bridge/bridge-init.ts
// Initializes communication between React app and workspace shell
import { useStore } from '../store';

window.__scitex_bridge = {
    onProjectChange: (project) => {
        useStore.getState().setProject(project);
    },
};
```

### vite.config.js output path

```javascript
// vite.config.js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
    plugins: [react()],
    build: {
        outDir: 'static/my_awesome_app/dist',
        emptyOutDir: true,
    },
});
```

---

## Using the Files SDK in Views

For file operations, use the SDK instead of `open()` directly:

```python
from scitex_app.sdk import get_files

def api_view(request):
    files = get_files(request.user.project_dir)   # or get_files() for cloud
    content = files.read("data/config.yaml")
    files.write("output/result.json", '{"ok": true}')
    tree = files.list("", extensions=[".py", ".yaml"])
    return JsonResponse({"files": tree})
```

`get_files()` auto-selects backend:
1. Explicit `backend=` argument
2. `SCITEX_API_TOKEN` env var → cloud backend
3. Fallback → local `FileSystemBackend`

# EOF
