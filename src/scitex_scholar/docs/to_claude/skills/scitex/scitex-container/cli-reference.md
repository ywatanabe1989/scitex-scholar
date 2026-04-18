---
skill: scitex-container/cli-reference
description: CLI commands reference for scitex-container
---

# CLI Reference

Entry point: `scitex-container`
MCP server entry point: `scitex-container-mcp`

## Global Options

```bash
scitex-container --version
scitex-container --help-recursive   # Show help for ALL commands recursively
scitex-container list-python-apis   # List Python APIs
scitex-container list-python-apis -v    # With function signatures
scitex-container list-python-apis -vv   # With signatures + docstrings
```

---

## Apptainer (top-level commands)

```bash
# Build SIF from .def file
scitex-container build [NAME]                    # default NAME: scitex-final
scitex-container build NAME --sandbox            # Build sandbox dir instead of SIF
scitex-container build NAME --force              # Force rebuild even if up-to-date
scitex-container build NAME --output-dir DIR     # Write output to DIR

# List versioned SIFs (* = active)
scitex-container list [--dir DIR]

# Switch active version (updates current.sif symlink atomically)
scitex-container switch VERSION [--dir DIR] [--sudo]

# Roll back to previous version
scitex-container rollback [--dir DIR] [--sudo]

# Deploy active SIF to production
scitex-container deploy [--target /opt/scitex/singularity] [--dir DIR]

# Remove old versions (keeps 3 most recent by default)
scitex-container cleanup [--keep N] [--dir DIR]

# Freeze lock files from a SIF (pip, dpkg, npm)
scitex-container freeze SIF_PATH [--output-dir DIR]

# Verify SIF integrity
scitex-container verify [SIF_PATH] [--def DEF_FILE] [--lock-dir DIR] [--json]
# If SIF_PATH omitted, uses current active version

# Unified status dashboard
scitex-container status

# Environment snapshot
scitex-container env-snapshot
```

---

## sandbox sub-group

```bash
# Create a sandbox from a SIF or .def file (timestamped: sandbox-YYYYMMDD_HHMMSS/)
scitex-container sandbox create --source PATH [--dir DIR] [--output OUTPUT]

# List versioned sandboxes (* = active)
scitex-container sandbox list [--dir DIR]

# Switch active sandbox
scitex-container sandbox switch VERSION [--dir DIR] [--sudo]
# VERSION is a timestamp string, e.g. 20260225_173700

# Roll back to previous sandbox
scitex-container sandbox rollback [--dir DIR] [--sudo]

# Remove old sandboxes (keeps 5 most recent by default)
scitex-container sandbox cleanup [--keep N] [--dir DIR]

# Update ecosystem packages inside sandbox (fast, no rebuild)
scitex-container sandbox update --sandbox-dir PATH [--proj-root DIR] [--pkg PKG] [--deps]

# Run maintenance command with --writable --fakeroot
scitex-container sandbox maintain --sandbox-dir PATH COMMAND...

# Configure PS1 prompt in sandbox
scitex-container sandbox configure-ps1 --sandbox-dir PATH [--ps1 PROMPT]

# Remove SIF files and artifacts (*.sif, *.sif.old, *.sif.backup.*)
scitex-container sandbox purge-sifs [--dir DIR] [--keep N]
```

---

## docker sub-group

```bash
# Rebuild Docker images (no-cache)
scitex-container docker rebuild [--env ENV] [--project-dir DIR]
# ENV default: "dev"

# Restart Docker containers (compose down + up -d)
scitex-container docker restart [--env ENV] [--project-dir DIR]

# Show Docker container status
scitex-container docker status [--env ENV] [--project-dir DIR]
```

---

## host sub-group

```bash
# Check which host packages are installed
scitex-container host check

# Install host packages
scitex-container host install [--texlive] [--imagemagick] [--all]
```

---

## mcp sub-group

```bash
# Start MCP server (stdio mode for Claude Desktop)
scitex-container mcp start

# List available MCP tools
scitex-container mcp list-tools

# Check MCP dependencies
scitex-container mcp doctor
```
