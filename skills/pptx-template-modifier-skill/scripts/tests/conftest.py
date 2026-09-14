"""Shared fixtures for pptx-template-modifier-skill tests."""
import sys
from pathlib import Path

import pytest

_HERE = Path(__file__).resolve().parent            # .../pptx-template-modifier-skill/scripts/tests
_MODIFIER_SCRIPTS = _HERE.parent                   # .../pptx-template-modifier-skill/scripts
_SKILLS = _MODIFIER_SCRIPTS.parent.parent          # .../skills
_FILLER_SCRIPTS = _SKILLS / "pptx-generate-slide-skill" / "scripts"
# PLAN-GIT-72: shared contract/extraction infra now in _common.
_COMMON_SCRIPTS = _SKILLS / "_common" / "scripts"

# _FILLER_SCRIPTS stays: tests/test_layout_creator.py imports generate_ppt_from_data
# (the fill entry) for end-to-end clone renders. _COMMON_SCRIPTS added for the
# shared contract/schema modules.
for _p in (str(_MODIFIER_SCRIPTS), str(_COMMON_SCRIPTS), str(_FILLER_SCRIPTS)):
    if _p not in sys.path:
        sys.path.insert(0, _p)


@pytest.fixture
def template_path(tmp_path):
    """BT-142 Phase 2.3: synthesize a minimal valid template in tmp_path.

    Previously read ``template/default.pptx`` at the repo root — that bundled
    default is removed per the user's "no bundled default" invariant. The
    fixture now uses ``master_repairer._build_minimal_pptx_bytes(None)`` to
    produce a minimal valid PPTX (one master + one blank layout + minimal
    theme) — the same in-code fallback the production engine uses.
    """
    from master_repairer import _build_minimal_pptx_bytes
    p = tmp_path / "default.pptx"
    p.write_bytes(_build_minimal_pptx_bytes(None))
    return str(p)
