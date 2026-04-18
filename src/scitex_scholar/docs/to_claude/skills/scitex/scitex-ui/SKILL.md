---
description: Vanilla TS workspace shell framework + React app components for SciTeX apps. Use when building or customizing SciTeX workspace UIs, integrating shell panels, or using frontend components.
allowed-tools: mcp__scitex__ui_*
---

# scitex-ui — Workspace Shell Framework

## Installation

```bash
pip install scitex-ui
# Development:
pip install -e /home/ywatanabe/proj/scitex-ui
```

Reusable frontend framework for SciTeX workspace apps.
**Shell = vanilla TypeScript. App content = React (optional).**

## Sub-skills

* [python-api](python-api.md) — Python API: `list_components`, `get_component`, `get_static_dir`, Django integration
* [shell-modules](shell-modules.md) — `initShell`, adapters, TypeScript shell module API
* [frontend-components](frontend-components.md) — React app components, Bridge infrastructure, panel resize
* [css-theme](css-theme.md) — CSS design tokens, theme variables, dark/light mode
* [cli](cli.md) — CLI commands: `scitex-ui mcp`, `docs`, `skills`

## Architecture

```
ts/shell/          ← Vanilla TS workspace shell (single source of truth)
ts/app/            ← Vanilla TS app components
react/app/         ← React app components (usePanelResize, DataTable)
css/shell/         ← Shell CSS
templates/         ← Django HTML templates
```

## MCP Tools

| Tool | Purpose |
|------|---------|
| `skills_list` | List available skill pages |
| `skills_get` | Get a skill page by name |
