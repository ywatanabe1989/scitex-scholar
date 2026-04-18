---
description: Basic speak() usage, return value structure, and first steps with scitex-audio.
---

# Quick Start

## Basic usage

```python
from scitex_audio import speak

# Minimal call — auto-selects best available backend
speak("Hello, world!")

# With specific backend
speak("Fast speech", backend="gtts", speed=1.5)

# Save to file without playing
speak("Silent generation", output_path="/tmp/alert.mp3", play=False)

# Save and play
speak("Save and play", output_path="/tmp/notify.mp3")
```

## speak() signature

```python
def speak(
    text: str,
    backend: str | None = None,       # 'elevenlabs', 'luxtts', 'gtts', 'pyttsx3'
    voice: str | None = None,          # voice name, ID, or language code
    play: bool = True,                 # whether to play the audio
    output_path: str | None = None,    # path to save audio file
    fallback: bool = True,             # try next backend on failure
    rate: int | None = None,           # words per minute (pyttsx3 only)
    speed: float | None = None,        # speed multiplier (gtts: >1.0=faster)
    mode: str | None = None,           # override mode: 'local', 'remote', 'auto'
    **kwargs,
) -> dict:
```

## Return value

`speak()` returns a dict:

```python
{
    "success": True,
    "played": True,
    "play_requested": True,
    "backend": "gtts",       # which backend was used
    "mode": "local",         # 'local' or 'remote'
    "path": "/tmp/...",      # only if output_path was set
}
```

## Check what backends are available

```python
from scitex_audio import available_backends

backends = available_backends()
# e.g. ['pyttsx3', 'gtts', 'elevenlabs']
```

## Get a backend instance directly

```python
from scitex_audio import get_tts

tts = get_tts("gtts")
tts.speak("Hello via Google TTS")

# Auto-select best backend
tts = get_tts()
tts.speak("Best available backend")
```

## Generate audio bytes (no playback)

```python
from scitex_audio import generate_bytes

audio_bytes = generate_bytes("Convert to bytes", backend="gtts")
# Returns raw MP3 bytes
```

## Stop speech

```python
from scitex_audio import stop_speech

stop_speech()  # kills espeak processes
```
