---
description: scitex-ui CLI reference — MCP server, docs, skills subcommands.
---

# scitex-ui CLI

Entry point: `scitex-ui` (requires `pip install scitex-ui[cli]`).

## MCP Server

```bash
scitex-ui mcp start           # Start MCP server (stdio transport)
scitex-ui mcp doctor          # Check dependencies and server health
scitex-ui mcp list-tools      # List available MCP tools
scitex-ui mcp list-tools -v   # With one-line descriptions
scitex-ui mcp list-tools -vv  # With full descriptions
scitex-ui mcp list-tools --json  # JSON output
scitex-ui mcp installation    # Show Claude Code settings.json snippet
```

### Claude Code Integration

```json
{
  "mcpServers": {
    "scitex-ui": {
      "command": "scitex-ui",
      "args": ["mcp", "start"]
    }
  }
}
```

Add to `~/.claude/settings.json`.

## Skills

```bash
scitex-ui skills list              # List available skill pages
scitex-ui skills get               # Get main SKILL.md
scitex-ui skills get shell-modules # Get a named sub-skill page
```

Available skill names: `python-api`, `shell-modules`, `frontend-components`, `css-theme`, `cli`.

## Documentation

```bash
scitex-ui docs    # Open or display bundled Sphinx docs
```

## Global Options

```bash
scitex-ui --version           # Show version (e.g. 0.4.2)
scitex-ui --help              # Show help
scitex-ui --help-recursive    # Show help for all subcommands
```

## Installation

```bash
pip install scitex-ui           # base package
pip install scitex-ui[cli]      # + CLI (click, scitex-dev)
pip install scitex-ui[mcp]      # + MCP server (fastmcp)
pip install scitex-ui[all]      # everything
```
