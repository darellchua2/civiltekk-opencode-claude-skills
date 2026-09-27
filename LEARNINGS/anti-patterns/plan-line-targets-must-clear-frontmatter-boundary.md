# PLAN line targets must clear the frontmatter boundary

**Category**: anti-patterns
**Confidence**: 0.8
**Scope**: project
**Date**: 2026-09-27

## Pattern

A PLAN step citing line numbers in a SKILL.md must verify none fall inside the YAML frontmatter slice (descriptions commonly span L3-5). Any frontmatter line — especially the `description` — is a registry event: `installer/build-registry.mjs` embeds it verbatim in `registry.json`, so editing it contradicts every no-registry-diff gate (and silently changes installer output). Caught pre-implementation on #595: PLAN step 2.3 targeted "L5/27/29" of `pr-creation-workflow-skill` where L5 is the description's last line while AC5 promised registry no-diff. Fix: scope the step to body-only lines and treat the description's capability wording as out of scope unless a frontmatter-change step (registry recommit + docs sync) is explicit.

## Anti-pattern signaled by

PLAN steps mixing line ranges that straddle the `---` fence with ACs asserting `git diff --exit-code registry.json`. Sibling of `frontmatter-key-rewrites-scope-to-frontmatter-slice`. Origin: #595 architecture review (BLOCK-1).
