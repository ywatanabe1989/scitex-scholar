---
description: Supported data sources — OpenNeuro, DANDI, PhysioNet, local database.
---

# Data Sources

## OpenNeuro
```python
from scitex_dataset.neuroscience.openneuro import fetch_datasets, OPENNEURO_API
datasets = fetch_datasets(query="motor imagery")
```

## DANDI Archive
```python
from scitex_dataset.neuroscience import dandi
datasets = dandi.fetch(query="calcium imaging")
```

## PhysioNet
```python
from scitex_dataset.neuroscience import physionet
datasets = physionet.fetch(query="ECG arrhythmia")
```

## Local Database
```python
from scitex_dataset import database as db
db.build()                    # Build/update local DB
results = db.search("EEG")   # Search local cache
stats = db.stats()            # Database statistics
```
