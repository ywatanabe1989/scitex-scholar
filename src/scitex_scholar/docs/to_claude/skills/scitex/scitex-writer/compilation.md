---
description: Compile manuscript, supplementary, and revision documents to PDF.
---

# Compilation

## CLI

```bash
./compile.sh manuscript --quiet    # Main manuscript
./compile.sh supplementary --quiet # Supplementary materials
./compile.sh revision --quiet      # Revision with tracked changes
```

## Python API

```python
writer = sw.Writer("/path/to/project")

# Main manuscript
result = writer.compile_manuscript()

# Supplementary materials
result = writer.compile_supplementary()

# Revision with tracked changes
result = writer.compile_revision()

# Get section content
content = writer.get_section("introduction")
content = writer.get_section("methods", doc_type="supplementary")

# Get PDF path
pdf = writer.get_pdf("manuscript")
```

## Clean Compile After Bibliography Changes

After adding/removing BibTeX entries, a clean compile is required:

```bash
# 1. Merge bibliography sources
python3 scripts/python/merge_bibliographies.py 00_shared/bib_files -o bibliography.bib --force

# 2. Clean auxiliary files (required for BibTeX to re-resolve)
rm -f 01_manuscript/logs/manuscript.{aux,bbl,blg}

# 3. Compile
./compile.sh manuscript --quiet

# 4. Verify
grep "Citation.*undefined" 01_manuscript/logs/manuscript.log | wc -l  # should be 0
```

If undefined citations persist after one compile, the BibTeX pass ordering may need a second clean compile.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SCITEX_WRITER_DARK_MODE` | `false` | Dark mode: black background, white text |
| `SCITEX_WRITER_DRAFT_MODE` | `false` | Draft watermark on pages |
| `SCITEX_WRITER_VERBOSE_BIBTEX` | `false` | Show BibTeX output |
| `SCITEX_WRITER_VERBOSE_PDFLATEX` | `false` | Show pdflatex output |

## Updating Downstream Projects

Sync a downstream project with the latest scitex-writer template:

```bash
scitex-writer update                    # update current directory
scitex-writer update ~/proj/my-paper    # update specific project
scitex-writer update --dry-run          # preview changes only
scitex-writer update --tag v2.8.0       # update to specific version
```

## SyncTeX Support

Compilation uses `-synctex=1` to generate `.synctex.gz` files alongside the PDF, enabling editor-PDF synchronization (forward lookup from `.tex` line to PDF position).

## Word Count

The compile output includes word counts with comma-separated formatting and per-section breakdown.

## Common Issues

**Figures still appearing after removal**: The compile script auto-discovers `.tex` files from `caption_and_media/`. Move ALL files (`.tex`, `.jpg`, `.png`, `.mmd`) to `legacy/`, including those in `jpg_for_compilation/` and `mermaid_originals/` subdirectories. See [figures-and-tables.md](figures-and-tables.md).

**Tables regenerating after removal**: Same issue — move source `.tex` and `.csv` files from `caption_and_media/` to `legacy/`.

**Dark mode when env says false**: Check that `SCITEX_WRITER_DARK_MODE=false` is exported in the shell environment, not just set in a config file.
