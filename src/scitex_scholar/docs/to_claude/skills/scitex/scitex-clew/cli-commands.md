---
description: CLI reference for the clew command (requires pip install scitex-clew[cli]).
---

# CLI Commands

Requires `pip install scitex-clew[cli]` (adds `click` dependency).

Entry point: `clew` (defined as `scitex_clew._cli:main`).

## Global options

```bash
clew --version          # Print version and exit
clew --help-recursive   # Show help for all commands
```

## Verification commands

```bash
# Git-status-like overview of all verified/mismatch/missing runs
clew status

# List tracked runs
clew list
clew list --limit 100    # default: 50

# Verify a specific run by session ID (hash check)
clew verify <SESSION_ID>
# Output:
#   [OK]   2025Y-11M-18D-09h12m03s_HmH5 (verified)
#     [OK] output results/model.csv
#     [!!] output results/plot.png

# Database statistics
clew stats
```

## Visualization commands

```bash
# Generate Mermaid DAG diagram (all runs)
clew mermaid

# Generate Mermaid DAG from registered claims
clew mermaid --claims
```

## Integration commands

```bash
# Start MCP server
clew mcp start

# List public Python API (introspect)
clew list-python-apis

# Shell completion
eval "$(clew completion bash)"
eval "$(clew completion zsh)"
clew completion fish | source
```

## Skills commands (requires scitex-dev)

```bash
clew skills list               # List all skill pages
clew skills get quick-start    # Get a specific skill page
```

## Notes

- `clew verify` accepts a session ID (e.g., `2025Y-11M-18D-09h12m03s_HmH5`)
- Session IDs come from `@stx.session` in scitex, or from `clew list`
- `clew status` returns JSON to stdout
- `clew stats` returns JSON to stdout
- All commands exit 0 on success; non-zero on errors
