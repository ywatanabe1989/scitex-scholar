#!/usr/bin/env python3
"""BibTeX / DOI / export tool schemas."""

from __future__ import annotations

import mcp.types as types

__all__ = ["get_bibtex_tool_schemas"]


def get_bibtex_tool_schemas() -> list[types.Tool]:
    return [
        types.Tool(
            name="resolve_dois",
            description=(
                "Look up DOIs from paper titles via the Crossref API — resumable across "
                "long batches so interrupted runs pick up where they left off. Drop-in "
                "replacement for manual Crossref REST calls and `habanero.Crossref().works`. "
                "Use whenever the user asks to 'find the DOI for this paper', 'resolve DOIs "
                "in my BibTeX', 'fill in missing DOIs', 'look up DOIs for these titles', or "
                "has a title list / .bib file with blank `doi` fields. Accepts a BibTeX file "
                "or a raw list of titles."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "bibtex_path": {
                        "type": "string",
                        "description": "Path to BibTeX file to resolve DOIs for",
                    },
                    "titles": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of paper titles to resolve DOIs for",
                    },
                    "resume": {
                        "type": "boolean",
                        "description": "Resume from previous progress",
                        "default": True,
                    },
                    "project": {
                        "type": "string",
                        "description": "Project name for organizing results",
                    },
                },
            },
        ),
        types.Tool(
            name="enrich_bibtex",
            description=(
                "Upgrade a `.bib` file in place — fill in missing DOIs, abstracts, citation "
                "counts, and journal impact factors using CrossRef + OpenAlex + Semantic "
                "Scholar. Drop-in replacement for manual metadata-completion scripts, "
                "`betterbib`, and Zotero 'Retrieve Metadata'. Use whenever the user asks to "
                "'enrich this BibTeX', 'fill in abstracts / citations / impact factors', "
                "'complete my .bib file', 'add IF to each entry', or has a sparse BibTeX that "
                "needs upgrading before a paper submission. Writes per-field provenance so "
                "reviewers can see which source supplied each value."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "bibtex_path": {
                        "type": "string",
                        "description": "Path to BibTeX file to enrich",
                    },
                    "output_path": {
                        "type": "string",
                        "description": "Output path for enriched BibTeX (optional)",
                    },
                    "add_abstracts": {
                        "type": "boolean",
                        "description": "Add missing abstracts",
                        "default": True,
                    },
                    "add_citations": {
                        "type": "boolean",
                        "description": "Add citation counts",
                        "default": True,
                    },
                    "add_impact_factors": {
                        "type": "boolean",
                        "description": "Add journal impact factors",
                        "default": True,
                    },
                },
                "required": ["bibtex_path"],
            },
        ),
        types.Tool(
            name="parse_bibtex",
            description=(
                "Parse a `.bib` file into structured paper objects with fields (title, "
                "authors, year, journal, doi, abstract, etc.). Drop-in replacement for "
                "`bibtexparser`, `pybtex`. Use when the user asks to 'read my BibTeX', "
                "'parse this .bib', 'load citations from file', or needs structured access "
                "before enriching/filtering/exporting."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "bibtex_path": {
                        "type": "string",
                        "description": "Path to BibTeX file",
                    },
                },
                "required": ["bibtex_path"],
            },
        ),
        types.Tool(
            name="export_papers",
            description=(
                "Export a project's papers to BibTeX, RIS, JSON, or CSV — ready for "
                "LaTeX, EndNote, Zotero, Mendeley, or a spreadsheet. Drop-in replacement "
                "for `pybtex` writers and manual `.bib` templating. Use when the user asks "
                "to 'export my library', 'give me a .bib for this project', 'write out RIS "
                "for EndNote', 'dump papers to CSV', or is preparing a reading list / "
                "submission bibliography. Set `filter_has_pdf=True` to only export papers "
                "whose PDFs were actually downloaded."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "project": {
                        "type": "string",
                        "description": "Project name to export",
                    },
                    "output_path": {
                        "type": "string",
                        "description": "Output file path",
                    },
                    "format": {
                        "type": "string",
                        "description": "Export format",
                        "enum": ["bibtex", "ris", "json", "csv"],
                        "default": "bibtex",
                    },
                    "filter_has_pdf": {
                        "type": "boolean",
                        "description": "Only export papers with downloaded PDFs",
                        "default": False,
                    },
                },
                "required": ["output_path"],
            },
        ),
    ]


# EOF
