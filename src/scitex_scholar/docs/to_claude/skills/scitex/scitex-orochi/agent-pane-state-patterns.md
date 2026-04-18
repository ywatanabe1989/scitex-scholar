---
name: orochi-pane-state-patterns
description: Canonical regex catalog for classifying tmux pane state of an Orochi Claude Code agent. Feeds into auto-unblock + credential rotation + "working side" triage. Upstream truth at ~/.emacs.d/lisp/emacs-claude-code.
---

# Pane State Patterns

Every fleet healer, watchdog, and auto-unblock loop needs one shared way to answer "what is this tmux pane doing right now?" This skill is the canonical regex catalog. It is a **library**, not a process — `scitex-orochi/pane_state.py` (PR #118) and future healer loops consume it.

## Why

2026-04-13 the fleet hit every failure mode in a single session: dev-channels prompts that blocked for 5 hours, quota exhaustion banners that looked like idle cursors, permission prompts that nobody answered, `--continue` conflicts manifesting as startup hangs, mcp-channel zombies that left the pane silent, and a classifier that mistook "busy" for "dead" because it only looked at Orochi post timestamps.

The operator's directive was consistent (msgs #9438 / #9442 / #9550 / #9674 / #10210):

1. Collect the patterns, don't invent them on each observation.
2. Classify by state, not by guess.
3. **Fall to the working side** — auto-answer benign prompts, default to continuing, escalate only when unsafe.
4. Single source of truth: `~/.emacs.d/lisp/emacs-claude-code` has already catalogued the patterns — mirror, don't diverge.

## States

A pane is in **exactly one** of the states below per classification call:

| State | Meaning | Severity | Auto-action |
|---|---|---|---|
| `:running` | Claude is actively producing tokens | green | none |
| `:waiting` | Claude at `❯` prompt, no queue, alive | green | none |
| `:mulling` | Claude animation active (`* Mulling…` / `* Pondering…` / `* Churning…` / `Roosting…`) | green | none — busy, not idle |
| `:paste_pending` | `Press up to edit queued messages` or similar; input already queued | green | send `Enter` once |
| `:permission_prompt` | Generic "Do you want to proceed? (y/n)" or numbered choices | yellow | send the **safe** option (`2`/`n`) by default |
| `:dev_channels_prompt` | First-run "I am using this for local development" 1/2 prompt | yellow | send `1` Enter (dev acceptance) |
| `:auth_needed` | `/login` flow, OAuth URL visible, awaiting code paste | yellow | post URL to `#operator`, wait for code |
| `:quota_exhausted` | "out of extra usage · resets …" | red | swap credential per `agent-account-switch.md` |
| `:quota_warning` | `\d\d% \| Limit reach` (≥ 80%) | yellow | pre-emptive swap if alternate account < 70% |
| `:mcp_broken` | `.mcp.json` missing or sidecar died; hub heartbeat stopped while pane looks fine | red | `scitex-agent-container restart` |
| `:stuck_error` | API error messages not matching quota/auth patterns | red | capture pane, escalate to `#escalation` |
| `:dead` | Claude exited; pane shows shell prompt or empty | red | autostart unit should respawn; else escalate |
| `:unknown` | Nothing matched | neutral | log + alert, never guess |

**`:running` and `:mulling` are not idle.** Healers that escalate on "silent for N seconds" without checking the animation row produce false positives. This was the 2026-04-13 head-<host> incident.

## Regexes

Match on the **tail** of `tmux capture-pane -pt "${PANE}"` (last 60–200 lines). Regexes are case-sensitive unless noted.

### `:mulling` — busy animation
```
(?m)^\s*[*✻]\s*(Mulling|Pondering|Churning|Roosting|Thinking|Cogitating|Musing|Reflecting)…?\s+\(\d+\w+
```
Notes: Claude's animation verbs rotate. `emacs-claude-code` upstream has the full list — mirror from there, don't invent.

### `:paste_pending`
```
Press up to edit queued messages
```
Singular match, bottom of pane. Trigger: send `Enter` once, then re-capture.

### `:permission_prompt` — generic y/n
```
(?mi)(Do you want to proceed\?|\[y/N\]|\(y/n\)|Continue\?)
```
Action: the **safe default** varies per prompt. Healer must also match the prompt *context*:

- File-edit prompts → default `y` if the file is under `~/.scitex/` / `~/proj/`, else `n`
- Network install prompts (`pip install`, `apt install`) → `n` by default unless agent context authorizes
- Unknown → `n` and escalate

### `:permission_prompt` — numbered 1/2/3
```
(?m)^\s*❯?\s*(1\.|2\.|3\.)\s+[A-Z]
```
Action: pair with context. Commonly `2` = safe "exit / cancel", `1` = "proceed in dev mode". The dev-channels prompt below is a specific subtype.

### `:dev_channels_prompt` — first-run dev channels
```
I am using this for local development
```
Full prompt (from the 2026-04-13 head-<host> incident):
```
❯ 1. I am using this for local development
  2. Exit
```
Action: send `1` + Enter (accept dev mode). See memory `project_permission_prompt_blockers.md` — `--dangerously-skip-permissions` does not cover this one.

### `:auth_needed` — OAuth login
```
https://claude\.com/cai/oauth/authorize\?code=true
```
Or:
```
(?i)Paste your login code here
```
Action: extract the URL, post to `#operator` (as file or chat), wait for the code. Do not attempt to auto-complete OAuth — the code comes from the human.

### `:quota_exhausted`
```
(?i)out of extra usage
```
Or:
```
(?i)resets (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d+
```
Or:
```
/extra-usage to finish what you're working on
```
Action: trigger `agent-account-switch.md` swap.

### `:quota_warning`
```
(?m)(8\d|9\d)%\s+⚠\s+Limit reach
```
Action: pre-emptive swap if the alternate account is < 70% on both windows.

### `:mcp_broken`
Pane looks fine but:

- `pgrep -f 'bun.*mcp_channel' -c` returns 0 on the host for this agent **and**
- hub `/api/agents/<agent>/` shows `last_heartbeat` older than 3 × sampler period

Action: `scitex-agent-container restart <yaml>` — side-car-only restart, preserves Claude Code state. Escalate if restart fails twice in 10 minutes.

### `:stuck_error`
Generic fallback for API errors not matching the quota/auth patterns:
```
(?i)(API Error|internal server error|rate.?limit|ECONNRESET|unexpected EOF)
```
Do not auto-retry — capture pane, post to `#escalation`, let a human route.

### `:dead`
```
(?m)^\s*\$\s*$
```
Or `tmux capture-pane` returns empty. Claude exited, shell prompt or blank. Action: autostart unit should respawn; if autostart fails, escalate.

## Session-existence preflight — `tmux ls`, not `screen -ls`

Added 2026-04-15 after `worker-healer-<host>` msg #12799 false-alarmed
"fleet down — all 12 agents + screen sessions gone" while all 12
tmux sessions were in fact alive.

Before any pane-state classification, a healer must first confirm
the session exists. The session-existence check must use the same
multiplexer the agents are actually running in:

- scitex-agent-container defaults to `multiplexer: tmux` since v0.7.
  Session-existence check: **`tmux ls`**.
- `screen -ls` is only valid on hosts where an agent's YAML explicitly
  sets `multiplexer: screen`. On all other hosts (primary workstation included) the
  screen socket is empty and `screen -ls` reports "No Sockets found",
  which is **not** evidence that the agents are dead.

Contract for any liveness probe:

1. **Primary signal**: `tmux ls` (or `screen -ls` iff the agent's
   configured multiplexer is screen). If the expected session name is
   present, the session exists. Classify pane state from here.
2. **Secondary signal only**: `scitex-agent-container list` output.
   Treat an empty list as a **hypothesis** to cross-check with the
   primary signal, never as ground truth. A stale / crashed
   scitex-agent-container list command can return an empty list while
   the underlying sessions are fine.
3. **Never escalate** a "fleet down" classification on the secondary
   signal alone. If `tmux ls` shows the session, the session is alive;
   post-fix the probe code instead of the fleet.
4. If the probe cannot reach the multiplexer at all (e.g. SSH is
   down), classify the **host** as unreachable — not the individual
   sessions as dead. The agents inside an unreachable host cannot be
   probed, and "can't probe" is distinct from "confirmed dead"
   (rule #11 absence-of-response still applies for DM-based probes,
   but the host layer is a separate question).

A healer that short-circuits this preflight will false-alarm the operator
and the heads, waste fleet attention on a non-incident, and risk
triggering a destructive "restart everything" response. Always two
signals, primary-before-secondary, before classifying a host as down.

## Scrollback false-positive guard — strict last-N-lines window

Added 2026-04-14 after `worker-healer-<host>` msg #10865. Regexes must match against the **last 5 lines** of `tmux capture-pane -p -S -5`, not the full scrollback buffer.

Why: scrollback accumulates every prompt the session has ever seen — a "Press Enter to continue" from 6 hours ago, now scrolled off but still in the buffer, will match a full-buffer regex and trigger a false-positive unblock action. The strict last-5-lines window ensures only the **currently-displayed** prompt is considered.

Implementation contract:

- Capture: `tmux capture-pane -p -S -5 -t <session>` (last 5 lines, joined).
- All regex matches run against that slice, not against `capture-pane -p` (full scrollback) or `capture-pane -pS -` (entire buffer).
- The only exception is `:mulling` detection which checks for an `*` animation row — that can appear anywhere in the visible region, so last-10-lines is acceptable for `:mulling` specifically.
- When a classifier needs to distinguish "live prompt" from "scrollback residue", the rule is **"if it's not in the last 5 lines, it's not a current prompt"**.

Classifiers that ignore this guard will produce spurious `:paste_pending` / `:dev_channels_prompt` / `:permission_prompt` hits on agents that are actually idle at `❯`, and will then send `Enter` or `1` into a live idle prompt — which is a **destructive action** (it submits whatever the agent had been drafting).

Add the last-5-lines check to every new classifier implementation *before* shipping, not as a follow-up fix.

## Classification algorithm

Priority order (highest wins — exit on first match):

1. `:mulling` — animation active → busy
2. `:paste_pending`
3. `:auth_needed`
4. `:quota_exhausted`
5. `:dev_channels_prompt`
6. `:permission_prompt` (numbered, then y/n)
7. `:quota_warning`
8. `:stuck_error`
9. `:mcp_broken` — requires external heartbeat check
10. `:dead` — requires shell-prompt match
11. `:running` — if active output seen in the last 5 seconds
12. `:waiting` — default when nothing above matches and pane tail ends with `❯`
13. `:unknown` — any other case

## Auto-actions

Healers call this module read-only to **classify**, then consult a per-state action table before acting. Action table is **per-agent** (healers may disable auto-unblock on production agents) and **per-host** (spartan must not `systemctl --user restart` anything).

| State | Default action | Confirmation needed? |
|---|---|---|
| `:mulling` | none | no |
| `:paste_pending` | `Enter` | no |
| `:permission_prompt` (safe) | `n` / `2` | no |
| `:dev_channels_prompt` | `1` + Enter | no |
| `:auth_needed` | post URL to `#operator` | no |
| `:quota_exhausted` | credential swap | no, if alternate < 70% |
| `:quota_warning` | pre-swap | yes (log warn first) |
| `:mcp_broken` | `scitex-agent-container restart` | yes, escalate if repeated |
| `:stuck_error` | post to `#escalation` | no (informational) |
| `:dead` | autostart unit | no |
| `:unknown` | escalate once, do not act | no |

## Upstream single source of truth (memory: `project_tui_pattern_single_source`)

This skill is a **mirror**, not a primary. Three sibling catalogs hold the authoritative regex for pane state, and they are kept in sync by humans + worker-skill-manager, **not** by agents inventing new patterns in this file:

| Source | Location | Role |
|---|---|---|
| **Elisp (upstream)** | `~/.emacs.d/lisp/emacs-claude-code/ecc-state-detection.el` (GitHub `the operator1989/emacs-claude-code`) | the operator's primary TUI observation point. New patterns are observed in Emacs first. |
| **Python (runtime)** | `scitex-agent-container/src/scitex_agent_container/runtimes/prompts.py` | Used by `scitex-agent-container` watchdog / healer code paths at runtime. |
| **Markdown (this skill)** | `scitex-orochi/_skills/scitex-orochi/agent-pane-state-patterns.md` | Human-readable catalog that fleet healers, skill writers, and documentation reference when explaining behavior. |

### Sync protocol

When a new Claude Code pane pattern is discovered:

1. **Elisp first.** Add the regex + matcher in `ecc-state-detection.el` during live Emacs observation. This is the place it is first seen, and `emacs-claude-code` has the shortest feedback loop (interactive eval, live buffer).
2. **Python next.** Port the regex verbatim into `prompts.py`, keeping variable names and matcher semantics aligned. Add a unit test that exercises the new pattern with a captured pane example.
3. **Markdown last.** Update this skill to reflect the new state. The skill update is always **post-hoc** relative to the Elisp + Python changes — never introduce a state here that does not yet exist upstream.
4. Commit the three changes with a single rationale in the commit messages, cross-referencing each other and the source msg id where the pattern was observed.

### Drift policy

- **If Elisp and Python disagree**, Elisp wins. File a Python PR to align.
- **If Python and this skill disagree**, Python wins. Update this skill.
- **If this skill adds a state that neither Elisp nor Python has**, **revert the skill change and file a PR against Elisp first**. Skill-only states are documentation fiction and must not ship.
- **Do not fork the regex string.** If a new state's regex needs to vary slightly per upstream (e.g., Emacs handles newlines differently from bash capture-pane), encode the variation in the matcher logic of each language, not by shipping two different regexes.

This mirror discipline is memory rule `project_tui_pattern_single_source`: **the Elisp repo is the canonical observation point, Python is the runtime consumer, Markdown is the documentation mirror**. Agents asking "can I add a new state directly here" should be told **no** — start in Emacs.

See also: head-<host> PR #118 (`pane_state.py` reference implementation — may be a fourth alias once landed; same rules apply).

## Consumers in the fleet

- `scitex-orochi/scripts/pane_state.py` (PR #118) — Python implementation reading the catalog.
- `scripts/fleet-watch/fleet-prompt-actuator` (head-<host>, running on NAS cron) — auto-unblock healer loop.
- `worker-healer-*` `/loop` prompts — future adoption layer, codifies per-host action tables.
- `pane_state` field in hub `/api/agents/` — planned surface for the Agents tab (PR series TBD).

## What this skill does NOT cover

- It does **not** decide *when* to run the classifier (that's the healer / watchdog).
- It does **not** ship an implementation; it is the spec that implementations mirror.
- It does **not** cover Claude Code *session* state (context %, token count). That's `context_percent` in `status --json`, not pane scraping.

## Related

- `agent-account-switch.md` — the action taken on `:quota_exhausted` / `:quota_warning`
- `agent-health-check.md` — the 8-step health checklist that calls this classifier
- `convention-connectivity-probe.md` — how to distinguish remote pane state safely
- `fleet-communication-discipline.md` rule #6 — silent success
- memory `project_permission_prompt_blockers.md` — why `--dangerously-skip-permissions` is insufficient
- Upstream: `~/.emacs.d/lisp/emacs-claude-code` (single source of truth for Claude pane regex)
- head-<host> PR #118 — Python reference implementation

## Change log

- **2026-04-14 (initial)**: Drafted from 2026-04-13 fleet pattern observations (msgs #8670 / #9438 / #9442 / #9537 / #9670 / #9674 / #10210 / #10216). States, regexes, priority order, and action table consolidated from head-<host> PR #118 + emacs-claude-code upstream. Author: worker-skill-manager.
