---
description: Core save/load API with two-tier format registry and custom format registration.
---

# Save and Load

## save()

```python
def save(
    obj,
    specified_path,
    makedirs=True,
    verbose=True,
    symlink_from_cwd=False,
    symlink_to=None,
    dry_run=False,
    no_csv=False,
    use_caller_path=False,
    **kwargs,
) -> Path:
```

- Format auto-detected from extension
- `makedirs=True` creates parent directories
- Returns `Path` to saved file, or `False` on error

### Auto path routing

When `specified_path` is relative, the output directory is auto-determined:

| Context | Output directory | Example |
|---------|-----------------|---------|
| Script `analysis.py` | `analysis_out/{path}` | `analysis_out/results.csv` |
| Notebook `exp.ipynb` | `exp_out/{path}` | `exp_out/fig.png` |
| Interactive/IPython | `/tmp/{USER}/{path}` | `/tmp/ywatanabe/data.csv` |
| Absolute path | Used as-is | `/data/output/results.csv` |

```python
# In script ~/proj/scripts/analysis.py:
sio.save(df, "results.csv")
# → ~/proj/scripts/analysis_out/results.csv

# Absolute path bypasses routing:
sio.save(df, "/data/shared/results.csv")
# → /data/shared/results.csv
```

### use_caller_path

By default, `save()` uses the **immediate caller's** filename (`inspect.stack()[1]`) for path routing. This fails when `save()` is called from a library wrapper — the path resolves to the wrapper's location, not the user's script.

`use_caller_path=True` walks up the call stack, skipping all frames inside the scitex source tree, and uses the **first external frame** as the script path.

```python
# WITHOUT use_caller_path — wrapper pollutes path routing:
# File: ~/proj/mylib/helpers.py
def save_results(df):
    sio.save(df, "results.csv")
    # → ~/proj/mylib/helpers_out/results.csv  (WRONG — resolves to wrapper location)

# WITH use_caller_path — resolves to actual user script:
# File: ~/proj/mylib/helpers.py
def save_results(df):
    sio.save(df, "results.csv", use_caller_path=True)
    # → ~/proj/scripts/analysis_out/results.csv  (CORRECT — resolves to calling script)
```

This is essential for `stx.io.save()` inside the scitex framework, where `save()` is wrapped by `scitex.io.save()`. Without it, all saves would route to the scitex package directory.

### symlink_from_cwd

After saving to the auto-routed path, creates a **symlink from your current working directory** back to the saved file. Useful when you want quick access from cwd.

```python
# cwd: ~/proj/
# Script: ~/proj/scripts/analysis.py

sio.save(df, "results.csv", symlink_from_cwd=True)
# Saves to:    ~/proj/scripts/analysis_out/results.csv
# Symlinks:    ~/proj/results.csv → ~/proj/scripts/analysis_out/results.csv
```

### symlink_to

Creates a symlink at a **specific path** pointing to the saved file.

```python
sio.save(fig, "fig1.png", symlink_to="/data/latest/fig1.png")
# Saves to:    ~/proj/scripts/analysis_out/fig1.png
# Symlinks:    /data/latest/fig1.png → ~/proj/scripts/analysis_out/fig1.png

# Combine both:
sio.save(df, "results.csv", symlink_from_cwd=True, symlink_to="/shared/results.csv")
# Saves to:    ~/proj/scripts/analysis_out/results.csv
# Symlinks:    ~/proj/results.csv → (saved file)
#              /shared/results.csv → (saved file)
```

### no_csv

Image saves (`.png`, `.jpg`, `.gif`, `.tiff`, `.tif`, `.svg`, `.pdf`) auto-export a companion `.csv` with the figure's plotted data. Disable with `no_csv=True`.

```python
sio.save(fig, "plot.png")              # → plot.png + plot.csv
sio.save(fig, "plot.png", no_csv=True) # → plot.png only
```

### dry_run

Simulates the save without writing any files. Prints the resolved path.

```python
sio.save(df, "results.csv", dry_run=True)
# Prints: (dry run) Saved to: ./scripts/analysis_out/results.csv
```

### f-string paths

Paths starting with `f"` or `f'` are evaluated with the caller's variables:

```python
epoch = 10
sio.save(model, f'f"model_epoch_{epoch}.pt"')
# → analysis_out/model_epoch_10.pt
```

## load()

```python
def load(
    lpath,
    ext=None,
    show=False,
    verbose=False,
    cache=True,
    **kwargs,
) -> Any:
```

- Glob patterns (`*`, `?`, `[`) load all matches as list
- `ext=` overrides extension detection
- `cache=True` (default) caches by path + mtime
- Symlinks resolved automatically

```python
df = sio.load("data.csv")              # single file
dfs = sio.load("results/*.csv")        # glob → list
arr = sio.load("data.h5", key="/grp")  # HDF5 with key
```

## Two-tier registry

```python
from scitex_io import register_saver, register_loader

# Decorator form
@register_saver(".custom")
def save_custom(obj, path, **kwargs):
    ...

@register_loader(".custom")
def load_custom(path, **kwargs):
    ...

# Direct form
register_saver(".custom", my_fn)
register_loader(".custom", my_fn)
```

- **Built-in** handlers: registered at import (lower priority)
- **User** handlers: override built-ins (higher priority)
- `unregister_saver(ext)` / `unregister_loader(ext)` to remove
- `list_formats()` shows both tiers
