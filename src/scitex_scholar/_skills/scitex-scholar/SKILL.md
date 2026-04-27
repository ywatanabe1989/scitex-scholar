---
name: scitex-scholar
description: Scientific-paper search, metadata enrichment, PDF download, and BibTeX library management for the SciTeX ecosystem. Use when searching the literature, resolving DOIs, enriching citations, downloading PDFs through institutional access, or managing a reproducible paper library.
type: reference
allowed-tools: mcp__scitex__scholar_*
---

# scitex-scholar

Unified toolkit for scientific literature workflows: search across
multiple academic databases, resolve DOIs, enrich BibTeX with impact
factors and citation counts, download PDFs (including paywalled papers
via OpenAthens browser automation), and organise papers in a
deduplicated, project-based library at `~/.scitex/scholar/library/`.

## Installation & import (two equivalent paths)

The same module is reachable via two install paths. Both forms work at
runtime; which one a user has depends on their install choice.

```python
# Standalone — pip install scitex-scholar
import scitex_scholar
scitex_scholar.Scholar(...)

# Umbrella — pip install scitex
import scitex.scholar
scitex.scholar.Scholar(...)
```

`pip install scitex-scholar` alone does NOT expose the `scitex` namespace;
`import scitex.scholar` raises `ModuleNotFoundError`. To use the
`scitex.scholar` form, also `pip install scitex`.

See [../../general/02_interface-python-api.md] for the ecosystem-wide
rule and empirical verification table.

## Core / interfaces

- [01_quick-start.md](01_quick-start.md) — single-paper and BibTeX-batch workflows; project organization
- [02_python-api.md](02_python-api.md) — `Scholar`, `Paper`, `Papers`, `ScholarConfig`, `ScholarAuthManager`
- [03_cli-reference.md](03_cli-reference.md) — `scitex-scholar` and `scitex scholar` CLI commands
- [04_mcp-tools.md](04_mcp-tools.md) — MCP tools for AI agents
- [05_api-overview.md](05_api-overview.md) — top-level re-exports, subpackages, storage layout, install extras

## Workflows

- [10_authentication.md](10_authentication.md) — OpenAthens SSO login, session caching, cookie storage
- [11_search.md](11_search.md) — multi-source search (CrossRef, OpenAlex, Semantic Scholar, PubMed, arXiv)
- [12_doi-resolution.md](12_doi-resolution.md) — resolve DOIs from titles, resumable batches, rate limits
- [13_bibtex-enrichment.md](13_bibtex-enrichment.md) — add metadata (abstract, citations, IF) with per-field provenance
- [14_pdf-download.md](14_pdf-download.md) — OpenURL → publisher → PDF, Zotero translators, browser modes
- [15_library-management.md](15_library-management.md) — MASTER/8DIGIT-ID storage, project symlinks, metadata.json
- [16_semantic-highlight.md](16_semantic-highlight.md) — overlay claim / method / limitation highlights on a PDF


## Environment

- [20_env-vars.md](20_env-vars.md) — SCITEX_* env vars read by scitex-scholar at runtime
