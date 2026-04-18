---
description: Complete CLI reference for scitex-audio with all subcommands, options, and examples.
---

# CLI Commands

Entry point: `scitex-audio`

## speak — convert text to speech

```bash
scitex-audio speak TEXT [OPTIONS]

Options:
  -b, --backend [pyttsx3|gtts|luxtts|elevenlabs]
                          TTS backend (auto-selects with fallback if not set)
  -v, --voice TEXT        Voice name, ID, or language code
  -o, --output PATH       Save audio to file
  --no-play               Don't play audio (only save)
  -r, --rate INTEGER      Speech rate in WPM (pyttsx3 only, default: 150)
  -s, --speed FLOAT       Speed multiplier (gtts only, e.g., 1.5)
  --no-fallback           Disable backend fallback on error
  --json                  Output as structured JSON

Examples:
  scitex-audio speak "Hello world"
  scitex-audio speak "Bonjour" --backend gtts --voice fr
  scitex-audio speak "Test" --output speech.mp3 --no-play
  scitex-audio speak "Fast speech" --backend pyttsx3 --rate 200
  scitex-audio speak "Slow speech" --backend gtts --speed 0.8
  scitex-audio speak "Hello" --json
```

## backends — list available TTS backends

```bash
scitex-audio backends [--json]

Examples:
  scitex-audio backends
  scitex-audio backends --json
```

Output shows fallback order with available/not-installed status.

## check — check audio status (especially for WSL)

```bash
scitex-audio check [--json]

Checks:
  - WSL detection
  - WSLg availability
  - PulseAudio connection
  - Windows fallback availability

Examples:
  scitex-audio check
  scitex-audio check --json
```

## stop — stop currently playing speech

```bash
scitex-audio stop [--json]

Examples:
  scitex-audio stop
```

## relay — run HTTP relay server for remote audio

```bash
scitex-audio relay [OPTIONS]

Options:
  --host TEXT     Bind host (default: 0.0.0.0)
  --port INTEGER  Bind port (default: 31293)
  --force         Kill existing process on port before starting

Endpoints:
  POST /speak         — play TTS on local machine
  GET  /health        — server health check
  GET  /list_backends — list available backends

Examples:
  scitex-audio relay --port 31293
  scitex-audio relay --force
```

## env-template — generate environment variable template

```bash
scitex-audio env-template [OPTIONS]

Options:
  -o, --output PATH  Write to file instead of stdout
  --no-sensitive     Exclude API keys from template

Examples:
  scitex-audio env-template                   # print to stdout
  scitex-audio env-template -o audio.src     # write to file
  scitex-audio env-template --no-sensitive    # exclude API keys
```

## mcp — MCP server operations

```bash
scitex-audio mcp start [OPTIONS]

Options:
  -t, --transport [stdio|sse|http]  Transport protocol (default: stdio)
  --host TEXT                       Host for HTTP/SSE (default: 0.0.0.0)
  --port INTEGER                    Port for HTTP/SSE (default: 31293)

Examples:
  scitex-audio mcp start                        # stdio (for Claude Code)
  scitex-audio mcp start -t http --port 31293  # HTTP transport

scitex-audio mcp doctor          # check FastMCP + backend availability
scitex-audio mcp list-tools      # list MCP tools
scitex-audio mcp list-tools -v   # with signatures
scitex-audio mcp installation    # show Claude Code config JSON
```

## skills — browse skill pages

```bash
scitex-audio skills list          # list available skill pages
scitex-audio skills get SKILL     # get specific skill page content
```

## list-python-apis — list Python API

```bash
scitex-audio list-python-apis           # basic list
scitex-audio list-python-apis -v        # with signatures
scitex-audio list-python-apis -vv       # with docstrings
scitex-audio list-python-apis --json    # JSON output
```
