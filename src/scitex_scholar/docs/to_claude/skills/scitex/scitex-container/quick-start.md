---
skill: scitex-container/quick-start
description: Installation and first-use examples for scitex-container
---

# Quick Start

## Installation

```bash
pip install scitex-container
# with MCP support:
pip install "scitex-container[mcp]"
```

## CLI Quick Start

```bash
# Build a SIF from a .def file (name default: scitex-final)
scitex-container build scitex-final

# Build and force rebuild even if up-to-date
scitex-container build scitex-final --force

# Build a sandbox instead of SIF
scitex-container build scitex-final --sandbox

# List available versioned SIFs (* = active)
scitex-container list

# Switch active version
scitex-container switch 2.19.5

# Roll back to previous version
scitex-container rollback

# Freeze lock files from a built SIF
scitex-container freeze ./scitex-v2.19.5.sif

# Verify SIF integrity
scitex-container verify ./scitex-v2.19.5.sif

# Unified status dashboard (Apptainer + host + Docker)
scitex-container status
```

## Sandbox Quick Start

```bash
# Create a sandbox from a SIF (timestamped)
scitex-container sandbox create --source ./scitex-v2.19.5.sif

# List sandboxes (* = active)
scitex-container sandbox list

# Run a maintenance command inside sandbox (writable + fakeroot)
scitex-container sandbox maintain --sandbox-dir ./sandbox-20260225_173700 pip install mypackage

# Update ecosystem packages inside sandbox (fast, no full rebuild)
scitex-container sandbox update --sandbox-dir ./sandbox-20260225_173700

# Convert sandbox back to SIF
# (use: apptainer build --force output.sif sandbox-dir/ or via Python API)
```

## Python Quick Start

```python
from pathlib import Path
import scitex_container.apptainer as apptainer
import scitex_container.docker as docker
import scitex_container.host as host
from scitex_container import env_snapshot

# Build a SIF
sif_path = apptainer.build("scitex-final")

# List SIF versions
versions = apptainer.list_versions(Path("/opt/scitex/singularity"))
# Returns: [{"version": "2.19.5", "path": "...", "size": "4.2 GB",
#            "date": "2026-02-25 17:00", "active": True}, ...]

# Switch active version
apptainer.switch_version("2.19.5", Path("/opt/scitex/singularity"))

# Sandbox operations
sandbox_dir = apptainer.sandbox_create(source=sif_path)
results = apptainer.sandbox_update(sandbox_dir)  # {"scitex": "ok", ...}

# Docker Compose
docker.restart()
docker.status()

# Environment snapshot for reproducibility
snap = env_snapshot()
# Returns dict with schema_version, timestamp, container, host, dev_repos, lock_files
```
