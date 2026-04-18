Quick Start
===========

Python API
----------

Search and collect papers:

.. code-block:: python

   from scitex_scholar import Scholar

   scholar = Scholar()
   papers = scholar.search("deep learning EEG", limit=20)

   # Save as BibTeX
   papers.save("results.bib")

   # Iterate
   for paper in papers:
       print(paper.metadata.basic.title, paper.metadata.id.doi)

Convert a BibTeX file:

.. code-block:: python

   from scitex_scholar import Papers, to_bibtex, generate_cite_key

   papers = Papers.from_bibtex("input.bib")
   print(to_bibtex(papers))

Semantic PDF Highlighting
-------------------------

Overlay colour-coded rhetorical highlights on a PDF (claim / method / limitation /
supportive / contradicting). See :doc:`semantic_highlight` for the full scheme.

.. code-block:: python

   from scitex_scholar.pdf_highlight import highlight_pdf

   result = highlight_pdf(
       "paper.pdf",
       output_path="paper.highlighted.pdf",
       model="claude-haiku-4-5-20251001",   # sentence-level by default
   )
   print(result.counts())                     # {'focal_claim': 43, 'focal_method': 64, ...}
   print(result.annotations_added)

Offline label-apply workflow (no LLM calls; reviewer-in-the-loop):

.. code-block:: python

   from scitex_scholar.pdf_highlight import (
       extract_blocks, apply_classifications, save_with_highlights,
   )

   doc, blocks = extract_blocks("paper.pdf", sentence_level=True)
   apply_classifications(blocks, [
       {"id": 12, "category": "focal_claim",  "confidence": 0.95},
       {"id": 13, "category": "focal_method", "confidence": 0.85},
   ])
   save_with_highlights(doc, blocks, "paper.highlighted.pdf",
                        source_name="paper.pdf")

CLI
---

.. code-block:: bash

   # Full paper pipeline
   scitex-scholar single --doi "10.1093/brain/awx173" --project my_project
   scitex-scholar bibtex --bibtex refs.bib --project my_project

   # Semantic highlighting
   export ANTHROPIC_API_KEY=sk-ant-...
   scitex-scholar highlight paper.pdf
   scitex-scholar highlight paper.pdf --stub           # no API calls
   scitex-scholar highlight paper.pdf --dry-run        # classify only

   # MCP server (unified scitex serve)
   scitex serve --transport stdio

Next Steps
----------

- :doc:`semantic_highlight` — five-category scheme, model selection, known limitations.
- :doc:`cli` — full CLI reference.
- :doc:`mcp` — MCP server tools for AI agents.
- :doc:`api/index` — Python API reference.
