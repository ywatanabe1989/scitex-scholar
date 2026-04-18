#!/usr/bin/env python3
# File: src/scitex_scholar/_mcp/pdf_highlight_handlers.py
"""MCP handler for the semantic PDF highlighter.

Kept in its own file rather than appended to the main ``handlers.py``
because that module is already large. Re-exported from
:mod:`all_handlers` for the unified scitex MCP server.
"""

from __future__ import annotations

import asyncio
from datetime import datetime


async def highlight_pdf_handler(
    pdf_path: str,
    output_path: str | None = None,
    model: str = "claude-haiku-4-5-20251001",
    sentence_level: bool = True,
    add_legend: bool = True,
    use_stub: bool = False,
    dry_run: bool = False,
) -> dict:
    """Overlay semantic highlights on a PDF.

    Each sentence is tagged by Claude as one of
    focal_claim / focal_method / focal_limitation /
    related_supportive / related_contradictive, then highlighted in
    the corresponding colour. The original PDF is not modified — the
    result is written to ``output_path`` (defaults to
    ``<input>.highlighted.pdf``). A compact colour-legend overlay is
    placed on the last page.
    """
    try:
        from scitex_scholar.pdf_highlight._mcp import run_tool

        loop = asyncio.get_running_loop()
        result = await loop.run_in_executor(
            None,
            lambda: run_tool(
                {
                    "pdf_path": pdf_path,
                    "output_path": output_path,
                    "model": model,
                    "sentence_level": sentence_level,
                    "add_legend": add_legend,
                    "use_stub": use_stub,
                    "dry_run": dry_run,
                }
            ),
        )
        return {
            "success": True,
            **result,
            "timestamp": datetime.now().isoformat(),
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


__all__ = ["highlight_pdf_handler"]
