---
name: neurovista-reporting
description: Neurovista PAC analysis report generation — PDF creation, email delivery, and GitHub issue tracking.
---

# Neurovista Report Generation

## File Naming
Always use timestamped filenames: `neurovista-report-YYYYMMDD-HHmmss.pdf`
Save to: `~/proj/neurovista/reports/` on Spartan.

## Report Structure
1. Title page with timestamp and dataset summary
2. Executive summary — key findings in bullet points
3. Methods — dataset, PAC computation, statistical tests, corrections, effect sizes
4. Results: Bimodality Coefficient — ALL per-patient effect size + spatial plots with numbered captions
5. Results: PAC Z-Mean — ALL per-patient effect size + spatial plots with numbered captions
6. Correction comparison table (uncorrected vs FDR vs Bonferroni)
7. Per-patient summary table (patient_id, significant channels, max |g|)
8. Pipeline status (PAC chain, power spectrum, disk usage)

Every figure must have a numbered caption (Figure 1, Figure 2, ...) with explanation.

## PDF Bookmarks (Required)
Every PDF report MUST include navigable bookmarks for each section. Use `matplotlib.backends.backend_pdf.PdfPages` metadata or `fpdf2`:

```python
# With fpdf2 (preferred for bookmarks)
from fpdf import FPDF

pdf = FPDF()
pdf.set_auto_page_break(auto=True, margin=15)

# Add bookmarks for each section
pdf.add_page()
pdf.start_section("Executive Summary", level=0)

pdf.add_page()
pdf.start_section("Methods", level=0)

pdf.add_page()
pdf.start_section("Results: Bimodality Coefficient", level=0)
pdf.start_section("Patient P01", level=1)  # Sub-bookmark
```

If using `matplotlib PdfPages`, add bookmarks post-hoc with `pikepdf`:
```python
import pikepdf
with pikepdf.open('report.pdf') as pdf:
    with pdf.open_outline() as outline:
        outline.root.extend([
            pikepdf.OutlineItem("Executive Summary", 0),
            pikepdf.OutlineItem("Methods", 1),
            pikepdf.OutlineItem("Bimodality Results", 2),
        ])
    pdf.save('report-bookmarked.pdf')
```

## Scientific Figure Rules
- Shared axes MUST be aligned: use `sharex=True` or `sharey=True` in `plt.subplots()`
- Seizure vs control comparison: same axis range, side-by-side, with `sharex=True, sharey=True`
- Remove redundant axis labels on upper/inner panels — only label outer edges
- Compact layout: 2-4 figures per page in grid, not one per page
- Preserve original aspect ratios (read dimensions with PIL first)
- Use `fig.align_ylabels()` and `fig.align_xlabels()` for clean alignment

## Data Sources
- CSV: `~/proj/neurovista/.data/spartan/pac/channel_frequency_analysis/seizure_vs_control_effect_size_fdr.csv`
- Plots: `~/proj/neurovista/.data/spartan/pac/channel_frequency_analysis/*.png`
- Always check for new results before generating (compare FINISHED_SUCCESS counts)

## Generation
Use Python with `fpdf2` or `reportlab`. If neither installed, use `matplotlib.backends.backend_pdf.PdfPages`.

CRITICAL: Preserve original aspect ratio of all figures. Never stretch or distort.

```python
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
from PIL import Image

PAGE_WIDTH = 10  # inches

with PdfPages('neurovista-report-TIMESTAMP.pdf') as pdf:
    for i, png in enumerate(sorted(glob.glob('*.png')), 1):
        # Preserve aspect ratio
        img_pil = Image.open(png)
        w, h = img_pil.size
        ratio = h / w
        fig_height = PAGE_WIDTH * ratio

        fig, ax = plt.subplots(figsize=(PAGE_WIDTH, fig_height))
        img = mpimg.imread(png)
        ax.imshow(img)
        ax.set_title(f'Figure {i}: {caption}', fontsize=12, pad=10)
        ax.axis('off')
        fig.tight_layout()
        pdf.savefig(fig, dpi=100)  # Keep under 10MB
        plt.close(fig)
```

## PDF Size Management
Target: under 10MB for email. If PDF exceeds 10MB:
1. Reduce image DPI: `fig.savefig(..., dpi=100)` instead of default
2. Or compress: `gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -o output.pdf input.pdf`
3. Or split into parts if still too large

## Email Rules
Every email MUST include:
1. **PDF attachment** (the report itself, not just PNGs)
2. **GitHub Issue URL** in the body: `https://github.com/ywatanabe1989/todo/issues/98`
3. **Summary** of key findings in the email body
4. **Timestamp** in subject line
5. **File path on Spartan** for reference

Email subject format: `[Neurovista] PAC Report YYYY-MM-DD — Key Finding Summary`

```python
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

msg = MIMEMultipart()
msg['Subject'] = f'[Neurovista] PAC Report {date} — {n_sig} seizure-specific channels'
body = f"""Neurovista PAC Analysis Report

GitHub Issue: https://github.com/ywatanabe1989/todo/issues/98

Key findings: ...

Report on Spartan: ~/proj/neurovista/reports/{filename}
"""
msg.attach(MIMEText(body, 'plain'))
# Attach PDF (check size < 10MB first)
# ...
with smtplib.SMTP('localhost', 25) as server:
    server.sendmail(from_addr, 'yusuke.watanabe@unimelb.edu.au', msg.as_string())
```

## Tracking
After delivery, comment on the relevant GitHub issue:
```bash
gh issue comment 98 --repo ywatanabe1989/todo --body "Report delivered: neurovista-report-TIMESTAMP.pdf
Path: ~/proj/neurovista/reports/neurovista-report-TIMESTAMP.pdf
Size: XMB
Email: sent/failed (reason)"
```
