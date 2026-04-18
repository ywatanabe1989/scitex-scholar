---
description: Convention — plotting functions must return fig for composability and external save/show handling.
---

# Return Fig Convention

Plotting functions should `return fig` for consistency. Save and show can be handled outside of plotting functions.

```python
def plot_xxx(...):
    fig, ax = fr.subplots(w_mm=85, h_mm=60)
    ax.plot(x, y)
    return fig

def main(args):
    fig = plot_xxx(...)
    fr.save(fig, "output.png")
```
