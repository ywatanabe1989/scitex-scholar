---
description: MCP tools for AI agents — 10 statistical tools accessible via scitex MCP server.
---

# MCP Tools (for AI Agents)

All tools are prefixed `stats_` under the scitex MCP server.

| Tool | Purpose |
|------|---------|
| `stats_run_test` | Run any statistical test by name |
| `stats_recommend_tests` | Auto-recommend appropriate tests for given data |
| `stats_describe` | Compute descriptive statistics (mean, std, CI, etc.) |
| `stats_effect_size` | Calculate effect size between groups |
| `stats_correct_pvalues` | Apply multiple comparison correction |
| `stats_posthoc_test` | Run post-hoc pairwise comparisons |
| `stats_power_analysis` | Power analysis and sample size estimation |
| `stats_normality_test` | Test data for normality |
| `stats_format_results` | Format statistical results for publication |
| `stats_p_to_stars` | Convert p-value to significance stars |

## Handler Organization

MCP handlers are in `scitex_stats/_mcp/_handlers/`:
- `_run_test.py` — Main test dispatcher
- `_recommend.py` — Auto test recommendation
- `_descriptive.py` — Descriptive statistics
- `_effect_size.py` — Effect size computation
- `_corrections.py` — Multiple comparison correction
- `_posthoc.py` — Post-hoc tests
- `_power.py` — Power analysis
- `_normality.py` — Normality testing
- `_format.py` — Publication formatting
- `_stars.py` — p-to-stars conversion
