---
description: Crop whitespace from figure images using mm or pixel margins. Requires Pillow (figrecipe[imaging]).
---

# Cropping

Removes whitespace border from saved figure images, leaving only the content area with a specified margin.

Requires: `pip install figrecipe[imaging]` (Pillow).

## fr.crop()

```python
def crop(
    input_path,
    output_path=None,       # default: input with "_cropped" suffix
    margin_mm=1.0,          # margin in millimeters (default: 1.0)
    margin_px=None,         # margin in pixels (overrides margin_mm)
    overwrite=False,        # overwrite input file in place
    verbose=False,
    return_offset=False,    # if True, return (path, offset_dict)
) -> Path | Tuple[Path, dict]
```

## Examples

```python
import figrecipe as fr

# Crop with default 1mm margin
fr.crop("figure.png")
# → figure_cropped.png

# Specify output path
fr.crop("figure.png", output_path="figure_tight.png")

# Larger margin
fr.crop("figure.pdf", margin_mm=3.0)

# Pixel margin
fr.crop("figure.png", margin_px=10)

# Overwrite in place
fr.crop("figure.png", overwrite=True)

# Get crop offset metadata
path, offset = fr.crop("figure.png", return_offset=True)
# offset: {"left": N, "top": N, "right": N, "bottom": N}  (pixels)
```

## CLI: figrecipe crop

```bash
# Default 1mm margin
figrecipe crop figure.png

# Specify output
figrecipe crop figure.png -o figure_tight.png

# Custom margin in mm
figrecipe crop figure.png --margin 2mm

# Custom margin in pixels
figrecipe crop figure.png --margin 10px

# Overwrite in place
figrecipe crop figure.png --overwrite
```

## MCP tool: plt_crop

```python
result = plt_crop(
    input_path="figure.png",
    output_path=None,       # optional; defaults to input + ".cropped" suffix
    margin_mm=1.0,
    overwrite=False,
)
# result: {"output_path": "figure.cropped.png", "success": True}
```

## Auto-crop on compose

Figures created by `fr.compose()` are automatically marked for 1mm-margin cropping when saved. This happens transparently during `fr.save()` — no explicit crop call needed for composed figures.
