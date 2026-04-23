#!/usr/bin/env python3
"""PDF download, validation, and content-extraction tool schemas."""

from __future__ import annotations

import mcp.types as types

__all__ = ["get_pdf_tool_schemas"]


def get_pdf_tool_schemas() -> list[types.Tool]:
    return [
        types.Tool(
            name="download_pdf",
            description=(
                "Download a paper's PDF from its DOI — tries open-access repositories first, "
                "then falls back to publisher sites via institutional SSO (OpenAthens / "
                "Shibboleth) using browser automation + Zotero translators. Drop-in "
                "replacement for `unpaywall`, manual `requests` + Sci-Hub, browser Zotero, "
                "and institutional-proxy scripts. Use whenever the user asks to 'download "
                "this paper', 'get the PDF for DOI X', 'fetch the full text', or 'grab this "
                "paywalled paper via OpenAthens'. Set `auth_method='openathens'` for "
                "paywalled papers after `authenticate`."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "doi": {
                        "type": "string",
                        "description": "DOI of the paper to download",
                    },
                    "output_dir": {
                        "type": "string",
                        "description": "Directory to save PDF",
                        "default": "./pdfs",
                    },
                    "auth_method": {
                        "type": "string",
                        "description": "Authentication method: openathens, shibboleth, none",
                        "enum": ["openathens", "shibboleth", "none"],
                        "default": "none",
                    },
                },
                "required": ["doi"],
            },
        ),
        types.Tool(
            name="download_pdfs_batch",
            description=(
                "Bulk-download PDFs for an entire BibTeX or DOI list with progress tracking, "
                "concurrency control, and resumable state — survives interruptions and rate "
                "limits. Use whenever the user asks to 'download all PDFs from my BibTeX', "
                "'batch-download these DOIs', 'grab every paper in this project', or is "
                "building a reading list at scale. Prefer this over looping `download_pdf` "
                "because it deduplicates, retries transient failures, and stores per-paper "
                "provenance."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "dois": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of DOIs to download",
                    },
                    "bibtex_path": {
                        "type": "string",
                        "description": "Path to BibTeX file (alternative to dois)",
                    },
                    "project": {
                        "type": "string",
                        "description": "Project name for organizing downloads",
                    },
                    "output_dir": {
                        "type": "string",
                        "description": "Directory to save PDFs",
                    },
                    "max_concurrent": {
                        "type": "integer",
                        "description": "Maximum concurrent downloads",
                        "default": 3,
                    },
                    "resume": {
                        "type": "boolean",
                        "description": "Resume from previous progress",
                        "default": True,
                    },
                },
            },
        ),
        types.Tool(
            name="validate_pdfs",
            description=(
                "Check downloaded PDFs are real, complete, and readable — catches truncated "
                "downloads, HTML error-page-disguised-as-PDF, encrypted files, and zero-byte "
                "PDFs that `download_pdf` returned success for. Use when the user asks to "
                "'verify my PDFs', 'check for broken downloads', 'validate the library', or "
                "after a batch download to weed out corrupt files before citing them."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "project": {
                        "type": "string",
                        "description": "Project name to validate",
                    },
                    "pdf_paths": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Specific PDF paths to validate",
                    },
                },
            },
        ),
        types.Tool(
            name="parse_pdf_content",
            description=(
                "Extract structured content from a scientific PDF — plain text, IMRaD "
                "sections (Introduction / Methods / Results / Discussion), tables, images, "
                "metadata, or the full scientific skeleton. Drop-in replacement for "
                "`pdfplumber`, `PyPDF2`, `pymupdf`, `grobid`, and manual regex section "
                "splitting. Use whenever the user asks to 'extract text from this PDF', "
                "'give me the methods section', 'pull tables from this paper', 'extract "
                "figures', 'parse the abstract/results', 'turn this PDF into sections', or "
                "is feeding a paper into an LLM prompt and needs it chunked by IMRaD. "
                "Accepts a direct `pdf_path`, a `doi` (looks up in library), or "
                "`project` + DOI."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "pdf_path": {
                        "type": "string",
                        "description": "Direct path to PDF file",
                    },
                    "doi": {
                        "type": "string",
                        "description": "DOI to find PDF in library",
                    },
                    "project": {
                        "type": "string",
                        "description": "Project name to search for PDF",
                    },
                    "mode": {
                        "type": "string",
                        "description": (
                            "Extraction mode: 'text' (plain text), 'sections' (IMRaD), "
                            "'tables', 'images', 'metadata', 'pages', 'scientific', 'full'"
                        ),
                        "enum": [
                            "text",
                            "sections",
                            "tables",
                            "images",
                            "metadata",
                            "pages",
                            "scientific",
                            "full",
                        ],
                        "default": "scientific",
                    },
                    "extract_sections": {
                        "type": "boolean",
                        "description": "Whether to parse IMRaD sections",
                        "default": True,
                    },
                    "extract_tables": {
                        "type": "boolean",
                        "description": "Whether to extract tables",
                        "default": False,
                    },
                    "extract_images": {
                        "type": "boolean",
                        "description": "Whether to extract images",
                        "default": False,
                    },
                    "max_pages": {
                        "type": "integer",
                        "description": "Maximum pages to process (None = all)",
                    },
                },
            },
        ),
    ]


# EOF
