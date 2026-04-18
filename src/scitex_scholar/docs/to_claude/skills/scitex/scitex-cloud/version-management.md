---
description: Manage and sync versions across SciTeX ecosystem packages.
---

# Version Management

## Dashboard
```bash
scitex dev versions list --json
# Also: http://127.0.0.1:5000
```

## Version Sync
Bidirectional sync between local and remote (NAS):
```bash
scitex dev versions sync --confirm --host nas
scitex dev ecosystem list
```

## Ecosystem Package Order
1. scitex (scitex-python) — core framework
2. scitex-cloud — platform
3. figrecipe — plotting
4. openalex-local, crossref-local — literature
5. scitex-writer — manuscripts
6. scitex-dataset — data
7. socialia — social media

## Version Bump Checklist
- `pyproject.toml`
- `__init__.py`
- Git tag
- Push to origin/main and origin/develop
- GitHub Release
- PyPI Release
