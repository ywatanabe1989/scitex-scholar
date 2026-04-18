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


# Compact legend block sized for a corner overlay. Width is chosen so the
# category labels fit at 7pt; height covers 5 swatch rows + 2 signature lines.
_LEGEND_W = 210
_LEGEND_H = 112
_MARGIN = 24


def _corner_rect(
    page: pymupdf.Page, corner: str, w: float = _LEGEND_W, h: float = _LEGEND_H
) -> pymupdf.Rect:
    """Return a rect anchored to ``corner`` of ``page`` ("lr", "ll", "lc")."""
    pw, ph = page.rect.width, page.rect.height
    y0 = ph - _MARGIN - h
    y1 = ph - _MARGIN
    if corner == "ll":
        x0, x1 = _MARGIN, _MARGIN + w
    elif corner == "lc":
        x0 = (pw - w) / 2
        x1 = x0 + w
    else:  # "lr" default — lower-right
        x0, x1 = pw - _MARGIN - w, pw - _MARGIN
    return pymupdf.Rect(x0, y0, x1, y1)


def _draw_legend_overlay(
    page: pymupdf.Page,
    rect: pymupdf.Rect,
    *,
    signature: str,
    model_label: Optional[str],
    source_name: str,
) -> None:
    """Paint a small opaque legend panel into ``rect`` on ``page``.

    Opaque white background so the panel remains readable even if it
    overlays text underneath. Kept intentionally small — the
    information density is high and the goal is unobtrusive reference.
    """
    page.draw_rect(
        rect,
        color=(0.6, 0.6, 0.6),
        fill=(1.0, 1.0, 1.0),
        fill_opacity=0.92,
        width=0.4,
    )

    x0, y0 = rect.x0, rect.y0
    pad = 6

    page.insert_text(
        (x0 + pad, y0 + pad + 7),
        "Semantic highlights",
        fontname="helv",
        fontsize=7.5,
        color=(0.2, 0.2, 0.2),
    )

    swatch_w, swatch_h = 10, 7
    row_h = 10
    row_y = y0 + pad + 19
    short_labels = {
        "focal_claim": "claim / finding",
        "focal_method": "novel method",
        "focal_limitation": "limitation",
        "related_supportive": "related (supportive)",
        "related_contradictive": "related (contradictive)",
    }
    for cat in CATEGORIES:
        rgb = COLOR_RGB[cat]
        sw = pymupdf.Rect(
            x0 + pad, row_y - swatch_h + 2, x0 + pad + swatch_w, row_y + 2
        )
        page.draw_rect(sw, color=rgb, fill=rgb, fill_opacity=0.4, width=0.25)
        page.insert_text(
            (x0 + pad + swatch_w + 5, row_y),
            short_labels[cat],
            fontname="helv",
            fontsize=6.5,
            color=(0.2, 0.2, 0.2),
        )
        row_y += row_h

    # Two-line signature in 5pt — line 1: source, line 2: model + timestamp.
    # signature string looks like
    #   "Highlighted by scitex-scholar v1.0.1 (pdf_highlight) — 2026-04-18 20:27"
    ts = signature.rsplit("—", 1)[-1].strip() if "—" in signature else ""
    line1 = f"scitex-scholar · {source_name}"
    line2_bits = []
    if model_label:
        line2_bits.append(model_label)
    if ts:
        line2_bits.append(ts)
    line2 = "  ·  ".join(line2_bits)
    page.insert_text(
        (x0 + pad, row_y + 4),
        line1,
        fontname="helv",
        fontsize=5.5,
        color=(0.45, 0.45, 0.45),
    )
    if line2:
        page.insert_text(
            (x0 + pad, row_y + 11),
            line2,
            fontname="helv",
            fontsize=5.5,
            color=(0.45, 0.45, 0.45),
        )
    # CATEGORY_LABELS kept in import for future full-form rendering (e.g.
    # --legend-verbose) even though short_labels is used here.
    _ = CATEGORY_LABELS


def add_legend(
    doc: pymupdf.Document,
    *,
    signature: str,
    model_label: Optional[str],
    source_name: str,
    corner: str = "lr",
) -> None:
    """Stamp a compact legend overlay in a corner of the last page.

    Default corner is lower-right ("lr"); valid alternatives are
    lower-left ("ll") and lower-centre ("lc"). No new pages are added —
    the overlay sits on top of any existing content (opaque background).
    """
    page = doc[-1]
    rect = _corner_rect(page, corner)
    _draw_legend_overlay(
        page,
        rect,
        signature=signature,
        model_label=model_label,
        source_name=source_name,
    )


# Back-compat aliases — older callers referenced add_legend_page and
# add_legend_footer; both now collapse to the corner overlay on the
# last page, which is what the user confirmed they want.
add_legend_page = add_legend
add_legend_footer = add_legend
