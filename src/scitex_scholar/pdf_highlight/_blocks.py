"""Block extraction — paragraph-level layout + sentence-level splitting."""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional

import pymupdf


@dataclass
class Block:
    """A unit of classification — either a paragraph or a sentence.

    ``bbox`` is always the paragraph-level clip rectangle. For sentence
    units this is used only as the search region when locating the
    sentence's glyphs on the page at annotation time.
    """

    id: int
    page: int
    bbox: tuple[float, float, float, float]
    text: str
    category: Optional[str] = None
    confidence: float = 0.0


_ABBREV = {
    "fig",
    "figs",
    "eq",
    "eqs",
    "ref",
    "refs",
    "eg",
    "e.g",
    "ie",
    "i.e",
    "cf",
    "vs",
    "al",
    "etc",
    "inc",
    "ltd",
    "dr",
    "prof",
    "mr",
    "mrs",
    "no",
    "nos",
    "vol",
    "pp",
    "chap",
    "sec",
    "st",
}

_SENT_RE = re.compile(r"(?<=[.!?])\s+(?=[A-Z0-9(\"'])")


def _split_sentences(text: str) -> list[str]:
    """Naive academic-aware sentence splitter.

    Splits on sentence-ending punctuation followed by whitespace and a
    capital/digit/opening quote, then re-joins splits that follow common
    abbreviations (Fig., e.g., et al., single-initial J.).
    """
    parts = _SENT_RE.split(text)
    out: list[str] = []
    for p in parts:
        p = p.strip()
        if not p:
            continue
        if out:
            last = out[-1]
            tail = last.rsplit(None, 1)[-1].lower().rstrip(".,")
            if tail in _ABBREV or (len(tail) <= 2 and tail.isalpha()):
                out[-1] = f"{last} {p}"
                continue
        out.append(p)
    return out


def _iter_text_blocks(
    doc: pymupdf.Document, min_chars: int, sentence_level: bool
) -> Iterable[Block]:
    next_id = 0
    for page_idx in range(doc.page_count):
        page = doc[page_idx]
        for b in page.get_text("blocks"):
            btype = b[6]
            if btype != 0:
                continue
            text = " ".join(str(b[4]).split())
            if len(text) < min_chars:
                continue
            bbox = (float(b[0]), float(b[1]), float(b[2]), float(b[3]))
            if not sentence_level:
                yield Block(id=next_id, page=page_idx, bbox=bbox, text=text)
                next_id += 1
                continue
            for sent in _split_sentences(text):
                if len(sent) < min_chars:
                    continue
                yield Block(id=next_id, page=page_idx, bbox=bbox, text=sent)
                next_id += 1


def extract_blocks(
    pdf_path: str | os.PathLike,
    min_chars: int = 40,
    *,
    sentence_level: bool = True,
) -> tuple[pymupdf.Document, list[Block]]:
    """Open a PDF and return (document, units-of-classification).

    ``sentence_level=True`` (default) yields one unit per sentence,
    which gives much tighter highlights — avoids painting a whole
    paragraph green when only its last two sentences state the claim.
    ``sentence_level=False`` yields one unit per paragraph.

    Units shorter than ``min_chars`` are dropped (filters page numbers,
    running headers, short captions, and sentence fragments).
    """
    doc = pymupdf.open(Path(pdf_path))
    return doc, list(
        _iter_text_blocks(doc, min_chars=min_chars, sentence_level=sentence_level)
    )
