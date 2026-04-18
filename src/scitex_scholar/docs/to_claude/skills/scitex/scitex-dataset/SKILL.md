---
description: Dataset fetcher for neuroscience research — OpenNeuro, DANDI, PhysioNet with local database search and BIDS support.
allowed-tools: mcp__scitex__dataset_*
---

# scitex-dataset

Dataset search and fetch for neuroscience research.

## Sub-skills

- [quick-start.md](quick-start.md) — Basic usage
- [data-sources.md](data-sources.md) — OpenNeuro, DANDI, PhysioNet
- [cli-reference.md](cli-reference.md) — CLI commands
- [mcp-tools.md](mcp-tools.md) — MCP tools for AI agents

## CLI

```bash
scitex-dataset search "EEG epilepsy"
scitex-dataset fetch openneuro ds003104
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `dataset_search` | Search across all sources |
| `dataset_openneuro_fetch` | Fetch from OpenNeuro |
| `dataset_dandi_fetch` | Fetch from DANDI Archive |
| `dataset_physionet_fetch` | Fetch from PhysioNet |
| `dataset_db_search` | Search local database |
| `dataset_db_build` | Build local database |
| `dataset_db_stats` | Database statistics |
| `dataset_list_sources` | List available sources |
