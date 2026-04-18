---
name: manuscript-workflow
description: Complete manuscript workflow from project creation to submission.
---

# Manuscript Workflow

## 1. Create Project
```bash
scitex template clone-template research-paper ./my-paper/
```

## 2. Write Sections
Edit LaTeX files in `sections/`: abstract, introduction, methods, results, discussion.

## 3. Add Figures
```bash
scitex-writer figures add ./my-paper/ fig.png --caption "Results" --label fig:results
```

## 4. Add Tables
```bash
scitex-writer tables add ./my-paper/ data.csv --caption "Summary" --label tab:summary
```

## 5. Manage Bibliography
```bash
scitex-writer bib add ./my-paper/ --doi 10.1038/s41586-024-00001-1
scitex-writer bib enrich ./my-paper/references.bib
```

## 6. Track Claims
Link claims to computational evidence for reproducibility.

## 7. Check Guidelines
```bash
scitex-writer guidelines get nature
```

## 8. Compile
```bash
scitex-writer compile manuscript ./my-paper/
scitex-writer compile supplementary ./my-paper/
scitex-writer compile revision ./my-paper/
```

## 9. Export
```bash
scitex-writer export overleaf ./my-paper/ -o overleaf/
scitex-writer export manuscript ./my-paper/ -o submission/
```

## Directory Structure
```
my-paper/
├── main.tex
├── sections/{abstract,introduction,methods,results,discussion}.tex
├── figures/
├── tables/
├── references.bib
├── claims.yaml
└── project.yaml
```
