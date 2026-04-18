---
description: Text-to-speech with multiple backends (ElevenLabs, LuxTTS, gTTS, pyttsx3), smart local/relay routing, and MCP tools. Use when generating speech, playing audio notifications, or routing audio between machines.
allowed-tools: mcp__scitex__audio_*
---

# scitex-audio

Text-to-speech with multiple backends and smart local/relay routing.

## Sub-skills

* [quick-start](quick-start.md) — Basic usage, first call, return values
* [available-backends](available-backends.md) — All TTS backends, capabilities, install commands
* [smart-routing](smart-routing.md) — Auto/local/remote modes, relay server, SSH tunneling
* [cli-commands](cli-commands.md) — Complete CLI reference
* [mcp-tools-for-ai-agents](mcp-tools-for-ai-agents.md) — MCP tools and installation
* [common-workflows](common-workflows.md) — Notification patterns, multi-backend, save audio

## MCP Tools

| Tool | Purpose |
|------|---------|
| `audio_speak` | Speak text with smart routing and backend selection |

## CLI

```bash
scitex-audio speak "Hello world"          # Basic speech
scitex-audio backends                     # List available backends
scitex-audio check                        # Check audio status (WSL)
scitex-audio relay --port 31293          # Start relay server
scitex-audio mcp start                   # Start MCP server (stdio)
scitex-audio skills list                 # List skill pages
```
