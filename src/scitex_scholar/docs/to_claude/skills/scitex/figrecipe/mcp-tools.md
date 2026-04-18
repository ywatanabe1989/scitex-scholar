---
description: figrecipe MCP tools for AI agents — creating, composing, cropping, validating, and extracting data from figures.
---

# MCP Tools

All tools are prefixed `plt_` and available via the figrecipe MCP server.

Start server: `figrecipe mcp start`

## Core figure tools

### plt_plot

Create a matplotlib figure from a declarative specification dict.

```python
result = plt_plot(
    spec={
        "figure": {"width_mm": 80, "height_mm": 60, "style": "SCITEX"},
        "plots": [
            {"type": "line", "x": [1,2,3,4,5], "y": [1,4,9,16,25],
             "color": "blue", "label": "quadratic"}
        ],
        "xlabel": "X",
        "ylabel": "Y",
        "title": "My Plot",
    },
    output_path="figure.png",
    dpi=300,
    save_recipe=True,
)
# result: {"image_path": "figure.png", "recipe_path": "figure.yaml", "success": True}
```

Full spec format: see `figrecipe://spec-schema` MCP resource.

### plt_reproduce

Reproduce a figure from a saved YAML recipe.

```python
result = plt_reproduce(
    recipe_path="figure.yaml",
    output_path=None,        # defaults to figure.reproduced.png
    format="png",            # "png", "pdf", "svg"
    dpi=300,
)
# result: {"output_path": "figure.reproduced.png", "success": True}
```

### plt_compose

Compose multiple figures into one panel figure.

```python
# Grid-based (list sources)
result = plt_compose(
    sources=["panel_a.png", "panel_b.png", "panel_c.png"],
    output_path="figure.png",
    layout="horizontal",       # "horizontal", "vertical", "grid"
    gap_mm=5.0,
    panel_labels=True,
    label_style="uppercase",   # "uppercase", "lowercase", "numeric"
    dpi=300,
    save_recipe=True,
)

# Free-form mm-based (dict sources)
result = plt_compose(
    sources={
        "panel_a.yaml": {"xy_mm": [0, 0], "size_mm": [80, 50]},
        "panel_b.yaml": {"xy_mm": [90, 0], "size_mm": [80, 50]},
    },
    output_path="figure.png",
    canvas_size_mm=[180, 60],
)
# result: {"output_path": ..., "success": True, "layout_spec": ..., "recipe_path": ...}
```

## Image processing

### plt_crop

Crop whitespace from a figure image.

```python
result = plt_crop(
    input_path="figure.png",
    output_path=None,          # defaults to input + ".cropped" suffix
    margin_mm=1.0,
    overwrite=False,
)
# result: {"output_path": "figure.cropped.png", "success": True}
```

## Information and validation

### plt_info

Get metadata about a recipe file.

```python
result = plt_info(
    recipe_path="figure.yaml",
    verbose=False,
)
# result: dict with figure dimensions, axes count, call counts, etc.
```

### plt_validate

Validate that a recipe can reproduce its original figure.

```python
result = plt_validate(
    recipe_path="figure.yaml",
    mse_threshold=100.0,
)
# result: {"valid": True, "mse": 0.5, "message": "...", "recipe_path": "..."}
```

### plt_extract_data

Extract plotted data arrays from a recipe.

```python
result = plt_extract_data(recipe_path="figure.yaml")
# result: {"call_id": {"x": [...], "y": [...]}, ...}
# Arrays are serialized as lists for JSON compatibility
```

## Discovery

### plt_get_plot_types

```python
result = plt_get_plot_types()
# result: {
#   "plot_types": ["line", "scatter", "bar", ...],
#   "mapping": {"line": "plot", "scatter": "scatter", ...},
#   "categories": {
#     "line_curve": ["line", "plot", "step", ...],
#     "scatter_points": ["scatter"],
#     ...
#   }
# }
```

### plt_list_styles

```python
result = plt_list_styles()
# result: {"presets": ["SCITEX", "SCITEX_DARK", "MATPLOTLIB", ...], "count": N}
```

## Per-type plot tools

Individual tools for each standard matplotlib plot type. Accept `data_file` + column names or inline arrays.

| Tool | Plot type |
|------|-----------|
| `plt_line` / `plt_plot` | Line plot |
| `plt_scatter` | Scatter plot |
| `plt_bar` | Vertical bar chart |
| `plt_barh` | Horizontal bar chart |
| `plt_hist` | Histogram |
| `plt_hist2d` | 2D histogram |
| `plt_boxplot` | Box plot |
| `plt_violinplot` | Violin plot |
| `plt_errorbar` | Error bar plot |
| `plt_fill_between` | Filled band |
| `plt_fill_betweenx` | Horizontal filled band |
| `plt_stackplot` | Stacked area |
| `plt_contour` | Contour lines |
| `plt_contourf` | Filled contours |
| `plt_imshow` | Image / heatmap |
| `plt_pcolormesh` | 2D grid mesh |
| `plt_pie` | Pie chart |
| `plt_stem` | Stem plot |
| `plt_stairs` | Stair/step plot |
| `plt_hexbin` | Hexbin density |
| `plt_quiver` | Vector field |
| `plt_streamplot` | Flow streamlines |
| `plt_ecdf` | Empirical CDF |
| `plt_acorr` | Autocorrelation |
| `plt_xcorr` | Cross-correlation |
| `plt_psd` | Power spectral density |
| `plt_csd` | Cross spectral density |
| `plt_specgram` | Spectrogram |
| `plt_cohere` | Coherence |

## SciTeX scientific plot tools

| Tool | Plot type |
|------|-----------|
| `plt_stx_line` | Styled line |
| `plt_stx_shaded_line` | Line with error band |
| `plt_stx_mean_std` | Mean ± std |
| `plt_stx_mean_ci` | Mean with CI |
| `plt_stx_median_iqr` | Median with IQR |
| `plt_stx_violin` | Violin with points |
| `plt_stx_scatter_hist` | Scatter + marginal histograms |
| `plt_stx_heatmap` | Annotated heatmap |
| `plt_stx_conf_mat` | Confusion matrix |
| `plt_stx_raster` | Spike raster |
| `plt_stx_ecdf` | ECDF (styled) |
| `plt_stx_fillv` | Vertical fill regions |
| `plt_stx_image` | Image with scale bar |
| `plt_stx_rectangle` | Annotated rectangle |

## Diagram tools

| Tool | Purpose |
|------|---------|
| `plt_diagram_create` | Create from spec dict |
| `plt_diagram_render` | Render to image |
| `plt_diagram_compile_mermaid` | Compile Mermaid text |
| `plt_diagram_compile_graphviz` | Compile Graphviz DOT |
| `plt_diagram_list_presets` | List presets |
| `plt_diagram_get_preset` | Get preset config |
| `plt_diagram_get_backends` | List backends |
| `plt_diagram_get_paper_modes` | List paper modes |
| `plt_diagram_split` | Split across pages |

## MCP Resources

| Resource URI | Contents |
|-------------|---------|
| `figrecipe://spec-schema` | Full declarative spec format documentation |
| `figrecipe://cheatsheet` | Quick reference |
| `figrecipe://mcp-spec` | MCP tool specification format |
| `figrecipe://api/core` | Full API documentation |
