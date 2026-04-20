#!/usr/bin/env python3
"""`scitex scholar db {build,migrate,lookup,list}` CLI."""

from __future__ import annotations

import json
from pathlib import Path

import scitex_logging as logging

from ..storage import _library_index as idx

logger = logging.getLogger(__name__)


def _default_library_root() -> Path:
    return Path("~/.scitex/scholar/library").expanduser().resolve()


def register_subparser(subparsers) -> None:
    p = subparsers.add_parser(
        "db",
        help="Manage the library SQLite index",
        description=(
            "Build / migrate / query the library index at <library_root>/index.db."
        ),
    )
    sub = p.add_subparsers(dest="db_command", required=True)

    b = sub.add_parser("build", help="(Re)build the index from MASTER metadata")
    b.add_argument(
        "--library-root",
        type=Path,
        default=None,
        help="Defaults to ~/.scitex/scholar/library",
    )
    b.add_argument("--verbose", action="store_true")

    m = sub.add_parser("migrate", help="Apply pending schema migrations")
    m.add_argument("--library-root", type=Path, default=None)

    lu = sub.add_parser("lookup", help="Fetch a paper by DOI or paper_id")
    lu.add_argument("--library-root", type=Path, default=None)
    g = lu.add_mutually_exclusive_group(required=True)
    g.add_argument("--doi")
    g.add_argument("--paper-id")

    ls = sub.add_parser("list", help="List indexed papers")
    ls.add_argument("--library-root", type=Path, default=None)
    ls.add_argument("--limit", type=int, default=20)
    ls.add_argument("--offset", type=int, default=0)


def run(args) -> int:
    root = args.library_root or _default_library_root()

    if args.db_command == "build":
        n = idx.build(root, verbose=args.verbose)
        print(f"{n} papers indexed at {idx.db_path(root)}")
        return 0

    if args.db_command == "migrate":
        v = idx.migrate(root)
        print(f"Schema version: {v}")
        return 0

    if args.db_command == "lookup":
        if args.doi:
            row = idx.lookup_by_doi(root, args.doi)
        else:
            row = idx.lookup_by_paper_id(root, args.paper_id)
        if row is None:
            logger.error("Not found")
            return 1
        print(json.dumps(row, indent=2, default=str))
        return 0

    if args.db_command == "list":
        rows = idx.list_all(root, limit=args.limit, offset=args.offset)
        for r in rows:
            print(
                f"{r['paper_id']}\t{r.get('year') or ''}\t{(r.get('title') or '')[:80]}"
            )
        return 0

    logger.error(f"Unknown db command: {args.db_command}")
    return 1
