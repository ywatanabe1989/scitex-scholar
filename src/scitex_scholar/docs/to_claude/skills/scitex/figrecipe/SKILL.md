---
description: Reproducible matplotlib figures with mm-precision layouts, declarative specs, YAML recipes, multi-panel composition, and diagram generation. Use when creating publication-ready figures.
allowed-tools: mcp__scitex__plt_*
---

# figrecipe

## Installation

```bash
pip install figrecipe
# Development:
pip install -e /home/ywatanabe/proj/figrecipe
```

Reproducible, style-editable scientific figures via YAML recipes. Drop-in replacement for `plt.subplots()` that records all plotting calls for exact reproduction.

## Sub-skills

* [quick-start](quick-start.md) — Core workflow: subplots, save, reproduce
* [plot-types](plot-types.md) — All supported plot types with examples
* [composition](composition.md) — Multi-panel figure composition (grid and mm-based)
* [cropping](cropping.md) — Figure cropping, whitespace removal
* [styles](styles.md) — Style presets, SCITEX/MATPLOTLIB, custom styles
* [bundle](bundle.md) — ZIP bundle format (spec.json + data.csv + exports)
* [diagram](diagram.md) — Box-and-arrow diagrams, Mermaid, Graphviz
* [cli-reference](cli-reference.md) — All CLI commands
* [mcp-tools](mcp-tools.md) — MCP tool reference for AI agents
* [return-fig](return-fig.md) — Convention: plotting functions must return fig

## MCP Tools

| Tool | Purpose |
|------|---------|
| `plt_plot` | Create figure from declarative spec dict |
| `plt_reproduce` | Reproduce figure from YAML recipe |
| `plt_compose` | Compose multi-panel figure |
| `plt_crop` | Crop whitespace from figure image |
| `plt_validate` | Validate recipe reproducibility |
| `plt_extract_data` | Extract plotted data arrays |
| `plt_info` | Get recipe metadata |
| `plt_get_plot_types` | List all supported plot types |
| `plt_list_styles` | List available style presets |
| `plt_diagram_create` | Create box-and-arrow diagram |
| `plt_diagram_render` | Render diagram to image |
| `plt_diagram_compile_mermaid` | Compile Mermaid diagram |
| `plt_diagram_compile_graphviz` | Compile Graphviz diagram |
| `plt_diagram_list_presets` | List diagram presets |
| `plt_line`, `plt_scatter`, `plt_bar`, ... | Per-type plot tools |

## CLI Summary

```bash
figrecipe plot spec.yaml           # Create from spec
figrecipe reproduce recipe.yaml    # Reproduce figure
figrecipe compose a.yaml b.yaml -o out.png  # Compose panels
figrecipe crop figure.png          # Crop whitespace
figrecipe validate recipe.yaml     # Check reproducibility
figrecipe gui recipe.yaml          # Launch GUI editor
figrecipe style list               # List style presets
figrecipe diagram render flow.mmd  # Render diagram
figrecipe mcp start                # Start MCP server
```
