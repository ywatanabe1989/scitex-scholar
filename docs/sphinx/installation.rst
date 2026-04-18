Installation
============

Basic Installation
------------------

.. code-block:: bash

   pip install scitex-scholar

Optional Dependencies
---------------------

.. code-block:: bash

   # PDF parsing and semantic highlighting
   pip install scitex-scholar[pdf]

   # MCP server for AI agents
   pip install scitex-scholar[mcp]

   # Everything
   pip install scitex-scholar[all]

Development Installation
------------------------

.. code-block:: bash

   git clone https://github.com/ywatanabe1989/scitex-scholar.git
   cd scitex-scholar
   pip install -e ".[all,dev]"

Environment Variables
---------------------

Set before use:

.. code-block:: bash

   # Required for semantic highlighting (reads ANTHROPIC_API_KEY)
   export ANTHROPIC_API_KEY=sk-ant-...

   # Optional — override default Scholar library location
   export SCITEX_DIR=$HOME/.scitex
