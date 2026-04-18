"""Semantic PDF highlighter for academic papers.

Overlays rhetorical-role highlights (claim / method / limitation /
supportive / contradictive) onto a copy of a PDF without modifying its
underlying text. Highlights are standard PDF annotation objects
compatible with any viewer.
"""

from .highlighter import (
    CATEGORIES,
    COLOR_RGB,
    Block,
    HighlightResult,
    apply_classifications,
    extract_blocks,
    highlight_pdf,
    save_with_highlights,
)

__all__ = [
    "CATEGORIES",
    "COLOR_RGB",
    "Block",
    "HighlightResult",
    "apply_classifications",
    "extract_blocks",
    "highlight_pdf",
    "save_with_highlights",
]
