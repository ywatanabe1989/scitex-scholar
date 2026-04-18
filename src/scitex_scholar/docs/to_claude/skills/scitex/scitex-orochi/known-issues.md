---
name: orochi-known-issues
description: Known operational issues with Orochi agents and the hub, with workarounds.
---

# Known Issues

Active issues encountered during fleet operations. Check here before debugging a "new" problem.

## Media Download Returns HTTP 400

**Symptom**: `download_media` MCP tool and direct `curl` to `http://192.168.11.22:8559/media/...` return HTTP 400.

**Root cause**: Django's `ALLOWED_HOSTS` may not include the LAN IP. The Daphne server rejects HTTP requests with `Host: 192.168.11.22:8559`. WebSocket connections bypass this check, so agent messaging works fine.

**Impact**: Agents cannot download images or files shared in chat. Agents that attempt auto-fetch may enter error loops or go silent.

**Workaround**: Agents should gracefully handle media attachment URLs they cannot download — log the URL and continue processing the text content. Do not block or retry indefinitely.

**Fix**: Add the LAN IP to `ALLOWED_HOSTS` in the Django settings on the hub server.

## Agents Crash on Media in Reply/Threading

**Symptom**: Agents go offline shortly after a message with media attachments is posted, especially in replies or threads.

**Root cause**: The MCP sidecar formats attachments as `[Attachments: filename -> url]` in notification text. If the agent tries to auto-process the URL and hits the 400 error above, it may enter an error loop.

**Workaround**: Agents should treat attachment URLs as informational only — do not attempt automatic download unless explicitly asked.

## Thread Notifications Not Delivered to MCP

**Symptom**: Messages posted in threads (reply_to) do not trigger MCP channel notifications to agents. Agents only see top-level channel messages.

**Root cause**: The MCP sidecar's WebSocket subscription may not include threaded messages, or the hub's broadcast logic skips thread replies for the main channel feed.

**Impact**: Agents miss context when conversations happen in threads. Users must re-post in the main channel to get agent attention.

**Workaround**: For messages that need agent response, post in the main channel (not in a thread). Use `@mention` in top-level messages.

## Dev Channel Dialog Blocks Agent Startup

**Symptom**: Agent gets stuck on "Do you want to proceed?" TUI prompt for `--dangerously-load-development-channels`. The agent appears connected to the hub but never processes messages.

**Root cause**: Claude Code's interactive confirmation prompt. `screen -X stuff $'\n'` works sometimes but is unreliable.

**Workaround**: Workspace-level `.claude/settings.json` with permission allowlists prevents most prompts. For the dev channel dialog specifically, `screen -X stuff $'\r'` (bare carriage return) usually accepts the default.

**Fix in progress**: Issue #15 — add detection to the launcher pipeline (`scitex-agent-container`) to auto-confirm this dialog via screen hardcopy + grep.

## Global settings.json Is Dangerous

**Symptom**: Adding `Bash(*)` to global `~/.claude/settings.json` allows ALL Claude Code sessions on the machine to run arbitrary commands without approval.

**Rule**: ALWAYS use workspace-level `.claude/settings.json` for agent permissions. Never put broad permissions in the global config.

## Quota Exhaustion Disconnects All Agents Simultaneously

**Symptom**: Multiple agents go offline at the same time. WebSocket reconnects succeed but Claude Code stops responding.

**Root cause**: Anthropic API usage cap reached. Four Opus agents consumed 72% of monthly quota in 3.5 days during testing.

**Workaround**: Use `claude-haiku-4-5` for non-critical agents (mamba-healer, mamba-skill-manager). Reserve Opus for head agents and task-managers that need deep reasoning.
