---
name: agent-container-auto-accept
description: Modular TUI prompt detection and auto-acceptance for Claude Code.
---

# Auto-Accept TUI Prompts

Claude Code shows confirmation prompts for dangerous flags. The auto-accept system handles them via modular handlers in `runtimes/prompts.py`.

## Built-in Handlers

| Name | Detects | Sends |
|------|---------|-------|
| bypass-permissions | "2. Yes, I accept" + "Bypass Permissions" | `2`, `Enter` |
| dev-channels | "1. I am using this for local development" | `1`, `Enter` |
| thinking-effort | "Medium" + "thinking" | `1`, `Enter` |
| skip-permissions-yn | "skip-permissions" or "Trust" (legacy y/n) | `y`, `Enter` |

## Design

- **Number keys** sent directly (not arrow keys) — cursor-position independent
- **Order-agnostic** — all handlers checked each poll cycle
- **Detects by option text** (e.g., "2. Yes, I accept") for reliability
- Uses `capture-pane` (tmux) or `hardcopy` (screen) to read content

## Adding New Handlers

```python
from scitex_agent_container.runtimes.prompts import register_prompt, PromptHandler

register_prompt(PromptHandler(
    name="my-new-prompt",
    detect=lambda c: "3. My Option" in c and "Enter to confirm" in c,
    keys=["3", "Enter"],
    priority=4,
))
```

## Runtime Prompt Detection (via mamba-healer)

In addition to startup auto-accept, mamba-healer's health scan includes runtime permission prompt detection. This catches prompts that appear mid-session (e.g., new tool permissions, MCP reconnect confirmations).

**Detection patterns** (checked every health scan cycle):
- "Do you want to" — general permission prompt
- "Allow X to" — tool/MCP permission
- "Enter to confirm" — confirmation dialog

**Excluded** (false positive prevention):
- Status bar text like "bypass permissions on" — not an actual prompt

If a runtime prompt is detected, healer reports `stuck_prompt` status and can auto-respond via tmux `stuff`. This complements the startup auto-accept handlers above.

## Disabling Auto-Accept

```yaml
spec:
  claude:
    auto_accept: false   # Manual TUI acceptance required
```

## Diagnostics

Logged to `~/.scitex/agent-container/logs/{name}/auto-accept.log`:
- Every poll: pane content snapshot, elapsed time
- Handler matches with timestamps
- Timeout diagnostics with last captured content
