#!/usr/bin/env python3
"""Project + search + library tool schemas."""

from __future__ import annotations

import mcp.types as types

__all__ = ["get_project_tool_schemas"]


def get_project_tool_schemas() -> list[types.Tool]:
    return [
        types.Tool(
            name="search_papers",
            description=(
                "Search the scientific literature — across the local library AND/OR external "
                "databases (CrossRef, Semantic Scholar, PubMed, arXiv, OpenAlex). Drop-in "
                "replacement for `scholarly`, `habanero`, `pyalex`, `semanticscholar`, "
                "`arxiv`, and Google Scholar scraping. Use whenever the user asks to "
                "'find papers on X', 'search the literature for Y', 'any papers about Z?', "
                "'look this up on PubMed/arXiv/OpenAlex', 'what's in my local library about …', "
                "or needs a ranked list of relevant papers with metadata."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query string"},
                    "search_mode": {
                        "type": "string",
                        "description": "Search mode: 'local' (library only), 'external' (online databases), 'both'",
                        "enum": ["local", "external", "both"],
                        "default": "local",
                    },
                    "sources": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": (
                            "Sources to search: pubmed, crossref, semantic_scholar, "
                            "arxiv, openalex"
                        ),
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of results",
                        "default": 20,
                    },
                    "year_min": {
                        "type": "integer",
                        "description": "Minimum publication year",
                    },
                    "year_max": {
                        "type": "integer",
                        "description": "Maximum publication year",
                    },
                },
                "required": ["query"],
            },
        ),
        types.Tool(
            name="get_library_status",
            description=(
                "Summarize the state of the local paper library — total papers, how many "
                "have PDFs, which are missing, per-project counts, validation results. Use "
                "when the user asks 'how many papers do I have?', 'which ones are missing "
                "PDFs?', 'is my project complete?', 'audit my library', or before launching "
                "a big `download_pdfs_batch` to see the gap."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "project": {
                        "type": "string",
                        "description": "Project name to check (optional)",
                    },
                    "include_details": {
                        "type": "boolean",
                        "description": "Include detailed per-paper status",
                        "default": False,
                    },
                },
            },
        ),
        types.Tool(
            name="create_project",
            description=(
                "Create a named project (folder) for grouping papers — e.g. one per "
                "manuscript, thesis chapter, or literature review. Papers live once in a "
                "deduplicated MASTER store and appear in projects via symlinks. Use when the "
                "user asks to 'start a new project', 'make a folder for paper X', 'organize "
                "papers for my review on …', or is setting up a fresh literature track."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "project_name": {
                        "type": "string",
                        "description": "Name of the project to create",
                    },
                    "description": {
                        "type": "string",
                        "description": "Optional project description",
                    },
                },
                "required": ["project_name"],
            },
        ),
        types.Tool(
            name="list_projects",
            description=(
                "List every scholar project in the library with paper counts. Use when the "
                "user asks 'what projects do I have?', 'list my review folders', 'show all "
                "scholar projects', or is orienting before adding/exporting papers."
            ),
            inputSchema={"type": "object", "properties": {}},
        ),
        types.Tool(
            name="add_papers_to_project",
            description=(
                "Attach papers to an existing project — by DOI list or by importing a "
                "BibTeX file. Papers are deduplicated against the MASTER store, so the same "
                "paper added from two projects only downloads once. Use when the user asks "
                "to 'add these DOIs to my project', 'import this .bib into project X', "
                "'bulk-add papers to the review', or is populating a fresh project."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "project": {"type": "string", "description": "Target project name"},
                    "dois": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of DOIs to add",
                    },
                    "bibtex_path": {
                        "type": "string",
                        "description": "Path to BibTeX file with papers to add",
                    },
                },
                "required": ["project"],
            },
        ),
    ]


# EOF
