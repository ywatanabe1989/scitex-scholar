#!/usr/bin/env python3
"""Papers collection utilities — dict / DataFrame / BibTeX conversion.

These are module-level helpers for turning a ``Papers`` collection into
other formats. Historically they were referenced from multiple sites
(``core/Papers.py``, ``cli/handlers/project_handler.py``) but the module
did not exist, leading to ``ImportError`` at runtime on deprecated code
paths. This file fills that gap.
"""

from __future__ import annotations

from typing import Any, Dict, List

import scitex_logging as logging

logger = logging.getLogger(__name__)

__all__ = ["papers_to_dict", "papers_to_dataframe", "papers_to_bibtex"]


def _paper_flat_row(paper: Any) -> Dict[str, Any]:
    """Flatten Paper metadata into a single row dict for CSV/DataFrame."""
    d = paper.to_dict() if hasattr(paper, "to_dict") else {}
    meta = d.get("metadata", {}) if isinstance(d, dict) else {}
    basic = meta.get("basic", {}) if isinstance(meta, dict) else {}
    pub = meta.get("publication", {}) if isinstance(meta, dict) else {}
    ids = meta.get("id", {}) if isinstance(meta, dict) else {}
    authors = basic.get("authors") or []
    if isinstance(authors, list):
        authors = "; ".join(str(a) for a in authors)
    return {
        "title": basic.get("title"),
        "authors": authors,
        "year": basic.get("year"),
        "journal": pub.get("journal"),
        "doi": ids.get("doi"),
        "abstract": basic.get("abstract"),
    }


def papers_to_dict(papers: Any) -> List[Dict[str, Any]]:
    """Convert a Papers collection into a list of dicts."""
    return [p.to_dict() if hasattr(p, "to_dict") else dict(p) for p in papers]


def papers_to_dataframe(papers: Any):
    """Convert a Papers collection into a pandas DataFrame.

    Raises ``ImportError`` if pandas is not available — callers should
    catch and degrade gracefully.
    """
    import pandas as pd

    return pd.DataFrame([_paper_flat_row(p) for p in papers])


def papers_to_bibtex(papers: Any, output_path: Any = None) -> str:
    """Render a Papers collection as a BibTeX string.

    Delegates to ``scitex_scholar.storage.BibTeXHandler.papers_to_bibtex``
    so the formatting stays in sync with the canonical writer.
    """
    from scitex_scholar.storage.BibTeXHandler import BibTeXHandler

    content = BibTeXHandler().papers_to_bibtex(papers)
    if output_path is not None:
        from pathlib import Path

        Path(output_path).write_text(content, encoding="utf-8")
    return content
