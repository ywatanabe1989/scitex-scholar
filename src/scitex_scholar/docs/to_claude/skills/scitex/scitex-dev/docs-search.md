---
topic: docs-search
package: scitex-dev
description: >
  Documentation aggregation and unified search across all SciTeX packages.
  get_docs resolves pre-built Sphinx HTML, existing Sphinx builds, or
  introspected docstrings. search supports Google-like query syntax across
  Python API, CLI commands, MCP tools, and docs pages.
---

# Docs Aggregation and Search

## get_docs

Get documentation for one, several, or all installed SciTeX packages.

```python
from scitex_dev import get_docs

# All installed packages (manifest overview)
get_docs()

# Single package — returns unwrapped result
get_docs(
    package: str | None = None,         # single package name
    packages: list[str] | None = None,  # list of packages
    format: str | None = None,          # None (manifest) | "json" | "html"
    page: str | None = None,            # specific page (with format="html"/"json")
) -> Any
```

Resolution chain per package (fastest to slowest):
1. Pre-built `_sphinx_html/` in installed package (production)
2. Sphinx `_build/` available (existing build)
3. Introspect from docstrings + signatures (always works)

```python
# Manifest overview of all packages
manifests = get_docs()

# Single package manifest
info = get_docs(package="scitex-io")
print(info["version"], info["description"])
print(info["pages"])

# HTML path
html_dir = get_docs(package="scitex-io", format="html")

# Specific page
page_data = get_docs(package="scitex-io", format="json", page="api")

# Multiple packages
results = get_docs(packages=["scitex-io", "scitex-stats"])
for pkg, data in results.items():
    print(pkg, data.get("version"))
```

## build_docs

Build docs from Sphinx source for one or all packages.

```python
from scitex_dev import build_docs

result = build_docs(
    package: str | None = None,            # None = all discovered packages
    output_dir: Path | None = None,        # override output dir
    formats: list[str] | None = None,      # ["html"] default
) -> dict[str, dict]  # {pkg_name: {format: path_or_error}}
```

Requires `sphinx` (`pip install scitex-dev[docs]`).

```python
# Build all
build_docs()

# Build specific package
result = build_docs(package="scitex-io", formats=["html", "json"])
print(result["scitex-io"]["html"])   # path to built HTML
```

## search_docs

Simple keyword search over package page titles and introspected content.

```python
from scitex_dev import search_docs

results = search_docs(
    query: str,
    package: str | None = None,        # limit to single package
    packages: list[str] | None = None, # limit to specific packages
    max_results: int = 10,
) -> list[dict]
# [{"package", "name", "title", "score", "match_type"}, ...]
```

```python
hits = search_docs("save figure")
for h in hits:
    print(h["package"], h["name"], h["score"])
```

## search

Unified search across Python APIs, CLI commands, MCP tools, and docs pages.
Supports Google-like query syntax.

```python
from scitex_dev import search

results = search(
    query: str,                        # see syntax below
    scope: str = "all",                # "all" | "api" | "cli" | "mcp" | "docs"
    package: str | None = None,
    packages: list[str] | None = None,
    max_results: int = 10,
    fuzzy: bool = True,                # difflib fuzzy matching
) -> list[dict]
# [{"package", "name", "title", "score", "scope", "match_type"}, ...]
```

### Query syntax

| Syntax | Meaning |
|---|---|
| `save figure` | match any term (OR) |
| `"save figure"` | exact phrase match (3x weight) |
| `+ttest statistics` | `ttest` required (must appear) |
| `stats -deprecated` | exclude results containing "deprecated" |
| `+save "to disk"` | required term + exact phrase |

Score weights: phrase=3.0, required=2.0, optional=1.0, fuzzy=0.5.

```python
# Search all scopes
results = search("save figure")

# Python API only
results = search("ttest", scope="api")

# MCP tools only, excluding deprecated
results = search("stats -deprecated", scope="mcp")

# Exact phrase match
results = search('"session decorator"')

# Required term
results = search("+load csv")

# Scoped to single package
results = search("save", scope="api", package="scitex-io")
```

## CLI

```bash
# Search across all packages
scitex-dev search "save figure"
scitex-dev search "ttest" --scope api
scitex-dev search "stats" --scope mcp --max-results 5
scitex-dev search '"session decorator"'
scitex-dev search "save figure" --json

# Docs commands
scitex-dev docs list
scitex-dev docs get scitex-io
scitex-dev docs get scitex-io --format html
scitex-dev docs search "save figure"
scitex-dev docs build scitex-io
```
