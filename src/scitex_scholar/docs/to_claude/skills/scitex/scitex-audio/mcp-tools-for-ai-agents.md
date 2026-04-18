---
description: MCP tools available to AI agents for text-to-speech, backend listing, and audio status.
---

# MCP Tools for AI Agents

## Installation

Add to Claude Code settings (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "scitex-audio": {
      "command": "scitex-audio",
      "args": ["mcp", "start"]
    }
  }
}
```

Or show the config via CLI:
```bash
scitex-audio mcp installation
```

## Available tools

### audio_speak

Convert text to speech with smart routing and backend selection.

```python
# Parameters (from speak_handler in _mcp/handlers.py):
text: str                    # text to speak
backend: str | None = None   # 'elevenlabs', 'luxtts', 'gtts', 'pyttsx3'
voice: str | None = None     # voice name, ID, or language code
rate: int = 150              # words per minute (pyttsx3 only)
speed: float = 1.5           # speed multiplier (gtts)
play: bool = True            # play audio
save: bool = False           # save to timestamped file in ~/.scitex/audio/
output_path: str | None = None  # explicit save path
fallback: bool = True        # try fallback backends
agent_id: str | None = None  # agent identifier for logging
wait: bool = True            # wait for speech to complete
signature: bool = False      # prepend hostname/project/branch to text
num_threads: int | None = None  # CPU threads for LuxTTS
```

Return value:
```python
{
    "success": True,
    "text": "original text",
    "full_text": "hostname. project. branch. original text",  # if signature=True
    "signature": "hostname. project. branch. ",               # if signature=True
    "backend": "gtts",
    "played": True,
    "play_requested": True,
    "mode": "local",           # or "remote" or "cloud_relay"
    "path": "/tmp/...",        # if saved
    "timestamp": "2026-01-01T12:00:00"
}
```

### SciTeX Cloud mode

When `SCITEX_CLOUD=true`, audio_speak emits an OSC escape sequence to relay speech through the PTY to the browser's speech synthesis:

```
\x1b]9999;speak:<base64-text>\x07
```

This flows: PTY → WebSocket → browser xterm.js → `speakText()`.

## Checking health

```bash
scitex-audio mcp doctor        # check FastMCP installed + backends available
scitex-audio mcp list-tools    # list all registered MCP tools
```

## Starting the MCP server

```bash
# stdio (for Claude Code)
scitex-audio mcp start

# HTTP transport (for remote access)
scitex-audio mcp start -t http --port 31293

# SSE transport
scitex-audio mcp start -t sse --port 31293
```

## Relay vs MCP

| Feature | Relay server | MCP server |
|---------|-------------|------------|
| Protocol | HTTP REST | MCP (stdio/SSE/HTTP) |
| Start command | `scitex-audio relay` | `scitex-audio mcp start` |
| Use case | Agent → relay → local speakers | Claude Code integration |
| Port | 31293 | 31293 (HTTP transport) |
| Endpoints | `/speak`, `/health`, `/list_backends` | MCP tool calls |
