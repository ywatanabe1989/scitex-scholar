---
name: zero-trust-agents
description: Enforce agent isolation with code guards, not documentation. Prevent cross-contamination between agent contexts.
---

# Zero-Trust Agent Isolation

## Principle

Enforce with code, not documentation. Agents and humans don't reliably follow written instructions.

## Guard Pattern (4 layers)

1. `SCITEX_OROCHI_DISABLE=true` -- env var kill switch
2. `CLAUDE_AGENT_ROLE` check -- role-based blocking (e.g., telegram must not load Orochi)
3. `TELEGRAM_BOT_TOKEN` detection -- context-based blocking
4. MCP config isolation -- write to `/tmp/`, not shared workdir

## Truthy/Falsy Convention

Accept: `true`, `1`, `yes`, `enable`, `enabled` (case-insensitive)
Reject: `false`, `0`, `no`, `disable`, `disabled`, empty, unset

## Rules

- Code enforces, docs explain
- Default enabled (opt-out, not opt-in)
- Every guard logs WHY it blocked
- `exit(0)` for intentional disable, `exit(1)` for error/forbidden
- Guards run at module-load time, before any initialization

## Implementation Reference

```python
def _is_truthy(val: str | None) -> bool:
    return (val or "").lower() in ("true", "1", "yes", "enable", "enabled")

# Layer 1: kill switch
if _is_truthy(os.environ.get("SCITEX_OROCHI_DISABLE")):
    log.info("Skipping — SCITEX_OROCHI_DISABLE is set")
    return []

# Layer 2: role-based
role = os.environ.get("CLAUDE_AGENT_ROLE", "")
if role.lower() == "telegram":
    log.info("Skipping — telegram agent must not load this")
    return []
```

## Anti-Patterns

- Writing MCP config to workdir (shared between sessions)
- Trusting CLAUDE.md instructions to prevent loading (agents ignore them)
- Silent guard failures (always log the reason)
- `exit(1)` for intentional opt-out (use `exit(0)`)
