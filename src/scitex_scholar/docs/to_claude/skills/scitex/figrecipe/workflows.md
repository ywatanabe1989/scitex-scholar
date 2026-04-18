---
description: Common figrecipe workflows — quick recipes for plots, multi-panel figures, diagrams, cropping, and data extraction.
---

# Common Workflows

### "I need a simple plot"

```python
fig, ax = fr.subplots(w_mm=85, h_mm=60)
ax.plot(x, y, label="data")
ax.set_xlabel("Time (s)")
ax.set_ylabel("Amplitude")
fr.save(fig, "plot.png")
```

### "I need a multi-panel figure"

```python
# From code
fig, axes = fr.subplots(nrows=2, ncols=3, w_mm=170, h_mm=120)
for ax, data in zip(axes.flat, datasets):
    ax.plot(data)
fr.save(fig, "panels.png")

# From existing images
fr.compose(
    ["a.png", "b.png", "c.png", "d.png"],
    ncols=2,
    labels=True,  # Auto a, b, c, d labels
    output="composed.png",
)
```

### "I need a diagram (not a data plot)"

```python
# Mermaid
diagram = fr.Diagram("graph LR; A-->B; B-->C")
diagram.render("flow.png")

# Graphviz
diagram = fr.Diagram("digraph { A -> B -> C }", backend="graphviz")
diagram.render("graph.png")
```

### "I need to crop whitespace"

```python
fr.crop("figure.pdf", output="figure_cropped.pdf", margins_mm=2)
```

### "I need to extract data from a figure"

```python
data = fr.extract_data("plot.png")
# Returns dict of extracted x, y arrays
```

## Detailed Sub-skills

- [quick-start.md](quick-start.md) — Core workflow: subplots, save, reproduce
- [plot-types.md](plot-types.md) — All plot types with examples
- [composition.md](composition.md) — Multi-panel figure composition
- [cropping.md](cropping.md) — Figure cropping
- [styles.md](styles.md) — Style presets
- [diagram.md](diagram.md) — Diagrams (Mermaid, Graphviz)
