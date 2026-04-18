---
description: Load caching with mtime invalidation, reload, flush, and configuration.
---

# Cache

`sio.load()` caches by default (`cache=True`). Invalidation uses file mtime + size.

## Usage

```python
import scitex_io as sio

data = sio.load("data.csv")          # cached
data = sio.load("data.csv")          # cache hit (fast)
data = sio.reload("data.csv")        # force re-read (bypass cache, same as load with cache=False)
sio.flush()                           # clear all caches (alias: clear_load_cache)
```

## Configuration

```python
sio.configure_cache(
    enabled=True,       # enable/disable caching
    max_size=32,        # max entries (FIFO eviction)
    verbose=False,      # log cache hits
)

info = sio.get_cache_info()
# → {"stats": {"hits": 5, "misses": 2, "evictions": 0},
#    "config": {"enabled": True, "max_size": 32, "verbose": False},
#    "metadata_size": 2, "data_size": 2}
```

## Implementation details

- Weakref cache for non-numpy objects (auto GC)
- LRU cache (maxsize=16) for numpy arrays
- Metadata cache tracks `(abs_path, mtime, size)` for invalidation
- `.npy`/`.npz` use dedicated `load_npy_cached()` path

## Low-level cache()

```python
from scitex_io import cache

# Stores/retrieves variables by ID in ~/.cache/
result = cache("my_experiment", "var1", "var2")
```

Pickle-based. Saves if variables exist in caller scope; loads from cache if not.
