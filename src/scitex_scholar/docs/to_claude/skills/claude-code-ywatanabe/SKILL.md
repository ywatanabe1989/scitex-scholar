---
description: Custom Claude Code Skills for ywatanabe
---

# Custom Claude Code Skills for ywatanabe

## Sub-skills
* [orchestrator](orchestrator.md) — Master orchestrator: delegate work, stay responsive, never block
* [emacs-mcp-server](emacs-mcp-server.md) — Emacs MCP server workarounds, vterm control via eval_elisp
* [self-compact](self-compact.md) — Self-compact context via Emacs vterm when auto-compact fails
* [master-worker](master-worker.md) — Master-worker architecture: one Telegram bot, screen sessions per project
* [environmental-variables](environmental-variables.md) — Env var locations for ywatanabe's secrets
* [self-identify-vterm](self-identify-vterm.md) — Pattern for agents to find their own Emacs vterm buffer after compaction

## When to Use
- Orchestrating work via Telegram (plotting, speaking, launching agents, monitoring)
- Debugging multi-agent Python systems
- Setting up Claude Code infrastructure (channels, plugins)
- File placement conventions
- Controlling Emacs vterm from Claude Code
- Launching and monitoring Claude Code instances in Emacs vterm

## Core Guidelines

### Debugging
Multi-agent debugging approach:
@HOW-TO-DEBUG-with-MULTIPLE_AGENTS.md

### Claude Code Channels (Telegram)
One bot serves all projects. Master agent at `~/proj` holds the Telegram channel. Workers run per-project in screen sessions. See [master-worker.md](master-worker.md) for the full setup.

Key files:
- Screen functions: `~/.bash.d/all/010_claude/020_claude_agents_in_screen.src`
- Channel functions: `~/.bash.d/all/010_claude/010_claude_channels.src`
- Token: `~/.claude/channels/telegram/.env`
- Requires: Bun runtime, claude.ai login, v2.1.80+

**Gotchas:**
- `CLAUDE_ID` env var causes `_cld_start_session` to silently abort — must `unset CLAUDE_ID` before launching in screen
- Bun PATH must be in `.bash.d` (not just `~/.bash_profile`) for screen sessions
- `screen -dmS` needs `bash --rcfile` approach + `stuff` to get interactive shell with functions loaded
- One bot per channel, not per project — master receives all messages and delegates

### Emacs MCP Server (`~/proj/emacs_mcp_server/`)
- `eval_elisp` works even when `list_buffers` and vterm tools are broken — use as fallback
- vterm creation: `(vterm "buffer-name")` via eval_elisp
- vterm send: `(with-current-buffer "name" (vterm-send-string "cmd") (vterm-send-return))`
- vterm read: `(with-current-buffer "name" (buffer-substring-no-properties ...))`

### File Placement Conventions
| Type | Location | Example |
|------|----------|---------|
| Installer scripts | `~/.bin/installers/` | `install_claude_channels.sh` |
| Shell functions | `~/.bash.d/all/<category>/*.src` | `010_claude_channels.src` |
| Documentation | Same dir as `.src` or skill dir | `CHANNELS_SETUP.md` |
| Helper binaries | `~/.local/bin/` | NOT `~/.bin/` directly |
| CLI tools | `~/.bin/<category>/` subdir | `~/.bin/claude/`, `~/.bin/emacs/` |

**Never place raw binaries directly in `~/.bin/`** — use `~/.local/bin/` or `~/.bin/<category>/` subdirs.

### Environment Variables
Private env vars (Twilio, email, Claude Code tokens) live in:
- `~/.dotfiles/src/.bash.d/secrets/`
- `~/.dotfiles/src/.bash.d/secrets/010_scitex`

Always keep these up-to-date when adding new service credentials. See [environmental-variables.md](environmental-variables.md).
