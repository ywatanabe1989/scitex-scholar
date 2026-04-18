---
description: Basic dataset search and fetch — OpenNeuro, DANDI, PhysioNet.
---

# Quick Start

```python
from scitex_dataset import search_datasets, fetch_datasets

# Search across all sources
results = search_datasets("EEG epilepsy")
for ds in results:
    print(f"{ds.id}: {ds.title}")

# Fetch from OpenNeuro
datasets = fetch_datasets(query="resting state EEG")

# Fetch all datasets (cached locally)
from scitex_dataset import fetch_all_datasets
all_ds = fetch_all_datasets()

# Sort results
from scitex_dataset import sort_datasets
sorted_ds = sort_datasets(results, by="downloads")
```
