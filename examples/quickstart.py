#!/usr/bin/env python3
"""Quickstart for scitex-scholar: pure helpers and Paper construction (offline)."""

import scitex_scholar
from scitex_scholar import (
    Paper,
    Papers,
    ScholarConfig,
    clean_abstract,
    make_citation_key,
)


def main() -> int:
    print(f"scitex_scholar version: {scitex_scholar.__version__}")

    # 1. Pure-text helper
    raw = "  This abstract has\n\nweird   whitespace.  "
    print(f"\nclean_abstract({raw!r}) -> {clean_abstract(raw)!r}")

    # 2. Citation key generation
    key = make_citation_key("Smith", 2024)
    print(f"make_citation_key('Smith', 2024) -> {key!r}")

    # 3. Construct a Paper (offline; no network)
    p = Paper()
    p.metadata.basic.title = "An offline example paper"
    p.metadata.basic.year = 2024
    print(f"\nPaper title: {p.metadata.basic.title}")
    print(f"Paper year:  {p.metadata.basic.year}")

    # 4. Wrap in a Papers collection
    coll = Papers([p])
    print(f"\nPapers collection length: {len(coll)}")

    # 5. Default ScholarConfig
    cfg = ScholarConfig()
    print(f"ScholarConfig type: {type(cfg).__name__}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
