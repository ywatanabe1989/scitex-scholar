---
description: Figure style presets — loading, applying, and customizing SCITEX/MATPLOTLIB styles and dark themes.
---

# Styles

## fr.load_style()

```python
def load_style(
    style="SCITEX",      # preset name, path to YAML, None/False to unload
    dark=False,          # apply dark theme transformation
    background=None,     # override background: "white", "transparent", etc.
) -> DotDict | None
```

After calling `load_style()`, subsequent `fr.subplots()` calls automatically use the loaded style.

## Built-in presets

| Preset | Description |
|--------|-------------|
| `"SCITEX"` / `"FIGRECIPE"` | Scientific publication style (default) |
| `"SCITEX_DARK"` / `"FIGRECIPE_DARK"` | Dark variant |
| `"MATPLOTLIB"` | Vanilla matplotlib defaults |

```python
import figrecipe as fr

# Scientific publication style (default)
fr.load_style()
fr.load_style("SCITEX")  # explicit

# Dark theme
fr.load_style("SCITEX_DARK")
fr.load_style("SCITEX", dark=True)  # equivalent

# Opaque white background (default is transparent)
fr.load_style("SCITEX", background="white")

# Vanilla matplotlib
fr.load_style("MATPLOTLIB")
fr.load_style(None)   # unload (same as MATPLOTLIB)
fr.load_style(False)  # unload
```

## fr.unload_style()

```python
fr.unload_style()
# Resets to matplotlib defaults; next subplots() is unstyled
```

## fr.list_presets()

```python
presets = fr.list_presets()
# Returns list of available preset names
```

## CLI: figrecipe style

```bash
figrecipe style list              # list all presets
figrecipe style show SCITEX       # show SCITEX style details
figrecipe style apply SCITEX      # apply style globally
figrecipe style reset             # reset to matplotlib defaults
```

## MCP: plt_list_styles

```python
result = plt_list_styles()
# result: {"presets": ["SCITEX", "SCITEX_DARK", "MATPLOTLIB", ...], "count": N}
```

## Custom style from YAML

```python
fr.load_style("/path/to/my_style.yaml")
```

## Accessing style values

```python
style = fr.load_style("SCITEX")
style.axes.width_mm   # 40 (default axes width)
style.axes.height_mm
style.fonts.size
```

## Style in declarative spec

```yaml
figure:
  width_mm: 80
  height_mm: 60
  style: SCITEX          # applied before plotting
  facecolor: white       # optional opaque background
```
