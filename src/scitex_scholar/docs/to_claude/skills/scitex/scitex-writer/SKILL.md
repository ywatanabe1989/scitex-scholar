---
description: LaTeX manuscript compilation with bibliography, figures, tables, claims tracking, and journal guideline enforcement.
allowed-tools: mcp__scitex__writer_*
---

# scitex-writer

## Installation

```bash
pip install scitex-writer
# Development:
pip install -e /home/ywatanabe/proj/scitex-writer
```

LaTeX manuscript compilation framework for scientific papers. Compiles manuscripts, supplementary materials, and revision documents with tracked changes. Manages bibliography (BibTeX merge, DOI dedup, enrichment), figures/tables (auto-discovery from `caption_and_media/`, CSV-to-LaTeX conversion), and verifiable claims linked to session hashes via `sw.claim.add()`.

## Sub-skills

### Manuscript Management

| Skill | Description |
|-------|-------------|
| [quick-start.md](quick-start.md) | Basic workflow: create project, add content, compile PDF |
| [compilation.md](compilation.md) | Compile manuscript/supplementary/revision; clean compile after bib changes; env vars (dark mode, draft mode) |
| [bibliography.md](bibliography.md) | BibTeX management: add, list, merge, enrich; DOI dedup; clean aux for resolution |
| [figures-and-tables.md](figures-and-tables.md) | Figure/table lifecycle: add, remove (must move ALL files from caption_and_media/), move to supplementary |
| [claims.md](claims.md) | Verifiable claims: `sw.claim.add()` with session ID + output hash; render via `\vclaim{}` |
| [cli-reference.md](cli-reference.md) | CLI commands reference |
| [mcp-tools.md](mcp-tools.md) | MCP tools for AI agents |

### Scientific Writing Guidelines

| Skill | Description |
|-------|-------------|
| [writing-attitude.md](writing-attitude.md) | Evidence requirements, critical analysis, scientific standards |
| [writing-figures-stats.md](writing-figures-stats.md) | Figure rules (axes, ranges, labels), statistical reporting (effect sizes, FDR correction) |
| [writing-proofreading.md](writing-proofreading.md) | Language rules, formatting, common corrections, anti-patterns (AP1-AP9), tone, hedging, transitions, terminology |
| [writing-abstract.md](writing-abstract.md) | 7-section structure: intro, background, problem, main result, comparisons, context, perspective |
| [writing-introduction.md](writing-introduction.md) | 8-section structure: opening, importance, knowledge/gaps, limitations, hypothesis, methods, results, significance |
| [writing-methods.md](writing-methods.md) | Reproducibility-focused; passive voice; procedures others can replicate |
| [writing-discussion.md](writing-discussion.md) | 5-section structure: key findings, comparison, supporting evidence, limitations, implications |
| [writing-mermaid.md](writing-mermaid.md) | Academic mermaid diagram style guide |
| [audit-paper.md](audit-paper.md) | Pre-submission audit: number consistency, citation verification, figure-text alignment |

## Key Patterns

**Figure removal**: The compile script auto-discovers `.tex` files from `caption_and_media/`. To remove a figure, move ALL files (`.tex`, `.jpg`, `.png`, `.mmd`) to `legacy/`, including `jpg_for_compilation/` and `mermaid_originals/` subdirectories. See [figures-and-tables.md](figures-and-tables.md).

**Bibliography clean compile**: After adding/removing BibTeX entries, run `rm -f logs/manuscript.{aux,bbl,blg}` before recompile. See [compilation.md](compilation.md).

**Claims as first-class objects**: Every manuscript claim (statistic, figure, table) can be tied to a session hash, enabling Clew backward verification from manuscript to source data.

## MCP Tools

| Tool | Description |
|------|-------------|
| `writer_compile_manuscript` | Compile LaTeX manuscript to PDF |
| `writer_compile_content` | Compile content sections |
| `writer_compile_supplementary` | Compile supplementary materials |
| `writer_compile_revision` | Compile revision with tracked changes |
| `writer_add_figure` | Add figure to manuscript |
| `writer_add_table` | Add table to manuscript |
| `writer_add_bibentry` | Add bibliography entry |
| `writer_add_claim` | Add verifiable claim |
| `writer_render_claims` | Render claims to LaTeX |
| `writer_export_manuscript` | Export for submission |
| `writer_export_overleaf` | Export to Overleaf format |
