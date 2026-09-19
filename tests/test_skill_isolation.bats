#!/usr/bin/env bats

# Skill isolation guard (#437, PLANS/PLAN-437.md).
# Enforces the AGENTS.md §Skill Isolation Contract:
#   1. no reference to the deleted shared skills/_common package remains
#   2. no skill computes a filesystem path escaping its own directory
#      (parent-chain _common resolution, ../_common hops)
#   3. cross-skill path references are banned except the single declared
#      handoff: pptx-template-modifier-skill -> pptx-generate-slide-skill
#   4. the three pptx vendored scripts/_common trees are pairwise
#      byte-identical (fix once, copy to all three — never edit one copy)

# The one declared cross-skill dependency (#437): the modifier extends
# templates, the slide engine fills. Declared in the modifier SKILL.md
# prerequisites; any other edge must be declared the same way or duplicated.
HANDOFF_OWNER="pptx-template-modifier-skill"
HANDOFF_TARGET="pptx-generate-slide-skill"

@test "skill_isolation_no_shared_common_references" {
  # Catches both repo paths (skills/_common/...) and deploy strings
  # (.opencode/skills/_common/...) in any file type.
  run grep -rn "skills/_common" skills/ \
    --exclude-dir=__pycache__ --exclude-dir=.pytest_cache
  [ "$status" -ne 0 ]
}

@test "skill_isolation_no_parent_chain_common_escapes" {
  # Own-dir resolution is `parent / "_common"` (or parents[1]). Anything
  # reaching parents[2]/parents[3]/parent.parent.parent, or a ../_common hop,
  # escapes the skill dir.
  run grep -rnE 'parents\[[2-9]\][^)]*"_"|parent\.parent\.parent|\.\./_common|"_"[[:space:]]*/[[:space:]]*"common"' \
    skills/ --include='*.py' --include='*.md' --exclude-dir=__pycache__
  [ "$status" -ne 0 ]
}

@test "skill_isolation_no_sibling_skill_paths_outside_declared_handoff" {
  run python3 - "$HANDOFF_OWNER" "$HANDOFF_TARGET" <<'PYEOF'
import re, sys
from pathlib import Path

owner, target = sys.argv[1], sys.argv[2]
root = Path("skills")
# Deploy-path strings (opencode/skills/<x>-skill/... or skills/<x>-skill/...)
# and python path-joins ("<x>-skill" / "scripts").
ref_re = re.compile(
    r"opencode/skills/([a-z0-9-]+-skill)/|(?<![\w/-])skills/([a-z0-9-]+-skill)/"
    r'|"([a-z0-9-]+-skill)"\s*/\s*"scripts"'
)
violations = []
# Runtime carriers only: SKILL.md inline code + python imports decide whether
# an installed skill works; docs/** prose (e.g. file-tree diagrams naming a
# sibling's layout) cannot break an install.
for p in sorted(root.rglob("*")):
    if not p.is_file():
        continue
    if p.name != "SKILL.md" and p.suffix != ".py":
        continue
    parts = p.parts
    if parts[1].startswith("_"):  # _archived etc. — not shipped via npx add
        continue
    if any(part in ("__pycache__", ".pytest_cache") for part in parts):
        continue
    try:
        text = p.read_text(encoding="utf-8")
    except (UnicodeDecodeError, ValueError):
        continue  # binary payload — not a path reference carrier
    own = parts[1]
    for m in ref_re.finditer(text):
        referred = m.group(1) or m.group(2) or m.group(3)
        if referred == own:
            continue
        if own == owner and referred == target:
            continue  # the declared handoff
        line = text.count("\n", 0, m.start()) + 1
        violations.append(f"{p}:{line}: {m.group(0)!r} ({own} -> {referred})")
if violations:
    print("Sibling skill path refs outside the declared handoff "
          f"({owner} -> {target}):")
    print("\n".join(violations))
    sys.exit(1)
print("ok")
PYEOF
  [ "$status" -eq 0 ]
}

@test "skill_isolation_pptx_vendored_trees_pairwise_identical" {
  for s in pptx-generate-slide-skill pptx-template-modifier-skill pptx-generate-template-skill; do
    [ -d "skills/$s/scripts/_common" ] || { fail "missing skills/$s/scripts/_common"; }
  done
  diff -r --exclude=__pycache__ --exclude=.pytest_cache \
    "skills/pptx-generate-slide-skill/scripts/_common" \
    "skills/pptx-template-modifier-skill/scripts/_common"
  diff -r --exclude=__pycache__ --exclude=.pytest_cache \
    "skills/pptx-generate-slide-skill/scripts/_common" \
    "skills/pptx-generate-template-skill/scripts/_common"
}
