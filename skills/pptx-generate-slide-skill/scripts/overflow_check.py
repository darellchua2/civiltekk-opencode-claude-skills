"""BT-142 Phase 2.4 — Interactive overflow detection.

Wraps ``text_fit.py``'s estimator in a binary ``FIT``/``OVERFLOW`` decision.
When ``OVERFLOW``, the orchestrator agent should pause and present a
``question()`` to the user offering two paths:

  - **Squeeze** — keep as 1 slide; engine shrinks per-placeholder font sizes
    in −2pt steps (8pt floor) to fit content within the original boundaries.
  - **Split** — split into 2 slides at a natural breakpoint, preserving the
    original speaker message verbatim across both and drafting a connecting
    transition line.

This module is **pure** (no I/O, no LLM calls, no ``question()`` invocation).
It returns structured verdicts; the orchestrator agent is responsible for
presenting the question and executing the chosen path. This keeps the
detection logic unit-testable without mocking the question tool.

Headless fallback (no interactive session): the orchestrator picks **Split**
with safe defaults and emits a notice in the return contract ``Issues:`` field.
Squeeze is never auto-chosen silently.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any, Dict, List, Literal, Optional, Tuple

logger = logging.getLogger(__name__)

# Re-use the calibrated estimator from text_fit (Phase 2.4a).
try:
    from text_fit import (
        estimate_height_in,
        estimate_lines,
        fit_font_size,
        LINE_SPACING_DEFAULT,
        DEFAULT_PARA_SPACING_FACTOR,
    )
except ImportError:  # pragma: no cover — import-time fallback
    logger.warning("text_fit not importable; overflow_check will be conservative")
    estimate_height_in = None  # type: ignore[assignment]
    estimate_lines = None  # type: ignore[assignment]
    fit_font_size = None  # type: ignore[assignment]
    LINE_SPACING_DEFAULT = 1.3  # type: ignore[assignment]
    DEFAULT_PARA_SPACING_FACTOR = 0.7  # type: ignore[assignment]


OverflowVerdict = Literal["FIT", "OVERFLOW"]

# Body-role placeholder types that are subject to text overflow.
_BODY_ROLES = {"body", "body_left", "body_right", "subtitle"}


@dataclass
class OverflowFinding:
    """Per-slide overflow verdict + evidence."""

    slide_index: int
    slide_type: str
    verdict: OverflowVerdict
    overflowing_fields: List[str] = field(default_factory=list)
    estimated_heights_in: Dict[str, float] = field(default_factory=dict)
    available_heights_in: Dict[str, float] = field(default_factory=dict)
    notes: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "slide_index": self.slide_index,
            "slide_type": self.slide_type,
            "verdict": self.verdict,
            "overflowing_fields": self.overflowing_fields,
            "estimated_heights_in": self.estimated_heights_in,
            "available_heights_in": self.available_heights_in,
            "notes": self.notes,
        }


def _available_height_for_field(
    field_name: str,
    slide_type: str,
    contract: Optional[Dict[str, Any]],
) -> Optional[float]:
    """Look up the available content height (in inches) for a body field.

    Returns ``None`` when the contract is missing or the field is unknown —
    in that case the caller treats overflow detection as best-effort (a missing
    ceiling means we cannot confidently say OVERFLOW, so default to FIT and
    let the post-render image verification (Phase 2.4b) catch real overflow).
    """
    if contract is None:
        return None
    # The contract exposes per-layout placeholder geometry. Look up by slide_type.
    layouts_by_type = contract.get("layouts_by_slide_type") if isinstance(contract, dict) else None
    if not isinstance(layouts_by_type, dict):
        return None
    layout = layouts_by_type.get(slide_type)
    if not isinstance(layout, dict):
        return None
    placeholders = layout.get("placeholders") if isinstance(layout.get("placeholders"), list) else []
    # Match by role: 'body' → 'body'; 'body_left'/'body_right' → look for left/right
    for ph in placeholders:
        if not isinstance(ph, dict):
            continue
        ph_role = ph.get("role", "")
        ph_height = ph.get("height_in")
        if ph_height is None:
            continue
        if field_name == "body" and ph_role in ("body", "OBJECT", "object"):
            try:
                return float(ph_height)
            except (TypeError, ValueError):
                continue
        if field_name in ("body_left", "body_right") and ph_role in ("body", "OBJECT", "object"):
            # Two-body layouts report a single body height per column; use as estimate.
            try:
                return float(ph_height)
            except (TypeError, ValueError):
                continue
        if field_name == "subtitle" and ph_role in ("subtitle", "SUBTITLE"):
            try:
                return float(ph_height)
            except (TypeError, ValueError):
                continue
    return None


def _text_for_field(slide_data: Dict[str, Any], field_name: str) -> str:
    """Extract the text content for a body-like field from slide_data."""
    val = slide_data.get(field_name)
    if val is None:
        return ""
    return str(val)


def _field_overflows(
    text: str,
    available_height_in: Optional[float],
    width_in: float = 6.0,
    base_size_pt: float = 14.0,
) -> Tuple[bool, Optional[float]]:
    """Check if ``text`` overflows a placeholder of ``available_height_in``.

    Returns ``(overflows, estimated_height_in)``. When ``available_height_in``
    is ``None`` or the estimator is unavailable, returns ``(False, None)``
    (defer to the post-render image oracle in Phase 2.4b).
    """
    if not text:
        return False, 0.0
    if available_height_in is None:
        return False, None  # unknown ceiling → defer to image oracle
    if estimate_height_in is None or estimate_lines is None:
        return False, None  # estimator unavailable → defer

    try:
        # Count paragraphs (split on \n; treat multiple paragraphs as gaps)
        paragraphs = [p for p in text.split("\n") if p.strip()]
        n_paragraphs = max(1, len(paragraphs))
        # Sum line counts across paragraphs at the base size
        total_lines = 0
        for p in paragraphs:
            total_lines += estimate_lines(p, base_size_pt, width_in)
        total_lines = max(1, total_lines)
        est = estimate_height_in(
            lines=total_lines,
            font_pt=base_size_pt,
            line_spacing=LINE_SPACING_DEFAULT,
            n_paragraphs=n_paragraphs,
        )
    except Exception as exc:
        logger.warning("overflow_check estimator failed (%s); deferring", exc)
        return False, None

    # Conservative: treat estimator output as a lower bound. Add a 15% safety
    # margin because the estimator systematically underestimates (Phase 2.4a
    # closes most of the gap, but not all — vision verification is the backstop).
    conservative_est = est * 1.15
    return conservative_est > available_height_in, conservative_est


def overflow_check(
    slide_data_list: List[Dict[str, Any]],
    template_contract: Optional[Dict[str, Any]] = None,
) -> List[OverflowFinding]:
    """Run overflow detection across a slide_data_list.

    Returns one :class:`OverflowFinding` per slide. Slides where the contract
    is silent on placeholder geometry return ``verdict="FIT"`` with
    ``notes="deferred — no contract geometry"`` — the post-render image oracle
    (Phase 2.4b) is the authoritative check for those slides.

    Non-body slides (title_slide, section_header_slide, closing_slide) are
    always ``FIT`` — their text is short by design.
    """
    findings: List[OverflowFinding] = []
    for idx, slide in enumerate(slide_data_list):
        slide_type = slide.get("slide_type", "content_slide")
        if slide_type in ("title_slide", "section_header_slide", "closing_slide"):
            findings.append(OverflowFinding(
                slide_index=idx, slide_type=slide_type, verdict="FIT",
                notes="non-body slide type — short text by design",
            ))
            continue

        overflowing: List[str] = []
        est_heights: Dict[str, float] = {}
        avail_heights: Dict[str, float] = {}
        deferred = False

        for field_name in ("subtitle", "body", "body_left", "body_right"):
            text = _text_for_field(slide, field_name)
            if not text:
                continue
            avail = _available_height_for_field(field_name, slide_type, template_contract)
            if avail is None:
                deferred = True
                continue
            overflows, est = _field_overflows(text, avail)
            avail_heights[field_name] = avail
            if est is not None:
                est_heights[field_name] = est
            if overflows:
                overflowing.append(field_name)

        if overflowing:
            verdict: OverflowVerdict = "OVERFLOW"
            notes = f"{len(overflowing)} body field(s) exceed placeholder height"
        elif deferred:
            verdict = "FIT"
            notes = "deferred — no contract geometry; relies on image oracle (Phase 2.4b)"
        else:
            verdict = "FIT"
            notes = ""

        findings.append(OverflowFinding(
            slide_index=idx,
            slide_type=slide_type,
            verdict=verdict,
            overflowing_fields=overflowing,
            estimated_heights_in=est_heights,
            available_heights_in=avail_heights,
            notes=notes,
        ))

    return findings


def slides_to_question_payload(
    findings: List[OverflowFinding],
    slide_data_list: List[Dict[str, Any]],
    prompt_language: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Convert overflow findings into the per-slide ``question()`` payloads.

    Returns one payload per OVERFLOW finding. Each payload matches the schema
    documented in PLAN-BT-142 Phase 2.4. ``prompt_language`` is informational
    only — the orchestrator agent is responsible for translating the
    ``header``/``question``/``description`` strings into the user's prompt
    language. ``label`` values stay English (they map to engine params).
    """
    payloads: List[Dict[str, Any]] = []
    for f in findings:
        if f.verdict != "OVERFLOW":
            continue
        slide = slide_data_list[f.slide_index] if f.slide_index < len(slide_data_list) else {}
        title = slide.get("title", f"(slide {f.slide_index + 1})")
        payloads.append({
            "header": f"Slide {f.slide_index + 1} overflow — choose an approach",
            "question": (
                f"The content for slide {f.slide_index + 1} (\"{title}\") exceeds "
                f"the available space (overflowing fields: {', '.join(f.overflowing_fields)}). "
                f"How would you like to handle it?"
            ),
            "multiple": False,
            "options": [
                {
                    "label": "Squeeze into 1 slide",
                    "description": (
                        "Keep it as a single slide; the engine will reduce per-placeholder "
                        "font sizes (e.g., -2pt steps down to an 8pt floor) to fit the "
                        "content within the original placeholder boundaries."
                    ),
                },
                {
                    "label": "Split into 2 slides (Recommended)",
                    "description": (
                        "Split the content across two slides. The agent will propose a "
                        "split point and draft a connecting story so the two slides flow "
                        "naturally (e.g., 'On slide N: problem + market size; on slide "
                        "N+1: solution + traction, with a transition line that bridges them')."
                    ),
                },
            ],
            "_slide_index": f.slide_index,  # consumed by orchestrator; not shown to user
        })
    return payloads
