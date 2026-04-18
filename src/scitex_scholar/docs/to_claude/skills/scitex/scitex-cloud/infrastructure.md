---
description: Infrastructure management — environment setup, Docker container management, deploy, logs, SSH, and MCP server start/diagnose.
---

# Infrastructure CLI

## Setup

```bash
scitex-cloud setup [--env dev|prod] [--force]
```

Interactive wizard: checks prerequisites (docker, git), creates `.env` from template, validates docker-compose file.

```bash
scitex-cloud setup              # interactive, prompts for env
scitex-cloud setup --env dev    # dev environment
scitex-cloud setup --env prod   # production environment
scitex-cloud setup --env dev --force   # overwrite existing .env
```

## Docker

```bash
scitex-cloud docker [--env dev|prod] build [--no-cache]
scitex-cloud docker [--env dev|prod] up    [-d]           # start (detached default)
scitex-cloud docker [--env dev|prod] down  [-v]           # stop (--volumes to remove)
scitex-cloud docker [--env dev|prod] restart
scitex-cloud docker [--env dev|prod] ps                   # show container status
```

## Deploy and Status

```bash
scitex-cloud deploy                   # deploy with current settings
scitex-cloud status                   # show deployment health
scitex-cloud logs [service]           # tail service logs
scitex-cloud ssh                      # SSH into cloud
```

## MCP Server

```bash
# Start
scitex-cloud mcp start                          # stdio (Claude Desktop default)
scitex-cloud mcp start -t sse                   # SSE (deprecated, avoid)
scitex-cloud mcp start -t http                  # HTTP streamable (recommended for remote)
scitex-cloud mcp start -t http --host 0.0.0.0 --port 8086

# Diagnose
scitex-cloud mcp doctor                         # check deps, tea CLI, API key
scitex-cloud mcp installation                   # show client config snippets
scitex-cloud mcp list-tools [-v] [-vv] [--json] # list all MCP tools
```

### MCP Client Configuration

Local (stdio, Claude Desktop):
```json
{
  "mcpServers": {
    "scitex-cloud": {
      "command": "scitex-cloud",
      "args": ["mcp", "start"],
      "env": {
        "SCITEX_CLOUD_API_KEY": "your-api-key"
      }
    }
  }
}
```

Remote (HTTP):
```json
{
  "mcpServers": {
    "scitex-cloud-remote": {
      "url": "http://your-server:8086/mcp"
    }
  }
}
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `SCITEX_CLOUD_API_KEY` | API key for cloud operations |
| `SCITEX_CLOUD_URL` | Cloud server URL (default: `https://scitex.cloud`) |
| `SCITEX_CLOUD_MCP_HOST` | MCP server bind host |
| `SCITEX_CLOUD_MCP_PORT` | MCP server port (default: 8086) |

## DockerManager (Python API)

```python
from scitex_cloud import DockerManager, get_environment

env = get_environment("dev")        # or "prod"
docker = DockerManager(env)

docker.build(no_cache=False)
docker.up(detach=True)
docker.down(volumes=False)
docker.restart()
docker.ps()
```

## MCP Onsite Tools (AI agent browser control)

| Tool | What it does |
|------|-------------|
| `cloud_onsite_capture_page` | Screenshot current page |
| `cloud_onsite_eval_js` | Execute JavaScript in browser |
| `cloud_onsite_ui_action` | Drive UI actions (click, fill, navigate, scroll) |
| `cloud_onsite_get_context` | Get page context for AI agents |
| `cloud_onsite_check_permission` | Check API permissions |
| `cloud_onsite_get_dev_app_url` | Get dev server URL for app |
| `cloud_api_status` | Check cloud API status |

# EOF
