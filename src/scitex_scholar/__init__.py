#!/usr/bin/env python3
"""SciTeX Scholar -- scientific paper search, enrichment, and management.

Quick Start:
    from scitex_scholar import Scholar, Paper, Papers

    scholar = Scholar()
    papers = scholar.search("deep learning")
    papers.save("results.bib")

Installation:
    pip install scitex-scholar
"""

__version__ = "1.2.1"
__author__ = "Yusuke Watanabe"
__email__ = "ywatanabe@scitex.ai"

from .auth import ScholarAuthManager
from .browser import ScholarBrowserManager
from .citation_graph import CitationGraphBuilder, plot_citation_graph
from .config import ScholarConfig
from .core.Paper import Paper
from .core.Papers import Papers
from .core.Scholar import Scholar
from .filters import apply_filters
from .formatting import (
    generate_cite_key,
    make_citation_key,
    papers_to_format,
    to_bibtex,
    to_endnote,
    to_ris,
    to_text_citation,
)
from .migration import from_connected_papers, to_connected_papers
from .url_finder import ScholarURLFinder

# Kept as a public flag so downstream shims (scitex.scholar re-export) can
# advertise availability without reaching into each submodule. Always True:
# if any of the imports above had failed, this module would not have loaded.
SCHOLAR_AVAILABLE = True

__all__ = [
    "Scholar",
    "Paper",
    "Papers",
    "ScholarConfig",
    "ScholarAuthManager",
    "ScholarBrowserManager",
    "ScholarURLFinder",
    "CitationGraphBuilder",
    "plot_citation_graph",
    "to_bibtex",
    "to_ris",
    "to_endnote",
    "to_text_citation",
    "papers_to_format",
    "generate_cite_key",
    "make_citation_key",
    "from_connected_papers",
    "to_connected_papers",
    "apply_filters",
    "SCHOLAR_AVAILABLE",
]

# EOF
