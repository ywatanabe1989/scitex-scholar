---
name: orochi-quality-checks
description: Fleet-wide quality monitoring procedures — smoke tests, CLI conventions, skill drift, regression watch. Owned by worker-quality-checker.
---

# Quality Checks

Continuous quality monitoring across all SciTeX / Orochi packages. Owned by
**worker-quality-checker** but any agent can run these checks on demand.

## Smoke Test (per-package)

The canonical smoke test lives at `scitex-agent-container/scripts/scitex-smoke-test.py`
(originally created by head-<host> in todo#194). It verifies, for every
installed `scitex-*` package:

1. `import <pkg>` succeeds without exception
2. `<pkg> --help` exits 0 (CLI is reachable)
3. `<pkg> --json` exits 0 if `--json` is supported (advisory)

### Run

```bash
python scitex-agent-container/scripts/scitex-smoke-test.py
```

Output is grouped by `PASS / FAIL / SKIP`. Exit code is non-zero if any
installed package fails. Skips (uninstalled packages) do not fail the run.

### Schedule

worker-quality-checker runs the smoke test:
- **Hourly** on every host that has SciTeX packages installed (mba, nas,
  spartan, ywata-note-win), via `/loop 1h` or cron
- **On demand** when an agent suspects a regression
- **Pre-deploy** before any package release as a gate

Failures must be reported in `#general` and filed as a `bug` issue on
`the project's issue tracker` with the failing package, host, and traceback.

## CLI Convention Audit

Track which packages comply with the CLI conventions in `convention-cli.md`:
- `--help` exits 0
- `--json` machine-readable output supported
- `--version` exits 0
- Subcommands follow `<verb> <noun>` order

Maintain a public scorecard (table in #general or a dashboard widget) so
package owners can see drift over time.

## Skill Drift

Defer to `worker-skill-manager` for the canonical drift audit, but
worker-quality-checker should flag any obviously stale or contradictory skill
file it encounters during reviews and ping `@worker-skill-manager`.

## Regression Watch (Pre-Release Gate)

Before any package is tagged + released (see `infra-deploy-workflow.md` Release
Hygiene), worker-quality-checker should:

1. Pull latest `develop`
2. Run the smoke test on every reachable host
3. Run the package's own `pytest` if present
4. Run `ruff check .` if configured
5. Block the release on any regression vs. the previous tag

If everything passes, react with ✅ on the deploy request message.

## Reporting

worker-quality-checker reports in:
- `#progress` for routine cycle status (every loop)
- `#general` for surfacing failures or convention violations
- `#escalation` only for severe regressions affecting production (`scitex.ai`,
  hub on `scitex-orochi.com`)

Use the standard 1–2 line progress format: 完了 / 進行中 / 次.
