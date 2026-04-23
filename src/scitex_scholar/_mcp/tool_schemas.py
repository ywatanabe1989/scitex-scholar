#!/usr/bin/env python3
# Timestamp: 2026-04-23
# File: src/scitex_scholar/_mcp/tool_schemas.py
"""Tool schemas orchestrator for the scitex-scholar MCP server.

Tool schemas are grouped by domain in sibling modules
(`pdf_tool_schemas`, `auth_tool_schemas`, `bibtex_tool_schemas`,
`project_tool_schemas`, `crossref_tool_schemas`, `openalex_tool_schemas`,
`job_tool_schemas`) and aggregated here.
"""

from __future__ import annotations

import mcp.types as types

from .auth_tool_schemas import get_auth_tool_schemas
from .bibtex_tool_schemas import get_bibtex_tool_schemas
from .crossref_tool_schemas import get_crossref_tool_schemas
from .job_tool_schemas import get_job_tool_schemas
from .openalex_tool_schemas import get_openalex_tool_schemas
from .pdf_tool_schemas import get_pdf_tool_schemas
from .project_tool_schemas import get_project_tool_schemas

__all__ = ["get_tool_schemas"]


def get_tool_schemas() -> list[types.Tool]:
    """Return all tool schemas for the Scholar MCP server."""
    return (
        get_project_tool_schemas()
        + get_bibtex_tool_schemas()
        + get_pdf_tool_schemas()
        + get_auth_tool_schemas()
        + get_job_tool_schemas()
        + get_crossref_tool_schemas()
        + get_openalex_tool_schemas()
    )


# EOF
