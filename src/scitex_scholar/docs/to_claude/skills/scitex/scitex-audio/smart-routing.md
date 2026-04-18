---
description: Auto/local/remote modes, relay server setup, SSH tunneling for remote audio playback.
---

# Smart Routing

## Modes

| Mode | Behavior | Set via |
|------|---------|---------|
| `auto` | Smart routing: prefers relay if local audio unavailable | Default |
| `local` | Always use local TTS backends | `SCITEX_AUDIO_MODE=local` |
| `remote` | Always forward to relay server | `SCITEX_AUDIO_MODE=remote` |

```python
# Override mode per call
speak("Hello", mode="local")
speak("Hello", mode="remote")
speak("Hello", mode="auto")
```

## Auto mode logic

1. Check if local audio sink is available (pactl, not SUSPENDED)
2. If local OK and relay configured: tries relay first, falls back to local
3. If local unavailable and relay configured: uses relay
4. If local unavailable and no relay: returns error dict with `success=False`

## Relay server

The relay server runs on the machine with speakers and accepts HTTP POST requests from remote agents.

### Start relay on local machine

```bash
# Default port 31293
scitex-audio relay --port 31293

# Endpoints served:
# POST /speak         — play TTS
# GET  /health        — health check
# GET  /list_backends — list available backends
```

### Configure remote agent to use relay

```bash
# Option 1: Direct URL
export SCITEX_AUDIO_RELAY_URL=http://192.168.1.100:31293

# Option 2: Host + port
export SCITEX_AUDIO_RELAY_HOST=192.168.1.100
export SCITEX_AUDIO_RELAY_PORT=31293
```

### SSH reverse tunnel

For agents on remote servers, use SSH reverse tunneling:

```bash
# On remote server — forward port 31293 back to your local machine
ssh -R 31293:localhost:31293 remote-server

# scitex-audio auto-detects localhost:31293 if reachable
# No env vars needed when tunnel is active
```

Auto-detection priority in `get_relay_url()`:
1. `SCITEX_AUDIO_RELAY_URL` env var
2. `SCITEX_AUDIO_RELAY_HOST` + port
3. `localhost:31293` if reachable (SSH reverse tunnel)
4. SSH client IP from `SSH_CLIENT` / `SSH_CONNECTION`

## Relay client usage

```python
from scitex_audio._relay import RelayClient, relay_speak

# Direct client
client = RelayClient("http://localhost:31293")
client.speak("Hello from remote", backend="gtts", speed=1.5)

# Convenience function
relay_speak("Hello", backend="gtts")

# Check availability
from scitex_audio._relay import is_relay_available
if is_relay_available():
    relay_speak("Relay is up")
```

## Environment variables

| Variable | Default | Description |
|---------|---------|-------------|
| `SCITEX_AUDIO_MODE` | `auto` | Mode: `local`, `remote`, `auto` |
| `SCITEX_AUDIO_RELAY_URL` | — | Full relay URL |
| `SCITEX_AUDIO_RELAY_HOST` | — | Relay host (builds URL with port) |
| `SCITEX_AUDIO_RELAY_PORT` | `31293` | Relay port |
| `SCITEX_AUDIO_HOST` | `0.0.0.0` | Server bind host |
| `SCITEX_AUDIO_PORT` | `31293` | Server port |
| `SCITEX_AUDIO_ELEVENLABS_API_KEY` | — | ElevenLabs API key |
| `SCITEX_DIR` | `~/.scitex` | Base dir for audio cache |
| `SCITEX_CLOUD` | — | Set to `true` for browser relay (OSC escape) |

## Generate env template

```bash
scitex-audio env-template                  # print to stdout
scitex-audio env-template -o audio.src    # write to file
source audio.src                          # apply settings
```

```python
from scitex_audio import generate_env_template

template = generate_env_template(include_sensitive=True)
```

## WSL audio check

```python
from scitex_audio import check_wsl_audio

status = check_wsl_audio()
# {
#   "is_wsl": True,
#   "wslg_available": True,
#   "pulse_server_exists": True,
#   "pulse_connected": True,
#   "windows_fallback_available": True,
#   "recommended": "linux"   # or "windows" or "none"
# }
```

```bash
scitex-audio check       # human-readable
scitex-audio check --json
```
