---
topic: ecosystem
package: scitex-dev
description: >
  SciTeX package registry and sync operations. ECOSYSTEM is the canonical
  dict of all packages with local paths, PyPI names, and GitHub repos.
  sync_local reinstalls via pip install -e. sync_host/sync_all push via SSH.
  pull_local/remote_commit handle reverse sync.
---

# Ecosystem Management

## ECOSYSTEM

Canonical dict of all SciTeX packages.

```python
from scitex_dev import ECOSYSTEM

# Each entry:
ECOSYSTEM["scitex-io"] == {
    "local_path": "~/proj/scitex-io",
    "pypi_name": "scitex-io",
    "github_repo": "ywatanabe1989/scitex-io",
    "import_name": "scitex_io",
}
```

## get_all_packages / get_local_path

```python
from scitex_dev import get_all_packages, get_local_path

get_all_packages()               # list[str] of all package names
get_local_path("scitex-io")      # Path("~/proj/scitex-io").expanduser()
```

## sync_local

Reinstall local packages via `pip install -e .`

```python
from scitex_dev import sync_local

result = sync_local(
    packages: list[str] | None = None,  # None = all configured packages
    confirm: bool = False,              # False = dry-run (default)
    config=None,
) -> dict[str, dict]
# {pkg_name: {"status": "ok"|"dry_run"|"error"|"skipped", ...}}
```

```python
# Preview
sync_local(confirm=False)

# Execute
sync_local(packages=["scitex-io", "scitex-stats"], confirm=True)
```

## sync_host

Sync packages to a remote SSH host (git stash, git pull, pip install -e .).

```python
from scitex_dev import sync_host
from scitex_dev import HostConfig

result = sync_host(
    host: HostConfig,
    packages: list[str] | None = None,
    stash: bool = True,      # git stash before pull
    install: bool = True,    # pip install -e . after pull
    confirm: bool = False,   # False = dry-run (default)
    config=None,
) -> dict[str, dict]
# {pkg_name: {"status": "ok"|"dry_run"|"error"|"timeout", ...}}
```

## sync_all

Sync packages across all enabled hosts in parallel.

```python
from scitex_dev import sync_all

result = sync_all(
    hosts: list[str] | None = None,    # None = all enabled hosts
    packages: list[str] | None = None,
    stash: bool = True,
    install: bool = True,
    confirm: bool = False,             # False = dry-run (default)
    config=None,
) -> dict[str, dict]
# {host_name: {pkg_name: result}}
```

```python
# Dry run across all hosts
preview = sync_all(confirm=False)
for host, pkgs in preview.items():
    for pkg, info in pkgs.items():
        print(host, pkg, info["commands"])

# Execute on specific host
sync_all(hosts=["spartan"], confirm=True)
```

## sync_tags

Push local git tags to origin for all packages.

```python
from scitex_dev import sync_tags

result = sync_tags(
    packages: list[str] | None = None,
    confirm: bool = False,    # False = dry-run (default)
    config=None,
) -> dict[str, dict]
# {pkg_name: {"status": "ok"|"dry_run", "tag": "v0.3.2", ...}}
```

## pull_local

Pull latest from origin to local repos.

```python
from scitex_dev import pull_local

result = pull_local(
    packages: list[str] | None = None,
    confirm: bool = False,   # False = dry-run (default)
    stash: bool = True,      # stash before pull, pop after
    config=None,
) -> dict[str, dict]
# {pkg_name: {"status": "ok"|"dry_run"|"stash_conflict", "stashed": bool, ...}}
```

## remote_diff

Show uncommitted changes on remote SSH hosts (read-only).

```python
from scitex_dev import remote_diff

result = remote_diff(
    host: str | None = None,           # None = first enabled host
    packages: list[str] | None = None,
    config=None,
) -> dict[str, dict]
# {host_name: {pkg_name: {"status": "dirty"|"clean", "files": ..., "diff": ...}}}
```

## remote_commit

Commit dirty changes on remote host and push to origin.

```python
from scitex_dev import remote_commit

result = remote_commit(
    host: str,                          # required
    packages: list[str] | None = None,
    message: str | None = None,         # auto-generated if None
    push: bool = True,
    confirm: bool = False,              # False = dry-run (default)
    config=None,
) -> dict[str, dict]
# {pkg_name: {"status": "ok"|"dry_run"|"clean", ...}}
```

## CLI

```bash
# List ecosystem packages
scitex-dev ecosystem list
scitex-dev ecosystem list --versions
scitex-dev ecosystem list --json

# Sync
scitex-dev ecosystem sync              # dry-run (preview)
scitex-dev ecosystem sync --confirm   # execute (not available via click; use Python API)
scitex-dev ecosystem sync-local       # pip install -e . locally

# Pull and commit
scitex-dev ecosystem pull             # git pull locally
scitex-dev ecosystem commit           # commit on remote hosts
scitex-dev ecosystem diff             # show remote diffs

# Fix mismatches
scitex-dev ecosystem fix-mismatches --dry-run
scitex-dev ecosystem fix-mismatches

# Dashboard
scitex-dev ecosystem dashboard --port 8050
scitex-dev ecosystem dashboard --background
```
