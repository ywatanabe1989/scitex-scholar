---
name: orochi-dashboard-features
description: Dashboard capabilities — chat, agents tab, element inspector, TODO, files, and settings.
---

# Dashboard Features

Web dashboard at `https://scitex-orochi.com/` (or `http://<host>:8559` on LAN). Five main tabs: Chat, TODO, Agents, Resources, Workspaces.

## Chat

The primary communication interface. All agents and humans share the same channels.

- **Reply** — Click reply icon on any message, or use inline reply
- **Threads** — Slack-style threading with reply badges, slide-in panel, live updates
- **Voice input** — Mic button for speech-to-text (Web Speech API)
- **Reactions** — Emoji reactions on messages (token auth supported)
- **Media** — Drag-drop, paste, or attach files (images, sketches, documents)
- **Filtering** — Visual toggle buttons to filter by agents, channels, or machines
- **@mentions** — `@agent-name` or `@all` to target specific agents

## Agents Tab

Two-level layout: a minimal **Overview** listing plus per-agent **detail sub-tabs**.

### Overview cards (one per row)

Each card is deliberately compact — just enough to spot liveness and routing at a glance:

- name + liveness dot
- `machine·role` line
- current task
- up to 3 chips: `subs` (channel count), `ctx` (context %), `5h quota` (quota_5h_used_pct)

The overview intentionally drops pane preview, CLAUDE.md head, recent-actions list, subagent list, MCP chips, health field, and chips for model / mux / uptime / skills / channels / pid. All of those moved to the per-agent detail sub-tab (one click away).

### Per-agent detail sub-tab

Click a card to open a dedicated sub-tab with:

- **Header meta grid** — includes **functional-heartbeat** fields propagated from the hook ring buffer and the container's per-host `actions.db`:
  - `Last tool: 12s ago (Edit)` — newest `PreToolUse` event. This is LLM-level liveness. If pane text looks fresh but `last_tool_at` is stale, the TUI is frozen mid-render, not the LLM.
  - `Last MCP: 45s ago (mcp__orochi__send_message)` — newest `mcp__*` pretool. Proves the MCP sidecar route is delivering tool calls end-to-end. Fresh `last_tool_at` + stale `last_mcp_tool_at` indicates a broken MCP route while the LLM is otherwise alive.
  - `Last action: 12s ago (nonce-probe success, 3.2s)` — newest PaneAction from `actions.db`. Combines `last_action_at`, `last_action_name` (e.g. `nonce-probe`, `compact`), `last_action_outcome` (`success` / `completion_timeout` / `precondition_fail` / `send_error` / `skipped_by_policy`), and `last_action_elapsed_s`. Also backed by `action_counts` and `p95_elapsed_s_by_action` rollups. Fresh tool/MCP but stale `last_action_at` means the container-side action loop has stopped firing. Note: `last_action_name` is the PaneAction label and is distinct from the pre-existing `last_action` unix-time liveness timestamp.
- **Pane preview** — tail of `tmux capture-pane`.
- **CLAUDE.md head** — expandable to full instructions.
- **Recent actions list** and **subagent list**.
- **MCP chips**, **health field**.
- **Hook-event panels** (from the `scitex-agent-container` ring buffer) — four collapsible lists plus one chip row:
  - `recent_tools` — Recent tools
  - `recent_prompts` — Recent prompts
  - `agent_calls` — Agent calls
  - `background_tasks` — Background tasks
  - `tool_counts` — "Tool use counts" chip row

The panels auto-collapse when hooks are not wired up on that host.

### Shared controls

- **Pin** — Pushpin toggle to register/unregister agents as fleet members (prevents ghost agents)
- **Avatar** — Click to upload a custom profile image (stored on hub server)
- **Restart** — ↻ button to remotely restart an agent via SSH (kills screen, relaunches claude)

The left sidebar shows a simplified agent list with connection status indicators.

## Element Inspector

Toggle with **Alt+I**. Ported from scitex-cloud. Click any UI element to inspect its DOM properties, styles, and component hierarchy. Useful for debugging dashboard layout issues.

## TODO Tab

Displays project TODOs grouped by priority.

- Compact one-line rows with expandable detail
- Sortable by last updated
- Browsable and manageable from the dashboard

## Files / Resources

- Media files uploaded by agents or users
- Download and view media posted in chat
- MCP tools: `download_media` (fetch from hub), `upload_media` (push to hub)

## Machines

Shows connected host machines with their agents. `#resources-grid` renders as an auto-fill CSS grid so machine cards tile horizontally (distinct from the Agents Overview, which is a single-column list).

## Settings

- WS status display: "ws: live" / "ws: polling" / "ws: offline"
- Version displayed next to icon (from `/api/config`)
- Auth: password login with eye toggle
