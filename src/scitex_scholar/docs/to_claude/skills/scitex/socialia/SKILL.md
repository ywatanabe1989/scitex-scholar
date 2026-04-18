---
description: Unified social media management — posting across Twitter/X, LinkedIn, and other platforms.
allowed-tools: mcp__scitex__social_*
---

# socialia

## Installation

```bash
pip install socialia
# Development:
pip install -e /home/ywatanabe/proj/socialia
```

Unified social media posting and management.

## Sub-skills

- [quick-start.md](quick-start.md) — Basic usage
- [platforms.md](platforms.md) — Supported platforms
- [environment.md](environment.md) — Environment variables for all platforms
- [python-api.md](python-api.md) — Python API reference (classes, methods, utilities)
- [cli-reference.md](cli-reference.md) — CLI commands
- [mcp-tools.md](mcp-tools.md) — MCP tools for AI agents

## CLI

```bash
socialia post "New paper published!" --platform twitter
socialia status
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `social_post` | Post to social media |
| `social_status` | Check platform status |
| `social_delete` | Delete a post |
| `social_analytics_track` | Track custom GA4 event |
| `social_analytics_pageviews` | Get page view metrics |
| `social_analytics_sources` | Get traffic sources |
| `social_analytics_realtime` | Get realtime active users |
