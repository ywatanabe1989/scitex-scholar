---
topic: versions
package: scitex-dev
description: >
  Version checking and mismatch detection across the SciTeX ecosystem.
  Compares pyproject.toml, installed (importlib.metadata), git tag, and
  PyPI versions. fix_mismatches combines detection with sync.
---

# Version Management

## list_versions

Collect version info for ecosystem packages from all sources.

```python
from scitex_dev import list_versions

result = list_versions(
    packages: list[str] | None = None,  # None = all ecosystem packages
) -> dict[str, dict]
```

Returns a dict keyed by package name. Each value has:

```python
{
    "local": {
        "pyproject_toml": "0.3.2",   # from pyproject.toml
        "installed": "0.3.2",        # from importlib.metadata
    },
    "git": {
        "latest_tag": "v0.3.2",
        "branch": "develop",
        "dirty": False,
        "ahead": 0,
        "behind": 0,
        "short_hash": "f08fdfd",
    },
    "remote": {
        "pypi": "0.3.1",             # from PyPI JSON API
    },
    "status": "unreleased",          # ok | mismatch | unreleased | outdated | unavailable
    "issues": ["local (0.3.2) > pypi (0.3.1) - ready to release"],
}
```

Status values:
- `ok` — all sources agree, no issues
- `mismatch` — pyproject.toml != installed or git tag, or dirty/ahead/behind
- `unreleased` — local version > PyPI (ready to publish)
- `outdated` — local version < PyPI
- `unavailable` — package not found locally

```python
# Check specific packages
info = list_versions(["scitex-io", "scitex-stats"])
for pkg, data in info.items():
    print(pkg, data["status"], data.get("issues"))
```

## check_versions

Same as `list_versions` but adds a summary counts dict.

```python
from scitex_dev import check_versions

result = check_versions(
    packages: list[str] | None = None,
) -> dict
# {"packages": {...}, "summary": {"total": 20, "ok": 15, "mismatch": 3, ...}}
```

```python
report = check_versions()
print(report["summary"])
# {"total": 20, "ok": 15, "mismatch": 2, "unreleased": 2, "outdated": 1, ...}
```

## get_mismatches

Return only packages with non-ok status.

```python
from scitex_dev import get_mismatches

result = get_mismatches(
    packages: list[str] | None = None,
) -> dict[str, dict]  # same schema as list_versions, filtered to non-ok
```

```python
mismatches = get_mismatches()
for pkg, info in mismatches.items():
    print(f"{pkg}: {info['status']} — {info['issues']}")
```

## fix_mismatches

Detect mismatches and fix them (local pip reinstall + remote git pull).

```python
from scitex_dev import fix_mismatches

result = fix_mismatches(
    hosts: list[str] | None = None,    # None = all enabled hosts
    packages: list[str] | None = None, # None = all mismatched packages
    local: bool = True,                # pip install -e . locally
    remote: bool = True,               # git pull + pip install on SSH hosts
    confirm: bool = False,             # False = dry-run (default)
    config=None,
) -> dict
# {"detected": {...}, "local_fixes": {...}, "remote_fixes": {...}, "summary": {...}}
```

Safety: always defaults to `confirm=False` (dry-run). Pass `confirm=True`
to actually execute.

```python
# Inspect what would be fixed
preview = fix_mismatches(confirm=False)
print(preview["detected"])

# Execute fixes
result = fix_mismatches(confirm=True)
print(result["summary"])
# {"detected": 3, "local_fixed": 2, "remote_fixed": 1}
```

## CLI

```bash
# Show all packages with version info
scitex-dev ecosystem list --versions

# Preview fixes (dry run, no changes made)
scitex-dev ecosystem fix-mismatches

# Execute fixes (actually applies changes)
scitex-dev ecosystem fix-mismatches --confirm

# JSON output
scitex-dev ecosystem list --versions --json
```

## MCP Tools

| Tool | Purpose |
|------|---------|
| `mcp__scitex__dev_ecosystem_list` | Read-only: list all ecosystem packages with version status |
| `mcp__scitex__dev_ecosystem_fix_mismatches` | Auto-fix installed vs pyproject.toml mismatches (confirm=False for preview) |

## Full Ecosystem Update Workflow

When performing a full update across all packages, follow this order:

1. **Check CI** — verify GitHub Actions pass for each package (`gh run list -R ywatanabe1989/PACKAGE`)
2. **Check status** — `mcp__scitex__dev_ecosystem_list` or `scitex-dev ecosystem list --versions`
3. **Bump versions** — edit pyproject.toml, classify changes (feat → minor, fix → patch)
4. **Commit + tag** — `git commit` + `git tag vX.Y.Z`
5. **Push** — `git push origin develop --tags`
6. **GitHub Release** — `gh release create vX.Y.Z --generate-notes`
7. **Wait for PyPI** — verify `publish-pypi.yml` workflow completes
8. **Local reinstall** — `pip install -e .` in each updated repo
9. **Fix mismatches** — `scitex-dev ecosystem fix-mismatches --confirm` or `mcp__scitex__dev_ecosystem_fix_mismatches`
10. **Sync to NAS** — `scitex dev versions sync --confirm`
