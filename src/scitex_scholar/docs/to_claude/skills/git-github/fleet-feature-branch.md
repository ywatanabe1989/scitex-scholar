# Fleet feature-branch workflow

SciTeX fleet agents work from **any host** on a shared codebase. This page
codifies how an agent on MBA, NAS, Spartan, or ywata-note-win ships a change
without creating drift or blocking other hosts.

## The contract

1. Every non-trivial change goes through a feature branch, then a PR.
2. No agent is bottlenecked on another host for a fix.
3. Drift between hosts is detected by `mamba-synchronizer-mba` audits and
   acted on by the owning agent without a dispatcher prompt.

## Branch naming

| Prefix | For | Example |
|---|---|---|
| `fix/` | Bug fix | `fix/329-machines-tab` |
| `feat/` | New feature / module | `feat/ctrl-k-global-search` |
| `docs/` | Skill, README, changelog | `docs/411-mbsync-secrets` |
| `chore/` | Tooling, cleanup, CI | `chore/120-clean-lockfiles` |
| `perf/` | Performance work | `perf/378-drop-getfqdn` |

Include the issue number in the branch name whenever one exists. If the fix
has no issue, file one first (even a one-line filing is cheaper than
unauditable branches).

## Cross-host workflow

On any host with the repo cloned:

```bash
cd ~/proj/<pkg>
git fetch origin
git checkout develop && git pull --ff-only origin develop
git checkout -b fix/<nn>-<short>
# ... edit + test ...
git add -p
git commit -m "fix: short description (#NN)"
git push -u origin fix/<nn>-<short>
gh pr create --base develop --fill
```

A different host can then:

```bash
git fetch origin
git checkout fix/<nn>-<short>   # or review via the PR
# iterate, push more commits, or merge once approved
```

This works identically on MBA / NAS / Spartan compute node / ywata-note-win
WSL because every host has its own `~/proj/<pkg>` clone (see
`python-venv-convention.md` for the editable install pattern the clone
supports).

## Rule: no direct commits to `develop` for non-trivial changes

**Direct commits to `develop` are allowed only for:**
- Skill files under `_skills/` (owned by mamba-skill-manager, low blast
  radius, idempotent appendices)
- Memory files (single-author, short)
- README / CHANGELOG trivial typo fixes

**Everything else is a PR**:
- Code changes in `src/`
- Test changes in `tests/`
- CI / workflow changes
- Docker / deploy config
- Python package metadata (`pyproject.toml`, `setup.cfg`)
- Any commit that touches more than 3 files or introduces new files under
  source directories

Rule of thumb: **if the change could conceivably break another agent's work
when they next pull**, it is a PR, not a direct commit.

Cautionary example (2026-04-14): during the `star` fix chain, both
`mamba-explorer-mba` and `mamba-todo-manager` pushed direct-to-develop
commits in parallel to fix the same JS bug. Both commits landed, neither
fix worked until `docker restart` (see `deploy-workflow.md` §
"Post-deploy verification"), and the rapid commit sequence made it hard to
tell which patch was the source of truth. A PR would have serialized the
attempts and forced review.

## Drift audit — what the synchronizer catches

`mamba-synchronizer-mba` runs a periodic drift audit across every fleet
host's clone of every `~/proj/scitex-*` repo and reports:

- Divergent HEAD hashes on the same branch
- Different branch checked out per host
- Missing repos on hosts that should have them
- Repos on `main` when they should be on `develop` (or vice versa)

A drift report is a call to action for the owning agent, not a request for
approval. When you see your lane's repo flagged:

1. Identify the divergent host (usually yours — the audit surfaces the
   difference, not the culprit).
2. Fetch + fast-forward if your host is behind.
3. Push if your host is ahead.
4. If the divergence is on a feature branch, open or update the PR.
5. Report a one-line "drift resolved for `<pkg>`" to `#agent` when the
   synchronizer's next audit would be clean.

## Anti-patterns

- **Ask ywatanabe to pull on a host you don't have SSH to.** Fleet agents
  form a full bastion mesh (`orochi-bastion-mesh` skill); any host is
  reachable from any other agent. If you think you can't pull from the
  target host, re-read the bastion skill.
- **Commit on `develop` "just this one fix"** when the change touches
  `src/`. The habit compounds; every "just this one" commit makes the
  next drift audit noisier.
- **Leave a feature branch stale on one host** without pushing. Local
  branches never get reviewed, never get merged, and never survive a
  re-clone. Push or delete.
- **Merge via rebase onto develop without running CI**. Fast-forward merges
  that skip CI land broken code on `develop` (the 2026-04-14 `#378` false
  pass was one example).
- **Parallel direct commits from two agents on two hosts** without
  coordinating. Exactly the failure mode the `fleet-claim-protocol.md`
  DRAFT skill is designed to prevent once it lands; until then,
  coordinate in `#agent` or DM before touching a hot file.

## Related

- `fleet-communication-discipline.md` rules #5 (post-hoc reporting), #6
  (silent success), #12 (no [agent-name] prefix)
- `close-evidence-gate.md` — every merge-back should be paired with an
  issue close via `gh-issue-close-safe` if one exists
- `deploy-workflow.md` — PRs that land in `develop` still need the daphne
  restart discipline before the fix reaches users
- `fleet-claim-protocol.md` (DRAFT) — will provide the programmatic lock
  that this workflow currently enforces socially
- `python-venv-convention.md` — every host's `~/proj/<pkg>` clone should
  run under the shared `~/.venv` so PRs get tested identically everywhere
- `orochi-bastion-mesh` skill (loaded separately) — cross-host SSH reach

## Change log

- **2026-04-14 (initial)**: Codified per ywatanabe msg #10790 / #10792
  ("feature branch from any host, no bottleneck, PR back, help each other
  across machines") and todo-manager dispatch msg #10800 item 2. Author:
  mamba-skill-manager.
