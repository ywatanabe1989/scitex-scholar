---
description: Common TTS patterns for notifications, experiments, remote agents, and audio file generation.
---

# Common Workflows

## Basic notification

```python
from scitex_audio import speak

speak("Analysis complete")
speak("Warning: high error rate detected")
speak("Experiment finished. Results saved.")
```

## Backend-specific calls

```python
# Highest quality (paid)
speak("Premium quality", backend="elevenlabs", voice="rachel")

# Offline high-quality with voice cloning
speak("Offline speech", backend="luxtts", speed=2.0)

# Free, multi-language
speak("Bonjour tout le monde", backend="gtts", voice="fr")
speak("こんにちは", backend="gtts", voice="ja")

# System TTS, fast and free
speak("System voice", backend="pyttsx3", rate=180)
```

## Save audio file

```python
# Save without playing
speak("Notification sound", output_path="/tmp/notify.mp3", play=False)

# Save and play
speak("Save and play", output_path="/tmp/alert.mp3")

# Generate bytes (for HTTP responses, streaming)
from scitex_audio import generate_bytes
audio_bytes = generate_bytes("Hello", backend="gtts")
```

## Multi-backend with fallback

```python
# Try elevenlabs first, fall back automatically
result = speak("Important message", backend="elevenlabs", fallback=True)

# Disable fallback (fail fast)
result = speak("Critical only", backend="elevenlabs", fallback=False)

# Check which backend was used
print(result["backend"])  # e.g. "gtts" if elevenlabs failed
```

## Remote agent sending audio to local machine

```bash
# 1. Start relay on local machine (with speakers)
scitex-audio relay --port 31293

# 2. On remote agent, configure relay URL
export SCITEX_AUDIO_RELAY_URL=http://192.168.1.100:31293
# or use SSH reverse tunnel:
# ssh -R 31293:localhost:31293 remote-server
```

```python
# 3. Call speak() normally — auto-routes to relay
speak("Analysis complete on remote server")
```

## Check audio availability before speaking

```python
from scitex_audio import check_local_audio_available, speak

info = check_local_audio_available()
if info.get("available"):
    speak("Local audio works")
else:
    print(f"Audio unavailable: {info.get('reason')}")
    # speak() in auto mode will try relay automatically
```

## Announce context (hostname + project + branch)

```python
# Via MCP tool
# audio_speak(text="Starting training", signature=True)
# → speaks: "myhost. myproject. main. Starting training"
```

```bash
# Via CLI (delegates to MCP handler)
scitex-audio speak "Starting training"
```

## Voice cloning with LuxTTS

```python
from scitex_audio import LuxTTS

# Place reference audio in default search path
# ~/.config/scitex/audio/reference/my_voice.wav

tts = LuxTTS(
    reference_audio="~/.config/scitex/audio/reference/my_voice.wav",
    speed=2.0,
    device="cpu",   # or "cuda" for GPU
)
tts.speak("Speech in cloned voice")

# Or set via environment variable
# export SCITEX_AUDIO_LUXTTS_REFERENCE=~/.config/scitex/audio/reference/my_voice.wav
```

## List available voices

```python
from scitex_audio import get_tts

# ElevenLabs voices
tts = get_tts("elevenlabs")
voices = tts.get_voices()
# [{"name": "rachel", "id": "21m00...", "type": "preset"}, ...]

# Google TTS languages
tts = get_tts("gtts")
voices = tts.get_voices()
# [{"name": "English", "id": "en", "type": "language"}, ...]

# System voices
tts = get_tts("pyttsx3")
voices = tts.get_voices()
# [{"name": "...", "id": "...", "type": "system"}, ...]
```

## Stop speech

```python
from scitex_audio import stop_speech

stop_speech()   # kills espeak processes
```

```bash
scitex-audio stop
```
