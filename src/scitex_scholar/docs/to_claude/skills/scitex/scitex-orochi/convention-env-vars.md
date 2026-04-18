---
name: orochi-convention-env-vars
description: Environment-variable naming convention for scitex-orochi.
---

# Env-var convention — `SCITEX_OROCHI_*`

All scitex-orochi-specific configuration MUST use the `SCITEX_OROCHI_`
prefix. This avoids collisions with other scitex packages and with
industry-standard names (`GITHUB_TOKEN`, `PATH`, etc.) that other
tooling also reads.

## Source of truth

Runtime values are declared in
`~/.dotfiles/src/.bash.d/secrets/010_scitex/01_orochi.src` and sourced
automatically via the dotfiles login flow. Do **not** hard-code values
in the codebase or in deploy manifests — only sensible defaults for
local dev.

## Live variable table (as of 2026-04-17)

| Variable | Purpose | Fallback |
|---|---|---|
| `SCITEX_OROCHI_TOKEN` | Workspace auth token for agent → hub API | — |
| `SCITEX_OROCHI_ADMIN_TOKEN` | Admin-scope token | — |
| `SCITEX_OROCHI_HUB` / `SCITEX_OROCHI_HUB_URL` | Hub base URL | `https://scitex-orochi.com` |
| `SCITEX_OROCHI_HOST` / `SCITEX_OROCHI_PORT` | Daphne listen addr/port | `0.0.0.0` / `8559` |
| `SCITEX_OROCHI_CONFIG` | Path to orochi config file | auto |
| `SCITEX_OROCHI_AGENT` | This agent's name | `platform.node()` |
| `SCITEX_OROCHI_AGENT_ROLE` | Agent role label (`head`, `telegram`, …) | — |
| `SCITEX_OROCHI_HOSTNAME` | Display hostname for dashboard | `platform.node()` |
| `SCITEX_OROCHI_EXTERNAL_IP` | External IP (for routing from lan hosts) | — |
| `SCITEX_OROCHI_DB_PATH` | SQLite path inside container | `/data/db.sqlite3` |
| `SCITEX_OROCHI_SSO_URL` | scitex.ai SSO base | `https://scitex.ai` |
| `SCITEX_OROCHI_SCITEX_CLIENT_ID` / `SCITEX_OROCHI_SCITEX_SECRET` | OAuth creds for scitex.ai SSO | — |
| `SCITEX_OROCHI_VAPID_PUBLIC` / `_PRIVATE` / `_SUBJECT` | Web-push keys | baked defaults |
| `SCITEX_OROCHI_CHANNELS_YAML` | Channel-ACL config path | — |
| `SCITEX_OROCHI_GITHUB_TOKEN` | GitHub API token for dashboard widgets + issue hydration | `GITHUB_TOKEN` |
| `SCITEX_OROCHI_GITHUB_REPO` | Default repo for GH queries | `ywatanabe1989/scitex-orochi` |
| `SCITEX_OROCHI_GITHUB_WEBHOOK_SECRET` | HMAC secret for `/webhook/github/` | `GITHUB_WEBHOOK_SECRET` |
| `SCITEX_OROCHI_GITHUB_WEBHOOK_CHANNEL` | Channel that receives GH events | `GITHUB_WEBHOOK_CHANNEL` → `#progress` |
| `SCITEX_OROCHI_TELEGRAM_BOT_TOKEN` | Telegram bridge bot token | — |
| `SCITEX_OROCHI_TELEGRAM_CHAT_ID` | Telegram chat ID | — |
| `SCITEX_OROCHI_TELEGRAM_WEBHOOK_SECRET` | HMAC secret for `/webhook/telegram/` | — |
| `SCITEX_OROCHI_CADUCEUS_HOST` / `_MACHINE` / `_NAME` | Caduceus agent identity | — |
| `SCITEX_OROCHI_CONTACT_PHONE_JA` / `_AU` | Escalation phone numbers | `PRIV_MOBILE_*` |
| `SCITEX_OROCHI_DISABLE` | If truthy, skip MCP server startup | — |
| `SCITEX_OROCHI_PUSH_TS` | Override push-timestamp path | — |
| `SCITEX_OROCHI_AGENT_META_VERSION` | Version label baked into snapshots | `0.2` |

## Legacy-fallback rule

When migrating a third-party convention (e.g. `GITHUB_TOKEN`,
`GITHUB_WEBHOOK_SECRET`) into this namespace, the code reads the
`SCITEX_OROCHI_*` name first, then falls back to the bare name:

```python
token = (
    os.environ.get("SCITEX_OROCHI_GITHUB_TOKEN")
    or os.environ.get("GITHUB_TOKEN", "")
)
```

This keeps the convention clean for orochi-specific configuration
without breaking tooling that relies on the industry-standard name
being present in the shell.

## Where values actually live

- **Secrets** (tokens, OAuth client secrets, webhook HMAC): `~/.secrets/api_keys.src` — outside the dotfiles repo, never committed.
- **Derived / routing** (hostnames, channels, default URLs, chat IDs): `~/.dotfiles/src/.bash.d/secrets/010_scitex/01_orochi.src` — committed.
- **Container runtime** (passed through to docker): `deployment/docker/docker-compose.stable.yml` — committed.

## How to change an env var safely

1. Edit `~/.dotfiles/src/.bash.d/secrets/010_scitex/01_orochi.src` and add/update the export.
2. If the value needs to reach the container, add the matching line to `deployment/docker/docker-compose.stable.yml`.
3. If the code needs to read it, prefer the dual-read pattern in `convention-env-vars.md` (SCITEX_OROCHI_* first, legacy fallback only for conventional vars).
4. Redeploy: `scp` the updated compose file to mba, then `docker compose up -d`.
5. Document the new var in this file's table above.
