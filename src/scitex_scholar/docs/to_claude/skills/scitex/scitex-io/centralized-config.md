---
description: load_configs() loads YAML config directory into DotDict with dot-access and DEBUG_ override.
---

# Centralized Config

## load_configs()

```python
def load_configs(
    IS_DEBUG=None,
    show=False,
    verbose=False,
    config_dir=None,   # defaults to "./config"
) -> DotDict:
```

### Directory layout

```
project/
  config/
    PATHS.yaml          # DATA_DIR: /data/experiment_01
    PREPROCESS.yaml     # SAMPLE_RATE: 1000, BANDPASS: [0.5, 40]
    MODEL.yaml          # HIDDEN_DIM: 256, DROPOUT: 0.3
    PLOT.yaml           # FIGSIZE: [180, 60], DPI: 300
    IS_DEBUG.yaml       # IS_DEBUG: true
    categories/         # Optional subdirectory (also loaded)
```

- Each YAML filename becomes a namespace: `CONFIG.MODEL.HIDDEN_DIM`
- Use **UPPER_CASE** keys — Python's convention for constants
- Also loads from `config_dir/categories/` if it exists

### DEBUG_ prefix override

```python
# MODEL.yaml: { HIDDEN_DIM: 256, DEBUG_HIDDEN_DIM: 32 }
CONFIG = load_configs(IS_DEBUG=True)
CONFIG.MODEL.HIDDEN_DIM  # → 32 (DEBUG_ prefix stripped, value promoted)
```

If `IS_DEBUG=None`: reads from `IS_DEBUG.yaml` or `CI` env var.

## DotDict

```python
cfg = DotDict({"database": {"host": "localhost", "port": 5432}})
cfg.database.host          # "localhost" — attribute access
cfg["database"]["port"]    # 5432 — item access
cfg.database.host = "x"   # assignment works both ways
cfg.to_dict()              # convert back to plain dict
```

Nested dicts auto-wrapped. Supports `keys()`, `values()`, `items()`, `get()`, `copy()`, `update()`, `in`.
