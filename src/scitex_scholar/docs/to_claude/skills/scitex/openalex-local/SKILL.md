---
description: Local OpenAlex database with 284M+ works, abstracts, and semantic search for academic literature.
allowed-tools: mcp__scitex__openalex_*
---

# openalex-local

## Installation

```bash
pip install openalex-local
# Development:
pip install -e /home/ywatanabe/proj/openalex-local
```

Local OpenAlex database with 284M+ works and full-text search.

## Sub-skills

- [quick-start.md](quick-start.md) — Basic usage
- [search-syntax.md](search-syntax.md) — FTS5 query syntax
- [database-setup.md](database-setup.md) — Database architecture, build pipeline, access modes
- [cli-reference.md](cli-reference.md) — CLI commands
- [mcp-tools.md](mcp-tools.md) — MCP tools for AI agents

## CLI

```bash
openalex-local search "neural network attention"
openalex-local search-by-id W2741809807
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `openalex_search` | Full-text search across works |
| `openalex_search_by_id` | Get work by OpenAlex ID |
| `openalex_enrich_ids` | Enrich IDs with metadata |
| `openalex_status` | Database status |
