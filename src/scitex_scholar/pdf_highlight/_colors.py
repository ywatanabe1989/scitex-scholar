"""5-category rhetorical colour scheme for the semantic highlighter."""

from __future__ import annotations

CATEGORIES = (
    "focal_claim",
    "focal_method",
    "focal_limitation",
    "related_supportive",
    "related_contradictive",
)

_HEX = {
    "focal_claim": "#A8E6A1",  # green
    "focal_method": "#D4B8FF",  # purple
    "focal_limitation": "#FFA3A3",  # red
    "related_supportive": "#9FD6F7",  # light blue
    "related_contradictive": "#FFB870",  # orange
}


def _hex_to_rgb01(h: str) -> tuple[float, float, float]:
    h = h.lstrip("#")
    r, g, b = (int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4))
    return r, g, b


COLOR_RGB = {k: _hex_to_rgb01(v) for k, v in _HEX.items()}

CATEGORY_LABELS = {
    "focal_claim": "Focal — claim / finding (clarified, suggested, demonstrated)",
    "focal_method": "Focal — novel method or analysis",
    "focal_limitation": "Focal — limitation / caveat",
    "related_supportive": "Related — supporting evidence",
    "related_contradictive": "Related — contradicting evidence",
}
