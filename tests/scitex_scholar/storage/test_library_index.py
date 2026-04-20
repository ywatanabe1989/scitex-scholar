#!/usr/bin/env python3
"""Tests for the library SQLite index."""

from __future__ import annotations

import json
import sqlite3
from pathlib import Path

import pytest

from scitex_scholar.storage import _library_index as idx


def _write_entry(
    root: Path,
    paper_id: str,
    doi: str | None = None,
    arxiv_id: str | None = None,
    pmid: str | None = None,
    title: str = "t",
    year: int | None = 2024,
    journal: str = "J",
    is_oa: bool = False,
) -> None:
    entry = root / "MASTER" / paper_id
    entry.mkdir(parents=True)
    md = {
        "metadata": {
            "id": {"doi": doi, "arxiv_id": arxiv_id, "pmid": pmid},
            "basic": {"title": title, "year": year},
            "publication": {"journal": journal},
            "access": {"is_open_access": is_oa},
        }
    }
    (entry / "metadata.json").write_text(json.dumps(md))


def test_build_populates_papers(tmp_path: Path):
    _write_entry(tmp_path, "AAA", doi="10.1/aaa", year=2023, title="Alpha")
    _write_entry(tmp_path, "BBB", pmid="123", year=2024, title="Beta")

    n = idx.build(tmp_path)
    assert n == 2
    assert idx.db_path(tmp_path).exists()

    conn = sqlite3.connect(idx.db_path(tmp_path))
    conn.row_factory = sqlite3.Row
    rows = {r["paper_id"]: dict(r) for r in conn.execute("SELECT * FROM papers")}
    assert rows["AAA"]["doi"] == "10.1/aaa"
    assert rows["BBB"]["pmid"] == "123"
    assert rows["AAA"]["title"] == "Alpha"
    conn.close()


def test_build_is_idempotent(tmp_path: Path):
    _write_entry(tmp_path, "AAA", doi="10.1/aaa")
    idx.build(tmp_path)
    idx.build(tmp_path)  # rebuild, no error
    assert idx.lookup_by_doi(tmp_path, "10.1/aaa")["paper_id"] == "AAA"


def test_lookup_by_doi_case_insensitive(tmp_path: Path):
    _write_entry(tmp_path, "AAA", doi="10.1/aaa")
    idx.build(tmp_path)
    assert idx.lookup_by_doi(tmp_path, "10.1/AAA") is not None


def test_lookup_missing_returns_none(tmp_path: Path):
    _write_entry(tmp_path, "AAA", doi="10.1/aaa")
    idx.build(tmp_path)
    assert idx.lookup_by_doi(tmp_path, "nope") is None
    assert idx.lookup_by_paper_id(tmp_path, "ZZZ") is None


def test_list_all_orders_by_year_desc(tmp_path: Path):
    _write_entry(tmp_path, "OLD", doi="10.1/old", year=2010, title="old")
    _write_entry(tmp_path, "NEW", doi="10.1/new", year=2025, title="new")
    idx.build(tmp_path)
    rows = idx.list_all(tmp_path)
    assert [r["paper_id"] for r in rows] == ["NEW", "OLD"]


def test_duplicate_doi_second_wins(tmp_path: Path):
    # Two MASTER entries with the same DOI is a data bug; INSERT OR REPLACE
    # means the second-inserted row wins (silently replacing the first).
    # The DB stays consistent with a UNIQUE(doi) invariant.
    _write_entry(tmp_path, "AAA", doi="10.1/same", title="first")
    _write_entry(tmp_path, "BBB", doi="10.1/same", title="second")
    n = idx.build(tmp_path)
    assert n == 2  # attempted to insert 2 rows
    rows = idx.list_all(tmp_path)
    assert len(rows) == 1  # only one survives the UNIQUE(doi) constraint
    assert rows[0]["doi"] == "10.1/same"


def test_build_requires_master_dir(tmp_path: Path):
    with pytest.raises(FileNotFoundError):
        idx.build(tmp_path)


def test_migrate_on_fresh_db_creates_schema(tmp_path: Path):
    (tmp_path / "MASTER").mkdir()
    v = idx.migrate(tmp_path)
    assert v == idx.SCHEMA_VERSION


def test_schema_version_persisted(tmp_path: Path):
    _write_entry(tmp_path, "AAA", doi="10.1/aaa")
    idx.build(tmp_path)
    conn = sqlite3.connect(idx.db_path(tmp_path))
    v = conn.execute("SELECT value FROM meta WHERE key='schema_version'").fetchone()[0]
    conn.close()
    assert int(v) == idx.SCHEMA_VERSION
