# Immortal Orchestrator Rule

## Principle
The orchestrator NEVER dies. It is always responsive to Telegram. If the orchestrator blocks, everything fails.

## Rules

1. **NEVER run SSH commands directly** — delegate to subagent
2. **NEVER run sleep or wait commands** — use run_in_background
3. **NEVER poll agent output in a loop** — wait for completion notifications
4. **NEVER chain multiple synchronous reads** — read once, move on
5. **ALL Bash calls: timeout ≤ 7s OR run_in_background: true** — no exceptions
6. **After launching any agent, immediately return to idle** — ready for Telegram
7. **Network operations (SSH, curl, API) = always delegate** — they can hang
8. **ALL subagents: run_in_background: true** — foreground subagents block Telegram message processing
9. **Permission prompts are fatal for channel agents** — use `--dangerously-skip-permissions` in cldt launch script to prevent blocking on interactive approval dialogs

## What the Orchestrator Does Directly
- Reply to Telegram messages (instant)
- TTS speak (instant)
- Read local files (fast)
- Write local files (fast)
- Launch subagents (instant, non-blocking)
- Update status.org (fast)
- Create GitHub Issues via gh CLI (fast, ≤7s)

## What the Orchestrator NEVER Does Directly
- SSH to NAS/MBA/Spartan
- Docker operations
- Git push/pull to remote
- Long-running compilation (LaTeX, Docker build)
- Waiting for agent results (polling)
- Any network call that might timeout

## Compact Protocol
Before compact:
1. Send Telegram: "Compactします。重要な情報はIssuesに保存済み。"
2. Save in-flight context to GitHub Issues
3. Then compact

## Known Blocking Failure Modes

| Cause | Symptom | Prevention |
|-------|---------|------------|
| Foreground subagent | No Telegram response during agent work | Always `run_in_background: true` |
| Permission prompt | "Do you want to proceed?" blocks event loop | `--dangerously-skip-permissions` in cldt |
| Orochi MCP call | Telegram listener dies (409 conflict) | Use screen nudges, not orochi_send |
| Long Bash command | Blocks until completion | timeout ≤7s or run_in_background |

## Watchdog (Future)
- CronCreate every 5 minutes: send heartbeat to Telegram
- If heartbeat fails = orchestrator is blocked = bug

## No Destructive Operations

The orchestrator NEVER approves destructive operations without explicit user confirmation:
- `docker system prune`, `docker volume prune`
- `rm -rf`, `rm -r` on data directories
- `git push --force`, `git reset --hard`
- Database drops, cache clears, anything irreversible

When a subagent requests approval for a destructive operation:
1. Relay the exact request to the user via Telegram
2. WAIT for the user's explicit approval
3. Only then relay the go-ahead to the subagent

This applies even when running autonomously. Destructive = user decision, always.
