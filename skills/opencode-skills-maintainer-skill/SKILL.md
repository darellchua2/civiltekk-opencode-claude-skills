---
name: opencode-skills-maintainer-skill
description: Scan, validate, and audit OpenCode skills for consistency, redundancy, and modularization opportunities
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: OpenCode Meta
---

## What I do

Audit the skill library: structure validation, bloat/regrowth detection, redundancy mapping, consolidation candidates.

## When to use me

- Auditing all skills (`opencode_app/.opencode/skills/`) for consistency
- Validating frontmatter (name/description present, valid YAML, name = directory name)
- Finding redundant skills or consolidation candidates
- Detecting content bloat or regrowth after the 2026-09 trim

## Validation (one pass)

```bash
cd opencode_app/.opencode/skills
for dir in */; do
  f="$dir/SKILL.md"; [ -f "$f" ] || { echo "missing: $dir"; continue; }
  grep -q '^name:' "$f" || echo "no name: $dir"
  grep -q '^description:' "$f" || echo "no description: $dir"
  [ "${dir%/}" = "$(grep '^name:' "$f" | head -1 | cut -d' ' -f2)" ] || echo "name/dir mismatch: $dir"
  python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$f" 2>/dev/null || echo "bad YAML: $dir"
done
node installer/build-registry.mjs --check  # from repo root
```

## Bloat check (lean standard — from `opencode-skill-creation-skill`)

A skill encodes only house-specific content; model-known textbook/vendor docs are bloat. Flag:

- Category A/B/E SKILL.md **> 300 lines** (E exempt when a `reference.md` sibling exists and SKILL.md ≤ 200)
- Category C (house workflow) SKILL.md **> 600 lines** — workflows legitimately run long; this ceiling catches regrowth, not legitimacy
- Any trimmed skill (contains a `> Removed 2026-09` marker) whose body re-adds spec re-quotation, vendor doc dumps, or example catalogs
- `wc -l opencode_app/.opencode/skills/*/SKILL.md | sort -rn | head -20` — the standing top-20 bloat watchlist

## Redundancy & modularization

```bash
grep -h '^description:' skills/*/SKILL.md | sort | uniq -cd | sort -rn   # duplicate descriptions
```

Flag near-identical purposes/audiences across skills; compound skills containing multiple distinct capabilities; consolidation candidates with a migration path (which callers load which skill — grep the AGENTS.md chain first, external § anchors must survive any merge).

## Citation drift audit (autoresearch protocol)

1. **Keyword-presence-without-citation**: flag any SKILL.md containing iteration-related keywords (`{"pass"`, `Iterations:`, `results.tsv`, `keep/revert`, `stuck detection`, `autoresearch`) WITHOUT a corresponding `autoresearch-core-skill/references/` path citation.
2. **Frontmatter-section mismatch**: `metadata.protocol: autoresearch-opt-in` MUST be present in frontmatter iff `## Iteration Protocol (opt-in)` section is present in body. Flag mismatches in either direction.
3. **Reference existence**: every cited `autoresearch-core-skill/references/<name>.md` path must resolve.

Report: skill path + violation type + suggested fix.

## Report format

Skills found / valid / invalid; per-issue list (missing field, bad YAML, name mismatch, bloat flag, redundancy pair); standing watchlist (top-20 by size).

> Removed 2026-09: the 6-step ceremony walkthrough, categorization pattern table (categories come from frontmatter `category`), example report output, common-issues restatements, verification checklist duplication. Audit rules kept verbatim.

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

### Auto-detection
If invoked on an iterative task, prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". Cache answer for session.

### Skill-specific patterns

**Citation-drift check** (rule): flag any SKILL.md containing iteration-related keywords (`{"pass"`, `Iterations:`, `results.tsv`, `keep/revert`, `stuck detection`) WITHOUT a corresponding `autoresearch-core-skill/references/` citation. Also verify `metadata.protocol: autoresearch-opt-in` frontmatter is present iff `## Iteration Protocol` section is present. **Stuck detection:** 3 consecutive audits with same finding → escalate severity. See `evaluator-contract.md` + `stuck-detection.md`.

### Citations
- `autoresearch-core-skill/references/evaluator-contract.md`
- `autoresearch-core-skill/references/stuck-detection.md`

### Imperative gating
When `AUTORESEARCH_PROTOCOL` is unset, this section is descriptive only. Default behavior is documented in all sections above.
