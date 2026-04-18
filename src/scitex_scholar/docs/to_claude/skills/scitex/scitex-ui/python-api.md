---
description: Python API for scitex-ui — component registry, static path resolution, Django integration. Use when introspecting components or configuring Django.
---

# scitex-ui Python API

## Installation

```python
# Add to Django INSTALLED_APPS for static asset discovery
INSTALLED_APPS = [
    ...
    "scitex_ui",
]
```

## Public API (`from scitex_ui import ...`)

### `list_components() -> list[str]`

Returns sorted list of all registered component names.

```python
from scitex_ui import list_components
list_components()
# ['app-shell', 'confirm-modal', 'data-table', 'dropdown',
#  'file-browser', 'file-tabs', 'media-viewer', 'monaco-editor',
#  'package-docs-sidebar', 'resizer', 'status-bar',
#  'theme-provider', 'tooltip']
```

### `get_component(name: str) -> type | None`

Returns component class with metadata attributes, or `None` if not found.

```python
from scitex_ui import get_component
c = get_component("data-table")
c.name         # "data-table"
c.version      # "0.1.0"
c.description  # "Full spreadsheet component with selection, editing, virtual scroll, CSV import"
c.ts_entry     # "scitex_ui/ts/app/data-table/index"
c.css_file     # "scitex_ui/css/app/data-table.css"
```

### `get_static_dir() -> pathlib.Path`

Absolute path to the `static/scitex_ui/` directory (contains `css/`, `ts/`).
Used by build tools (Vite, Webpack) that need to resolve source files at build time.

```python
from scitex_ui import get_static_dir
static = get_static_dir()
# e.g. /usr/lib/.../scitex_ui/static/scitex_ui
```

### `get_docs_path() -> pathlib.Path`

Absolute path to the bundled Sphinx HTML docs directory (`_sphinx_html/`).

```python
from scitex_ui import get_docs_path
docs = get_docs_path()
```

### `register_component(name: str, metadata: Any) -> None`

Register a custom component. Used internally by `_components/`; available for custom component authors.

```python
from scitex_ui import register_component

class MyComponent:
    name = "my-component"
    version = "1.0.0"
    description = "Custom widget"
    ts_entry = "my_app/ts/my-component/index"
    css_file = "my_app/css/my-component.css"

register_component(MyComponent.name, MyComponent)
```

## Registered Components

| Name | Description | Category |
|------|-------------|----------|
| `app-shell` | Workspace layout shell with collapsible sidebar | shell |
| `resizer` | Draggable panel divider with collapse, snap, persistence | shell |
| `status-bar` | Bottom status bar with left/center/right sections | shell |
| `theme-provider` | Light/dark theme manager with semantic color tokens | shell |
| `confirm-modal` | Modern confirmation dialog replacing `window.confirm()` | app |
| `data-table` | Spreadsheet with selection, editing, virtual scroll, CSV import | app |
| `dropdown` | Context menu dropdown attached to a trigger element | app |
| `file-browser` | Tree view for navigating file hierarchies | app |
| `file-tabs` | Tab bar with drag-reorder and rename | app |
| `media-viewer` | Display images, PDFs, diagrams with zoom/pan | app |
| `monaco-editor` | Monaco code editor with diff support, themes, language detection | app |
| `package-docs-sidebar` | Navigable sidebar for Python package documentation | app |
| `tooltip` | Auto-positioned tooltip system using `data-tooltip` attributes | app |

## Django Static Files

Django's `AppDirectoriesFinder` auto-discovers `static/scitex_ui/` when `scitex_ui` is in `INSTALLED_APPS`. No manual `STATICFILES_DIRS` needed.

```python
# settings.py
INSTALLED_APPS = ["scitex_ui", ...]
# Run: python manage.py collectstatic
```

## Quick Template

```html
{% extends "scitex_ui/standalone_shell.html" %}
{% block app_content %}
    <div id="root"></div>
{% endblock %}
```
