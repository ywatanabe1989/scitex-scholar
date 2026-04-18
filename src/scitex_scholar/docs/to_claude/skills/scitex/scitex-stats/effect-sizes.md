---
description: Effect size measures — Cohen's d, Cliff's delta, eta squared, epsilon squared, probability of superiority.
---

# Effect Sizes

The `effect_sizes` submodule provides measures of practical significance.

## Available Measures

| Measure | Module | Use Case |
|---------|--------|----------|
| Cohen's d | `effect_sizes` | Standardized mean difference (parametric) |
| Cliff's delta | `effect_sizes` | Non-overlapping proportion (nonparametric) |
| Eta squared | `effect_sizes` | ANOVA effect size |
| Epsilon squared | `effect_sizes` | Kruskal-Wallis effect size |
| Probability of superiority | `effect_sizes` | P(X > Y) for two groups |

## Usage

```python
from scitex_stats import effect_sizes

# Cohen's d for two groups
d = effect_sizes.cohens_d(group1, group2)

# Cliff's delta (nonparametric alternative)
delta = effect_sizes.cliffs_delta(group1, group2)
```

## Interpretation Thresholds

| Measure | Small | Medium | Large |
|---------|-------|--------|-------|
| Cohen's d | 0.2 | 0.5 | 0.8 |
| Cliff's delta | 0.15 | 0.33 | 0.47 |
| Eta squared | 0.01 | 0.06 | 0.14 |
| Epsilon squared | 0.01 | 0.06 | 0.14 |

## Automatic Effect Size in run_test

When using `run_test()`, effect sizes are automatically computed and included in the result dict under the `effect_size` key.
