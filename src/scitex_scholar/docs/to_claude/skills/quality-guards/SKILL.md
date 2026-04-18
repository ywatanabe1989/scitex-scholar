---
name: quality-guards
description: Quality enforcement rules — no fallbacks, no false positives, no patch work, script everything. Use when reviewing code, verifying fixes, or ensuring code quality.
---

# Quality Guards

## No Fallbacks
- Never allow silent failures
- Never implement fallbacks unless user explicitly requests
- For user-confirmed fallbacks, comment it in source code
- Red cases are useful — do not hide them
- Not working must be not working. Not complete must be not complete.

## No False Positives
Never claim "fixed", "working", or "done" without ALL verification steps:

1. **Log-level** — read actual logs, check for errors/warnings
2. **Tests** — run relevant tests, read PASS/FAIL for each
3. **Visual** — open page with playwright-cli, take screenshot, compare layout
4. **Functional** — test exact user scenario on actual environment

Anti-patterns: trusting HTTP status codes, saying "should be working" without proof, declaring "code loaded" as "feature working".

## No Patch Work
- Find root causes, not surface fixes
- Don't apply band-aids that mask the real problem
- If a fix feels hacky, pause and find the elegant solution

## No Long-Term Memory
The user has deficits in long-term memory. Script everything:
- Minimize manual steps in installation
- Makefile as thin dispatcher, delegate to downstream scripts
- `make status` is the reliable information device
- Switch environments via `.env.{dev,prod}` and `./deployment` scripts

## No Destructive Operations Without User Approval
The orchestrator (and any agent acting on behalf of the user) NEVER approves destructive operations autonomously. Destructive operations include:

| Category | Examples |
|----------|----------|
| Docker | `docker system prune`, `docker volume prune`, `docker rm -f` |
| Filesystem | `rm -rf`, `rm -r` on data directories, bulk deletes |
| Git | `git push --force`, `git reset --hard`, `git clean -f` |
| Database | DROP TABLE, TRUNCATE, cache clear on production |

When a subagent or process requests a destructive operation:
1. Relay the exact request to the user via Telegram (or terminal)
2. WAIT for explicit user approval — do not proceed on silence
3. Only relay the go-ahead after confirmation received

This applies even during autonomous operation. Destructive = user decision.

## Detailed References
- [No fallbacks rules](no-fallbacks.md)
- [No false positives verification checklist](no-false-positives.md)
- [No long-term memory rules](no-long-term-memory.md)
