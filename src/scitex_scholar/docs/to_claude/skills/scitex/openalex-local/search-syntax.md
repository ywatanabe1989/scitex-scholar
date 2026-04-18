---
description: FTS5 full-text search syntax — operators, phrases, filters.
---

# Search Syntax

Uses SQLite FTS5 for full-text search across 284M+ works.

```python
# Simple terms
search("neural network")

# Phrase match
search('"deep learning"')

# Boolean operators
search("EEG AND epilepsy")
search("fMRI OR PET")
search("CRISPR NOT bacteria")

# Prefix search
search("neuro*")
```

## Async API

```python
from openalex_local import aio

async def main():
    results = await aio.search("machine learning")
    counts = await aio.count_many(["CRISPR", "neural network"])
```

## Caching

```python
from openalex_local import cache
# Cache search results for repeated queries
cached = cache.search("frequently searched term")
```
