CLI Reference
=============

The ``scitex-scholar`` command provides five subcommands. Every subcommand has
``--help`` for option listings.

.. code-block:: bash

   scitex-scholar --help

Subcommands
-----------

single
~~~~~~

Process a single paper from DOI or title through the full pipeline (resolve → enrich →
download → organize).

.. code-block:: bash

   scitex-scholar single --doi "10.1093/brain/awx173" --project my_project
   scitex-scholar single --title "Seizure prediction with iEEG" --project my_project

parallel
~~~~~~~~

Process multiple papers concurrently from a list.

.. code-block:: bash

   scitex-scholar parallel --dois "10.1...,10.2..." --project my_project --num-workers 4

bibtex
~~~~~~

Run the full pipeline across every entry in a BibTeX file. Resumable.

.. code-block:: bash

   scitex-scholar bibtex --bibtex refs.bib --project my_project \
                         --num-workers 4 --browser-mode stealth

mcp
~~~

Start the deprecated standalone MCP server. Prefer the unified ``scitex serve`` server
instead, which exposes scholar tools alongside the rest of the SciTeX ecosystem.

.. code-block:: bash

   scitex-scholar mcp      # deprecated — use 'scitex serve'
   scitex serve            # unified server, recommended

highlight
~~~~~~~~~

Overlay semantic highlights on a PDF. See :doc:`semantic_highlight`.

.. code-block:: bash

   export ANTHROPIC_API_KEY=sk-ant-...

   scitex-scholar highlight paper.pdf                  # sentence-level, Haiku, default output
   scitex-scholar highlight paper.pdf -o out.pdf
   scitex-scholar highlight paper.pdf --model claude-sonnet-4-6
   scitex-scholar highlight paper.pdf --stub           # offline keyword heuristic
   scitex-scholar highlight paper.pdf --dry-run
   scitex-scholar highlight paper.pdf --max-blocks 20  # smoke test

   # Offline label-apply workflow
   scitex-scholar highlight paper.pdf --labels-dump blocks.json
   scitex-scholar highlight paper.pdf --labels-apply labels.json

Also available as a standalone module:

.. code-block:: bash

   python -m scitex_scholar.pdf_highlight paper.pdf
