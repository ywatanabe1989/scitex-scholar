#!/usr/bin/env python3
"""Zotero-style SQLite index for the scholar library.

Location: ``<library_root>/index.db``.

Maintained as a derived cache of ``MASTER/<paper_id>/metadata.json``.
Safe to delete at any time — ``build()`` re-creates it from the
authoritative filesystem state.

Schema v1 (additive-only; bump ``SCHEMA_VERSION`` and add a migration
step before altering existing columns):

    papers(
        paper_id     TEXT PRIMARY KEY,
        doi          TEXT,
        arxiv_id     TEXT,
        pmid         TEXT,
        title        TEXT,
        year         INTEGER,
        venue        TEXT,
        is_oa        INTEGER,
        updated_at   REAL             -- metadata.json mtime at index time
    )

Indexes: unique on (doi) where doi not null; b-tree on arxiv_id, pmid,
year.

Consumers (e.g. scitex-writer's scholar bridge) read this DB directly
with sqlite3 — no Python dependency on scitex-scholar required.
"""

from __future__ import annotations

import json
import sqlite3
from contextlib import closing, contextmanager
from pathlib import Path
from typing import Iterator, Optional

import scitex_logging as logging

logger = logging.getLogger(__name__)

SCHEMA_VERSION = 1
DB_FILENAME = "index.db"


_SCHEMA_SQL_V1 = """
CREATE TABLE IF NOT EXISTS meta (
    key   TEXT PRIMARY KEY,
    value TEXT
);

CREATE TABLE IF NOT EXISTS papers (
    paper_id   TEXT PRIMARY KEY,
    doi        TEXT,
    arxiv_id   TEXT,
    pmid       TEXT,
    title      TEXT,
    year       INTEGER,
    venue      TEXT,
    is_oa      INTEGER,
    updated_at REAL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_papers_doi
    ON papers(doi) WHERE doi IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_papers_arxiv  ON papers(arxiv_id);
CREATE INDEX IF NOT EXISTS idx_papers_pmid   ON papers(pmid);
CREATE INDEX IF NOT EXISTS idx_papers_year   ON papers(year);
"""


def db_path(library_root: Path) -> Path:
    return Path(library_root) / DB_FILENAME


@contextmanager
def connect(
    library_root: Path, read_only: bool = False
) -> Iterator[sqlite3.Connection]:
    p = db_path(library_root)
    if read_only:
        uri = f"file:{p}?mode=ro"
        conn = sqlite3.connect(uri, uri=True)
    else:
        conn = sqlite3.connect(p)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def _apply_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(_SCHEMA_SQL_V1)
    conn.execute(
        "INSERT OR REPLACE INTO meta(key, value) VALUES ('schema_version', ?)",
        (str(SCHEMA_VERSION),),
    )
    conn.commit()


def _row_from_metadata(paper_id: str, meta_path: Path) -> Optional[tuple]:
    try:
        md = json.loads(meta_path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    m = md.get("metadata", {}) or {}
    id_ = m.get("id", {}) or {}
    basic = m.get("basic", {}) or {}
    pub = m.get("publication", {}) or {}
    access = m.get("access", {}) or {}
    return (
        paper_id,
        id_.get("doi"),
        id_.get("arxiv_id"),
        id_.get("pmid"),
        basic.get("title"),
        basic.get("year"),
        pub.get("short_journal") or pub.get("journal"),
        1
        if access.get("is_open_access")
        else (0 if "is_open_access" in access else None),
        meta_path.stat().st_mtime,
    )


def build(library_root: Path, verbose: bool = False) -> int:
    """(Re)build the index from MASTER metadata. Returns row count."""
    library_root = Path(library_root).resolve()
    master = library_root / "MASTER"
    if not master.is_dir():
        raise FileNotFoundError(master)

    target = db_path(library_root)
    if target.exists():
        target.unlink()

    rows = []
    for meta_file in master.glob("*/metadata.json"):
        paper_id = meta_file.parent.name
        row = _row_from_metadata(paper_id, meta_file)
        if row is not None:
            rows.append(row)
        elif verbose:
            logger.warning(f"Skipped unreadable {meta_file}")

    with closing(sqlite3.connect(target)) as conn:
        _apply_schema(conn)
        conn.executemany(
            "INSERT OR REPLACE INTO papers(paper_id, doi, arxiv_id, pmid, title, "
            "year, venue, is_oa, updated_at) VALUES (?,?,?,?,?,?,?,?,?)",
            rows,
        )
        conn.commit()

    logger.success(f"Indexed {len(rows)} papers at {target}")
    return len(rows)


def migrate(library_root: Path) -> int:
    """Apply pending migrations. Returns new schema version."""
    with connect(library_root) as conn:
        has_meta = conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='meta'"
        ).fetchone()
        if not has_meta:
            current = 0
        else:
            cur = conn.execute(
                "SELECT value FROM meta WHERE key='schema_version'"
            ).fetchone()
            current = int(cur["value"]) if cur else 0
        if current == SCHEMA_VERSION:
            return current
        if current == 0:
            _apply_schema(conn)
            return SCHEMA_VERSION
        # Future: chain migrations here (v1→v2, v2→v3, ...).
        raise RuntimeError(
            f"No migration path from schema v{current} to v{SCHEMA_VERSION}"
        )


def lookup_by_doi(library_root: Path, doi: str) -> Optional[dict]:
    with connect(library_root, read_only=True) as conn:
        row = conn.execute(
            "SELECT * FROM papers WHERE doi = ? COLLATE NOCASE", (doi,)
        ).fetchone()
        return dict(row) if row else None


def lookup_by_paper_id(library_root: Path, paper_id: str) -> Optional[dict]:
    with connect(library_root, read_only=True) as conn:
        row = conn.execute(
            "SELECT * FROM papers WHERE paper_id = ?", (paper_id,)
        ).fetchone()
        return dict(row) if row else None


def list_all(library_root: Path, limit: int = 100, offset: int = 0) -> list[dict]:
    with connect(library_root, read_only=True) as conn:
        rows = conn.execute(
            "SELECT * FROM papers ORDER BY year DESC, title LIMIT ? OFFSET ?",
            (limit, offset),
        ).fetchall()
        return [dict(r) for r in rows]
