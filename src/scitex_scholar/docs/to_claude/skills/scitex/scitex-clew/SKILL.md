---
description: Hash-based reproducibility verification for scientific pipelines. Use when verifying session runs, tracing provenance chains, auditing full DAGs, registering manuscript claims, or creating temporal stamps.
allowed-tools: mcp__scitex__clew_*
---

# scitex-clew

Hash-based verification tracking for reproducible science. Zero dependencies (pure stdlib + sqlite3). Auto-integrates with `@stx.session` and `stx.io` when scitex is present.

## Sub-skills

* [quick-start.md](quick-start.md) — Basic API, session tracking, first verification
* [cli-commands.md](cli-commands.md) — CLI reference (`clew status`, `clew verify`, etc.)
* [mcp-tools-for-ai-agents.md](mcp-tools-for-ai-agents.md) — MCP tool reference for AI agents
* [common-workflows.md](common-workflows.md) — Claims, DAG patterns, stamps, reproducibility

## MCP Tools

| Tool | Purpose |
|------|---------|
| `clew_status` | Git-status-like overview of verification state |
| `clew_list` | List all tracked runs with verification status |
| `clew_run` | Verify a session by checking all file hashes |
| `clew_chain` | Trace provenance chain for a target file |
| `clew_dag` | Verify full DAG for multiple targets or claims |
| `clew_mermaid` | Generate Mermaid diagram for verification DAG |
| `clew_rerun_dag` | Re-execute entire DAG and compare outputs |
| `clew_rerun_claims` | Re-execute sessions backing manuscript claims |
| `clew_stats` | Show verification database statistics |

## CLI

```bash
clew status              # Git-status-like overview
clew list                # List tracked runs
clew verify <SESSION_ID> # Verify a specific run
clew stats               # Database statistics
clew mermaid             # Generate Mermaid DAG diagram
clew mcp start           # Start MCP server
clew skills list         # List skill pages
clew skills get SKILL    # Get a specific skill page
```
