---
description: Path resolution utilities for SciTeX apps. get_base_dir(), resolve_user_project_dir(), resolve_published_project_dir(), resolve_manifest(), find_partial_template(), parse_dev_module_name().
---

# Path Resolution

`scitex_app.paths` — Django-agnostic path utilities for SciTeX app directories.

All functions accept an explicit `base_dir` parameter. When omitted, `SCITEX_BASE_DIR` env var is used.

## Directory Layout

```
base_dir/
  data/
    users/<owner>/proj/<repo>/      # user (dev) apps
      manifest.json
      templates/<app_name>/index_partial.html
      static/<app_name>/...
    projects/<slug>/                # published projects
      manifest.json
      ...
```

## Base Directory

```python
def get_base_dir(base_dir: Union[str, Path, None] = None) -> Path
```

Priority: explicit argument > `SCITEX_BASE_DIR` env var.

```python
from scitex_app.paths import get_base_dir

base = get_base_dir("/data/scitex")           # explicit
base = get_base_dir()                          # reads SCITEX_BASE_DIR
# raises ValueError if neither is available
```

## Project Directory Resolution

```python
def resolve_user_project_dir(
    owner: str,
    repo: str,
    *,
    base_dir: Union[str, Path, None] = None,
) -> Optional[Path]
```

Returns `None` if `base_dir/data/users/<owner>/proj/<repo>/` does not exist.

```python
from scitex_app.paths import resolve_user_project_dir

project_dir = resolve_user_project_dir("alice", "my_app")
if project_dir:
    print(project_dir)  # Path(".../data/users/alice/proj/my_app")
```

```python
def resolve_published_project_dir(
    slug: str,
    *,
    base_dir: Union[str, Path, None] = None,
) -> Optional[Path]
```

Returns `None` if `base_dir/data/projects/<slug>/` does not exist.

```python
from scitex_app.paths import resolve_published_project_dir

project_dir = resolve_published_project_dir("my-app-v2")
```

## Manifest

```python
def resolve_manifest(project_dir: Union[str, Path]) -> dict
```

Reads `manifest.json` from a project directory. Returns `{}` if the file does not exist or is invalid JSON (logs a warning).

```python
from scitex_app.paths import resolve_manifest

manifest = resolve_manifest(project_dir)
app_name = manifest.get("name", "unknown")
```

## Template Resolution

```python
def find_partial_template(
    templates_dir: Union[str, Path],
    filename: str = "index_partial.html",
) -> Optional[Path]
```

Supports two layouts:
- Flat: `templates/index_partial.html`
- Nested: `templates/<app_name>/index_partial.html` (first matching subdirectory)

```python
def resolve_template_dir(project_dir: Union[str, Path]) -> Optional[Path]
```

Returns `project_dir/templates` if it exists, else `None`.

## Static Directory

```python
def resolve_static_dir(project_dir: Union[str, Path]) -> Optional[Path]
```

Returns `project_dir/static` if it exists, else `None`.

## Module Name Parsing

```python
def parse_dev_module_name(module_name: str) -> Optional[tuple[str, str]]
```

Parses the `dev__<owner>__<repo>` convention used by scitex-cloud for dev apps.

```python
from scitex_app.paths import parse_dev_module_name

result = parse_dev_module_name("dev__alice__my_app")
# ("alice", "my_app")

result = parse_dev_module_name("published_app")
# None — not a dev module name
```

## Directory Utilities

```python
def safe_iterdir(directory: Union[str, Path]) -> Iterator[Path]
```

Iterates directory entries in sorted order, skipping hidden files (names starting with `.`). Silently handles `PermissionError` and `OSError`.

```python
def validate_project_structure(project_dir: Union[str, Path]) -> tuple[bool, str]
```

Returns `(is_valid, message)`. Checks:
1. `project_dir` exists and is a directory
2. `project_dir/templates/` exists
3. `index_partial.html` is found inside `templates/`

```python
from scitex_app.paths import validate_project_structure

ok, msg = validate_project_structure("/path/to/my_app")
if not ok:
    print(f"Invalid: {msg}")
```
