"""LLM and offline classifiers for the semantic highlighter."""

from __future__ import annotations

import json
from typing import Any, Optional

from ._blocks import Block
from ._colors import CATEGORIES

CLASSIFIER_SYSTEM = """You tag sentences from an academic paper into at most one of these rhetorical categories. Emit "none" when nothing clearly fits — precision matters more than recall.

Categories (use these exact strings):
  focal_claim            — THIS paper states, clarifies, suggests, demonstrates, establishes, or
                           reports a finding, result, or interpretation of its own. First-person
                           stance markers ("we show/find/demonstrate/suggest/clarify/establish",
                           "our results", "this finding", "these data indicate") are strong signals.
                           Quantitative results ("β = -1.5", "5/6 subjects", "accuracy 0.85") are
                           usually claims when attached to the paper's own analysis.
  focal_method           — description of THIS paper's own novel method, model, cohort, or analysis
                           pipeline. NOT routine study logistics. NOT background on existing methods.
  focal_limitation       — self-admitted limitation, caveat, confound, or threat to validity of
                           THIS paper. Hedging that names a weakness in the paper's own work.
  related_supportive     — a specific prior/other paper whose finding SUPPORTS this paper's position
                           ("consistent with X (2019)", "as shown by Y", "corroborates").
  related_contradictive  — a specific prior/other paper whose finding CONTRADICTS this paper
                           ("in contrast to X", "unlike Y", "disagrees with").
  none                   — background setup without a stance, reference list entries, headers,
                           figure/table prose, boilerplate. Default when uncertain.

Important: the priority is catching CLAIMS. If a sentence both describes a method and reports
what that method yielded, prefer focal_claim. If a block mentions prior work but does not take a
supportive or contradictive stance toward it, return "none".

Confidence in [0,1]: <0.5 = guess, >0.8 = clear-cut.

Respond with ONLY a JSON array of objects: {"id": int, "category": str, "confidence": float}. Include every input id exactly once."""


def _extract_text_from_message(msg: Any) -> str:
    for block in msg.content:
        if getattr(block, "type", None) == "text":
            return block.text
    return ""


def _strip_code_fence(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("```"):
        raw = raw.split("```", 2)[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.strip()
    return raw


def classify_llm(
    blocks: list[Block],
    model: str,
    batch_size: int = 25,
    on_warning: Optional[Any] = None,
) -> None:
    """Classify blocks in-place by calling the Anthropic Messages API."""
    import anthropic

    client = anthropic.Anthropic()
    for start in range(0, len(blocks), batch_size):
        batch = blocks[start : start + batch_size]
        payload = [{"id": b.id, "text": b.text} for b in batch]
        msg = client.messages.create(
            model=model,
            max_tokens=2048,
            system=CLASSIFIER_SYSTEM,
            messages=[
                {
                    "role": "user",
                    "content": (
                        f"Classify these {len(batch)} units:\n\n"
                        f"{json.dumps(payload, ensure_ascii=False)}"
                    ),
                }
            ],
        )
        raw = _strip_code_fence(_extract_text_from_message(msg))
        try:
            preds = json.loads(raw)
        except json.JSONDecodeError as exc:
            if on_warning is not None:
                on_warning(f"parse failure at batch {start}: {exc}")
            continue
        by_id = {b.id: b for b in batch}
        for p in preds:
            b = by_id.get(p.get("id"))
            if b is None:
                continue
            cat = p.get("category", "none")
            if cat in CATEGORIES:
                b.category = cat
                b.confidence = float(p.get("confidence", 0.0))


def classify_stub(blocks: list[Block]) -> None:
    """Offline keyword heuristic. No API calls. Useful for smoke tests."""
    rules = [
        (
            "focal_limitation",
            ("limitation", "caveat", "however, our", "we did not", "a threat to"),
        ),
        (
            "focal_method",
            ("we propose", "we introduce", "our method", "our approach", "we develop"),
        ),
        (
            "focal_claim",
            (
                "we show",
                "we find",
                "we demonstrate",
                "we suggest",
                "we clarify",
                "we establish",
                "our results",
                "we report",
                "this finding",
            ),
        ),
        (
            "related_contradictive",
            ("in contrast", "unlike", "disagree", "contrary to", "fails to"),
        ),
        (
            "related_supportive",
            (
                "consistent with",
                "in line with",
                "as shown by",
                "supports",
                "corroborat",
            ),
        ),
    ]
    for b in blocks:
        low = b.text.lower()
        for cat, needles in rules:
            if any(n in low for n in needles):
                b.category = cat
                b.confidence = 0.5
                break
