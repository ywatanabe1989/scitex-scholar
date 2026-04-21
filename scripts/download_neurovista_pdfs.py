#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File: scripts/download_neurovista_pdfs.py
# ----------------------------------------
"""Auto-download NeuroVista core paper PDFs into the ywata-note-win cache.

Reads a seed BibTeX (defaults to
``~/proj/neurovista/.scitex/scholar/neurovista_seeds.bib``), checks which DOIs
are already present in the Scholar library under the ``neurovista`` project, and
downloads only the missing ones via scitex-scholar's PDF-fetch API.

After the library download, PDFs are mirrored into the NeuroVista project cache
(``~/proj/neurovista/.scitex/scholar/downloads/``) so the writer can cite them
with local copies.

Logs per-DOI successes/failures to stdout and to
``~/proj/neurovista/.scitex/scholar/logs/download_<timestamp>.json``.

Usage:
    python scripts/download_neurovista_pdfs.py
    python scripts/download_neurovista_pdfs.py --bibtex /path/to/custom.bib
    python scripts/download_neurovista_pdfs.py --dry-run
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

DEFAULT_BIBTEX = Path.home() / "proj/neurovista/.scitex/scholar/neurovista_seeds.bib"
DEFAULT_DOWNLOADS_MIRROR = Path.home() / "proj/neurovista/.scitex/scholar/downloads"
DEFAULT_LOG_DIR = Path.home() / "proj/neurovista/.scitex/scholar/logs"
DEFAULT_PROJECT = "neurovista"


def parse_bibtex_dois(bibtex_path: Path) -> List[Tuple[str, str]]:
    """Return list of (citekey, doi) from a BibTeX file.

    Intentionally minimal -- avoids pulling a full BibTeX parser for a tiny
    seed file. Accepts both braces and quotes around the DOI value and
    normalises to lowercase (DOIs are case-insensitive).
    """
    text = bibtex_path.read_text(encoding="utf-8")
    # Match @type{citekey, ... doi = {...}, ...}
    entries = re.findall(
        r"@\w+\s*\{\s*([^,]+)\s*,(.*?)\n\}", text, flags=re.DOTALL
    )
    out: List[Tuple[str, str]] = []
    for citekey, body in entries:
        m = re.search(r"doi\s*=\s*[\{\"]([^\}\"]+)[\}\"]", body, flags=re.IGNORECASE)
        if m:
            out.append((citekey.strip(), m.group(1).strip().lower()))
    return out


def discover_cached_dois(project: str) -> Dict[str, Path]:
    """Return {doi: storage_dir} for PDFs already in the Scholar library.

    Looks for metadata.json under ``~/.scitex/scholar/library/<project>/*/``.
    Resolves symlinks so callers can reach into MASTER storage for the PDF.
    """
    library_project = Path.home() / ".scitex/scholar/library" / project
    cached: Dict[str, Path] = {}
    if not library_project.is_dir():
        return cached
    for entry in sorted(library_project.iterdir()):
        meta = entry / "metadata.json"
        if not meta.is_file():
            continue
        try:
            data = json.loads(meta.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        # Support both legacy flat shape and current nested shape
        doi = (
            data.get("doi")
            or data.get("metadata", {}).get("id", {}).get("doi")
            or None
        )
        if doi:
            cached[doi.lower()] = entry.resolve()
    return cached


def find_pdf_in_storage(storage_dir: Path) -> Optional[Path]:
    """Return the first .pdf under a scholar storage directory, if any."""
    if not storage_dir.is_dir():
        return None
    for pdf in sorted(storage_dir.glob("*.pdf")):
        return pdf
    return None


def find_mirror_pdf(citekey: str, mirror_dir: Path) -> Optional[Path]:
    """Return a pre-existing PDF in the mirror that matches this citekey.

    Matches both ``<citekey>.pdf`` and ``<citekey>_<suffix>.pdf`` (e.g.
    ``brinkmann2016_awx098.pdf``) so manually-placed downloads are honoured.
    """
    if not mirror_dir.is_dir():
        return None
    exact = mirror_dir / f"{citekey}.pdf"
    if exact.is_file() and exact.stat().st_size > 0:
        return exact
    for pdf in sorted(mirror_dir.glob(f"{citekey}_*.pdf")):
        if pdf.stat().st_size > 0:
            return pdf
    return None


def mirror_pdf(src: Path, citekey: str, mirror_dir: Path) -> Optional[Path]:
    """Copy `src` into `mirror_dir/<citekey>.pdf` if not already present."""
    mirror_dir.mkdir(parents=True, exist_ok=True)
    dest = mirror_dir / f"{citekey}.pdf"
    if dest.exists() and dest.stat().st_size > 0:
        return dest
    try:
        shutil.copy2(src, dest)
        return dest
    except OSError as exc:
        print(f"  ! mirror copy failed ({citekey}): {exc}")
        return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--bibtex",
        type=Path,
        default=DEFAULT_BIBTEX,
        help=f"Seed BibTeX path (default: {DEFAULT_BIBTEX})",
    )
    parser.add_argument(
        "--project",
        default=DEFAULT_PROJECT,
        help=f"Scholar project name (default: {DEFAULT_PROJECT})",
    )
    parser.add_argument(
        "--mirror-dir",
        type=Path,
        default=DEFAULT_DOWNLOADS_MIRROR,
        help=(
            "Copy downloaded PDFs here for the writer to consume "
            f"(default: {DEFAULT_DOWNLOADS_MIRROR})"
        ),
    )
    parser.add_argument(
        "--log-dir",
        type=Path,
        default=DEFAULT_LOG_DIR,
        help=f"Where to write the per-run JSON log (default: {DEFAULT_LOG_DIR})",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only report which DOIs would be fetched; no downloads.",
    )
    parser.add_argument(
        "--browser-mode",
        default="stealth",
        choices=["stealth", "interactive"],
        help="Scholar browser mode (default: stealth)",
    )
    args = parser.parse_args()

    if not args.bibtex.is_file():
        print(f"ERROR: seed BibTeX not found: {args.bibtex}", file=sys.stderr)
        return 2

    seeds = parse_bibtex_dois(args.bibtex)
    if not seeds:
        print(f"ERROR: no DOIs parsed from {args.bibtex}", file=sys.stderr)
        return 2

    print(f"Seed papers: {len(seeds)} (from {args.bibtex})")

    cached = discover_cached_dois(args.project)
    print(f"Already in scholar library/{args.project}: {len(cached)}")

    to_fetch: List[Tuple[str, str]] = []
    already_present: List[Tuple[str, str]] = []
    metadata_only: List[Tuple[str, str]] = []
    mirror_only: List[Tuple[str, str, Path]] = []
    for citekey, doi in seeds:
        if doi in cached:
            # Distinguish "PDF in library" from "metadata-only library entry"
            if find_pdf_in_storage(cached[doi]):
                already_present.append((citekey, doi))
                continue
            # Metadata-only — still needs the PDF
            mirror_pdf_path = find_mirror_pdf(citekey, args.mirror_dir)
            if mirror_pdf_path:
                mirror_only.append((citekey, doi, mirror_pdf_path))
                continue
            metadata_only.append((citekey, doi))
            to_fetch.append((citekey, doi))
            continue
        mirror_pdf_path = find_mirror_pdf(citekey, args.mirror_dir)
        if mirror_pdf_path:
            mirror_only.append((citekey, doi, mirror_pdf_path))
            continue
        to_fetch.append((citekey, doi))

    if metadata_only:
        print(
            "Library metadata-only (no PDF yet): "
            f"{len(metadata_only)}"
        )
        for ck, doi in metadata_only:
            print(f"  * {ck}: {doi}")

    if mirror_only:
        print(
            f"Pre-existing in mirror (not in library, skip): {len(mirror_only)}"
        )
        for ck, doi, pdf in mirror_only:
            print(f"  ~ {ck} ({doi}) -> {pdf.name}")

    print(f"Missing and to fetch: {len(to_fetch)}")
    for ck, doi in to_fetch:
        print(f"  - {ck}: {doi}")

    # Mirror already-present PDFs into the project cache for completeness
    args.mirror_dir.mkdir(parents=True, exist_ok=True)
    mirrored_existing = 0
    for ck, doi in already_present:
        pdf = find_pdf_in_storage(cached[doi])
        if pdf and mirror_pdf(pdf, ck, args.mirror_dir):
            mirrored_existing += 1
    print(f"Mirrored already-cached PDFs into {args.mirror_dir}: {mirrored_existing}")

    if args.dry_run:
        print("Dry run complete -- no downloads attempted.")
        return 0

    stats: Dict[str, int] = {"downloaded": 0, "failed": 0, "errors": 0}
    per_doi: Dict[str, str] = {}

    if to_fetch:
        # Import lazily so --dry-run works without the scholar deps
        from scitex_scholar import Scholar

        scholar = Scholar(project=args.project, browser_mode=args.browser_mode)

        dois_only = [doi for _, doi in to_fetch]
        try:
            stats = scholar.download_pdfs_from_dois(dois_only)
        except Exception as exc:  # noqa: BLE001 - surface everything for the log
            print(f"ERROR: scholar.download_pdfs_from_dois failed: {exc}",
                  file=sys.stderr)
            stats = {"downloaded": 0, "failed": len(dois_only), "errors": 1}
            per_doi = {doi: f"exception: {exc}" for doi in dois_only}

        # Re-scan the library to pick up newly-downloaded PDFs and mirror them
        refreshed = discover_cached_dois(args.project)
        mirrored_new = 0
        for ck, doi in to_fetch:
            if doi in refreshed:
                pdf = find_pdf_in_storage(refreshed[doi])
                if pdf and mirror_pdf(pdf, ck, args.mirror_dir):
                    mirrored_new += 1
                    per_doi[doi] = "downloaded"
                else:
                    per_doi[doi] = "library entry exists but no .pdf found"
            else:
                per_doi.setdefault(doi, "failed")
        print(f"Mirrored newly-downloaded PDFs: {mirrored_new}")
    else:
        print("Nothing to download -- all seeds already cached.")

    # Write a run log
    args.log_dir.mkdir(parents=True, exist_ok=True)
    log_path = args.log_dir / f"download_{datetime.now():%Y%m%d_%H%M%S}.json"
    log_path.write_text(
        json.dumps(
            {
                "bibtex": str(args.bibtex),
                "project": args.project,
                "mirror_dir": str(args.mirror_dir),
                "seeds_total": len(seeds),
                "already_present": [
                    {"citekey": ck, "doi": doi} for ck, doi in already_present
                ],
                "metadata_only": [
                    {"citekey": ck, "doi": doi} for ck, doi in metadata_only
                ],
                "mirror_only": [
                    {"citekey": ck, "doi": doi, "pdf": str(pdf)}
                    for ck, doi, pdf in mirror_only
                ],
                "fetched": [
                    {"citekey": ck, "doi": doi, "result": per_doi.get(doi, "unknown")}
                    for ck, doi in to_fetch
                ],
                "stats": stats,
                "timestamp": datetime.now().isoformat(),
            },
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    print(f"Log written: {log_path}")

    print()
    print("Summary")
    print(f"  attempted     : {len(to_fetch)}")
    print(f"  downloaded    : {stats.get('downloaded', 0)}")
    print(f"  failed        : {stats.get('failed', 0)}")
    print(f"  errors        : {stats.get('errors', 0)}")
    print(f"  already cached: {len(already_present)}")
    print(f"  metadata only : {len(metadata_only)}")
    print(f"  mirror only   : {len(mirror_only)}")

    return 0 if stats.get("errors", 0) == 0 else 1


if __name__ == "__main__":
    sys.exit(main())

# EOF
