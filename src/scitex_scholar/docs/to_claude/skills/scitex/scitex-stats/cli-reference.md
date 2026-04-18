---
description: CLI commands for scitex-stats — run tests, recommend, describe, power analysis from the terminal.
---

# CLI Reference

```bash
# Entry point
scitex-stats <command> [options]

# Run a test
scitex-stats run ttest_ind --data1 group1.csv --data2 group2.csv
scitex-stats run anova --data groups.csv

# Recommend tests
scitex-stats recommend --data1 group1.csv --data2 group2.csv

# Descriptive statistics
scitex-stats describe --data data.csv

# MCP server
scitex-stats mcp start              # stdio transport (Claude Desktop)
scitex-stats mcp start -t http      # HTTP transport
scitex-stats mcp doctor             # Diagnose MCP setup
scitex-stats mcp list-tools -vv     # List tools with descriptions

# Skills
scitex-stats skills list
scitex-stats skills get

# Documentation
scitex-stats docs list
scitex-stats docs get quickstart

# Browse API
scitex-stats list-python-apis -v
```
