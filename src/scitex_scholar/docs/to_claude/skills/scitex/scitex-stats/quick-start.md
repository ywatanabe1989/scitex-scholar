---
description: Basic usage of scitex-stats — run_test, recommend_tests, describe, effect sizes.
---

# Quick Start

## Python API

```python
import scitex_stats as ss

# Run a t-test via unified dispatcher
result = ss.run_test("ttest_ind", group1, group2)
# Returns dict: statistic, p_value, effect_size, ci, power, n1, n2, ...

# Auto-recommend which test to use
recommendations = ss.recommend_tests(group1, group2)

# Descriptive statistics
desc = ss.describe(data)

# Individual test functions (23 available)
result = ss.test_ttest_ind(group1, group2)
result = ss.test_anova(group1, group2, group3)
result = ss.test_pearson(x, y)
result = ss.test_chi2(contingency_table)

# p-value to stars
stars = ss.p_to_stars(0.003)  # → "**"
```

## run_test() — Unified Dispatcher

```python
ss.run_test(
    test_name,       # str: test name or alias (e.g., "ttest_ind", "ttest", "anova")
    *groups,         # array-like: data groups
    alternative="two-sided",  # "two-sided", "less", "greater"
    return_as="dict",         # "dict", "dataframe", "latex", "json"
)
```

Aliases: `"ttest"` → `test_ttest_ind`, `"mann_whitney"` → `test_mannwhitneyu`, etc.

## return_as Formats

All public functions decorated with `@supports_return_as`:
- `"dict"` — Python dict (default)
- `"dataframe"` — pandas DataFrame
- `"latex"` — LaTeX-formatted string
- `"json"` — JSON-safe dict

## List Available Tests

```python
ss.available_tests()
# → ['test_anova', 'test_anova_2way', 'test_anova_rm', 'test_brunner_munzel',
#    'test_chi2', 'test_cochran_q', 'test_fisher', 'test_friedman',
#    'test_kendall', 'test_kruskal', 'test_ks_1samp', 'test_ks_2samp',
#    'test_mannwhitneyu', 'test_mcnemar', 'test_normality', 'test_pearson',
#    'test_shapiro', 'test_spearman', 'test_theilsen', 'test_ttest_1samp',
#    'test_ttest_ind', 'test_ttest_rel', 'test_wilcoxon']
```
