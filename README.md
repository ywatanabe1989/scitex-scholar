# SciTeX Scholar (<code>scitex-scholar</code>)

<p align="center">
  <a href="https://scitex.ai">
    <img src="docs/scitex-logo-banner.png" alt="SciTeX Scholar" width="400">
  </a>
</p>

<p align="center"><b>Scientific paper search, enrichment, download, and management for reproducible research</b></p>

<p align="center">
  <a href="https://badge.fury.io/py/scitex-scholar"><img src="https://badge.fury.io/py/scitex-scholar.svg" alt="PyPI version"></a>
  <a href="https://scitex-scholar.readthedocs.io/"><img src="https://readthedocs.org/projects/scitex-scholar/badge/?version=latest" alt="Documentation"></a>
  <a href="https://github.com/ywatanabe1989/scitex-scholar/actions/workflows/test.yml"><img src="https://github.com/ywatanabe1989/scitex-scholar/actions/workflows/test.yml/badge.svg" alt="Tests"></a>
  <a href="https://www.gnu.org/licenses/agpl-3.0"><img src="https://img.shields.io/badge/License-AGPL--3.0-blue.svg" alt="License: AGPL-3.0"></a>
</p>

<p align="center">
  <a href="https://scitex-scholar.readthedocs.io/">Full Documentation</a> · <code>pip install scitex-scholar</code>
</p>

---

## Problem

Managing scientific literature programmatically requires juggling multiple tools and APIs: searching across databases, resolving DOIs, downloading PDFs through institutional access, enriching BibTeX metadata, and organizing everything in a reproducible structure. Each step involves different libraries, authentication flows, and data formats.

## Solution

scitex-scholar provides a unified interface for the full literature management workflow:

- **Search** across Google Scholar, Semantic Scholar, PubMed, and CrossRef
- **Enrich** BibTeX entries with abstracts, DOIs, citation counts, and impact factors
- **Download** PDFs through institutional access (OpenAthens) with browser automation
- **Organize** papers in a structured library with deduplication and metadata
- **Highlight** each sentence of a PDF by rhetorical role — claim, method, limitation, supportive citation, contradicting citation — via Claude

## Installation

```bash
pip install scitex-scholar
```

With optional dependencies:

```bash
pip install scitex-scholar[pdf]     # PDF parsing
pip install scitex-scholar[mcp]     # MCP server for AI agents
pip install scitex-scholar[all]     # Everything
```

## Usage

```python
from scitex_scholar import Scholar, Paper, Papers

# Search for papers
scholar = Scholar()
papers = scholar.search("deep learning EEG")

# Export as BibTeX
papers.save("results.bib")

# Enrich metadata
from scitex_scholar import to_bibtex, generate_cite_key
bibtex = to_bibtex(papers)
```

## Core API

| Class / Function | Purpose |
|-----------------|---------|
| `Scholar` | Main search and management interface |
| `Paper` | Single paper with metadata |
| `Papers` | Collection of papers with export methods |
| `ScholarConfig` | Configuration (paths, API keys) |
| `to_bibtex` | Export to BibTeX format |
| `generate_cite_key` | Generate citation keys |
| `apply_filters` | Filter paper collections |
| `pdf_highlight.highlight_pdf` | Overlay semantic highlights on a PDF |

## Semantic PDF Highlighting

Overlay colour-coded highlights on a PDF that separate what the paper **claims** from its
**methods**, **self-admitted limitations**, and stance toward related work. Highlights are
standard PDF annotation objects placed on a copy of the source — the original bytes are unchanged
and any viewer can show or strip them.

| colour | category | meaning |
|---|---|---|
| green | `focal_claim` | what the paper clarifies, suggests, demonstrates |
| purple | `focal_method` | novel method, model, cohort, or analysis |
| red | `focal_limitation` | self-admitted caveat or threat to validity |
| blue | `related_supportive` | prior work whose finding supports the paper |
| orange | `related_contradictive` | prior work whose finding contradicts the paper |

A compact colour legend + signature (model name, timestamp) is stamped in the lower-right corner
of the last page. See [docs](https://scitex-scholar.readthedocs.io/en/latest/semantic_highlight.html)
for full details.

```bash
export ANTHROPIC_API_KEY=sk-ant-...
scitex-scholar highlight paper.pdf            # sentence-level, Haiku, writes paper.highlighted.pdf
scitex-scholar highlight paper.pdf --stub     # offline keyword heuristic (no API calls)
```

```python
from scitex_scholar.pdf_highlight import highlight_pdf
result = highlight_pdf("paper.pdf", output_path="paper.highlighted.pdf")
print(result.counts(), result.annotations_added)
```

Also exposed as the `scholar_highlight_pdf` MCP tool (unified `scitex serve` server) and as the
`semantic-highlight` agent skill under `src/scitex_scholar/_skills/scitex-scholar/`.

## License

AGPL-3.0
