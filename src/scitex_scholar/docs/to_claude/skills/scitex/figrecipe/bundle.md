---
description: ZIP bundle format — self-contained figures with spec.json, style.json, data.csv, and exported images.
---

# Bundle Format

A bundle is a self-contained ZIP file containing everything needed to view, edit, and reproduce a figure.

## Bundle structure

```
my_figure.zip
├── spec.json          # WHAT to plot (semantic specification)
├── style.json         # HOW it looks (colors, fonts, sizes)
├── data.csv           # Raw data (immutable source)
├── recipe.yaml        # Reproducible recipe (for fr.reproduce())
└── exports/
    ├── figure.png
    └── figure_hitmap.png
```

## fr.save_bundle()

```python
def save_bundle(
    fig,
    path: str | Path,              # output .zip path (extension added if missing)
    dpi: Optional[int] = None,     # default from style or 300
    image_formats: Optional[list] = None,  # default: ["png"]
    save_hitmap: bool = True,
    verbose: bool = True,
) -> Path
```

```python
import figrecipe as fr
import numpy as np

fig, ax = fr.subplots(axes_width_mm=80, axes_height_mm=60)
ax.plot(np.linspace(0, 10, 100), np.sin(np.linspace(0, 10, 100)), id="sine")

bundle_path = fr.save_bundle(fig, "my_figure")
# → my_figure.zip
```

## fr.load_bundle()

```python
spec, style, data = fr.load_bundle("my_figure.zip")
# spec: dict (spec.json contents)
# style: dict (style.json contents)
# data: DataFrame or None (data.csv contents)
```

## fr.reproduce_bundle()

```python
fig, axes = fr.reproduce_bundle("my_figure.zip")
# Reproduces the figure from bundle contents
```

`fr.reproduce()` also accepts `.zip` bundles and auto-detects the format.

## Figz and Pltz classes

`Figz` and `Pltz` are the bundle-aware figure/axes wrappers:

```python
from figrecipe import Figz, Pltz
```

These are returned by `reproduce_bundle()` and provide structured access to bundle contents.

## Principles

| Component | Editable | Notes |
|-----------|----------|-------|
| `spec.json` | Yes | Change to modify what is plotted |
| `style.json` | Yes | Change to modify appearance |
| `data.csv` | No | Immutable source data |
| `exports/` | No | Regenerated from spec + data |
| `cache/` | No | Regenerable, safe to delete |
