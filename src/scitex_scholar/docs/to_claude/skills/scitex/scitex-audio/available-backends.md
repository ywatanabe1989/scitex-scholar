---
description: All TTS backends with capabilities, install commands, and engine class details.
---

# Available Backends

Fallback order (auto-selection): `elevenlabs` -> `luxtts` -> `gtts` -> `pyttsx3`

## Summary table

| Backend | Key | Quality | Offline | Speed range | Requires |
|---------|-----|---------|---------|-------------|---------|
| ElevenLabs | `elevenlabs` | Highest | No | 0.7–1.2x | API key + `pip install elevenlabs` |
| LuxTTS | `luxtts` | High | Yes | 2.0x default | `pip install git+https://github.com/ysharma3501/LuxTTS.git` |
| Google TTS | `gtts` | Medium | No | 1.5x default | `pip install gTTS` |
| System TTS | `pyttsx3` | Basic | Yes | rate in WPM | `pip install pyttsx3` + espeak-ng |

## ElevenLabsTTS

```python
from scitex_audio import ElevenLabsTTS

tts = ElevenLabsTTS(
    api_key=None,           # reads SCITEX_AUDIO_ELEVENLABS_API_KEY or ELEVENLABS_API_KEY
    voice="rachel",         # preset name or voice ID
    model_id="eleven_multilingual_v2",
    stability=0.5,
    similarity_boost=0.75,
    speed=1.0,              # clamped to 0.7–1.2 by API
)
tts.speak("Hello from ElevenLabs")
```

Preset voices: `rachel`, `adam`, `antoni`, `bella`, `domi`, `elli`, `josh`, `sam`

Environment variables:
- `SCITEX_AUDIO_ELEVENLABS_API_KEY` (preferred)
- `ELEVENLABS_API_KEY` (fallback)

Install: `pip install scitex-audio[elevenlabs]`

## LuxTTS

```python
from scitex_audio import LuxTTS

tts = LuxTTS(
    device=None,            # auto-detects: 'cuda', 'mps', or 'cpu'
    model_id="YatharthS/LuxTTS",
    reference_audio=None,   # path to reference .wav/.mp3 for voice cloning
    num_steps=4,
    speed=2.0,
    rms=0.01,
    t_shift=0.9,
    ref_duration=5.0,
)
tts.speak("Offline high-quality speech")
```

- Outputs 48kHz WAV
- Voice cloning: place reference audio in `~/.config/scitex/audio/reference/`
- Environment: `SCITEX_AUDIO_LUXTTS_REFERENCE` for reference audio path
- Environment: `SCITEX_AUDIO_LUXTTS_TRIM_START` to trim hallucinated preamble (seconds)

Install: `pip install scitex-audio[luxtts]`

## GoogleTTS

```python
from scitex_audio import GoogleTTS

tts = GoogleTTS(
    lang="en",              # language code (default: 'en')
    slow=False,
    speed=1.5,              # speed multiplier via pydub (requires ffmpeg)
)
tts.speak("Hello in English")
tts.speak("Bonjour", voice="fr")   # override language per call
```

Supported languages include: `en`, `es`, `fr`, `de`, `it`, `pt`, `ru`, `ja`, `ko`, `zh-CN`, `zh-TW`, `ar`, `hi`, `nl`, `pl`, `sv`, `tr`, `vi`

Install: `pip install scitex-audio[gtts]`

## SystemTTS (pyttsx3)

```python
from scitex_audio import SystemTTS

tts = SystemTTS(
    rate=150,               # words per minute
    volume=1.0,             # 0.0 to 1.0
    voice=None,             # voice name or ID
)
tts.speak("Offline system speech")
tts.speak_direct("Direct without file")  # faster, no temp file
```

Platform support:
- Linux: `espeak-ng` — `sudo apt install espeak-ng libespeak1`
- Windows: SAPI5 (built-in)
- macOS: NSSpeechSynthesizer (built-in)

Install: `pip install scitex-audio[pyttsx3]`

## Installing all backends

```bash
pip install scitex-audio[all]
# or selectively:
pip install scitex-audio[gtts,pyttsx3]
pip install scitex-audio[elevenlabs]
pip install scitex-audio[luxtts]
```
