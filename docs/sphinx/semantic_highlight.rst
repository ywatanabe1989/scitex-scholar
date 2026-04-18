Semantic PDF Highlighting
=========================

Overlay colour-coded highlights on a PDF that separate what the paper **claims** from its
**methods**, self-admitted **limitations**, and stance toward related work. Highlights are
standard PDF annotation objects placed on a copy of the source — the original bytes are
unchanged and any viewer can show or strip them.

Five rhetorical categories, five colours:

.. list-table::
   :header-rows: 1
   :widths: 10 25 65

   * - colour
     - category
     - meaning
   * - green
     - ``focal_claim``
     - what THIS paper clarifies, suggests, demonstrates, establishes, reports. First-person
       stance markers ("we show/find/demonstrate", "our results", "this finding") and
       quantitative results attached to the paper's own analysis.
   * - purple
     - ``focal_method``
     - THIS paper's own novel method, model, cohort, or analysis pipeline. Not routine study
       logistics, not background on existing methods.
   * - red
     - ``focal_limitation``
     - self-admitted limitation, caveat, confound, or threat to validity.
   * - blue
     - ``related_supportive``
     - a specific prior/other paper whose finding SUPPORTS this paper's position.
   * - orange
     - ``related_contradictive``
     - a specific prior/other paper whose finding CONTRADICTS this paper.

Precision-biased: when a sentence does not clearly fall into one category, the classifier
returns ``none`` and no highlight is drawn.

Pipeline
--------

.. code-block:: text

   PDF
     -> PyMuPDF paragraph extraction (bounding boxes)
     -> sentence splitting (abbreviation-aware — handles Fig., e.g., et al.)
     -> Claude classifier (5 categories, batched JSON-structured output)
     -> tight per-line quads via PyMuPDF dict layout
     -> PDF Highlight annotations (opacity 0.4)
     -> compact legend overlay stamped in the lower-right corner of the last page
     -> save

The source PDF is never modified; the output is a copy with annotation objects overlaid.

Four Interfaces
---------------

Python API
~~~~~~~~~~

.. code-block:: python

   from scitex_scholar.pdf_highlight import (
       highlight_pdf,          # one-shot: extract -> classify -> annotate -> save
       extract_blocks,         # stage 1 only
       apply_classifications,  # merge offline labels into extracted blocks
       save_with_highlights,   # stage 3 only (apply labels -> write PDF)
   )

   result = highlight_pdf(
       "paper.pdf",
       output_path="paper.highlighted.pdf",
       model="claude-haiku-4-5-20251001",
       sentence_level=True,
       add_legend=True,
   )
   print(result.counts(), result.annotations_added)

CLI
~~~

.. code-block:: bash

   # Top-level scholar CLI
   scitex-scholar highlight paper.pdf
   scitex-scholar highlight paper.pdf --output paper.marked.pdf
   scitex-scholar highlight paper.pdf --model claude-sonnet-4-6
   scitex-scholar highlight paper.pdf --stub            # offline keyword heuristic
   scitex-scholar highlight paper.pdf --dry-run         # classify only, no PDF write
   scitex-scholar highlight paper.pdf --max-blocks 20   # smoke test

   # Offline label-apply workflow
   scitex-scholar highlight paper.pdf --labels-dump blocks.json        # extract
   #  ... produce labels.json with {id, category, confidence} objects ...
   scitex-scholar highlight paper.pdf --labels-apply labels.json       # annotate only

   # Standalone module entry point
   python -m scitex_scholar.pdf_highlight paper.pdf

MCP
~~~

Exposed as ``scholar_highlight_pdf`` in the unified ``scitex serve`` server. The handler
is re-exported from ``scitex_scholar._mcp.all_handlers`` for direct registration.

.. code-block:: python

   from scitex_scholar._mcp.all_handlers import highlight_pdf_handler
   # Register with any FastMCP-compatible server

Skill
~~~~~

The AI-agent skill lives at
``src/scitex_scholar/_skills/scitex-scholar/semantic-highlight.md``
and documents the classification scheme, model trade-offs, and the label-apply workflow.

Model Selection
---------------

.. list-table::
   :header-rows: 1
   :widths: 30 25 15 30

   * - model
     - wall time (8-page paper)
     - cost tier
     - strengths
   * - ``claude-haiku-4-5-20251001``
     - ~40 s sentence / ~10 s paragraph
     - cheap
     - structural tagging (method / claim / limitation)
   * - ``claude-sonnet-4-6``
     - ~70 s sentence / ~17 s paragraph
     - mid
     - catches subtle supportive / contradictive stances in related work

Use Haiku for library-wide scans. Escalate to Sonnet when the supportive/contradictive axis
matters for a specific paper.

Known Limitations
-----------------

- **Paragraph clip regions.** Extraction uses PyMuPDF's paragraph blocks as the clip region
  for each sentence. Multi-column papers are handled, but pathological layouts (wrapped
  tables, pull-quotes) may produce skewed rectangles.
- **Sentence splitter is regex-based.** Handles common academic abbreviations
  (``Fig.``, ``e.g.``, ``et al.``, single-initial names) but is not a full statistical
  sentence tokenizer. Edge cases fall back to line-level quads (still tight — no margin
  inflation).
- **One label per sentence.** A sentence that both describes a method and reports what the
  method found gets the higher-priority label (``focal_claim`` wins over ``focal_method``
  per the prompt). Overlapping annotations would be possible but are not currently emitted.
- **No self-citation detection.** "Cook et al. (11)" where (11) is the same first author
  as the focal paper is tagged as ``related_supportive`` when the sentence endorses it,
  even though mechanically it is self-citation.
