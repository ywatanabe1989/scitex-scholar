---
skill: scitex-container/mcp-tools
description: MCP tools for AI agents using scitex-container
---

# MCP Tools (for AI agents)

Start MCP server: `scitex-container-mcp` (stdio, for Claude Desktop)
Alternative: `scitex-container mcp start`

Requires: `pip install "scitex-container[mcp]"` (fastmcp >= 2.0.0)

---

## Available Tools

### Apptainer

| Tool | Purpose |
|------|---------|
| `container_build` | Build SIF or sandbox from .def file (`name`, `sandbox`, `force`, `base`) |
| `container_list` | List versioned SIFs with active marker |
| `container_switch` | Switch active SIF version |
| `container_rollback` | Roll back to previous SIF version |
| `container_deploy` | Copy active SIF to production target dir |
| `container_cleanup` | Remove old SIF versions (keep N most recent) |
| `container_verify` | Verify SIF SHA256, .def origin, and lock file consistency |
| `container_status` | Unified dashboard: Apptainer + host packages + Docker |
| `container_env_snapshot` | Capture environment snapshot (container + host + git) |

### Sandbox

| Tool | Purpose |
|------|---------|
| `sandbox_create` | Convert a SIF to a writable timestamped sandbox directory |

### Docker

| Tool | Purpose |
|------|---------|
| `docker_rebuild` | Rebuild Docker images without cache |
| `docker_restart` | Restart Docker containers (compose down + up -d) |

### Host

| Tool | Purpose |
|------|---------|
| `host_install` | Install TeXLive / ImageMagick on the host |
| `host_check` | Check which host packages are installed |

---

## Claude Desktop Configuration

```json
{
  "mcpServers": {
    "scitex-container": {
      "command": "scitex-container-mcp"
    }
  }
}
```
