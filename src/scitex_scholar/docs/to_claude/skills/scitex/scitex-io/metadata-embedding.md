---
description: Embed and read provenance metadata in PNG/JPEG/SVG/PDF files.
---

# Metadata Embedding

Embed experiment provenance directly into figure files so they carry their own history.

## API

```python
from scitex_io import embed_metadata, read_metadata, has_metadata

# Embed
embed_metadata("figure.png", {
    "experiment": "exp_042",
    "model": "resnet50",
    "accuracy": 0.94,
    "timestamp": "2026-03-11",
})

# Read back
meta = read_metadata("figure.png")  # → dict or None
meta["experiment"]                   # "exp_042"

# Check
has_metadata("figure.png")           # → True
```

## Supported formats

| Format | Storage method |
|--------|---------------|
| PNG | tEXt chunks |
| JPEG | EXIF ImageDescription field |
| SVG | `<metadata>` element (scitex namespace) |
| PDF | XMP metadata |

## Behavior

- Metadata dict must be JSON-serializable
- NumPy arrays auto-converted via `.tolist()`
- Files modified in-place
- `has_metadata()` returns `False` on any error (never raises)
- `read_metadata()` returns `None` if no metadata found
- When `sio.save(fig, "plot.png")` is used, metadata is auto-embedded by the session system
