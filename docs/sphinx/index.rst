SciTeX Scholar
==============

.. image:: _static/scitex-logo-banner.png
   :alt: SciTeX Scholar
   :align: center
   :width: 400px

.. raw:: html

   <p align="center"><b>Scientific paper search, enrichment, download, and management for reproducible research</b></p>
   <br>

**SciTeX Scholar** provides a unified interface for the full literature management workflow:
searching scholarly databases, resolving DOIs, enriching BibTeX metadata, downloading PDFs
through institutional access, organizing a deduplicated library, and — new — overlaying
colour-coded **semantic highlights** on papers so a reader can tell at a glance what the paper
*claims*, how it *claims* it, and where its *limitations* sit.

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   installation
   quickstart

.. toctree::
   :maxdepth: 2
   :caption: User Guide

   semantic_highlight
   cli
   mcp

.. toctree::
   :maxdepth: 2
   :caption: API Reference

   api/index

Quick Example
-------------

.. code-block:: python

   from scitex_scholar import Scholar

   scholar = Scholar()
   papers = scholar.search("deep learning EEG")
   papers.save("results.bib")

Semantic highlighting — new in 1.0:

.. code-block:: bash

   export ANTHROPIC_API_KEY=sk-ant-...
   scitex-scholar highlight paper.pdf    # writes paper.highlighted.pdf

See :doc:`semantic_highlight` for the full five-category colour scheme, model selection, and
the offline label-apply workflow.

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
