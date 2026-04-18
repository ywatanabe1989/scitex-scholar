---
skill: scitex-container/environment
description: Environment variables used by scitex-container
---

# Environment Variables

## Container Session Variables

These are injected by `build_exec_args()` when starting a container session:

| Variable | Value | Purpose |
|----------|-------|---------|
| `SCITEX_CLOUD` | `true` | Flag: running inside a SciTeX container |
| `SCITEX_PROJECT` | `<project_slug>` | Current project identifier |
| `SCITEX_USER` | `<username>` | Username inside container |
| `USER` | `<username>` | Standard user variable |
| `LOGNAME` | `<username>` | Standard login name variable |
| `SHELL` | `/bin/bash` | Shell path |
| `TERM` | `xterm-256color` | Terminal type |
| `PATH` | `/usr/local/bin:/usr/bin:/bin:...` | Standard PATH |
| `PYTHONPATH` | `/opt/dev/<repo>/src:...` | Injected when dev_repos are mounted |

## Runtime Overrides

| Variable | Purpose |
|----------|---------|
| `SCITEX_CLOUD_APPTAINER_PS1` | Override sandbox shell prompt at runtime |

Example override:
```bash
apptainer exec --env SCITEX_CLOUD_APPTAINER_PS1='(mylab) \W $ ' ./current-sandbox /bin/bash
```

## Directory Conventions

| Path | Purpose |
|------|---------|
| `current.sif` | Symlink to active SIF file in containers dir |
| `current-sandbox` | Symlink to active sandbox directory |
| `sandbox-YYYYMMDD_HHMMSS/` | Versioned sandbox directory |
| `scitex-v<version>.sif` | Versioned SIF file |
| `.def-hash` | Stored SHA256 hash of last built .def file |
| `requirements-lock.txt` | pip freeze output from built SIF |
| `dpkg-lock.txt` | dpkg package list from built SIF |
| `node-lock.txt` | npm global package list from built SIF |

## SLURM Integration

`build_exec_args()` uses `--containall` and `--cleanenv` flags for isolation:
- `--containall` — prevents host filesystem leakage
- `--cleanenv` — clears host environment variables
- `--writable-tmpfs` — per-session tmpfs overlay (user sessions)
- `--writable --fakeroot` — for maintenance/admin tasks only
