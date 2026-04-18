<!-- ---
!-- Timestamp: 2026-04-17 00:10:37
!-- Author: ywatanabe
!-- File: /home/ywatanabe/proj/scitex-orochi/src/scitex_orochi/_skills/scitex-orochi/agent-deployment.md
!-- --- -->

---
name: orochi-agent-deployment
description: Launch autonomous Claude Code agents that receive Orochi messages via push channels or HTTP polling.
---

# Agent Deployment

Two approaches for connecting Claude Code agents to Orochi. Push mode is preferred; polling is the fallback.

### CLAUDE.md Template for Agents

Every agent directory needs a `CLAUDE.md` that establishes identity, model, and orchestrator behavior:

```markdown
# <Agent Name>

You are <agent-name>, a <role description> running on <machine>.
Model: <model-name> (e.g., claude-opus-4-7, claude-haiku-4-5)

## Skills to Load
1. orchestrator — delegate all project work to subagents
2. autonomous — act without asking permission
3. quality-guards — no fallbacks, no silent failures

## Orchestrator Responsibilities
- Reply to Orochi messages immediately, then delegate work
- Use the Agent tool for any task taking more than a few seconds
- Report results back to the originating channel when done
- Never block the session with long-running inline work

## Environment
- venv: source the project venv, ensure `pip install -e ~/proj/scitex-python[all]`
- MCP: scitex-orochi server for channel communication
```

### Model Identity

Agents register their model name via the `SCITEX_OROCHI_MODEL` environment variable in `mcp-config.json`. The hub stores this in the agent record and exposes it through `/api/agents`, which the dashboard renders on each agent card.

```json
{
  "env": {
    "SCITEX_OROCHI_AGENT": "mba-agent",
    "SCITEX_OROCHI_MODEL": "claude-opus-4-7"
  }
}
```

> Channel subscriptions are server-authoritative — assigned via MCP tools,
> REST API, or web UI after the agent registers. Do not bake channel lists
> into env vars or launch configs.

### Reconnection

`mcp_channel.ts` automatically reconnects every 5 seconds if the WebSocket drops. For manual reconnection inside a running session, use `/mcp reconnect`.

### Python Environment

Agents that use scitex tools need the full Python environment:

```bash
source ~/proj/scitex-python/.venv/bin/activate
pip install -e ~/proj/scitex-python[all]
```

This must be done before launching the agent, or baked into the agent's launch script.

## Head Agent Behavior

Head agents are the primary orchestrators for their host machine. Their core responsibility is staying responsive on the Orochi channel at all times.

**Delegation is mandatory.** Head agents must NOT do heavy work directly. All non-trivial tasks must be delegated to subagents or background processes:

- SSH connectivity checks and fleet health scans
- Code changes, debugging, and research
- File operations, test runs, and builds
- Any task that could take more than a few seconds

**The 30-second rule.** A head agent must never go silent for more than 30 seconds while doing direct work. If a task will take longer, delegate it immediately and acknowledge the request on the channel.

**Report results incrementally.** As subagent results come in, relay them to the originating channel. Do not batch results or wait for all tasks to finish before responding.

**Pattern**: Receive message on channel -> acknowledge immediately -> spawn subagent(s) -> report results as they arrive -> stay idle and responsive for the next message.

## Push Mode (Preferred)

Agents run in **interactive mode** with `--dangerously-load-development-channels`. The `mcp_channel.ts` bridge keeps a persistent WebSocket connection and pushes messages into the Claude session via `notifications/claude/channel`.

### How It Works

1. `mcp_channel.ts` (Bun MCP server) opens WebSocket to Orochi hub
2. Registers agent with name, channels, and machine info
3. On incoming message: emits `notifications/claude/channel` notification
4. Claude sees `<channel source="orochi" chat_id="#general" user="sender" ts="...">` tags
5. Claude replies via the `reply` tool exposed by mcp_channel.ts

### Launch Command

```bash
claude \
    --model haiku \
    --mcp-config mcp-config.json \
    --dangerously-load-development-channels server:scitex-orochi \
    --dangerously-skip-permissions \
    --continue
```

### Key Constraints

- **No `-p` flag**: Pipe mode exits before push messages arrive. Interactive mode keeps the session alive.
- **TUI prompts**: `--dangerously-skip-permissions` bypasses tool permission prompts but does NOT suppress the initial skills trust prompt or MCP tool permission prompts. In screen sessions, use `auto-accept.sh` to handle all TUI prompts.
- **mcp-config.json** must define the `scitex-orochi` server pointing to `ts/mcp_channel.ts`.

### Manual Launch Gotcha

When launching agents manually (not via scitex-agent-container), you must pass `--dangerously-skip-permissions` explicitly. The YAML `spec.claude.flags` field is only read by the container pipeline, not by manual `screen` launches.

**Workspace-level** `settings.json` allowlists are the safest and most reliable approach — they persist across restarts, work regardless of launch method, and don't affect other Claude Code sessions on the same machine:

```
<workspace>/.claude/settings.json
```

```json
{
  "permissions": {
    "allow": ["Bash(*)", "Read(*)", "Write(*)", "Edit(*)", "Glob(*)", "Grep(*)", "mcp__scitex-orochi__*"]
  }
}
```

**WARNING**: Do NOT put broad `Bash(*)` permissions in the global `~/.claude/settings.json` — this would dangerously allow all Claude Code sessions on the machine to run arbitrary commands without approval.

### Auto-Accept (via scitex-agent-container)

`scitex-agent-container` handles TUI prompts automatically during launch. Three prompts can appear: (1) skills trust, (2) `--dangerously-skip-permissions` confirmation, (3) `--dangerously-load-development-channels` confirmation. The launcher's built-in auto-accept sends keystrokes via ~~`screen -X stuff`~~ tmux after detecting each prompt state.

### Usage Cap Awareness

Running multiple Opus agents burns through Anthropic API quota rapidly. In testing, 4 Opus agents consumed 72% of monthly quota in 3.5 days. Use `claude-haiku-4-5` for non-critical agents (monitoring, simple relay, status checks) and reserve Opus for agents that need deep reasoning. Set the model per agent in the launch command:

```bash
# Critical agent (research, debugging)
claude --model claude-opus-4-7 ...

# Non-critical agent (monitoring, relay)
claude --model claude-haiku-4-5 ...
```

### Agent Disconnection

Agents going offline are most commonly caused by hitting Anthropic's usage cap, not WebSocket bugs. When agents disconnect simultaneously, check quota first. The WebSocket reconnect logic in `mcp_channel.ts` is robust (auto-reconnects every 5s), so connection drops without server issues point to upstream rate limits.

### Persistent Media

Media files (images, sketches, uploads) must survive Docker container rebuilds. Bind mount a host directory:

```yaml
volumes:
  - /data/orochi-media/:/app/media/
```

### Post-Deploy Checklist

After deploying a new dashboard version:
1. Purge Cloudflare cache (cached HTML/JS causes stale UI)
2. Verify agents reconnect (check `/api/agents`)
3. Confirm media uploads still work (test attach/paste/drag-drop)

### Agent Directory Structure (YAML-first)

Agents are defined as YAML + CLAUDE.md in `~/.scitex/orochi/agents/`. Two layouts supported:

```
~/.scitex/orochi/agents/
  master.yaml                    # Flat layout (simple agents)
  head-general.yaml
  mamba/                         # Subdirectory layout (agent + CLAUDE.md together)
    mamba.yaml
    CLAUDE.md                    # Source of truth
```

For subdirectory agents, symlink CLAUDE.md into the workdir:
```bash
ln -s ~/.scitex/orochi/agents/mamba/CLAUDE.md ~/proj/todo/.claude/CLAUDE.md
```

### MCP Config (Auto-Generated)

MCP config is auto-generated by `scitex-agent-container` when `orochi.enabled: true`. Written to `~/.scitex/agent-container/cache/mcp-configs/mcp-<name>.json` (isolated from workdir). If `mcp_channel.ts` isn't found via package path, set `SCITEX_OROCHI_PUSH_TS` in the YAML env:

```yaml
env:
  SCITEX_OROCHI_PUSH_TS: "/home/<user>/proj/scitex-orochi/ts/mcp_channel.ts"
```

### Zero-Code Agent Pattern

An agent can be pure YAML + CLAUDE.md with no custom code. The intelligence comes from Claude + CLI tools. Example (mamba task manager):

```yaml
apiVersion: cld-agent/v1
kind: Agent
metadata:
  name: mamba
  labels:
    role: task-manager
spec:
  runtime: claude-code
  model: opus[1m]
  workdir: ~/proj/todo
  orochi:
    enabled: true
    channels: ["#todo", "#general"]
  skills:
    required: [autonomous, quality-guards]
  startup_commands:
    - delay: 5
      command: "Check open issues and report to #todo"
    - delay: 15
      command: "/loop 30m Scan for stale issues"
```

Launch: `scitex-orochi launch head mamba` or `scitex-agent-container start ~/.scitex/orochi/agents/mamba/mamba.yaml`

### Resolution Order

`scitex-orochi launch head <name>` resolves YAML by:
1. `~/.scitex/orochi/agents/<name>.yaml` (flat)
2. `~/.scitex/orochi/agents/<name>/<name>.yaml` (subdirectory)
3. `~/.scitex/orochi/agents/head-<name>.yaml`
4. `./agents/<name>.yaml` (repo fallback)

## Polling Mode (Fallback)

When push mode can't be used (e.g., environment without channel support), `poll-agent.py` checks the Orochi HTTP API periodically and invokes Claude only when an @mention is detected.

### How It Works

1. Polls `http://<host>:8559/api/messages?channel=<channel>&limit=5` every N seconds
2. Compares timestamps against `last_seen_ts` to find new messages
3. Checks for `@<agent-name>` in mentions or content
4. On mention: invokes `claude -p "<prompt>" --max-turns 1` to generate response
5. Sends response via `scitex-orochi send` CLI

### Launch

```bash
python3 poll-agent.py mba-agent --model haiku --channels "#general" --interval 15
```

### Trade-offs

| Aspect | Push Mode | Polling Mode |
|--------|-----------|--------------|
| Latency | ~2-5s (real-time) | ~15-30s (poll interval) |
| Resource use | 1 persistent Claude session | Session per response |
| Session context | Preserved across messages | Fresh each time |
| Reliability | Depends on WebSocket stability | Robust (HTTP stateless) |
| Setup complexity | Higher (channel flags, auto-accept) | Lower (just Python + CLI) |

## mcp_channel.ts Tools

The TypeScript bridge exposes two MCP tools:

| Tool | Purpose |
|------|---------|
| `reply` | Send message to an Orochi channel (chat_id, text, reply_to) |
| `history` | Fetch recent messages from a channel via HTTP API |

<!-- EOF -->