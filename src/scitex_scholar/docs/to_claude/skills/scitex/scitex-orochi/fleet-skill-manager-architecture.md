---
name: orochi-skill-manager-architecture
description: Two-layer architecture for fleet skill lifecycle. Splits `worker-skill-manager-<host>` (agent-layer worker, LLM-backed, on-demand queries) from `skill-sync-daemon` (process-layer daemon, no LLM, periodic rollup loop on primary host launchd primary + standby host systemd warm-standby via idempotent dual-run). First pilot of the hybrid-worker split pattern. Ratified 2026-04-14 msg#11475.
---

# Skill-Manager Architecture

The fleet's skill lifecycle (CRUD, aggregation, cross-host sync,
drift detection) has two halves with opposite requirements:

1. **Deterministic bulk work** — walking directories, running
   `scitex-dev skills export --clean`, diffing, rsync. Zero LLM
   judgment, pure procedure. Belongs in the **process layer**.
2. **Agentic query work** — "which skill covers X?", "can you
   scitexify this?", "is this skill still accurate given today's
   changes?". Requires LLM judgment. Belongs in the **agent layer**.

Before 2026-04-14 both halves lived inside a single Claude Code
session (`worker-skill-manager-<host>`), which meant the fleet was
burning Claude quota to run a deterministic filesystem scan every
rollup tick. The fix is to split them.

## Origin

See `00-agent-types.md` for the taxonomy that makes this split
the natural default (defining axis: "LLM-in-loop?"). The
skill-manager is intentionally the **first** hybrid agent to split,
so the same pattern can be applied immediately to
`worker-todo-manager-<host>` (parallel pilot `todo-sweep-daemon`), and
subsequently to `worker-synchronizer-<host>`, `worker-auth-manager-<host>`,
and others.

The host choice evolved across two phases (see
`00-agent-types.md` Origin for the full arc):

- **Phase 1** (msg#11438–#11448): standby host proposed as the sole daemon
  host because it's 24/7 on and systemd-native.
- **Phase 2** (msg#11464, #11483–#11502): empirical standby host load from
  `scitex-cloud` SLURM visitor sessions (6 concurrent jobs, 12/12
  CPU, 24GB allocated) plus primary host's better stability per the operator's
  assessment → pilot moves to **primary host primary + standby host warm-standby**
  via idempotent dual-run (head-<host> option (d), msg#11499).
- **Ratification**: msg#11475 the operator "final check before GO".

## The split

```
╔═══════════════════════════════════════════════════════════════╗
║  AGENT LAYER (LLM-backed, quota-consuming)                    ║
║                                                               ║
║    worker-skill-manager-<host>                                    ║
║    role=worker  function=[skill-sync, taxonomy-curator]       ║
║    host=primary host (Claude Code session)                             ║
║    job=Track B (on-demand queries)                            ║
║                                                               ║
║    Reads skill files, answers "where is X", drafts new        ║
║    skills from conversation, scitexifies legacy scripts,      ║
║    curates taxonomy revisions. Silent otherwise.              ║
╠═══════════════════════════════════════════════════════════════╣
║  PROCESS LAYER (no LLM, quota-zero)                           ║
║                                                               ║
║    skill-sync-daemon                                          ║
║    role=daemon  function=[skill-sync]                         ║
║    host=primary host launchd (primary)                                 ║
║         + standby host systemd (warm-standby, idempotent dual-run)     ║
║    cadence=30 min on both hosts                               ║
║    job=Track A (periodic rollup)                              ║
║                                                               ║
║    Scans the 4 skill locations, runs scitex-dev skills        ║
║    export --clean, diffs, rsync to dotfiles, writes           ║
║    one-line result to host-local log. Never holds a           ║
║    WebSocket session. Idempotent — running on both hosts      ║
║    produces the same output, no shared lease required.        ║
╚═══════════════════════════════════════════════════════════════╝
```

## Track A — `skill-sync-daemon` (process layer, primary host primary + standby host warm-standby)

A launchd job on primary host (primary) running the same bash/python script
as a systemd user timer on standby host (warm-standby). Pure
bash/python, no Claude session on either host.

### Cadence

- **Default**: every 30 minutes on **both** hosts.
- **No lease election required.** The output is idempotent: same
  input (two shared skill repos at a given HEAD commit) → same
  dotfiles mirror state. If primary host primary runs at `T+0` and writes
  the mirror, standby host standby running at `T+0:30` finds the same
  inputs and writes the same mirror (or an updated mirror if HEAD
  moved during the interval). Both mirrors live on their own host
  and are equivalent because the inputs are canonical. This is
  head-<host> option (d) from msg#11499 — idempotent dual-run, no
  shared lease store required.
- **Adjustable live**: if the skill library churns fast enough
  that 30 min backs up drift, drop to 15 min; if ticks keep
  finding nothing, stretch to 60 min. The cadence knob lives in
  the launchd plist on primary host and the systemd unit on standby host; either
  host's own head can adjust without cross-host coordination.
- **Miss-backfill property**: if primary host primary misses an interval
  (launchd not loaded, host sleeping, etc.), the next standby host tick
  within 30 minutes catches the drift. Worst-case drift window
  is bounded by `max(primary host cadence, standby host cadence)`, not by any
  single host's uptime.

### Per-tick procedure (in order)

1. **Scan the skill locations (public + private):**
   - `~/proj/scitex-agent-container/src/scitex_agent_container/_skills/scitex-agent-container/` (public, canonical)
   - `~/proj/scitex-orochi/src/scitex_orochi/_skills/scitex-orochi/` (public, canonical)
   - `~/.scitex/agent-container/skills/scitex-agent-container-private/` (private per-machine, symlinked on export)
   - `~/.scitex/orochi/skills/scitex-orochi-private/` (private per-machine, symlinked on export)
   - Convention: `~/.scitex/<suffix>/skills/<package>-private/` → `~/.claude/skills/scitex/<package>-private/`
2. **Git status** of the two shared locations. If dirty (uncommitted
   local edits), skip the export step for that repo and log the
   skip — never clobber in-progress work.
3. **Run** `scitex-dev skills export --clean` in each clean repo.
   Verify exit 0. On non-zero: write the full stderr to the log
   and drop a touch-file `~/.scitex/orochi/skill-sync-daemon.fail`
   so the agent layer's healer-prober notices on next probe.
4. **Frontmatter integrity scan.** Verify each `*.md` skill file
   in the two shared trees has a frontmatter block with `name:`
   and `description:` fields. Repair eligibility is **strictly
   limited** (see "Auto-repair threshold" below).
5. **Dedupe candidate detection.** Compare `name:` and
   `description:` across skills in the same tree; flag files whose
   name or description shares ≥3 significant tokens with another
   skill. Log the candidates, do **not** merge — merge is an
   agent-layer decision (Track B worker opens an issue).
6. **Dotfiles mirror sync.** If either shared tree's HEAD commit
   changed since this host's previous tick, rsync the tree into
   `~/.dotfiles/src/.claude/skills/` so new agent hosts inherit
   the update. Use `rsync --delete` within the target subtree to
   keep the mirror exact. **Host-local**: primary host writes to
   `~/.dotfiles/...`, standby host writes to its own
   `~/.dotfiles/...`; both mirrors are equivalent because both
   read from the same canonical upstream repos via `git pull`.
7. **Write one log line** to host-local
   `~/.scitex/orochi/logs/skill-sync-daemon.log` with:
   `ISO8601 | host=<mba|nas> | tick=N | exported=<N> | drift-repaired=<N> | dedupe-flags=<N> | mirror-updated=<bool> | wall-time=<sec>`
8. **No hub post.** Ever. State-change-only reporting is the
   agent layer's job (Track B worker reads the log via host-local
   file access on primary host, or via SSH on standby host, when asked).

### Why primary host primary, standby host warm-standby

1. **Empirical stability** (the operator msg#11464) — primary host is
   currently the most stable agent host, and the skill-sync pilot
   benefits from the least-risky landing pad.
2. **standby host SLURM traffic is real** (head-<host> msg#11492/#11493) —
   `scitex-cloud` visitor sessions run 6 concurrent SLURM jobs
   (12/12 CPU, 24GB allocated, 59-min walltime caps,
   `scitex-alloc-<hash>.sh` allocation scripts). A CPU-hot direct-
   exec systemd timer on standby host would step on visitor allocations via
   the kernel scheduler even without going through SLURM.
   `scitex-dev skills export --clean` is fast but non-trivial; it
   should not be a first-class primary host→standby host offload target.
3. **standby host is the right warm-standby** because it's 24/7 on and
   systemd-native. The standby's cost is one idempotent bash
   script per 30 minutes — I/O-light and CPU-cheap, which is
   exactly what the "standby host accepts" column of the daemon host
   policy table (`00-agent-types.md`) calls out as fine.
4. **Escape hatch**: if a future heavy-compute phase is needed
   (e.g. bulk embedding over all skills, semantic deduplication),
   submit as `sbatch` on standby host rather than direct systemd-timer
   exec. standby host's SLURM queue alongside visitor traffic is the right
   path, not a direct launchd-style CPU burst.

### Auto-repair threshold (per head-<host> review, msg#11427)

The daemon is **only** allowed to auto-repair frontmatter issues
that are mechanical, reversible, and carry zero semantic risk:

- Fix frontmatter typos in field names (`descrption:` →
  `description:`).
- Align `name:` to filename when the mismatch is obviously a
  rename that forgot to update the field.
- Normalize whitespace / trailing newlines in the frontmatter
  block.

The daemon **must not** auto-edit:

- The `description:` body text, or any other free-text field.
- The markdown body of the skill.
- Trigger rules, deliverables, cadences, or any other
  semantics-bearing content.

Anything outside the auto-repair whitelist → log the finding and
open a `gh issue` under label `skill-drift` tagged
`@worker-skill-manager-<host>`. The agent-layer worker reviews those
issues on demand.

### Failure handling

- Non-zero exit from `scitex-dev skills export`: drop
  host-local `~/.scitex/orochi/skill-sync-daemon.fail` touch-file,
  include full stderr in the log, continue the rest of the tick.
  Do **not** retry — an agent-layer worker should look at it.
- Rsync failure: same pattern. Don't self-recover.
- Filesystem scan error: log, skip the affected path, continue.

Each host owns its own `.fail` touch-file in its own
`~/.scitex/orochi/` so failures on one host don't block the
other. The Track B worker on primary host reads the local `.fail`
directly and reads standby host's via SSH (or via a hub `fleet_report`
endpoint if/when the daemon inventory gets aggregated centrally).

The daemon never escalates. The healer-prober notices the
`.fail` touch-file or the stale log timestamp on its next probe
and spins up an agent-layer worker to triage.

## Track B — `worker-skill-manager-<host>` (agent layer, primary host)

The existing Claude Code session, but with Track A responsibility
removed. After the split, Track B's job is purely on-demand:
respond to queries, draft new skills, review daemon-flagged
drift/dedupe candidates, curate taxonomy.

### Response SLA

| Source              | Target latency | Escalate if                                       |
|---------------------|----------------|---------------------------------------------------|
| DM from any agent   | ≤ 60 s         | miss → #escalation after 5 min                    |
| #agent @mention     | ≤ 60 s         | same                                              |
| #the operator direct   | ≤ 30 s         | miss → TTS escalation                             |
| #the operator fleet    | only if skills expertise is the blocker; otherwise silent (the operator thread is DM-ish, not fleet broadcast) |

### Response format (terse, in order)

1. **Canonical file path** — absolute path under one of the four
   skill locations.
2. **One-line summary** of what the skill actually enforces.
3. **Gap note** — if the question reveals a missing skill, say so
   explicitly and offer to draft one. Do not silently invent a
   new skill inline.

### Standing queues the worker services

- **Drift issues** opened by `skill-sync-daemon` under label
  `skill-drift` — review and close or escalate, do not let them
  accumulate.
- **Dedupe candidates** logged by the daemon — decide per
  candidate whether to merge (requires the operator or head-<host>
  sign-off), rename, or leave as-is with a note.
- **Export failures** signaled by
  `~/.scitex/orochi/skill-sync-daemon.fail` on either host —
  fetch the log, diagnose, clear the touch-file only after the
  root cause is fixed.

### Silent-otherwise discipline

Outside of query response, daemon-queue servicing, and the single
startup announce to `#the operator`, the Track B worker is silent.
No heartbeat. No "still idling". No "queues empty, nothing to
do." Those go to `~/.scitex/orochi/logs/skill-manager-worker.log`
(per head-<host> review, msg#11427 — explicit local log path).

### What Track B worker does **not** do

- Does **not** run the Track A scan itself. That's the daemon's
  job. If both daemon instances are down, the worker raises
  `#escalation` for the healer to resurrect them — the worker
  does **not** run the deterministic loop "temporarily" to cover.
- Does **not** close issues. `gh-issue-close-safe` + the
  close-evidence-gate auditor own that.
- Does **not** edit other agents' workspace files. Only the two
  shared skill trees + the dotfiles mirror (on primary host; standby host is
  idempotent-equivalent).
- Does **not** post heartbeat / keep-alive pings. Healer prober
  owns liveness.
- Does **not** decide merges unprompted. Flagged dedupe
  candidates require human or head-<host> sign-off before any merge.

## Parallel pilot #2 — `todo-sweep-daemon`

`worker-todo-manager-<host>` Track A is being daemonized
simultaneously on **primary host launchd** as a redundancy stress-test.
Same scaffolding as `skill-sync-daemon`, different input
interface (`gh issue` sweep + cross-ref index refresh + close-
evidence audit of the todo-repo mirror) instead of skill-tree
walking. Both daemons feed the same observability stream (log
line + optional `.fail` touch-file), and if either falls over,
the other keeps data flowing. This is **day-1 redundancy, not
retrofit** — the fleet gets two independent pilots of the same
split pattern landing in the same ratification commit so the
pattern is proven on more than one concrete case before it
becomes the default recommendation.

See `worker-todo-manager-<host>`'s own architecture doc (when
drafted) for the per-tick procedure on that side.

## Parallel pilot #3 — `slurm-resource-scraper`

A third pilot lands alongside this one in the same ratification PR:
`slurm-resource-scraper` on Spartan + standby host + secondary host, drafted by
head-<host> under the "external-tool-compat" design principle (use
stock SLURM CLI output — `sinfo`, `squeue`, `sacct`,
`scontrol --json`, `sreport` — as canonical wire format, emit
NDJSON with SLURM long-form column names, bash + systemd-timer,
no custom schema). See `infra-slurm-resource-scraper-contract.md` for
the full contract — it is the canonical example of the
external-tool-compat design principle for *all* metrics-collector
daemons in the fleet.

The scraper is the canonical example of the design-time
external-tool-compat principle for *all* metrics-collector
daemons in the fleet: never invent a bespoke JSON schema when a
widely-deployed external tool (SLURM, systemctl, docker,
cloudflared, autossh, etc.) already speaks a canonical one.
`host-self-describe`, `tunnel-health`, and future collectors
should copy this pattern.

## Split rationale summary

| Concern                      | Before (single session)                         | After (split)                                                     |
|------------------------------|-------------------------------------------------|-------------------------------------------------------------------|
| Quota cost of rollup loop    | 1 Claude session running 24/7 just to walk dirs | Zero — launchd on primary host + systemd on standby host, both quota-free           |
| Response latency for queries | Depends on whether the tick loop was mid-`export` | Always fast — worker session is idle between queries              |
| Failure isolation            | Rollup failure took down the query responder   | Daemon failure is signaled to the worker, worker stays up         |
| Single point of failure      | One host, one session                           | Two hosts, idempotent dual-run, miss-backfill within one cadence  |
| Observability                | Mixed chatter + real findings                   | Daemon log is machine-parseable; worker posts only when asked     |
| Host locality                | primary host (same as everything)                        | primary host primary (stability) + standby host warm-standby (24/7); host-diverse   |
| standby host visitor SLURM collision  | N/A (rollup was on primary host)                         | Avoided — standby is I/O-light, CPU-hot stays on primary host              |

## Related skills

- `00-agent-types.md` — the 2-layer + role × function model
  that makes this split the default shape for hybrid agents.
- `infra-slurm-resource-scraper-contract.md` — parallel pilot #3 and
  canonical example of external-tool-compat design principle for
  metrics-collector daemons.
- `silent-success.md` — rule #6 discipline that governs the
  worker's posting behavior.
- `fleet-communication-discipline.md` — #the operator vs #agent vs
  #progress rules the worker follows.
- `agent-startup-protocol.md` — 5-step boot sequence the Track B
  worker runs before entering its idle-respond loop.
- `fleet-close-evidence-gate.md` — the evidence standard the worker
  cites when asked "how do I close a skill-related issue
  properly?".
- `infra-deploy-workflow.md` — deployment distinctions (launchd
  reload on primary host / systemd reload on standby host for the daemon vs pane
  restart for the worker).
- `hpc-etiquette.md` — if the standby host-side standby ever needs to be
  rerouted through `sbatch`, this skill's login-node / SLURM
  discipline applies.
