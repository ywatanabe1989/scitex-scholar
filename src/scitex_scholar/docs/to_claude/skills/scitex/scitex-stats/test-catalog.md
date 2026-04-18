---
description: All 23 statistical tests organized by category — parametric, nonparametric, correlation, categorical, normality.
---

# Test Catalog (23 Tests)

## Parametric (6)

| Function | Use Case |
|----------|----------|
| `test_ttest_ind` | Independent two-sample t-test |
| `test_ttest_rel` | Paired/related samples t-test |
| `test_ttest_1samp` | One-sample t-test vs. population mean |
| `test_anova` | One-way ANOVA (3+ groups) |
| `test_anova_rm` | Repeated-measures ANOVA |
| `test_anova_2way` | Two-way ANOVA |

## Nonparametric (5)

| Function | Use Case |
|----------|----------|
| `test_brunner_munzel` | Two independent samples (no equal variance assumption) |
| `test_wilcoxon` | Paired samples (signed-rank) |
| `test_kruskal` | 3+ independent groups (Kruskal-Wallis) |
| `test_mannwhitneyu` | Two independent samples (rank-based) |
| `test_friedman` | 3+ related groups (Friedman) |

## Correlation (4)

| Function | Use Case |
|----------|----------|
| `test_pearson` | Linear correlation (parametric) |
| `test_spearman` | Monotonic correlation (rank-based) |
| `test_kendall` | Ordinal association (Kendall's tau) |
| `test_theilsen` | Robust linear regression (Theil-Sen) |

## Categorical (4)

| Function | Use Case |
|----------|----------|
| `test_chi2` | Chi-squared test of independence |
| `test_fisher` | Fisher's exact test (small samples) |
| `test_mcnemar` | McNemar's test (paired categorical) |
| `test_cochran_q` | Cochran's Q test (3+ related binary) |

## Normality (4)

| Function | Use Case |
|----------|----------|
| `test_shapiro` | Shapiro-Wilk normality test |
| `test_normality` | Combined normality assessment |
| `test_ks_1samp` | Kolmogorov-Smirnov (one-sample) |
| `test_ks_2samp` | Kolmogorov-Smirnov (two-sample) |

## Dispatcher Aliases

The `run_test()` dispatcher accepts aliases:

| Alias | Maps to |
|-------|---------|
| `"ttest"` | `test_ttest_ind` |
| `"ttest_ind"` | `test_ttest_ind` |
| `"ttest_paired"` | `test_ttest_rel` |
| `"mann_whitney"` | `test_mannwhitneyu` |
| `"brunnermunzel"` | `test_brunner_munzel` |
