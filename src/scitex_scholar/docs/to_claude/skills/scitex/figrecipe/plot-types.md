---
description: All plot types supported in figrecipe declarative specs and MCP tools, with usage guidance.
---

# Plot Types Reference

## Using plot types

### Via Python API (direct)

```python
fig, ax = fr.subplots()
ax.plot(x, y)           # any standard matplotlib method works
ax.scatter(x, y)
ax.bar(categories, values)
```

### Via declarative spec (plt_plot MCP tool or figrecipe plot CLI)

```yaml
figure:
  width_mm: 80
  height_mm: 60
  style: SCITEX
plots:
  - type: line
    x: [1, 2, 3, 4, 5]
    y: [1, 4, 9, 16, 25]
    color: blue
    label: "data"
xlabel: "X"
ylabel: "Y"
title: "My Plot"
```

## Line / Curve

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `line` | `plot` | Time series, trends |
| `plot` | `plot` | Same as line |
| `step` | `step` | Step functions, histograms |
| `fill` | `fill` | Filled polygon areas |
| `fill_between` | `fill_between` | Confidence bands, ranges |
| `fill_betweenx` | `fill_betweenx` | Horizontal confidence bands |
| `errorbar` | `errorbar` | Data with uncertainty |
| `loglog` | `loglog` | Both axes log-scale |
| `semilogx` | `semilogx` | X-axis log-scale |
| `semilogy` | `semilogy` | Y-axis log-scale |

## Scatter / Points

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `scatter` | `scatter` | Two continuous variables |
| `hexbin` | `hexbin` | Large scatter → density |

## Bar / Categorical

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `bar` | `bar` | Category comparison (vertical) |
| `barh` | `barh` | Category comparison (horizontal) |

## Distribution

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `hist` | `hist` | Single variable distribution |
| `hist2d` | `hist2d` | Joint distribution of two variables |
| `boxplot` / `box` | `boxplot` | Distribution comparison |
| `violinplot` / `violin` | `violinplot` | Distribution shape comparison |
| `ecdf` | `ecdf` | Empirical CDF |
| `stairs` | `stairs` | Step function / histogram |
| `stackplot` | `stackplot` | Cumulative stacked area |

## Image / Matrix

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `imshow` / `heatmap` | `imshow` | Images, heatmaps, 2D arrays |
| `matshow` | `matshow` | Matrix visualization |
| `pcolormesh` | `pcolormesh` | Non-uniform 2D grids |
| `pcolor` | `pcolor` | Non-uniform 2D grids (slower) |
| `contour` | `contour` | 2D scalar field contour lines |
| `contourf` | `contourf` | 2D scalar field filled contours |
| `spy` | `spy` | Sparse matrix sparsity pattern |

## Special

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `pie` | `pie` | Part-of-whole proportions |
| `stem` | `stem` | Discrete signals |
| `eventplot` | `eventplot` | Event sequences |

## Vector fields

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `quiver` | `quiver` | Arrow/vector fields |
| `streamplot` | `streamplot` | Flow streamlines |

## Correlation

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `acorr` | `acorr` | Autocorrelation |
| `xcorr` | `xcorr` | Cross-correlation |

## Spectral analysis

| Type | matplotlib method | Use when |
|------|-------------------|----------|
| `psd` | `psd` | Power spectral density |
| `csd` | `csd` | Cross spectral density |
| `specgram` | `specgram` | Spectrogram |
| `cohere` | `cohere` | Coherence between signals |
| `magnitude_spectrum` | `magnitude_spectrum` | Frequency magnitude |
| `phase_spectrum` | `phase_spectrum` | Frequency phase |
| `angle_spectrum` | `angle_spectrum` | Angle spectrum |

## SciTeX scientific plots

These are provided by the scitex/figrecipe scientific plot library. Available as `stx_*` or `fr_*` prefix.

| Type | MCP tool | Use when |
|------|----------|----------|
| `stx_line` | `plt_stx_line` | Styled line plot |
| `stx_shaded_line` | `plt_stx_shaded_line` | Line with shaded error band |
| `stx_mean_std` | `plt_stx_mean_std` | Mean ± standard deviation |
| `stx_mean_ci` | `plt_stx_mean_ci` | Mean with confidence interval |
| `stx_median_iqr` | `plt_stx_median_iqr` | Median with IQR |
| `stx_violin` | `plt_stx_violin` | Violin with individual points |
| `stx_scatter_hist` | `plt_stx_scatter_hist` | Scatter with marginal histograms |
| `stx_heatmap` | `plt_stx_heatmap` | Annotated heatmap |
| `stx_conf_mat` | `plt_stx_conf_mat` | Confusion matrix |
| `stx_raster` | `plt_stx_raster` | Spike raster plot |
| `stx_ecdf` | `plt_stx_ecdf` | Empirical CDF (styled) |
| `stx_fillv` | `plt_stx_fillv` | Vertical fill regions |
| `stx_image` | `plt_stx_image` | Image with scale bar |
| `stx_rectangle` | `plt_stx_rectangle` | Annotated rectangle regions |

## CSV column data in specs

Instead of inline arrays, reference columns from a CSV file:

```yaml
plots:
  - type: scatter
    data_file: experiment.csv  # path to CSV
    x: time                    # column name
    y: temperature             # column name
    color: red
```

## Choosing the right plot

| Goal | Recommended types |
|------|------------------|
| Show one variable distribution | `hist`, `ecdf`, `boxplot`, `violinplot` |
| Compare two continuous variables | `scatter`, `line`, `hexbin` |
| Compare groups/categories | `bar`, `barh`, `boxplot`, `violinplot` |
| Show time series | `line`, `fill_between`, `stackplot` |
| Show 2D field data | `contour`, `contourf`, `pcolormesh`, `imshow` |
| Statistical summary with error | `stx_mean_ci`, `stx_mean_std`, `stx_median_iqr` |
| Neuroscience / EEG | `stx_raster`, `specgram`, `psd`, `cohere` |
| Confusion matrix / classification | `stx_conf_mat`, `stx_heatmap` |
