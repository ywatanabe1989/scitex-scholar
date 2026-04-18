---
name: scitex-notification
description: Multi-backend notification system with fallback priority — audio TTS, desktop, emacs, matplotlib, playwright, email, webhook, Telegram, and Twilio phone/SMS. Use when alerting users, escalating to phone calls, or sending notifications from scripts and AI agents.
allowed-tools: mcp__scitex__notification_*
---

# scitex-notification

Multi-backend alerting with automatic fallback. One `alert()` covers local and remote delivery.

## Sub-skills

* [python-api](python-api.md) — `alert()`, `call()`, `sms()` signatures, backends table, env vars
* [backends](backends.md) — Per-backend setup, env vars, availability checks
* [configuration](configuration.md) — YAML config, `UIConfig`, level-based routing
* [cli-reference](cli-reference.md) — CLI commands: `send`, `call`, `sms`, `backends`, `config`
* [mcp-tools](mcp-tools.md) — MCP tool schemas: `notify`, `notify_by_level`, `list_notification_backends`

## Quick Start

```python
import scitex_notification as stxn

# Simple alert — fallback: audio -> emacs -> matplotlib -> playwright -> email
stxn.alert("Training complete!")

# Specific backend, no fallback
stxn.alert("Error in pipeline", backend="email", level="error")

# Multiple backends simultaneously
stxn.alert("Critical!", backend=["audio", "email"])

# Phone call via Twilio (requires SCITEX_NOTIFICATION_TWILIO_* env vars)
stxn.call("Wake up! Server is down!")

# SMS via Twilio
stxn.sms("Build finished successfully")
```

## CLI

```bash
scitex-notification send "Task done!"
scitex-notification call "Wake up!" --repeat 2
scitex-notification sms "Build complete"
scitex-notification backends          # List available backends
scitex-notification config            # Show configuration
scitex-notification mcp start         # Start MCP server
```

## MCP Tools

| Tool | Purpose |
|------|---------|
| `notification_send` | Send notification via backend(s) with fallback |
| `notification_call` | Make phone call via Twilio |
| `notification_sms` | Send SMS via Twilio |
| `notification_backends` | List backends and availability |
| `notification_config` | Show current configuration |
