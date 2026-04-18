"""PDF annotation — tight per-sentence highlights + legend/signature page."""

from __future__ import annotations

from typing import Iterable, Optional, cast

import pymupdf

from ._blocks import Block
from ._colors import CATEGORIES, CATEGORY_LABELS, COLOR_RGB


def _line_quads_in_rect(page: pymupdf.Page, rect: pymupdf.Rect) -> list[pymupdf.Quad]:
    """Return tight per-line quads for any text inside ``rect``.

    PyMuPDF's dict layout reports line-level bounding boxes that hug the
    actual glyph extent, so highlights do not inflate into left/right
    margins.
    """
    quads: list[pymupdf.Quad] = []
    data = cast(dict, page.get_text("dict", clip=rect))
    for blk in data.get("blocks", []):
        if not isinstance(blk, dict) or blk.get("type") != 0:
            continue
        for line in blk.get("lines", []):
            if not isinstance(line, dict):
                continue
            bb = line.get("bbox", (0, 0, 0, 0))
            x0, y0, x1, y1 = (float(v) for v in bb)
            if x1 <= x0 or y1 <= y0:
                continue
            quads.append(pymupdf.Rect(x0, y0, x1, y1).quad)
    return quads


def _search_quads_for_sentence(
    page: pymupdf.Page, rect: pymupdf.Rect, sentence: str
) -> list[pymupdf.Quad]:
    """Try PyMuPDF's text search for a sentence, with graceful fallbacks.

    Returns an empty list when the sentence cannot be located — the
    caller should then fall back to line-level quads within the clip.
    """
    probes: Iterable[str] = (
        sentence[:120] if len(sentence) > 120 else sentence,
        sentence[:80],
        sentence[:50],
    )
    for probe in probes:
        probe = probe.strip()
        if len(probe) < 20:
            continue
        found = page.search_for(probe, clip=rect, quads=True)
        if found:
            return list(found)
    return []


def apply_highlights(doc: pymupdf.Document, blocks: list[Block]) -> int:
    """Overlay one highlight annotation per classified block. Returns count."""
    added = 0
    for b in blocks:
        if b.category is None:
            continue
        page = doc[b.page]
        rect = pymupdf.Rect(*b.bbox)

        # Prefer sentence-level tight quads via text search; fall back to
        # line-level bounding boxes within the clip; last-resort use the
        # raw clip rect.
        quads = _search_quads_for_sentence(page, rect, b.text)
        if not quads:
            quads = _line_quads_in_rect(page, rect)
        if not quads:
            quads = [rect.quad]

        annot = page.add_highlight_annot(quads)
        annot.set_colors(stroke=COLOR_RGB[b.category])
        annot.set_info(
            title="scitex-scholar",
            content=f"{b.category} (conf={b.confidence:.2f})",
        )
        annot.update(opacity=0.4)
        added += 1
    return added


def add_legend_page(
    doc: pymupdf.Document,
    *,
    signature: str,
    model_label: Optional[str],
    source_name: str,
) -> None:
    """Prepend a legend + signature page describing the 5-colour scheme."""
    first = doc[0]
    w, h = first.rect.width, first.rect.height
    page = doc.new_page(pno=0, width=w, height=h)

    page.insert_text(
        (48, 72),
        "Semantic highlights",
        fontname="helv",
        fontsize=20,
    )
    page.insert_text(
        (48, 96),
        f"source: {source_name}",
        fontname="helv",
        fontsize=10,
        color=(0.3, 0.3, 0.3),
    )

    sig_y = 118
    page.insert_text(
        (48, sig_y),
        signature,
        fontname="helv",
        fontsize=9,
        color=(0.4, 0.4, 0.4),
    )
    if model_label:
        page.insert_text(
            (48, sig_y + 14),
            f"classifier: {model_label}",
            fontname="helv",
            fontsize=9,
            color=(0.4, 0.4, 0.4),
        )

    legend_top = sig_y + 52
    page.insert_text(
        (48, legend_top),
        "Legend",
        fontname="helv",
        fontsize=14,
    )
    y = legend_top + 24
    row_h = 28
    swatch_w, swatch_h = 36, 16
    for cat in CATEGORIES:
        rgb = COLOR_RGB[cat]
        swatch = pymupdf.Rect(48, y, 48 + swatch_w, y + swatch_h)
        page.draw_rect(swatch, color=rgb, fill=rgb, fill_opacity=0.4, width=0.5)
        page.insert_text(
            (48 + swatch_w + 12, y + swatch_h - 3),
            CATEGORY_LABELS[cat],
            fontname="helv",
            fontsize=11,
        )
        y += row_h

    page.insert_text(
        (48, h - 48),
        "Highlights are PDF annotations on a copy of the source document. "
        "The original text and layout are unchanged.",
        fontname="helv",
        fontsize=8,
        color=(0.4, 0.4, 0.4),
    )
