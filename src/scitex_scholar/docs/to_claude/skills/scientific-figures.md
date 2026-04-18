---
name: scientific-figures
description: Scientific figure standards for publication-quality reports and papers. Axis alignment, color scales, layout, and comparison rules.
---

# Scientific Figure Standards

## Comparison Figures: Mandatory Rules

When comparing conditions (e.g., seizure vs control, pre vs post, treatment vs baseline):

1. **Same color scale**: Both plots MUST share identical vmin/vmax. Compute global min/max across both conditions first:
```python
vmin = min(data_seizure.min(), data_control.min())
vmax = max(data_seizure.max(), data_control.max())
# Use symmetric scale for diverging colormaps
vabs = max(abs(vmin), abs(vmax))
im1 = ax1.imshow(data_seizure, vmin=-vabs, vmax=vabs, cmap='RdBu_r')
im2 = ax2.imshow(data_control, vmin=-vabs, vmax=vabs, cmap='RdBu_r')
# Single shared colorbar
fig.colorbar(im1, ax=[ax1, ax2])
```

2. **Aligned axes**: Use `sharex=True, sharey=True` in `plt.subplots()`. Remove redundant tick labels on inner axes.

3. **Side-by-side layout**: Place conditions horizontally for direct visual comparison. Label clearly: "Seizure (Preictal)" vs "Control (Interictal)".

4. **Same axis range**: Both x and y axes must cover the same range even if one condition has less data.

## Multi-Panel Layout

For per-subject/per-patient reports:
- One subject per page with all conditions shown together
- Grid layout: 2x2 or 2x3 per page (NOT one figure per page)
- Keep total page count reasonable (target: 15-25 pages for 15 patients)

## Temporal Plots with Shared Time Axis

When stacking a heatmap above a time series (e.g., channel heatmap + averaged profile):
```python
fig, (ax_heat, ax_line) = plt.subplots(2, 1, sharex=True,
    gridspec_kw={'height_ratios': [3, 1]})
# Remove x-axis labels from heatmap, show only on line plot
ax_heat.tick_params(labelbottom=False)
```

## PDF Report Layout

- Use bookmarks for navigation (fpdf2 `start_section()` or pikepdf)
- Target under 10MB (use dpi=100-150, compress with ghostscript)
- Preserve original aspect ratios (read image dimensions before embedding)
- Every figure has a numbered caption with description
- Include page numbers

## Color Maps

- Diverging data (positive/negative): `RdBu_r` or `coolwarm`
- Sequential data (0 to max): `viridis` or `plasma`
- Never use `jet` (perceptually non-uniform)
- Always include colorbar with units
