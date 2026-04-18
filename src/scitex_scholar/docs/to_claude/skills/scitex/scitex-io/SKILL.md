---
description: Universal file I/O supporting 30+ formats (CSV, NumPy, pickle, YAML, JSON, HDF5, images, figures, etc.). Use when loading or saving data files in scientific workflows.
allowed-tools: mcp__scitex__io_*
---

# scitex-io

Universal scientific data I/O with plugin registry. One `save()`/`load()` for 30+ formats.

## Sub-skills

* [save-and-load](save-and-load.md) — Core save/load API, registry, custom formats
* [centralized-config](centralized-config.md) — `load_configs()` and DotDict
* [metadata-embedding](metadata-embedding.md) — Provenance in PNG/JPEG/SVG/PDF
* [cache](cache.md) — Load caching, reload, flush
* [glob](glob.md) — Pattern matching with natural sort
* [linting-rules](linting-rules.md) — STX-IO001–007 lint rules
* [supported-formats](supported-formats.md) — All 30+ format tables
* [path-resolution](path-resolution.md) — Auto save-path, scitex.path utilities

## MCP Tools

| Tool | Purpose |
|------|---------|
| `io_save` | Save data to file (auto-detect format) |
| `io_load` | Load data from file (auto-detect format) |
| `io_load_configs` | Load config directory as merged dict |
| `io_list_formats` | List all registered save/load formats |
| `io_register_info` | Show registration info for a format |

## CLI

```bash
scitex-io info data.csv           # Format, shape, dtypes
scitex-io configs show ./config/  # Display merged configs
scitex-io mcp start               # Start MCP server
scitex-io skills list              # List skill pages
```
