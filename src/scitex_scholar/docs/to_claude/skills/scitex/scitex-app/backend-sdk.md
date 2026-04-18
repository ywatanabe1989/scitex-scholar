---
description: Backend SDK reference — FilesBackend protocol, Django integration, manifest schema, app validation, path resolution
---

#!/usr/bin/env python3
# scitex_app — AI Agent Developer Guide
# Timestamp: 2026-03-18
# Audience: AI coding agents building SciTeX apps

---

## 1. Quick Start

```python
from scitex_app.sdk import get_files

# Local: pass a directory path
files = get_files("./my_project")
content = files.read("data/config.yaml")
files.write("output/result.json", '{"ok": true}')

# Cloud: auto-detected when SCITEX_API_TOKEN is set
import os
os.environ["SCITEX_API_TOKEN"] = "your-token"
os.environ["SCITEX_API_URL"] = "https://scitex.ai"
files = get_files()  # routes to cloud REST API
```

Auto-detection order:
1. Explicit `backend=` argument wins
2. `SCITEX_API_TOKEN` env var → cloud backend
3. Fallback → local `FileSystemBackend`

---

## 2. FilesBackend Protocol

`FilesBackend` is a `typing.Protocol` — no inheritance needed, just implement these 7 methods.

```python
from scitex_app.sdk import FilesBackend
from typing import List, Optional, Union

class MyBackend:                                        # no inheritance required
    def read(self, path: str, *, binary: bool = False) -> Union[str, bytes]: ...
    def write(self, path: str, content: Union[str, bytes]) -> None: ...
    def list(self, directory: str = "", *, extensions: Optional[List[str]] = None) -> List[str]: ...
    def exists(self, path: str) -> bool: ...
    def delete(self, path: str) -> None: ...            # raises FileNotFoundError
    def rename(self, old_path: str, new_path: str) -> None: ...  # raises FileNotFoundError / FileExistsError
    def copy(self, src_path: str, dest_path: str) -> None: ...   # raises FileNotFoundError
```

Registering a custom backend:

```python
from scitex_app.sdk import register_backend

def my_s3_factory(root, **kwargs) -> MyBackend:
    return MyBackend(root, **kwargs)

register_backend("s3", my_s3_factory)
files = get_files(backend="s3", bucket="my-bucket")
```

---

## 3. Django Integration

### AppConfig

```python
# myapp/_django/apps.py
from scitex_app._django import ScitexAppConfig

class MyAppConfig(ScitexAppConfig):
    name = "myapp._django"
    label = "myapp"
    verbose_name = "My App"

# Properties available after loading manifest.json:
# config.manifest        -> dict (raw manifest)
# config.app_slug        -> str  (manifest["slug"])
# config.app_version     -> str  (manifest["version"])
# config.app_icon        -> str  (manifest["icon"])
# config.is_standalone   -> bool (manifest["standalone"], default False)
# config.frontend_type   -> str  (manifest["frontend_type"], default "django")
# config.validate_manifest() -> List[str]  (empty = valid)
```

### View factories

```python
# myapp/_django/views.py
from pathlib import Path
from scitex_app._django import scitex_editor_page, scitex_api_dispatch

STATIC_DIR = Path(__file__).parent / "static" / "myapp"

# Serves React SPA index.html; returns 503 if build missing
editor_page = scitex_editor_page(
    static_dir=STATIC_DIR,
    index_file="index.html",                    # default
    fallback_message="Run: npm run build",      # default
)

def _get_editor(request):
    """Return your app's editor/context object, or None."""
    ...

api_dispatch = scitex_api_dispatch(
    handlers={
        "load":   lambda req, editor: ...,      # JsonResponse
        "save":   lambda req, editor: ...,
    },
    parameterized=[
        ("file/", lambda req, editor, param: ...),  # /file/<anything>
    ],
    no_editor_endpoints={"health"},             # endpoints that skip editor check
    get_editor=_get_editor,
)
```

### URL patterns

```python
# myapp/_django/urls.py
from scitex_app._django import scitex_urlpatterns
from . import views

urlpatterns = scitex_urlpatterns(views)
# Generates:
#   ""                  -> views.editor_page  (name="editor")
#   "<path:endpoint>"   -> views.api_dispatch (name="api")
```

---

## 4. Manifest Schema

```json
{
  "name":    "My App",
  "slug":    "myapp",
  "label":   "myapp",
  "version": "0.1.0",
  "icon":    "fas fa-flask",

  "standalone":    false,
  "frontend_type": "react",

  "privileges": [
    {"type": "filesystem", "scope": "project"},
    {"type": "network",    "scope": "none"},
    {"type": "api",        "scope": "scitex"}
  ],
  "dependencies": ["scitex>=1.0"],
  "bridge": {}
}
```

Required fields: `name`, `slug`, `label`, `version`, `icon`

Valid privilege combinations:

| type         | valid scopes                    |
|--------------|---------------------------------|
| `filesystem` | `project`, `readonly`, `none`   |
| `network`    | `none`, `allowlist`             |
| `api`        | `scitex`, `llm`, `none`         |

---

## 5. App Validation

```python
from scitex_app.validator import AppValidator

validator = AppValidator("/path/to/myapp")      # accepts str or Path
result = validator.validate()

print(result.passed)     # bool
print(result.errors)     # List[str] — fail conditions
print(result.warnings)   # List[str] — advisory notices
print(result.manifest)   # dict | None
```

Validation pipeline (runs in order):
1. `validate_manifest()` — required fields, valid JSON, semver version
2. `validate_structure()` — `_django/views.py` and `_django/urls.py` present
3. `validate_css()` — no CSS targeting shell selectors (see below)
4. `validate_js()` — no dangerous JS patterns
5. `validate_bundle_size()` — total size < 50 MB (configurable via `max_bundle_size`)
6. `validate_privileges()` — privilege types and scopes must be valid

Shell selectors apps must NOT target:
`#scitex-ai-panel`, `#main-content`, `.ws-module-pane`, `.workspace-header`,
`.workspace-sidebar`, `.stx-shell-*`, `#workspace-container`, `.ws-app-sidebar`

Dangerous JS patterns blocked:
`eval(`, `Function(`, `document.cookie`, `window.parent`, `window.top`,
`__import__`, `os.system`, `subprocess`, `exec(`

Skipped directories during scanning: `node_modules`, `dist`, `.vite`, `_docs`,
`__pycache__`, `assets`

---

## 6. Path Resolution

```python
from scitex_app.paths import (
    get_base_dir,
    resolve_user_project_dir,
    resolve_published_project_dir,
    resolve_manifest,
    resolve_template_dir,
    resolve_static_dir,
    find_partial_template,
    parse_dev_module_name,
    safe_iterdir,
    validate_project_structure,
)

# Base dir: explicit arg > SCITEX_BASE_DIR env var > ValueError
base = get_base_dir()                         # reads SCITEX_BASE_DIR
base = get_base_dir("/data/scitex")           # explicit

# User dev-app: base_dir/data/users/<owner>/proj/<repo>/
project = resolve_user_project_dir("alice", "my-app", base_dir=base)

# Published project: base_dir/data/projects/<slug>/
project = resolve_published_project_dir("my-app-v1", base_dir=base)

# Manifest, templates, static from project dir
manifest = resolve_manifest(project)          # dict (empty if missing/invalid)
tpl_dir  = resolve_template_dir(project)      # Path | None
static   = resolve_static_dir(project)        # Path | None

# Find partial template (flat or nested layout)
tpl = find_partial_template(tpl_dir)          # searches for index_partial.html

# Parse dev module name convention: dev__<owner>__<repo>
owner, repo = parse_dev_module_name("dev__alice__my-app")  # -> ("alice", "my-app")

# Validate project structure (has templates/ + index_partial.html)
ok, msg = validate_project_structure(project)

# Safe directory iteration (skips hidden files, handles permission errors)
for entry in safe_iterdir(project):
    print(entry)
```

Directory layout convention:

```
base_dir/
  data/
    users/<owner>/proj/<repo>/    # dev apps
      manifest.json
      templates/<app>/index_partial.html
      static/<app>/...
    projects/<slug>/              # published apps
      manifest.json
```

---

## 7. Minimal App Checklist

```
myapp/
  _django/
    __init__.py
    apps.py      # class MyAppConfig(ScitexAppConfig)
    views.py     # editor_page = scitex_editor_page(...); api_dispatch = scitex_api_dispatch(...)
    urls.py      # urlpatterns = scitex_urlpatterns(views)
    manifest.json
  src/           # Python core logic (no Django)
```

- manifest.json must have all 5 required fields
- No CSS targeting shell selectors
- No dangerous JS patterns
- `_django/views.py` and `_django/urls.py` required for platform integration
- Use `get_files()` for all file I/O — never `open()` directly in app logic
- **Packaging**: Apps with a `bridge` key in manifest.json must keep `_django/frontend/src/` in their source tree. scitex-cloud discovers bridges by scanning sibling directories. Use an `[app]` optional extra for platform Python deps. In CI, clone the repo as a sibling.

# EOF
