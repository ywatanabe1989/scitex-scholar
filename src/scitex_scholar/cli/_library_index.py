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

    de = sub.add_parser(
        "dedupe",
        help="Resolve duplicate-DOI entries (quarantine losers)",
        description=(
            "Detect duplicate-DOI groups in MASTER and pick a winner per "
            "group by a scored rubric (PDF presence, populated metadata, "
            "citation count, mtime). Default is dry-run — pass --apply "
            "to move losers to MASTER_quarantine/ (reversible). "
            "--hard-delete removes losers instead of quarantining."
        ),
    )
    de.add_argument("--library-root", type=Path, default=None)
    de.add_argument(
        "--apply",
        action="store_true",
        help="Execute the plan (default is dry-run)",
    )
    de.add_argument(
        "--hard-delete",
        action="store_true",
        help="Delete losers instead of quarantining (irreversible)",
    )

    au = sub.add_parser(
        "audit",
        help="Report library anomalies without raising (read-only)",
        description=(
            "Walk MASTER and decorated symlinks, report duplicate DOIs, "
            "unparseable metadata, missing PDFs, and orphaned symlinks. "
            "Always exits 0 unless --strict is passed."
        ),
    )
    au.add_argument("--library-root", type=Path, default=None)
    au.add_argument(
        "--json",
        dest="as_json",
        action="store_true",
        help="Emit JSON instead of human-readable text",
    )
    au.add_argument(
        "--strict",
        action="store_true",
        help="Exit 1 when any issue is found (for CI)",
    )


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

    if args.db_command == "dedupe":
        from ..storage._library_dedupe import apply_plan, format_plan, plan_dedupe

        plan = plan_dedupe(root)
        if args.apply and plan.decisions:
            apply_plan(root, plan, hard_delete=args.hard_delete)
        print(format_plan(plan))
        return 0

    if args.db_command == "audit":
        from ..storage._library_audit import audit, format_report

        report = audit(root)
        if args.as_json:
            print(json.dumps(report.to_dict(), indent=2, default=str))
        else:
            print(format_report(report))
        return 1 if (args.strict and report.has_issues) else 0

    logger.error(f"Unknown db command: {args.db_command}")
    return 1
