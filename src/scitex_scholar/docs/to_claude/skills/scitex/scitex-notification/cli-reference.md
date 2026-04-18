---
description: scitex-notification CLI commands — send, call, sms, backends, config, mcp, and telegram-channel subcommands with all options.
---

# CLI Reference

Entry point: `scitex-notification` (defined in `pyproject.toml` as `scitex_notification._cli:main`).

```
scitex-notification [OPTIONS] COMMAND [ARGS]...
```

Global options:
- `--help-recursive` — print help for all subcommands
- `--json` — output as structured JSON

## send

Send a notification via configured backends.

```bash
scitex-notification send MESSAGE [OPTIONS]
```

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--title TEXT` | `-t` | — | Notification title |
| `--backend CHOICE` | `-b` | auto | One of: `audio`, `emacs`, `matplotlib`, `playwright`, `email`, `twilio`, `desktop`, `webhook` |
| `--level CHOICE` | `-l` | `info` | `info` \| `warning` \| `error` \| `critical` |
| `--no-fallback` | — | off | Disable backend fallback on error |
| `--dry-run` | — | off | Print what would be sent without sending |
| `--json` | — | off | Output as structured JSON |

```bash
scitex-notification send "Task complete!"
scitex-notification send "Error in step 3" --backend email --level error
scitex-notification send "Hello" --title "CI Alert" --no-fallback --json
scitex-notification send "Test" --dry-run
```

## call

Make a phone call via Twilio. Requires `SCITEX_NOTIFICATION_TWILIO_*` env vars.

```bash
scitex-notification call MESSAGE [OPTIONS]
```

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--title TEXT` | `-t` | — | Call title/context |
| `--level CHOICE` | `-l` | `info` | Alert level |
| `--to TEXT` | — | env var | Destination phone number (overrides `SCITEX_NOTIFY_TWILIO_TO`) |
| `--repeat INT` | `-r` | `$SCITEX_NOTIFICATION_PHONE_CALL_N_REPEAT` (default: `1`) | Repeat call N times (30s apart). Use `1` with iOS Emergency Bypass; `2` for iOS "Repeated Calls" bypass. |
| `--flow-sid TEXT` | — | — | Twilio Studio Flow SID |
| `--dry-run` | — | off | Print what would happen without calling |
| `--json` | — | off | Output as structured JSON |

```bash
scitex-notification call "Build finished!"
scitex-notification call "Wake up!" --repeat 2
scitex-notification call "Alert!" --to +61400000000
scitex-notification call "Test" --dry-run
```

Required env vars:
```bash
export SCITEX_NOTIFICATION_TWILIO_SID=ACxxxxxxxxxxxxxxxx
export SCITEX_NOTIFICATION_TWILIO_TOKEN=your_auth_token
export SCITEX_NOTIFICATION_TWILIO_FROM=+15550001111
export SCITEX_NOTIFICATION_TWILIO_TO=+81900000000
```

## sms

Send an SMS via Twilio. Requires `SCITEX_NOTIFICATION_TWILIO_*` env vars.

```bash
scitex-notification sms MESSAGE [OPTIONS]
```

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--title TEXT` | `-t` | — | SMS title (prepended to message) |
| `--to TEXT` | — | env var | Destination phone number |
| `--dry-run` | — | off | Print what would happen without sending |
| `--json` | — | off | Output as structured JSON |

```bash
scitex-notification sms "Build finished!"
scitex-notification sms "Alert!" --to +61400000000
scitex-notification sms "Test" --title "CI" --dry-run
```

## backends

List all notification backends and their availability.

```bash
scitex-notification backends [--json]
```

Output shows fallback-order backends with `available`/`not available` status, plus explicit-only backends (`twilio`, `telegram`).

```bash
scitex-notification backends
scitex-notification backends --json
# JSON: {"available": [...], "all_backends": [...], "fallback_order": [...]}
```

## config

Show current notification configuration.

```bash
scitex-notification config [--json]
```

Displays: default backend, priority order, first available backend.

```bash
scitex-notification config
scitex-notification config --json
# JSON: {"default_backend": "audio", "backend_priority": [...], ...}
```

## mcp

MCP server management subgroup.

```bash
scitex-notification mcp start    # Start the MCP server
scitex-notification mcp stop     # Stop the MCP server
scitex-notification mcp status   # Show server status
```

## telegram-channel

Telegram bidirectional channel for Claude Code.

```bash
scitex-notification telegram-channel start
```

Starts the Telegram channel MCP server (`scitex_notification.telegram_channel`).

## list-python-apis

List public Python APIs of the package.

```bash
scitex-notification list-python-apis
scitex-notification list-python-apis -v        # include one-line docstring
scitex-notification list-python-apis -vv       # include full docstring
scitex-notification list-python-apis --json    # JSON output
scitex-notification list-python-apis --max-depth 2
```

## docs

Build and view package documentation (via `scitex_dev` plugin, if installed).

```bash
scitex-notification docs build
scitex-notification docs serve
```
