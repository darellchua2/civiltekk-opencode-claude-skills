"""Tests for BT-142 Phase 3.5a multipass_render."""

from __future__ import annotations

import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

from multipass_render import partition_slides, _batch_to_engine_slides


def test_partition_single_batch_under_cap():
    slides = [{"slide_type": f"t{i}"} for i in range(5)]
    batches = partition_slides(slides, max_layouts=8)
    assert len(batches) == 1
    assert batches[0] == slides


def test_partition_splits_when_over_cap():
    slides = [{"slide_type": f"t{i}"} for i in range(10)]
    batches = partition_slides(slides, max_layouts=8)
    assert len(batches) == 2
    assert len(batches[0]) == 8
    assert len(batches[1]) == 2


def test_partition_groups_same_layout_together():
    """Slides sharing a layout do not consume a new slot in the next batch."""
    slides = [
        {"slide_type": "a"},
        {"slide_type": "b"},
        {"slide_type": "a"},  # reuse — does not consume new slot
        {"slide_type": "c"},
        {"slide_type": "d"},
        {"slide_type": "e"},
        {"slide_type": "f"},
        {"slide_type": "g"},
        {"slide_type": "h"},
        {"slide_type": "i"},  # 9th distinct — triggers split
    ]
    batches = partition_slides(slides, max_layouts=8)
    assert len(batches) == 2
    # First batch has 9 slides (8 distinct + 1 reuse), then 1 slide (i)
    assert len(batches[0]) == 9
    assert len(batches[1]) == 1


def test_partition_layout_name_overrides_slide_type():
    slides = [
        {"slide_type": "content_slide", "layout_name": "Cover"},
        {"slide_type": "content_slide", "layout_name": "Story"},
        {"slide_type": "content_slide", "layout_name": "Cover"},  # reuse
    ]
    batches = partition_slides(slides, max_layouts=8)
    assert len(batches) == 1
    assert len(batches[0]) == 3  # 2 distinct layouts + 1 reuse


def test_partition_invalid_cap():
    import pytest
    with pytest.raises(ValueError):
        partition_slides([], max_layouts=0)


def test_batch_to_engine_slides_assigns_pseudo_types():
    batch = [
        {"slide_type": "x", "layout_name": "Cover"},
        {"slide_type": "y", "layout_name": "Story"},
        {"slide_type": "x", "layout_name": "Cover"},  # reuse
    ]
    engine, overrides = _batch_to_engine_slides(batch)
    # Two distinct layouts → two pseudo-types
    assert len(overrides) == 2
    assert engine[0]["slide_type"] == "_custom_1"
    assert engine[1]["slide_type"] == "_custom_2"
    assert engine[2]["slide_type"] == "_custom_1"  # reuse maps back
    # Override keys are <pseudo>_layout
    keys = list(overrides.keys())
    assert all(k.endswith("_layout") for k in keys)


def test_batch_to_engine_preserves_layout_name_pin():
    batch = [{"slide_type": "x", "layout_name": "Cover"}]
    engine, overrides = _batch_to_engine_slides(batch)
    assert overrides["_custom_1_layout"] == "Cover"


def test_multipass_render_uses_single_pass_when_under_cap(tmp_path):
    """When ≤8 layouts, multipass_render calls render_fn exactly once."""
    calls = []

    def fake_render(slides, tpl, out, overrides):
        calls.append(out)
        # Touch the output so the file exists
        with open(out, "w") as f:
            f.write("ok")
        return out

    from multipass_render import multipass_render
    out = multipass_render(
        [{"slide_type": f"t{i}"} for i in range(3)],
        template_path="/dev/null",
        output_path=str(tmp_path / "out.pptx"),
        max_layouts=8,
        render_fn=fake_render,
    )
    assert len(calls) == 1
    assert calls[0] == out
