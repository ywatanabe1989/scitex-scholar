---
description: run_standalone() — launch a SciTeX app locally with the full workspace shell (Django + sidebar + file tree + AI panel) without scitex-cloud.
---

# Standalone Mode

`scitex_app._standalone.run_standalone()` launches any SciTeX app locally with the full workspace shell — same UX as scitex-cloud, no server required.

## run_standalone()

```python
def run_standalone(
    app_module: str,
    port: int = 8050,
    host: str = "127.0.0.1",
    open_browser: bool = True,
    hot_reload: bool = False,
    working_dir: Optional[str] = None,
    desktop: bool = False,
    extra_installed_apps: Optional[list[str]] = None,
    extra_staticfiles_dirs: Optional[list[str]] = None,
    extra_env: Optional[dict[str, str]] = None,
) -> None
```

### Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `app_module` | required | Dotted path to the app's Django module (e.g. `"my_app"`) |
| `port` | `8050` | TCP port for the Django server |
| `host` | `"127.0.0.1"` | Host to bind (use `"0.0.0.0"` for LAN access) |
| `open_browser` | `True` | Open browser tab automatically after 1.5 s |
| `hot_reload` | `False` | Enable Django `--reload` (file watching) |
| `working_dir` | `None` | Sets `SCITEX_WORKING_DIR`; defaults to `cwd` |
| `desktop` | `False` | Launch as native window via `pywebview` if installed |
| `extra_installed_apps` | `None` | Additional Django app strings to add to `INSTALLED_APPS` |
| `extra_staticfiles_dirs` | `None` | Additional static file directories |
| `extra_env` | `None` | Extra env vars to set before Django configures |

### Basic usage

```python
from scitex_app._standalone import run_standalone

# Minimal — app at my_app/urls.py, my_app/views.py, etc.
run_standalone(app_module="my_app")

# Custom port, no browser
run_standalone(app_module="my_app", port=5050, open_browser=False)

# Native desktop window (requires: pip install pywebview)
run_standalone(app_module="my_app", desktop=True)
```

### From a scaffolded app's CLI

Apps created with `scitex-app app init` get a `_cli.py` with a `gui` command:

```bash
my-app gui                           # default port 8050
my-app gui --port 5000 --no-browser
my-app gui --force                   # kill existing process on port first
```

### Django settings configured

`run_standalone()` calls `django.conf.settings.configure()` with:

- `INSTALLED_APPS`: `django.contrib.staticfiles`, `<app_module>`, `scitex_ui` (if installed)
- `ROOT_URLCONF`: `<app_module>.urls`
- `STATIC_URL`: `/static/`
- `STATICFILES_DIRS`: app's own `static/` + `_standalone_static/` shell assets
- `DATABASES`: `{}` (no DB required for read-only apps)
- `SECRET_KEY`: from `DJANGO_SECRET_KEY` env or `"scitex-standalone-dev-key"`
- `DEBUG`: from `DJANGO_DEBUG` env (default `"true"`)

Settings configure only once — calling `run_standalone()` a second time is a no-op if Django is already configured.

### Requirements

- `django` (always required)
- `scitex_ui` (optional, provides the workspace shell sidebar/panel)
- `pywebview` (optional, only for `desktop=True`)
