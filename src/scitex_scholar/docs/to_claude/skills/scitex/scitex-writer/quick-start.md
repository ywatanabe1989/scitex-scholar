---
description: Basic manuscript workflow — create project, add content, compile PDF.
---

# Quick Start

```python
import scitex_writer as sw

# Create or open a project
writer = sw.Writer("/path/to/project")

# Compile manuscript to PDF
result = writer.compile_manuscript()
# result.pdf_path → Path to generated PDF

# Compile supplementary
result = writer.compile_supplementary()

# Compile revision with tracked changes
result = writer.compile_revision()

# Get compiled PDF
pdf = writer.get_pdf("manuscript")

# Ensure workspace structure
sw.ensure_workspace("/path/to/project", git_strategy="child")
```

## Key Classes

- `Writer` — Main class for manuscript operations
- `CompilationResult` — Result of compilation (pdf_path, log, success)
- `ManuscriptTree` — Manuscript directory structure
- `RevisionTree` — Revision directory structure
- `SupplementaryTree` — Supplementary materials structure
