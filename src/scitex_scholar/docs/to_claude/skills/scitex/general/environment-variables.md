---
description: Environment variable naming convention — SCITEX_<MODULE_NAME>_* prefix rule to avoid namespace collisions across the SciTeX ecosystem.
---

# Environment Variable Naming

All SciTeX packages MUST use the `SCITEX_<MODULE_NAME>_*` prefix for environment variables to avoid namespace collisions.

| Package | Prefix | Example |
|---------|--------|---------|
| scitex-orochi | `SCITEX_OROCHI_` | `SCITEX_OROCHI_HOST` |
| scitex-notification | `SCITEX_NOTIFICATION_` | `SCITEX_NOTIFICATION_DEFAULT_BACKEND` |
| scitex-cloud | `SCITEX_CLOUD_` | `SCITEX_CLOUD_HOST` |
| scitex-audio | `SCITEX_AUDIO_` | `SCITEX_AUDIO_BACKEND` |
| scitex-writer | `SCITEX_WRITER_` | `SCITEX_WRITER_OUTPUT_DIR` |
| scitex-scholar | `SCITEX_SCHOLAR_` | `SCITEX_SCHOLAR_EMAIL_FROM` |

## Rules

- Primary prefix: `SCITEX_<MODULE>_*` — the ONLY prefix checked in code
- No fallbacks to legacy or external env var names (e.g., `GITHUB_TOKEN`, `CLAUDE_AGENT_ROLE`). If the `SCITEX_<MODULE>_*` var is not set, it must fail visibly
- Secrets file (`~/.bash.d/secrets/`) bridges external vars: `export SCITEX_OROCHI_GITHUB_TOKEN="$GITHUB_TOKEN"`
- Never use bare `SCITEX_*` without a module name — reserved for framework-level config
- Verify with `env | grep SCITEX_<MODULE>_` — all vars the package uses must appear
- Show `$ENV_VAR_NAME` in CLI help defaults, not resolved values
- Configuration is external (env vars, config files) — never hardcode secrets or defaults that should be user-configurable

## Feature Flags

All SciTeX feature flags follow the **opt-out** pattern (default enabled, explicitly disable):

| Pattern | Example | Meaning |
|---------|---------|---------|
| `SCITEX_<MODULE>_DISABLE=true` | `SCITEX_OROCHI_DISABLE=true` | Disable a module entirely |
| `SCITEX_MCP_USE_<MODULE>=0` | `SCITEX_MCP_USE_PLT=0` | Disable MCP tool group |

**Convention:**
- Features are **enabled by default** (opt-out)
- Set `DISABLE=true` or `USE_*=0` to turn off
- Never require users to opt-in for core functionality
- Enforce with code (guards, exit), not documentation

### Exceptions (opt-in)

Some features require explicit opt-in due to external dependencies or resource costs:

| Variable | Reason |
|----------|--------|
| `SCITEX_OROCHI_TELEGRAM_BRIDGE_ENABLED` | Telegram bridge connects to external Bot API; must be intentional |
| `SCITEX_SCHOLAR_OPENATHENS_ENABLED` | External authentication service; security-sensitive |
| `SCITEX_NOTIFICATION_TELEGRAM_POLLING_ENABLED` | Long-polling is resource-intensive; opt-in to avoid waste |

These use `_ENABLED=true` to activate. The rule: if a feature touches external services, auth, or consumes resources when idle, it may use opt-in instead.
