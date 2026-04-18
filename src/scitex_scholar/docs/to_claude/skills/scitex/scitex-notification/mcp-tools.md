---
description: MCP tool schemas for scitex-notification — notify, notify_by_level, list_notification_backends, available_notification_backends, get_notification_config.
---

# MCP Tools

The scitex-notification MCP server exposes five tools. Start the server with:

```bash
scitex-notification mcp start
```

## notify

Send a notification via specified backend(s).

**Required**: `message` (string)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `message` | string | required | Notification message |
| `title` | string | — | Optional title |
| `level` | enum | `"info"` | `info` \| `warning` \| `error` \| `critical` |
| `backend` | string | config default | Single backend name |
| `backends` | array of string | — | Multiple backends simultaneously |
| `timeout` | number | `5.0` | Timeout for visual backends (`matplotlib`, `playwright`) |

Response:
```json
{
  "success": true,
  "message": "Training done",
  "title": null,
  "level": "info",
  "backends_used": ["audio"],
  "results": [{"backend": "audio", "success": true, "error": null, "details": null}],
  "success_count": 1,
  "total_count": 1,
  "timestamp": "2026-03-25T10:00:00"
}
```

## notify_by_level

Send notification using backends configured for a specific level (`level_backends` from config).

**Required**: `message` (string)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `message` | string | required | Notification message |
| `title` | string | — | Optional title |
| `level` | enum | `"info"` | Determines which backends are used (from `level_backends` config) |

For `level="critical"` the default config uses: `audio, emacs, desktop, matplotlib, email`.

## list_notification_backends

List all backends with their status. No input required.

Response:
```json
{
  "success": true,
  "backends": [
    {"name": "audio", "available": true, "package_available": true, "class": "AudioBackend"},
    {"name": "email", "available": false, "package_available": true, "class": "EmailBackend"},
    ...
  ],
  "total_count": 9,
  "available_count": 3,
  "timestamp": "2026-03-25T10:00:00"
}
```

## available_notification_backends

Get list of currently working backends only. No input required.

Response:
```json
{
  "success": true,
  "available_backends": ["audio", "emacs"],
  "count": 2,
  "timestamp": "2026-03-25T10:00:00"
}
```

## get_notification_config

Get current configuration including priority, level mappings, and timeouts. No input required.

Response:
```json
{
  "success": true,
  "config": {
    "default_backend": "audio",
    "backend_priority": ["audio", "emacs", "desktop", "matplotlib", "playwright", "email", "webhook"],
    "available_priority": ["audio", "emacs"],
    "first_available": "audio",
    "level_backends": {
      "info": ["audio"],
      "warning": ["audio", "emacs"],
      "error": ["audio", "emacs", "desktop", "email"],
      "critical": ["audio", "emacs", "desktop", "matplotlib", "email"]
    },
    "timeouts": {"matplotlib": 5.0, "playwright": 5.0}
  },
  "timestamp": "2026-03-25T10:00:00"
}
```

## MCP Tool Names (as registered)

The tool schema names (from `tool_schemas.py`) differ from the MCP-exposed names:

| Schema name | MCP tool prefix |
|-------------|-----------------|
| `notify` | `notification_send` |
| `notify_by_level` | `notification_call` (level-based) |
| `list_notification_backends` | `notification_backends` |
| `available_notification_backends` | — |
| `get_notification_config` | `notification_config` |

Use `mcp__scitex__notification_*` in `allowed-tools` to grant access to all notification MCP tools.
