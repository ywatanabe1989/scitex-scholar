# Delegation

## Principle
Never block on direct work in project repos. Delegate to agents, monitor, report.

## Core Delegation Rules

1. **Delegate ALL work to subagents.** Never do project work directly.
2. **Time threshold: >7 seconds = must delegate.** If a task will take more than ~7s, fire a subagent immediately.
3. **Investigation is free — delegate instantly.** The cost of spawning an investigator subagent is zero. Fire immediately on ambiguity.
4. **Default go signal.** Do not ask permission to delegate. Just execute.
5. **Report with numbered task list.** When reporting status, list tasks as #1, #2, #3 etc.
6. **Use org-mode status file for tracking.** Write/update `GITIGNORED/tasks/status.org` in the project root.
7. **`CLAUDE_ORCHESTRATOR=1` enables delegation hooks.** When this env var is set, the delegation hook activates and subagents inherit the orchestrator context.

## Issue-Based Task Tracking for Cross-Machine Delegation

Agents run on different hosts (WSL laptop, NAS, Spartan HPC, MBA). Sessions get compacted and restarted, losing in-context state. Local files like `todo.md` or `status.org` do not sync across machines. GitHub Issues at `ywatanabe1989/todo` are the **only reliable persistence layer** that survives compaction and works across all hosts.

### The Rule: Issue Before Delegation

For any task that spans machines or may survive a compaction, create a GitHub Issue **before** delegating. The issue number becomes the task's identity.

```bash
# 1. Create the issue FIRST
gh issue create --repo ywatanabe1989/todo \
  --title "Run PAC analysis on Spartan GPU" \
  --body "Run gPAC frequency sweep 2-200Hz on neurovista dataset. Report significant pairs." \
  --label "high-priority,research,spartan"

# 2. Delegate with the issue number
cld_screen_send spartan-agent "Work on ywatanabe1989/todo#85: Run PAC analysis on Spartan GPU"

# 3. Agent comments results on the issue when done
# 4. Orchestrator closes the issue after verification
```

### Why This Matters

Without an issue, a remote agent that compacts mid-task has no way to recover context. With an issue, the agent's post-compact recovery flow picks it up automatically. The orchestrator can also check issue comments instead of relying on screen output that may have scrolled away.

### Agent Responsibilities

When an agent receives a task with an issue number:
1. Read the issue for full context: `gh issue view NUMBER --repo ywatanabe1989/todo`
2. Add `in-progress` label: `gh issue edit NUMBER --repo ywatanabe1989/todo --add-label "in-progress"`
3. Comment progress updates on the issue (not just local stdout)
4. When done, comment results and remove `in-progress` label
5. The orchestrator (not the agent) closes the issue after verification

### When to Create Issues

Create an issue for any task that meets ANY of these criteria:
- Delegated to a remote machine (Spartan, NAS, MBA)
- Expected to take longer than one compaction cycle (~30 min of active work)
- Needs to be tracked across sessions (user is away, will check later)
- Involves multiple agents or coordination

Quick local tasks (grep, read, single-file edit) do not need issues.

### Anti-Pattern: Local Files as Primary Tracker

Local `todo.md`, `tasks.md`, or `status.org` files are supplementary display aids only. They are NOT the source of truth. If a local file says "task X is in progress" but there is no corresponding GitHub Issue, the task is effectively untracked and will be lost on compaction.

## Launch Agent via Emacs vterm

```elisp
(let ((buf (vterm (generate-new-buffer-name "agent-PROJECT"))))
  (with-current-buffer buf
    (vterm-send-string "cd ~/proj/PROJECT && cld")
    (vterm-send-return))
  (buffer-name buf))
```

## Launch Agent via screen

```bash
cld_screen PROJECT        # Start worker in screen
cld_screen_send PROJECT "task description"
cld_screen_ls             # List running agents
cld_screen_attach PROJECT # Attach to agent
```

## Send Task to Running Agent

### vterm
```elisp
(with-current-buffer "agent-PROJECT"
  (vterm-send-string "task description")
  (vterm-send-return))
```

### screen
```bash
cld_screen_send PROJECT "task description"
```

## Monitor Agent Output

```elisp
(with-current-buffer "agent-PROJECT"
  (let* ((content (buffer-substring-no-properties (point-min) (point-max)))
         (lines (seq-filter
                  (lambda (l) (not (string-empty-p (string-trim l))))
                  (split-string content "\n")))
         (last-lines (last lines 15)))
    (mapconcat #'identity last-lines "\n")))
```

## List All Active Agents

```elisp
(mapcar #'buffer-name
  (seq-filter (lambda (b)
    (with-current-buffer b (derived-mode-p 'vterm-mode)))
    (buffer-list)))
```

## Agent Model Selection

Agent definition files use one name per type (no model suffix variants like `-SONNET`, `-OPUS`, `-HAIKU`). The orchestrator chooses the model at call time based on task complexity:

- Simple/mechanical tasks (git commit, report formatting): `haiku`
- Standard development work: `sonnet` (default)
- Hard reasoning, architecture, debugging: `opus`

Do not maintain separate `-SONNET`, `-OPUS`, `-HAIKU` agent files. One definition per agent type. Project-specific agents go in `<project>/docs/to_claude/agents/`, not in dotfiles global agents.

## When to Delegate vs Do Directly

| Task | Action |
|------|--------|
| Code changes in a project | Delegate |
| Quick info lookup (grep, read) | Direct |
| Plot/figure generation | Direct (SciTeX MCP) |
| Audio feedback | Direct (scitex audio_speak) |
| Git operations in projects | Delegate |
| Test runs | Delegate |
| Status checks | Direct (read agent output) |
| Telegram replies | Direct |
| File creation at master level | Direct |
| Investigation / debugging | Delegate (cost is zero) |

## Use vterm When
- Emacs is running
- Need real-time output monitoring
- Want to manage from master agent context

## Use screen When
- Need persistent sessions across Emacs restarts
- Running headless or without Emacs
- Need process isolation

## Voice Message Handling
When Telegram voice/video messages arrive (attachment_kind: voice/video_note):
```bash
# 1. Download
mcp__plugin_telegram_telegram__download_attachment file_id=XXX

# 2. Convert to 16kHz WAV
ffmpeg -y -i INPUT -ar 16000 -ac 1 -f wav /tmp/msgN.wav

# 3. Transcribe (tiny model for speed)
~/.emacs.d/.cache/whisper.cpp/build/bin/whisper-cli \
  -m ~/.emacs.d/.cache/whisper.cpp/models/ggml-tiny.bin \
  -l ja -f /tmp/msgN.wav
```
- **tiny**: fast (~3s for 3s audio), minor accuracy trade-off (recommended default)
- **small**: better accuracy, slower
- **medium**: good accuracy, ~73s for 3s clip on CPU
- **large-v3-turbo**: best accuracy, slowest on CPU

## User Input Notes
User may use browser speech-to-text for Telegram messages.
Expect occasional typos from voice recognition (e.g., "貯" for "ちょ", "止" for "と").
Interpret charitably based on context.

## Self-Growth Capabilities

The orchestrator is self-improving. Key capabilities:

### What You Can Control
- **Context management**: Self-compact via Emacs MCP when context grows large
- **Auto mode**: Toggle auto-accept mode via vterm commands
- **MCP reconnect**: Reconnect MCP servers when disconnected
- **Skills/memory**: Update own skills and memory files to improve future sessions
- **Hooks**: Can modify hooks to change own behavior patterns

### Self-Improvement Loop
1. Experience a problem or receive correction
2. Save the learning to memory (feedback type) or skills
3. Next session loads improved rules automatically
4. Continuously better judgment over time

### Proactive Notifications
- Notify user via Telegram before context compaction
- Report task completion/failure immediately
- Warn about approaching limits or issues

## TODO Centralization Rule

When you encounter a TODO, task, or action item in ANY project:
1. Immediately create a GitHub Issue on `ywatanabe1989/todo`
2. Use standardized labels: priority (`high`/`medium`/`low`/`future`), project (`scitex-cloud`/`scitex-python`/etc), category (`bug`/`feature`/`improvement`/`research`/`devops`/`mobile`/`agent`)
3. NEVER store TODOs in local files — GitHub Issues is the single source of truth
4. When completing a task, close the Issue with a comment explaining what was done
5. Before compact, check if any in-flight work needs an Issue created

## Task Management via GitHub Issues (SINGLE SOURCE OF TRUTH)

**ALL TODOs are managed via GitHub Issues on `ywatanabe1989/todo`.** No local TODO files.
- `~/proj/todo/` is **deprecated** for task tracking. Do NOT create new task files there.
- `~/proj/todo/scitex/status.org` is kept ONLY for Emacs dashboard display — not for task management.
- Always check GitHub Issues first for current work.

### Priority Labels
- `high-priority` — must do now
- `medium-priority` — do this session if time permits
- `future` — backlog, not urgent
- `in-progress` — currently being worked on

### Create Issue
```bash
gh issue create --repo ywatanabe1989/todo \
  --title "Title" --body "Description" \
  --label "high-priority"
```

### Check Open Issues (do this after every compact)
```bash
gh issue list --repo ywatanabe1989/todo --state open --limit 20
```

### Close Completed Issue
```bash
gh issue close NUMBER --repo ywatanabe1989/todo --comment "Done in commit XXX"
```

### Additional Labels (optional)
- `scitex` / `general` / `paper` / `infra` — project category
- `bug` / `feature` / `task` — type
- `blocked` / `needs-review` — status

### Post-Compact Recovery Flow
1. After compact, first check open Issues: `gh issue list --repo ywatanabe1989/todo`
2. Pick highest priority open Issue
3. Continue working autonomously
4. Close Issues as they're completed

### Pre-Compact Handoff
When compact notification fires (count 27/30):
1. Save any in-flight context to Issues (create new or comment on existing)
2. Ensure all important state is in memory/skills/Issues
3. Compact will happen in ~3 tool calls

### Design Philosophy: Follow Anthropic (守破離)
When unsure about UX/design/layout decisions, follow Anthropic's patterns:
- Page layout (desktop/mobile): reference claude.ai
- Branding: subtle — snake icon only in chat/AI context
- Mobile responsiveness: match Anthropic-level polish
- Master by imitation first (守), then break away (破), then transcend (離)

## Communication Channels

### Telegram — Exclusive Channel Architecture
- Telegram agent (`cldt`) is the **sole communicator** with the user via Telegram.
- Only ONE process may poll Telegram Bot API — a second causes 409 conflict and disconnects the first.
- `--channels plugin:telegram@claude-plugins-official` is **explicit opt-in** — other `claude` instances without this flag cannot connect to Telegram. This is safe by design.
- `--dangerously-skip-permissions` is **required** for the Telegram agent — permission prompts block the event loop and make the agent unresponsive to Telegram messages (no way to approve from Telegram).
- Launch script: `cldt` (in `020_claude_telegram.src`) — manages lock file, plugin enable/disable, and screen session.
- Lock file: `~/.claude/channels/telegram/telegram.lock` — PID-based exclusivity with stale detection.
- Guard script: `~/.claude/channels/telegram/guard.sh` — source from other scripts to check/prevent Telegram conflicts.
- When a Telegram message arrives, treat it as a user response — always reset the speak counter.

### Telegram Failure Modes
| Symptom | Cause | Fix |
|---------|-------|-----|
| No response to messages | Permission prompt blocking | Use `--dangerously-skip-permissions` |
| 409 polling conflict | Two processes polling | Kill duplicate, check lock file |
| Listener dies after MCP call | Orochi MCP conflict (#70) | Use screen nudges instead |
| Agent unresponsive | Foreground subagent blocking | Always use `run_in_background: true` |

### Orochi MCP Conflict (GitHub #70)
Orochi MCP calls (`orochi_history`, `orochi_send`, `orochi_who`) break the Telegram incoming channel listener. Both share the same MCP connection and interfere.

**Workaround**: Use screen nudges (`cld_screen_send`) to communicate with agents instead of Orochi MCP tools. Avoid calling `orochi_send`, `orochi_history`, or `orochi_who` from the orchestrator session when Telegram listener is needed.

**Recovery**: If Telegram breaks, send `/reload-plugins` to your own vterm buffer (see `self-identify-vterm` skill).

**Long-term fix**: Telegram bridge in scitex-orochi (#71) — eliminates need for Telegram MCP plugin entirely.

### Webhook Channel (Push to Agents)
For pushing messages directly into running Claude Code sessions without screen:
```python
from channels.webhook.push import push_to_agent
push_to_agent(port=8788, message="Your task", token="secret")
```
Requires `--dangerously-load-development-channels server:webhook` on agent launch.
See `~/proj/master-agent/channels/webhook/README.md`.

### Auto-Restart Agents (#72)
Use `restart-loop.sh` instead of `launch-interactive.sh` for production agents:
```bash
~/proj/orochi-agents/restart-loop.sh mba-agent claude-opus-4-6
# Stop: touch /tmp/orochi-mba-agent-stop
```
Exponential backoff (30s→300s), resets after 5min stable. Logs to `/tmp/orochi-<name>.log`.

## Session Posture

Never give "session complete", "winding down", or summary-of-the-day messages unless the user explicitly ends the session. The orchestrator is always-on. Keep working, keep pushing agents, keep finding the next task. If all current work is done, check GitHub Issues for the next priority item.

## Agent Container (scitex-agent-container)

Declarative YAML-based agent management. Use instead of manual screen/SSH scripts.

### Deploy Remote Agent
```bash
scitex-agent-container start agents/head-mba.yaml       # auto-detect remote from YAML
scitex-agent-container start --no-preflight agents/head-research.yaml  # skip slow preflight
scitex-agent-container list                               # show all agents with remote status
scitex-agent-container stop head-mba                      # stop remote agent
scitex-agent-container check agents/head-mba.yaml         # preflight check
```

### Agent YAML Location
- Orochi: ~/proj/scitex-orochi/agents/
- Available agents: master, head-general, head-research, head-deploy, head-mba, telegrammer

## Orochi Agent Deployment

### restart-loop.sh Pattern

Production agents use `restart-loop.sh` for resilience. Each agent runs on its own host machine (not all from WSL laptop).

```bash
# On the agent's host machine:
~/proj/orochi-agents/restart-loop.sh <agent-name> <model>

# Examples:
# NAS:     ~/proj/orochi-agents/restart-loop.sh nas-agent claude-opus-4-6
# MBA:     ~/proj/orochi-agents/restart-loop.sh mba-agent claude-opus-4-6
# Spartan: ~/proj/orochi-agents/restart-loop.sh spartan-agent claude-opus-4-6
```

Features:
- Screen session with exponential backoff (30s to 300s)
- Auto-accept TUI prompts (skills trust, permissions, channels)
- Resets backoff after 5 minutes of stable operation
- Stop: `touch /tmp/orochi-<agent-name>-stop`
- Logs: `/tmp/orochi-<agent-name>.log`

### Host-Specific OROCHI_HOST

Each agent's `mcp-config.json` must set `OROCHI_HOST` based on its machine:
- NAS agent: `OROCHI_HOST=127.0.0.1` (Orochi runs locally on NAS)
- LAN machines (WSL, MBA): `OROCHI_HOST=192.168.0.102`
- External (Spartan): `OROCHI_HOST=orochi.scitex.ai` (but port 9559 is blocked -- see below)

### Spartan WebSocket Block

Spartan HPC's university firewall blocks outbound port 9559. Push mode does not work from Spartan until `orochi_push.ts` supports WSS proxy via `wss://orochi.scitex.ai`. Use polling mode as fallback.

### Usage Cap Awareness

Claude Max subscription is shared across all hosts. 4 Opus agents consumed 72% of monthly quota in 3.5 days. Mitigate by using Haiku for non-critical agents and reserving Opus for deep reasoning tasks. When multiple agents disconnect simultaneously, check quota first -- it is more likely than a network issue.
