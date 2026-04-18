---
description: Multi-panel figure composition — combining multiple recipe files or images into a single figure using grid-based or mm-based positioning.
---

# Composition

## fr.compose()

```python
def compose(
    sources: dict,
    layout: Optional[Tuple[int, int]] = None,
    canvas_size_mm: Optional[Tuple[float, float]] = None,
    gap_mm: float = 5.0,
    dpi: int = 300,
    panel_labels: bool = False,
    label_style: str = "uppercase",    # "uppercase", "lowercase", "numeric"
    **kwargs,
) -> Tuple[RecordingFigure, RecordingAxes | ndarray | list]
```

Two modes are auto-detected from the `sources` format.

## Mode 1: Grid-based

Sources keyed by `(row, col)` tuples.

```python
import figrecipe as fr

fig, axes = fr.compose(
    layout=(1, 2),
    sources={
        (0, 0): "panel_a.yaml",
        (0, 1): "panel_b.yaml",
    },
    panel_labels=True,
)
fr.save(fig, "composed_2panel.png")
```

Layout is auto-detected if not provided (uses max row/col from keys).

```python
# 2x2 grid, auto-detected layout
fig, axes = fr.compose(
    sources={
        (0, 0): "panel_a.yaml",
        (0, 1): "panel_b.yaml",
        (1, 0): "panel_c.yaml",
        (1, 1): "panel_d.yaml",
    },
    panel_labels=True,
    label_style="uppercase",   # labels: A, B, C, D
)
```

## Mode 2: Mm-based free-form

Sources keyed by file path, with explicit `xy_mm` and `size_mm`.

```python
fig, axes = fr.compose(
    canvas_size_mm=(180, 120),
    sources={
        "panel_a.yaml": {"xy_mm": (0, 0), "size_mm": (85, 55)},
        "panel_b.yaml": {"xy_mm": (90, 0), "size_mm": (85, 55)},
        "panel_c.yaml": {"xy_mm": (0, 60), "size_mm": (175, 55)},
    },
    panel_labels=True,
)
fr.save(fig, "composed_freeform.png")
```

`xy_mm` is `(left, top)` offset from canvas origin (top-left = (0, 0)).

If `canvas_size_mm` is omitted, it is auto-calculated from the source extents + 5mm padding.

## MCP tool: plt_compose

```python
# Grid-based via MCP
result = plt_compose(
    sources=["panel_a.png", "panel_b.png", "panel_c.png"],
    output_path="figure.png",
    layout="horizontal",     # "horizontal", "vertical", "grid"
    gap_mm=5.0,
    panel_labels=True,
    label_style="uppercase",
    dpi=300,
    save_recipe=True,
)
# result: {"output_path": ..., "success": True, "layout_spec": ..., "recipe_path": ...}

# Free-form mm-based via MCP
result = plt_compose(
    sources={
        "panel_a.yaml": {"xy_mm": [0, 0], "size_mm": [80, 50]},
        "panel_b.yaml": {"xy_mm": [90, 0], "size_mm": [80, 50]},
    },
    output_path="figure.png",
    canvas_size_mm=[180, 60],
)
```

`plt_compose` auto-converts list sources to mm-based positioning using `solve_layout_to_mm()`.

## Alignment helpers

```python
import figrecipe as fr

# Align panels to left/right/top/bottom/center
fr.align_panels(axes, mode="left")      # AlignmentMode enum or string
fr.align_panels(axes, mode="top")
fr.align_panels(axes, mode="center_h")

# Distribute panels with equal spacing
fr.distribute_panels(axes, direction="horizontal")
fr.distribute_panels(axes, direction="vertical")

# Smart alignment: combine alignment + distribution
fr.align_smart(axes, strategy="row_align")
```

## Visibility helpers

```python
from figrecipe._composition import hide_panel, show_panel, toggle_panel

hide_panel(ax)     # hide a panel (invisible but retains layout space)
show_panel(ax)     # show hidden panel
toggle_panel(ax)   # toggle visibility
```

## Supported source formats

Composition accepts: `.yaml`, `.yml` (recipe files), `.png`, `.jpg`, `.jpeg`, `.tiff`, `.bmp`, `.gif`, `.webp`, `.svg` (SVG requires `cairosvg`).

## Composition figures auto-crop

Figures created by `compose()` are automatically marked for 1mm-margin cropping when saved with `fr.save()`. No manual crop step needed.
