---
name: orochi-permission-prompt-patterns
description: Canonical pattern catalog for Claude Code permission prompts and other interactive "agent is stuck waiting for a keystroke" states. Loaded at boot by mamba-healer-<host> workers so the fleet-health-daemon Phase 4 recovery playbook §7.1 has concrete regex → action mappings. Grows by observation per operator msg#11779 ("パターンを蓄積することが大事"). Not executed by humans — fed to automation.
---

# Permission-Prompt Patterns

When a Claude Code pane is blocked on a permission / confirmation /
selection prompt, the worker-layer healer needs a concrete answer
to two questions, fast:

1. **Is this actually a permission prompt, or just something that
   looks like one** (e.g. a legitimate multi-choice prompt the
   agent is composing, or a selection menu mid-interactive
   command)?
2. **If yes, which keystroke unblocks it without lying about
   consent** (i.e. which option is the "go ahead, but respect
   existing allowlists" choice)?

This skill is the catalog of known prompts, their exact regexes,
and the recovery keystroke for each. Workers read it at boot and
attach it to `fleet-health-daemon-design.md` §7.1 (permission-
prompt recovery) as the lookup table. **The catalog is not
exhaustive.** It grows every time the fleet observes a new
prompt pattern. Treat every new observation as a commit
candidate.

## Why a catalog, not a catch-all

operator msg#11779 is explicit: "パターンを蓄積することが大事" —
pattern accumulation is the important discipline, not a greedy
"auto-send Enter on anything that looks stuck" heuristic. A
greedy heuristic race-corrupts agents mid-composition (see
`fleet-health-daemon-design.md` §7.6, head-<host> fleet sweep
2026-04-15 caught paste-buffer-unsent cases where a blanket-Enter
would have submitted garbage). A curated catalog with explicit
regex + action + rationale is the inverse: slow to add a new
pattern but always safe per pattern.

## Entry schema

Every entry in this catalog has the same 7 fields:

```
- id:               short stable slug
  regex:            Python regex that matches the prompt text within a tmux capture
  observed-as:      human-readable description of what a human would see on screen
  first-seen:       date + message ID where the pattern was first observed
  recovery-keystroke: the tmux send-keys sequence, as a string
  rationale:        why this keystroke is the right answer (which option it selects)
  escalation:       when to stop retrying and post to #escalation
```

## Catalog

### 1. Claude Code 3-option permission menu

```yaml
- id: claude-3-option-menu
  regex: |
    Do you want to.*\n.*❯?\s*1\.\s*Yes(,|\s).*\n.*❯?\s*2\.\s*Yes,.*always allow.*\n.*❯?\s*3\.\s*No
  observed-as: |
    Do you want to proceed?
    ❯ 1. Yes
      2. Yes, and always allow ...
      3. No
  first-seen: 2026-04-15 msg#11799 (head-<host> fleet sweep)
  recovery-keystroke: "2"
  rationale: |
    Option 2 is "always allow" — it accepts the action AND adds it
    to the agent's allowlist so the same prompt does not repeat
    next tick. This is the right answer for automation because
    it permanently unblocks the class of prompt without a case-
    by-case human call. Option 1 accepts this one instance but
    leaves the door open for the next matching prompt. Option 3
    is a rejection, which blocks forward motion and is almost
    never the healer's intent.
  escalation: |
    If the same session hits this pattern 3 times within 5 min
    after a "2" send, something is wrong with the allowlist
    persistence — escalate to #agent for human call.
```

### 2. Claude Code "Esc to cancel · Tab to amend" modal

```yaml
- id: claude-esc-cancel-tab-amend
  regex: |
    Esc to cancel\s*·\s*Tab to amend
  observed-as: |
    The agent is hovering on a Claude Code permission modal that
    shows the "Esc to cancel · Tab to amend" footer. The actual
    action buttons vary above this footer.
  first-seen: 2026-04-15 msg#11855 (head-<host> compound-failure incident)
  recovery-keystroke: "2"
  rationale: |
    Same as entry #1 — on current Claude Code, the 3-option menu
    footer almost always shows "Esc to cancel · Tab to amend".
    When only the footer matches but the menu body is off-screen
    in the tmux capture window, assume the 3-option pattern and
    send "2". If that's wrong, the agent will surface a new
    prompt and the next tick will classify correctly.

    **Gate**: never fire this recovery until the full capture
    (at least -S -15 lines) has been inspected for menu body.
    If the menu body shows a non-3-option variant (e.g.
    [y/N], pagination, sudo), fall through to entry #3+ or
    escalate.
  escalation: |
    If "2" Enter does not clear the modal within 5 s, the
    capture was misclassified — escalate.
```

### 3. Claude Code [y/N] single-line prompt

```yaml
- id: claude-y-n
  regex: |
    \[y/N\]\s*$|\s\[Y/n\]\s*$
  observed-as: |
    Inline y/N confirmation on a single line, typically after a
    description like "Overwrite ~/foo? [y/N]".
  first-seen: 2026-04-15 (general observation, no single incident)
  recovery-keystroke: "y\n"
  rationale: |
    **Only fire this recovery when the description text above
    the prompt matches an allowlist of known-safe actions**
    (e.g. "Overwrite", "Create directory", "Continue"). For
    destructive actions ("Delete", "Force push", "Drop
    database"), the healer must NOT auto-confirm — escalate
    instead. The allowlist lives in
    `safe-y-n-prefixes.md` as a separate skill (TBD, growing
    alongside this catalog).
  escalation: |
    Any y/N prompt where the description does not match the
    allowlist → immediate escalation, never auto-confirm.
```

### 4. Paste-buffer-unsent pseudo-prompt

```yaml
- id: paste-buffer-unsent
  regex: |
    \[Pasted text #\d+\s\+?\d+\s*lines\]
  observed-as: |
    The prompt area shows a "[Pasted text #N +M lines]" marker
    indicating the agent pasted content into the prompt but
    never submitted it. Observed 2026-04-15 across multiple
    agents during the fleet sweep (5 agents) and a secondary host sweep
    (worker-healer-<host>, ~2.5 h wedge).
  first-seen: 2026-04-15 msg#11799 (head-<host> fleet sweep, 5 panes)
  recovery-keystroke: "\n"   # (Enter)
  rationale: |
    The paste is in the agent's own input buffer waiting to be
    submitted. Sending Enter submits it as-is. Safe because the
    paste was composed by the agent itself (or by a user-
    controlled tool earlier in the session), not by the healer —
    the healer is only providing the "submit" keystroke that was
    missing. Never modify the paste, only submit it.

    **Critical constraint** (todo-manager msg#11809): fire ONLY
    when the pane has been *static* (no new output) for > 30 s
    AND the `[Pasted text ...]` marker is at prompt level (end
    of the tmux capture). If the agent is mid-composition, do
    not fire.
  escalation: |
    If the same session hits this pattern 3 times within 10 min,
    the agent is not consuming its own pasted input (deeper
    issue) — escalate to #agent with the pane capture.
```

### 5. Claude Code "Press Enter to continue" pagination

```yaml
- id: claude-press-enter-to-continue
  regex: |
    Press Enter to continue|--More--
  observed-as: |
    Pager / long-output gating (typical for `man`, `less`, or
    Claude Code's own long-output mode).
  first-seen: 2026-04-15 (general observation)
  recovery-keystroke: "\n"   # (Enter, or "q" for some pagers)
  rationale: |
    This is a display-level gate, not a permission prompt. The
    keystroke is purely "advance the pager" and has no semantic
    side effect. Safe to fire unconditionally.
  escalation: |
    If sending Enter does not clear the pager within 5 s, the
    pane is wedged on something else; fall through to entry #6.
```

### 6. Claude Code long-silence (no obvious pattern)

```yaml
- id: claude-long-silence-unknown
  regex: ~   # no match — this is a fallback state, not a pattern
  observed-as: |
    The pane has been static for > 2 min, no new output, no
    known-pattern match, but the agent is not responding to
    DM pings either.
  first-seen: always
  recovery-keystroke: null   # no automated recovery
  rationale: |
    When nothing in this catalog matches and the pane is just
    silent, the healer must NOT fire a blind keystroke. The
    fallback is to escalate to the recovery playbook's §7.4
    (tmux-stuck recovery, kill-respawn) OR to §7.3 (/compact)
    based on context_pct, not to guess-and-send.
  escalation: |
    Always escalate. This entry exists in the catalog only to
    make "unknown silence" an explicit classification rather
    than a gap in the matcher. The worker reads this entry as
    "there is no recovery keystroke, hand off to §7.3 or §7.4".
```

## How patterns get added

When a new observed prompt is NOT in the catalog, the discovery
workflow is:

1. **Capture the pane** with enough scrollback to show the full
   prompt (at least `tmux capture-pane -p -S -20`).
2. **Determine the safe keystroke** by human judgment (look at
   the options, pick the one that advances without granting
   more than needed).
3. **Draft the entry** as a 7-field YAML block matching the
   schema above. Include the exact message ID where the pattern
   was first observed (so the audit trail is preserved).
4. **Open a PR** against this file. The PR reviewer's job is to
   confirm the regex actually matches the observed capture and
   does not false-positive on other prompts. Add a test capture
   as a code block in the PR body for the reviewer to eyeball.
5. **Do NOT** rush — a wrong regex or wrong keystroke here
   becomes automation that lies to every healer in the fleet.
   Prefer caution and escalation over premature automation.

The catalog is a **living document**. Every new prompt variant
Claude Code ships (new wording, new option ordering, new modal
style) becomes a new entry here. operator msg#11779 frames this
as "pattern accumulation matters more than the automation rush"
— stay slow and safe on additions, fast on escalation when
nothing matches.

## Loading order for workers

At worker (mamba-healer-<host>) boot, load entries in order and
match the first one that fires:

1. `paste-buffer-unsent` (most specific, prompt-level marker)
2. `claude-3-option-menu` (specific menu body)
3. `claude-esc-cancel-tab-amend` (less specific, footer only)
4. `claude-press-enter-to-continue` (pager)
5. `claude-y-n` (only with allowlisted prefix)
6. `claude-long-silence-unknown` (fallback, always escalates)

Precedence matters because the paste-buffer-unsent marker can
coexist with the "Esc to cancel" footer (if the agent pasted
into a prompt that's now showing a modal). In that case, the
paste is the underlying blocker and the modal is downstream of
the paste being submitted — fire the paste recovery first, then
re-classify on the next tick.

## Deliberately NOT in the catalog

These prompts are excluded on purpose; the healer must NEVER
auto-recover them:

- **"Really delete? [y/N]"** — destructive, must escalate.
- **"Force push? [y/N]"** — destructive, must escalate.
- **"Send email? [y/N]"** — outbound-visible side effect, must
  escalate.
- **"Run this remote script? [y/N]"** — supply-chain risk, must
  escalate.
- **Anything containing `sudo`, `rm -rf`, `git reset --hard`,
  `DROP TABLE`, `kubectl delete`** — escalate, even if the rest
  of the prompt looks like a known-safe pattern.

If a new observed prompt looks even vaguely destructive, the
PR to add it to this catalog is automatically rejected — the
right place for that class of prompt is a human-call escalation,
not a regex.

## Related skills

- `fleet-health-daemon-design.md` — §7.1 (permission prompt
  recovery) and §7.6 (paste-buffer-unsent recovery) cite this
  catalog as the source of truth for regex + keystroke.
- `agent-pane-state-patterns.md` — the broader tmux pane state regex
  catalog (idle / working / permission_prompt / stuck). This
  catalog is the permission_prompt sub-classifier.
- `fleet-communication-discipline.md` — rule #6 silent-success
  governs when the worker posts after a successful recovery.
- `fleet-close-evidence-gate.md` — if a recovery closes an issue
  (e.g. "stuck agent unblocked → close reproducer issue"), the
  worker uses the gh-issue-close-safe wrapper, not bare
  `gh issue close`.

## Incident log

Every incident that motivated a new entry or exposed a gap in
this catalog is recorded here for audit. Short, dated, with a
message ID pointer.

- **2026-04-15 msg#11799** — fleet sweep caught 5 paste-buffer-
  unsent agents. Catalog gains entry #4, paste-buffer-unsent.
- **2026-04-15 msg#11855** — head-<host> 2.5 h compound-failure
  (stale agent_meta.py + Claude Code Esc/Tab modal). Catalog
  gains entry #2, claude-esc-cancel-tab-amend. Motivates the
  fleet-health-daemon §10A probe-liveness vs agent-responsiveness
  divergence section.
- **2026-04-15 msg#11907** — worker-healer-<host> ghost-alive case
  (probe NDJSON fresh but Claude session wedged). No new catalog
  entry but confirmed the loading order above (paste-buffer
  first, then modal).
- **2026-04-14 earlier** — head-<host> concurrent-instance incident
  (scitex-orochi#144). Not a permission prompt, but informs the
  "never auto-kill duplicate Claude sessions" anti-pattern in
  the fleet-health-daemon design.
