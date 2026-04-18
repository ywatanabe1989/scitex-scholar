"""MCP tool spec for the semantic PDF highlighter.

Provides a JSON-schema tool definition and a handler function that
any MCP server implementation can import and register. The handler
itself is synchronous; wrap with ``asyncio.to_thread`` inside the server.
"""

from __future__ import annotations

from typing import Any

from .highlighter import highlight_pdf

TOOL_NAME = "scholar_highlight_pdf"

TOOL_DESCRIPTION = (
    "Overlay colour-coded semantic highlights on a PDF. Tags each sentence as "
    "focal_claim (green), focal_method (purple), focal_limitation (red), "
    "related_supportive (blue), or related_contradictive (orange) via Claude. "
    "Writes a copy with PDF annotation objects; the original file is unchanged. "
    "A legend + signature page is prepended."
)

TOOL_SCHEMA: dict[str, Any] = {
    "name": TOOL_NAME,
    "description": TOOL_DESCRIPTION,
    "inputSchema": {
        "type": "object",
        "required": ["pdf_path"],
        "properties": {
            "pdf_path": {
                "type": "string",
                "description": "Absolute path to the input PDF.",
            },
            "output_path": {
                "type": "string",
                "description": "Output PDF path. Default: <input>.highlighted.pdf",
            },
            "model": {
                "type": "string",
                "description": "Anthropic model ID.",
                "default": "claude-haiku-4-5-20251001",
            },
            "sentence_level": {
                "type": "boolean",
                "description": "Classify at sentence granularity (default) vs. paragraph.",
                "default": True,
            },
            "add_legend": {
                "type": "boolean",
                "description": "Prepend a colour legend + signature page.",
                "default": True,
            },
            "use_stub": {
                "type": "boolean",
                "description": "Keyword heuristic only (no API calls). For smoke tests.",
                "default": False,
            },
            "dry_run": {
                "type": "boolean",
                "description": "Classify but do not write the output PDF.",
                "default": False,
            },
        },
    },
}


def run_tool(arguments: dict[str, Any]) -> dict[str, Any]:
    """Execute the highlighter and return a summary suitable for an MCP reply.

    The returned dict has ``output_path``, ``pages``, ``annotations_added``,
    and ``counts`` (per-category). Raises :class:`FileNotFoundError` or
    :class:`RuntimeError` as the highlighter does; MCP servers should
    translate these into tool-level errors.
    """
    pdf_path = arguments["pdf_path"]
    output_path = arguments.get("output_path") or None

    result = highlight_pdf(
        pdf_path,
        output_path=output_path,
        model=arguments.get("model", "claude-haiku-4-5-20251001"),
        use_stub=bool(arguments.get("use_stub", False)),
        dry_run=bool(arguments.get("dry_run", False)),
        sentence_level=bool(arguments.get("sentence_level", True)),
        add_legend=bool(arguments.get("add_legend", True)),
    )

    return {
        "input_path": str(result.input_path),
        "output_path": str(result.output_path) if result.output_path else None,
        "pages": result.pages,
        "annotations_added": result.annotations_added,
        "counts": result.counts(),
    }


__all__ = ["TOOL_NAME", "TOOL_DESCRIPTION", "TOOL_SCHEMA", "run_tool"]
