---
description: Scientific paper management — search, DOI resolution, BibTeX enrichment, PDF downloads via institutional SSO (OpenAthens), and library organization.
allowed-tools: mcp__scitex__scholar_*
---

# scitex-scholar

## Installation

```bash
pip install scitex-scholar
# Development:
pip install -e /home/ywatanabe/proj/scitex-scholar
```

End-to-end scientific literature pipeline: search across CrossRef / OpenAlex / Semantic Scholar / PubMed / arXiv, resolve DOIs from titles, enrich BibTeX with metadata (abstracts, citations, impact factors), download PDFs through institutional SSO (OpenAthens), and organize papers in a hash-addressable library at `~/.scitex/scholar/library/`.

## Sub-skills

### Workflow

| Skill | Description |
|-------|-------------|
| [quick-start.md](quick-start.md) | Single-paper and BibTeX-batch workflows; project organization |
| [authentication.md](authentication.md) | OpenAthens SSO login (Unimelb, etc.); session caching; cookie storage |
| [search.md](search.md) | Multi-source search (CrossRef, OpenAlex, Semantic Scholar, PubMed, arXiv); local library search |
| [doi-resolution.md](doi-resolution.md) | Resolve DOIs from titles; resumable batch resolution; rate-limit handling |
| [bibtex-enrichment.md](bibtex-enrichment.md) | Add metadata (abstract, citations, IF) to BibTeX entries; per-field provenance |
| [pdf-download.md](pdf-download.md) | OpenURL → publisher → PDF; Zotero translators; stealth/interactive browser modes |
| [library-management.md](library-management.md) | MASTER/8DIGIT-ID storage; project symlinks; metadata.json; screenshots |
| [cli-reference.md](cli-reference.md) | `scitex-scholar` and `scitex scholar` CLI commands |
| [mcp-tools.md](mcp-tools.md) | MCP tools for AI agents |
| [python-api.md](python-api.md) | `Scholar`, `Paper`, `Papers`, `ScholarConfig`, `ScholarAuthManager` |

## Key Patterns

**Hash-addressable storage**: Each paper lives once at `~/.scitex/scholar/library/MASTER/{8DIGIT}/`. Projects are directories of symlinks pointing to MASTER, so a paper added to multiple projects is never duplicated. See [library-management.md](library-management.md).

**Resumable pipelines**: DOI resolution, enrichment, and PDF download all checkpoint per-paper. Re-running with `--resume` (default) skips already-completed entries — important for rate-limit recovery and long batches. See [doi-resolution.md](doi-resolution.md).

**Provenance fields**: Every metadata field has a sibling `<field>_source` recording where it came from (CrossRef, OpenAlex, manual). When merging or enriching, source-tagged values let you trust the most authoritative source. See [bibtex-enrichment.md](bibtex-enrichment.md).

**Browser modes**: `stealth` runs Chrome headless with anti-bot evasion for batch downloads; `interactive` opens a visible browser when human assistance is needed (CAPTCHA, SSO MFA). See [pdf-download.md](pdf-download.md).

## MCP Tools

| Tool | Description |
|------|-------------|
| `scholar_authenticate` | Start SSO login (OpenAthens, Shibboleth) |
| `scholar_check_auth_status` | Check whether a valid session exists |
| `scholar_logout` | Clear cached authentication |
| `scholar_search_papers` | Search local library or external databases |
| `scholar_resolve_dois` | Resolve DOIs from titles (resumable) |
| `scholar_enrich_bibtex` | Enrich BibTeX with metadata |
| `scholar_resolve_openurls` | Resolve publisher URLs via OpenURL |
| `scholar_download_pdfs_batch` | Download PDFs in parallel (resumable) |
| `scholar_validate_pdfs` | Verify downloaded PDFs are real content |
| `scholar_parse_pdf_content` | Extract sections/text from PDF |
| `scholar_parse_bibtex` | Parse BibTeX file to structured records |
| `scholar_export_papers` | Export to BibTeX/RIS/EndNote/CSV |
| `scholar_create_project` | Create a new project |
| `scholar_list_projects` | List projects in the library |
| `scholar_add_papers_to_project` | Attach papers (DOIs / BibTeX) to a project |
| `scholar_get_library_status` | Library size, project counts, paper counts |
| `scholar_fetch_papers` | One-shot resolve + enrich + download |
| `scholar_start_job` / `scholar_get_job_status` / `scholar_get_job_result` / `scholar_list_jobs` / `scholar_cancel_job` | Background job management |
