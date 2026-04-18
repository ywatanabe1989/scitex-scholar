---
description: Basic linter usage — check files, list rules.
---

# Quick Start

```python
from scitex_linter import list_rules

# List all available rules
rules = list_rules()
for r in rules:
    print(f"{r.id}: {r.description}")

# Filter by category
io_rules = list_rules(category="io")
stats_rules = list_rules(category="stats")
plot_rules = list_rules(category="plot")
```

```bash
# CLI
scitex-linter check src/
scitex-linter check src/my_script.py
scitex-linter list-rules
```
