---
name: agent-container-troubleshooting
description: Common launch failures and their fixes for scitex-agent-container agents.
---

# Agent Launch Troubleshooting

## Session dies during auto-accept

The multiplexer session dies before prompts are accepted.

### Cause 1: `--continue` with no valid session

Claude Code's `--continue` flag fails if there's no resumable session.

**Fix:** Set `session: new` in the YAML.

### Cause 2: Startup commands sent into TUI prompt

If auto-accept times out (e.g., `hardcopy` fails on macOS with screen), startup commands get typed into the TUI prompt, selecting wrong options.

**Fix:** Use `multiplexer: tmux` (default) instead of screen. tmux's `capture-pane` works reliably on macOS.

### Cause 3: Wrong python / missing packages

**Fix:** Set `spec.venv` to activate the correct virtualenv:

```yaml
spec:
  venv: ~/.venv
```

## Auto-accept logs

Check `~/.scitex/agent-container/logs/{name}/auto-accept.log`:

```bash
cat ~/.scitex/agent-container/logs/my-agent/auto-accept.log
```

Shows every poll cycle: pane content, matched handlers, timeouts.

## Debugging a failed launch

### With tmux (recommended)

```bash
# Kill stale session
tmux kill-session -t <name> 2>/dev/null

# Launch manually
cd <workdir>
tmux new-session -d -s <name>-debug "bash -l -c 'claude --model opus[1m] --dangerously-skip-permissions; sleep 30'"

# Check content
sleep 5
tmux capture-pane -t <name>-debug -p

# Send keystrokes manually
tmux send-keys -t <name>-debug 2 Enter    # Select option 2
```

### With screen (legacy)

```bash
screen -dmS <name>-debug bash -l -c 'claude --model opus[1m] --dangerously-skip-permissions; exec bash'
sleep 10
screen -S <name>-debug -X hardcopy /tmp/<name>-debug.txt
cat /tmp/<name>-debug.txt
```

## TUI prompt handling

Claude Code shows confirmation prompts for dangerous flags. The auto-accept system (`runtimes/prompts.py`) handles them:

| Prompt | Option | Keys |
|--------|--------|------|
| Bypass Permissions | "2. Yes, I accept" | `2`, `Enter` |
| Dev channels | "1. I am using this for local development" | `1`, `Enter` |
| Thinking effort | "1. Medium (recommended)" | `1`, `Enter` |

Prompts may appear in any order. New prompts can be added to `PROMPT_HANDLERS` in `prompts.py`.

**Manual keystroke sending (tmux):**
```bash
tmux send-keys -t <name> 2 Enter     # Select option 2
tmux send-keys -t <name> 1 Enter     # Select option 1
```

## macOS screen issues

`screen -X hardcopy` returns empty on macOS. Additionally, SSH-started screens use `/var/folders/...` while local terminals use `~/.screen`.

**Fix:** Use `multiplexer: tmux` (default since v0.7).

## Workspace CLAUDE.md marker abort (`WorkspaceCLAUDEMarkerError`)

`scitex-agent-container start` refuses to deploy when the existing
`~/.scitex/orochi/workspaces/<agent>/CLAUDE.md` is non-empty but does not
contain the canonical marker pair:

```
<!-- Start of scitex-agent-container generated section (<ts>) -->
...managed block, overwritten on every deploy...
<!-- End of scitex-agent-container generated section -->
...user tail, preserved across restarts...
```

Hard-fail contract (see `runtimes/src_files.py::_validate_marker_invariants`,
per ywatanabe spec msg 5250–5260):

- exactly **one** Start marker
- exactly **one** End marker
- Start before End

Any violation aborts the deploy rather than guessing, because the tail past
the End marker is user-editable content and silent overwrite would destroy
work.

### Symptom

```
WorkspaceCLAUDEMarkerError: /Users/.../workspaces/<agent>/CLAUDE.md:
expected exactly 1 Start marker and 1 End marker, found Start=0 End=0.
Refusing to deploy to avoid data loss.
```

Agents that hit this stay down (session fails to start, no tmux pane).

### Root cause (observed 2026-04-15, head-mba restart batch)

Legacy workspace CLAUDE.md files from older agent-container versions were
~7-line placeholders with zero custom content and no markers at all. The
validator does not distinguish placeholder from contaminated, so any
markerless non-empty file blocks the deploy.

### Recovery procedure

1. **Inspect first.** Check whether there is any content worth keeping:
   ```bash
   cat ~/.scitex/orochi/workspaces/<agent>/CLAUDE.md
   ```
   Typical placeholder is 5–10 lines of boilerplate; if so, nothing to save.
2. **Back up custom tail** (if any real content exists):
   ```bash
   cp ~/.scitex/orochi/workspaces/<agent>/CLAUDE.md \
      ~/.scitex/orochi/workspaces/<agent>/CLAUDE.md.bak
   ```
3. **Remove the unmarked file:**
   ```bash
   rm ~/.scitex/orochi/workspaces/<agent>/CLAUDE.md
   ```
4. **Re-run start.** Deploy will now treat the workspace as empty and
   write a fresh managed section with both markers:
   ```bash
   scitex-agent-container start ~/.scitex/orochi/agents/<agent>/<agent>.yaml
   ```
5. **Re-append custom tail** (if you backed up real content) **below** the
   End marker in the newly written file, not above it.

### Never do

- Do not delete workspace CLAUDE.md files in bulk without inspecting — a
  real custom tail looks just like a placeholder in a directory listing.
- Do not hand-patch the start marker onto a placeholder. A start marker
  without the matching canonical end marker is still a hard-fail, and
  hand-rolled timestamps drift from the generated ones.
- Do not edit anything between the markers. That block is regenerated on
  every restart and changes are lost.

### Prevention

Agents that need persistent per-workspace notes should write them strictly
**below** the End marker. The guide comment immediately after the End
marker spells this out — if you see an agent editing above it, flag the
error and move the content down.
