---
description: Common statistical analysis workflows — group comparisons, correlations, normality, post-hoc, power.
---

# Common Workflows

## "Compare two groups"

```python
import scitex_stats as ss

# Auto-recommend the right test
recs = ss.recommend_tests(group1, group2)
# Uses normality check, sample size, paired/independent to suggest

# Then run it
result = ss.run_test("ttest_ind", group1, group2)
# result = {statistic, p_value, effect_size, ci, power, n1, n2, ...}
```

## "Compare multiple groups"

```python
result = ss.test_anova(group1, group2, group3)
# If significant, follow up with post-hoc:
from scitex_stats.posthoc import tukey_hsd, games_howell
posthoc = tukey_hsd(group1, group2, group3)
```

## "Check correlation"

```python
result = ss.test_pearson(x, y)    # parametric
result = ss.test_spearman(x, y)   # nonparametric
result = ss.test_kendall(x, y)    # ordinal
```

## "Correct for multiple comparisons"

```python
from scitex_stats.correct import bonferroni, fdr, holm

p_values = [0.01, 0.04, 0.03, 0.08]
corrected = fdr(p_values)             # Benjamini-Hochberg
corrected = bonferroni(p_values)      # Bonferroni
corrected = holm(p_values)            # Holm-Bonferroni
```

## "Check normality before choosing test"

```python
result = ss.test_shapiro(data)
result = ss.test_normality(data)   # combined normality check
result = ss.test_ks_1samp(data)    # Kolmogorov-Smirnov
```

## "Calculate power / sample size"

```python
from scitex_stats.power import power_analysis

result = power_analysis(
    test="ttest_ind",
    effect_size=0.5,    # Cohen's d
    alpha=0.05,
    power=0.8,
)
# result.n_per_group → required sample size
```

## "Format results for publication"

```python
result = ss.run_test("ttest_ind", g1, g2, return_as="latex")
# → "t(28) = 2.45, p = .021, d = 0.89"
```
