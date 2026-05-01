# SciTeX Scholar (`scitex-scholar`)

<!-- scitex-badges:start -->
[![PyPI](https://img.shields.io/pypi/v/scitex-scholar.svg)](https://pypi.org/project/scitex-scholar/)
[![Python](https://img.shields.io/pypi/pyversions/scitex-scholar.svg)](https://pypi.org/project/scitex-scholar/)
[![Tests](https://github.com/ywatanabe1989/scitex-scholar/actions/workflows/test.yml/badge.svg)](https://github.com/ywatanabe1989/scitex-scholar/actions/workflows/test.yml)
[![Install Test](https://github.com/ywatanabe1989/scitex-scholar/actions/workflows/install-test.yml/badge.svg)](https://github.com/ywatanabe1989/scitex-scholar/actions/workflows/install-test.yml)
[![Coverage](https://codecov.io/gh/ywatanabe1989/scitex-scholar/graph/badge.svg)](https://codecov.io/gh/ywatanabe1989/scitex-scholar)
[![Docs](https://readthedocs.org/projects/scitex-scholar/badge/?version=latest)](https://scitex-scholar.readthedocs.io/en/latest/)
[![License: AGPL v3](https://img.shields.io/badge/license-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
<!-- scitex-badges:end -->

<p align="center"><b>Scientific paper search, enrichment, PDF download, and library management for reproducible research.</b></p>

<p align="center">
  <a href="https://scitex-scholar.readthedocs.io/">Full Documentation</a> · <code>pip install scitex-scholar</code>
</p>

---

## Problem and Solution


| # | Problem | Solution |
|---|---------|----------|
| 1 | **Literature search is balkanized** -- CrossRef / OpenAlex / Semantic Scholar / arXiv / PubMed each have different APIs, rate limits, auth | **Unified search** -- `scitex scholar search "topic"` federates across all, deduplicates by DOI, returns ranked results |
| 2 | **BibTeX from the wild is missing abstracts / DOIs / impact factors** -- manuscript prep wastes hours | **`scitex scholar bibtex` enrichment** -- one call resolves DOIs, fetches abstracts, adds impact factors, normalizes formatting |
| 3 | **Paywalled PDFs require institutional login per journal** -- manual login-download-rename is the bottleneck | **Browser-automation + OAuth** -- persistent Chrome profile with stealth; `scitex scholar fetch 10.1038/...` grabs the PDF end-to-end |

## Problem

Literature management spans many tools and APIs: searching databases, resolving DOIs, downloading PDFs through institutional access, enriching BibTeX metadata, and keeping a reproducible, deduplicated library. Each step speaks a different library, auth flow, and data format.

## Solution

`scitex-scholar` provides a unified workflow:

- **Search** across CrossRef, Semantic Scholar, PubMed, arXiv, and OpenAlex
- **Resolve** DOIs from titles; enrich BibTeX with abstracts, citation counts, impact factors (JCR 2024), PMIDs, and arXiv IDs
- **Download** PDFs through institutional access (OpenAthens / SSO) with Playwright browser automation
- **Organize** papers in a MASTER-hash library with per-project symlinks at `~/.scitex/scholar/library/`
- **Highlight** each sentence of a PDF by rhetorical role — claim, method, limitation, supportive citation, contradicting citation — via Claude
- **Automate** the same operations from the CLI, a Python API, or the SciTeX MCP server

## Installation

```bash
pip install scitex-scholar                 # core
pip install "scitex-scholar[pdf]"          # PDF text extraction
pip install "scitex-scholar[mcp]"          # MCP server deps (fastmcp)
pip install "scitex-scholar[browser]"      # Playwright automation
pip install "scitex-scholar[all]"          # everything
```

## Python usage

```python
from scitex_scholar import Scholar, Paper, Papers, apply_filters, to_bibtex

scholar = Scholar()
papers = scholar.search("deep learning EEG", year_min=2020)   # auto-enriched
papers.save("results.bib")

# Filter + export
top = apply_filters(papers, min_citations=50, min_impact_factor=5.0)
print(to_bibtex(top))
```

## CLI

Entry point: `python -m scitex_scholar <subcommand>`.

```bash
# Single paper by DOI or title
python -m scitex_scholar single --doi 10.1038/nature12373 --project demo

# Multiple DOIs/titles in parallel
python -m scitex_scholar parallel --dois 10.1038/xxx 10.1126/yyy --project demo --num-workers 4

# Process a whole BibTeX file
python -m scitex_scholar bibtex --bibtex refs.bib --project demo --output refs.enriched.bib

# Start the (legacy) MCP server
python -m scitex_scholar mcp
```

Common flags: `--browser-mode {stealth,interactive}`, `--chrome-profile NAME`, `--force`.

## Core API

| Symbol | Purpose |
|-----------------|---------|
| `Scholar` | Main search / enrich / download / save interface |
| `Paper`, `Papers` | Single paper / collection with export methods |
| `ScholarConfig` | Paths, API keys, auto-enrich toggle, browser settings |
| `apply_filters` | Filter a `Papers` collection |
| `to_bibtex`, `to_ris`, `to_endnote`, `to_text_citation` | Export formats |
| `generate_cite_key`, `make_citation_key` | Deterministic BibTeX keys |
| `CitationGraphBuilder`, `plot_citation_graph` | Optional citation graph |
| `pdf_highlight.highlight_pdf` | Overlay semantic highlights on a PDF |

Sources: `core/`, `search_engines/`, `metadata_engines/`, `pdf_download/`, `pipelines/`, `browser/`, `auth/`, `storage/`, `pdf_highlight/`, `_mcp/`.

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

## MCP integration

The package ships MCP tool handlers consumed by the unified `scitex serve` server (tools prefixed `scholar_*`). A standalone server at `scitex_scholar.mcp_server` is still shipped but deprecated. See `src/scitex_scholar/_skills/scitex-scholar/SKILL.md` for the full tool list.

## Storage layout

```
~/.scitex/scholar/library/
├── MASTER/<HASH>/               # Canonical per-paper storage (metadata.json + PDF)
└── <project>/<human-label> -> ../MASTER/<HASH>
```

Cache and auth state live under `~/.scitex/scholar/cache/` (URL resolver, Chrome profiles, OpenAthens cookies). Override with `SCITEX_DIR`.

## License

AGPL-3.0-only.

## Part of SciTeX

`scitex-scholar` is part of [**SciTeX**](https://scitex.ai). Install via
the umbrella with `pip install scitex[scholar]` to use as
`scitex.scholar` (Python) or `scitex scholar ...` (CLI).

> Four Freedoms for Research
>
> 0. The freedom to **run** your research anywhere — your machine, your terms.
> 1. The freedom to **study** how every step works — from raw data to final manuscript.
> 2. The freedom to **redistribute** your workflows, not just your papers.
> 3. The freedom to **modify** any module and share improvements with the community.
>
> AGPL-3.0 — because we believe research infrastructure deserves the same freedoms as the software it runs on.

---

<p align="center">
  <a href="https://scitex.ai" target="_blank"><b>SciTeX</b></a>
</p>
