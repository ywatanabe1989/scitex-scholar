---
description: SciTeX code convention checker with pluggable rules for imports, naming, path handling, and package-specific patterns.
allowed-tools: mcp__scitex__linter_*
---

# scitex-linter

Code convention checker for SciTeX ecosystem packages.

## Sub-skills

- [quick-start.md](quick-start.md) — Basic usage
- [rule-catalog.md](rule-catalog.md) — All built-in rules
- [cli-reference.md](cli-reference.md) — CLI commands
- [mcp-tools.md](mcp-tools.md) — MCP tools for AI agents

## CLI

```bash
scitex-linter check [path]
scitex-linter list-rules
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `linter_check` | Check files for convention violations |
| `linter_check_source` | Check source code string |
| `linter_list_rules` | List available rules |
