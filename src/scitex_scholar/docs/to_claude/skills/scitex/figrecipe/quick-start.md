---
description: Core figrecipe workflow — creating figures, saving YAML recipes, and reproducing them exactly.
---

# Quick Start

## Core workflow

```python
import figrecipe as fr
import numpy as np

# 1. Create figure with recording-enabled axes
fig, ax = fr.subplots(
    axes_width_mm=80,    # axes width in mm
    axes_height_mm=60,   # axes height in mm
)

# 2. Plot — all calls are recorded automatically
x = np.linspace(0, 10, 100)
ax.plot(x, np.sin(x), color="red", label="sin", id="sine_wave")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Amplitude")
ax.legend()

# 3. Save — creates figure.png + figure.yaml + figure_data/
fr.save(fig, "figure.png")

# 4. Reproduce exactly from recipe
fig2, ax2 = fr.reproduce("figure.yaml")
```

## fr.subplots()

```python
def subplots(
    nrows: int = 1,
    ncols: int = 1,
    axes_width_mm: Optional[float] = None,
    axes_height_mm: Optional[float] = None,
    margin_left_mm: Optional[float] = None,
    margin_right_mm: Optional[float] = None,
    margin_bottom_mm: Optional[float] = None,
    margin_top_mm: Optional[float] = None,
    space_w_mm: Optional[float] = None,
    space_h_mm: Optional[float] = None,
    style: Optional[dict] = None,
    apply_style_mm: bool = True,
    panel_labels: Optional[bool] = None,
    **kwargs,            # passed to plt.subplots()
) -> Tuple[RecordingFigure, RecordingAxes | ndarray]
```

Drop-in replacement for `plt.subplots()`. All mm parameters are optional; omit for matplotlib defaults.

## fr.save()

```python
def save(
    fig,
    path: str | Path,         # .png, .pdf, .svg, .yaml, etc.
    save_recipe: bool = True, # save .yaml recipe alongside image
    include_data: bool = True,
    data_format: str = "csv", # "csv", "npz", or "inline"
    csv_format: str = "separate",  # "separate" or "single"
    validate: bool = True,
    validate_mse_threshold: float = 100.0,
    validate_error_level: str = "error",
    verbose: bool = True,
    dpi: Optional[int] = None,
    image_format: Optional[str] = None,
    facecolor: Optional[str] = None,
    save_hitmap: bool = True,
) -> Tuple[Path, Path | None, ValidationResult | None]
```

Returns `(image_path, yaml_path, validation_result)`.

## fr.reproduce()

```python
def reproduce(
    path: str | Path,
    calls: Optional[list[str]] = None,  # reproduce only these call IDs
    skip_decorations: bool = False,
    apply_style: bool = True,
) -> Tuple[Figure, Axes | list[Axes]]
```

Accepts `.yaml`, `.yml`, image paths (loads `.yaml` sibling), bundle directories, and `.zip` bundles.

`fr.load` is an alias for `fr.reproduce`.

## fr.info()

```python
fr.info("figure.yaml")
# Returns dict with figure dimensions, axes count, call counts, etc.
```

## fr.extract_data()

```python
data = fr.extract_data("figure.yaml")
# Returns {call_id: {"x": array, "y": array, ...}}
```

## fr.validate()

```python
result = fr.validate("figure.yaml", mse_threshold=100.0)
# result.valid, result.mse, result.message
```

## Multi-axes example

```python
fig, axes = fr.subplots(nrows=2, ncols=3, axes_width_mm=55, axes_height_mm=45)

for i, ax in enumerate(axes.flat):
    ax.scatter(x, y + i, s=5, id=f"data_{i}")

fr.save(fig, "multi_panel.png")
```

## call id parameter

Every plotting call accepts an optional `id` kwarg for traceability:

```python
ax.plot(x, y, id="my_trace")         # named trace
ax.bar(categories, values, id="bars")
```

IDs appear in the YAML recipe and are used by `extract_data()` and `reproduce(calls=[...])`.
