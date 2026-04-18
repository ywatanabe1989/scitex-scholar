---
description: Basic search and lookup — full-text search, DOI lookup, enrichment.
---

# Quick Start

```python
from openalex_local import search, get, count, get_many, exists, enrich_ids

# Full-text search
results = search("hippocampal sharp wave ripples")
for work in results:
    print(f"{work.title} ({work.year})")

# Get by OpenAlex ID
work = get("W2741809807")

# Count matches
n = count("machine learning")

# Check existence
exists("W2741809807")  # True/False

# Get multiple works
works = get_many(["W2741809807", "W2100837269"])

# Enrich IDs with full metadata
enriched = enrich_ids(["W2741809807"])

# Configure database mode
from openalex_local import configure, get_mode
configure(mode="local")  # or "api"
```
