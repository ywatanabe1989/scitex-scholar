---
name: orochi-agent-health-check
description: Step-by-step health checklist for verifying an Orochi agent is fully operational.
---

# Agent Health Check

Verify each agent in order. A failure at any step means later steps will also fail.

## Checklist

### 1. SSH Connection

The host machine is reachable.

```bash
ssh <host> hostname
```

### 2. Screen Session

The agent's screen session exists and is detached (running).

```bash
ssh <host> screen -ls | grep <agent-name>
```

Expected: line containing `<agent-name>` with status `(Detached)`.

### 3. Claude Code Process

The Claude Code CLI is running inside the screen session.

```bash
ssh <host> pgrep -la claude
```

Expected: at least one process matching the agent's session.

### 4. Bun MCP Sidecar

The `mcp_channel.ts` TypeScript bridge is running alongside Claude.

```bash
ssh <host> 'pgrep -la bun | grep mcp_channel'
```

Expected: a bun process with `mcp_channel` in its arguments.

### 5. WS Connected to Hub

The agent appears in the hub's live registry.

```bash
curl -s https://scitex-orochi.com/api/agents/ | python3 -m json.tool | grep <agent-name>
```

Or from the dashboard Agents tab — the agent should show as connected.

### 5b. Functional Heartbeat (LLM + MCP + PaneAction liveness)

A WebSocket registration only proves the sidecar is alive. To confirm the **LLM itself** is still executing tool calls, and that the **container-side PaneAction subsystem** (nonce probe, compact, ...) is still firing, inspect the functional-heartbeat shortcuts on `/api/agents/<name>/detail/`:

```bash
curl -s https://scitex-orochi.com/api/agents/<agent-name>/detail/ \
  | python3 -c "import json,sys; d=json.load(sys.stdin); \
    print('last_tool:    ', d.get('last_tool_at'),     d.get('last_tool_name')); \
    print('last_mcp:     ', d.get('last_mcp_tool_at'), d.get('last_mcp_tool_name')); \
    print('last_action:  ', d.get('last_action_at'),   d.get('last_action_name'), \
                            d.get('last_action_outcome'), d.get('last_action_elapsed_s')); \
    print('action_counts:', d.get('action_counts')); \
    print('p95_elapsed:  ', d.get('p95_elapsed_s_by_action'))"
```

Interpretation:

- Fresh `last_tool_at` (< 1-2 min): LLM is actively calling tools. Healthy.
- Stale `last_tool_at`, fresh pane text: TUI is frozen mid-render or LLM is stuck; pane-scraping alone would miss this.
- Fresh `last_tool_at`, stale `last_mcp_tool_at`: LLM alive but MCP sidecar route is broken -- agent cannot receive messages via `mcp__orochi__*`. Restart the sidecar (`scitex-agent-container restart`).
- Fresh tool/MCP, stale `last_action_at`: the container-side action loop (nonce-probe, compact, etc.) has stopped firing. The LLM is fine but the container watchdog is not driving PaneActions; check `scitex-agent-container` service logs.
- `last_action_outcome` repeatedly non-`success` (e.g. `completion_timeout` on `nonce-probe`, or `precondition_fail` on `compact`): action is failing preconditions or timing out; inspect `action_counts` and `p95_elapsed_s_by_action` for the offender.
- Both tool/MCP stale for > 10 min with connected WebSocket: classify as stuck; check pane state (see `agent-pane-state-patterns.md`).

> Naming caveat: `last_action_name` is the **PaneAction label** from the container's `actions.db` (e.g. `nonce-probe`, `compact`). It is not the same as the pre-existing `last_action` unix-time field, which is a liveness timestamp written by `mark_activity` on inbound events. Do not conflate them.

The tool/MCP fields are derived by `scitex-agent-container`'s `event_log.summarize()` from the Claude Code hook ring buffer; the action summary fields come from the container's per-host `actions.db`. Both propagate end-to-end via `heartbeat-push` -> `/api/agents/register/`. The per-agent detail view renders them in the header meta grid (e.g. "Last tool: 12s ago (Edit)", "Last action: 12s ago (nonce-probe success, 3.2s)").

### 6. Dev Channel Dialog Cleared

The agent is not stuck on the "Do you want to proceed?" TUI prompt for `--dangerously-load-development-channels`. This prompt blocks all message processing.

**Diagnosis**: Attach to the screen session and check visually:

```bash
ssh <host> -t screen -r <agent-name>
```

If stuck, send Enter via screen:

```bash
ssh <host> screen -S <agent-name> -X stuff $'\n'
```

### 6b. Permission Prompt Stuck

Claude Code permission dialogs ("Do you want to proceed?", tool approval prompts) block agents entirely. Unlike the dev channel dialog, **`screen -X stuff` keystrokes do NOT work** for these prompts — Claude Code uses raw terminal input (not line-buffered stdin), so injected keystrokes are silently dropped.

This is a known open issue tracked as "Dev channel dialog auto-confirm."

**Workarounds (in order of preference)**:

1. Pre-configure `allowedTools` in the agent's `settings.json` so permission prompts never appear.
2. Launch with `--dangerously-skip-permissions` to bypass tool permission prompts entirely.
3. Use `scitex-agent-container`'s auto-accept script, which handles TUI prompts during launch (but cannot handle mid-session permission prompts).

**When already stuck**: The only current fix is manual interaction (attach to the screen session and press the key) or a full session restart. There is no programmatic way to dismiss a mid-session permission prompt from outside the terminal.

**Root cause found**: Agents were launched without `--dangerously-skip-permissions` despite it being in YAML configs. The launch didn't go through the full scitex-agent-container pipeline — YAML `spec.claude.flags` is only read by the container pipeline, not by manual screen launches.

**Permanent fix**: Add `permissions.allow` to the **workspace-level** `.claude/settings.json` (NOT the global `~/.claude/settings.json`, which would dangerously allow all Claude Code sessions on the machine):

```
<workspace>/.claude/settings.json
```

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Glob(*)",
      "Grep(*)",
      "mcp__scitex-orochi__*"
    ]
  }
}
```

These take effect on next agent restart. Each agent workspace (`~/.scitex/orochi/workspaces/<agent-name>/`) should have its own `.claude/settings.json`.

**Prevention**: Use `scitex-orochi launch` (reads YAML flags properly) or rely on settings.json allowlists.

**Known issue**: `screen -X stuff $'\r'` (raw carriage return) DOES work sometimes — it sends Enter which accepts the default option 1 (Yes). This is unreliable but can unblock agents in a pinch.

### 7. MCP Tools Functional

The agent can send messages via its MCP tools (reply, history, etc.).

**Test**: Send a message from the agent's session or trigger a reply via @mention. The message should appear in the Orochi chat.

### 8. @mention Responsive

The agent responds to direct mentions.

**Test**: In the dashboard or via CLI, send:

```bash
scitex-orochi send '#general' "@<agent-name> hello"
```

Expected: the agent replies within a few seconds (push mode) or within the poll interval (polling mode).

## Quick Full-Fleet Check

Run the CLI status command to check all agents at once:

```bash
scitex-orochi show-status
```

Or query the API directly:

```bash
curl -s https://scitex-orochi.com/api/agents/ | python3 -c "
import json, sys
agents = json.load(sys.stdin)
for a in agents:
    print(f\"{a['name']:25s} {'CONNECTED' if a.get('connected') else 'OFFLINE':12s} {a.get('machine', '?')}\")
"
```
