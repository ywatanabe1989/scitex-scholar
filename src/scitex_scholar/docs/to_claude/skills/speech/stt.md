## Speech-to-Text (Voice Transcription)

### Pipeline
1. **Download** — Get the audio file (e.g., Telegram voice .oga)
2. **Convert** — `ffmpeg -y -i input.oga /tmp/output.wav`
3. **Transcribe** — whisper-cli with tiny model

### Whisper Command
```bash
/home/ywatanabe/.emacs.d/.cache/whisper.cpp/build/bin/whisper-cli \
  -m /home/ywatanabe/.emacs.d/.cache/whisper.cpp/models/ggml-tiny.bin \
  -l ja -f <wav_file>
```

### Model Selection
Always use **ggml-tiny.bin** — ~3s for a 3s clip vs ~73s with medium on CPU. Minor accuracy trade-off is acceptable.

### Available Models
Located at `~/.emacs.d/.cache/whisper.cpp/models/`:
- `ggml-tiny.bin` — fastest, default choice
- `ggml-base.bin` / `ggml-small.bin` — middle ground
- `ggml-medium.bin` — slow on CPU, better accuracy
- `ggml-large-v3-turbo.bin` — slowest, best accuracy

### Language
Default to `-l ja` (Japanese). Omit `-l` for auto-detection if language is unknown.

### Notes
- ffmpeg conversion is fast (<1s), not the bottleneck
- Telegram voice messages arrive as `.oga` (Opus codec); whisper requires `.wav`
- Transcription output includes timestamps: `[00:00:00.000 --> 00:00:03.460] text`
