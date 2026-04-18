---
description: Publication-ready statistical testing — 23 tests, effect sizes, power analysis, auto test selection, and MCP tools for AI agents.
allowed-tools: mcp__scitex__stats_*
---

# scitex-stats

Publication-ready statistical testing framework with 23 tests, effect sizes, power analysis, and automatic test recommendation.

## Sub-skills

- [quick-start.md](quick-start.md) — Basic usage and core patterns
- [test-catalog.md](test-catalog.md) — All 23 statistical tests with categories
- [effect-sizes.md](effect-sizes.md) — Effect size measures and interpretation
- [workflows.md](workflows.md) — Common analysis patterns
- [cli-reference.md](cli-reference.md) — CLI commands
- [mcp-tools.md](mcp-tools.md) — MCP tools for AI agents

## CLI

```bash
scitex-stats <command> [options]
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `stats_run_test` | Run a statistical test |
| `stats_recommend_tests` | Auto-recommend tests for data |
| `stats_describe` | Descriptive statistics |
| `stats_effect_size` | Compute effect sizes |
| `stats_correct_pvalues` | Multiple comparison correction |
| `stats_posthoc_test` | Post-hoc pairwise tests |
| `stats_power_analysis` | Power analysis / sample size |
| `stats_normality_test` | Normality testing |
| `stats_format_results` | Format for publication |
| `stats_p_to_stars` | p-value to significance stars |
