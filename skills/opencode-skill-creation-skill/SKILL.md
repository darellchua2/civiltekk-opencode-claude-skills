---
name: opencode-skill-creation-skill
description: Generate OpenCode skills following official documentation best practices
license: Apache-2.0
compatibility: opencode
category: OpenCode Meta
---

## What I do

Create new OpenCode skills: frontmatter contract, lean content standard, directory placement, registry rebuild.

## The lean standard (house rule — supersedes "more detail is better")

A skill encodes **only what is house-specific**: triggers, conventions, version-pinned facts, workflow contracts, codified learnings, commands and paths that differ from upstream/vendor defaults. **Never re-teach what the model already knows** — no textbook explanations, no spec re-quotation, no vendor docs, no illustrative example catalogs.

Line budgets by category:

| Category | SKILL.md target | Guidance |
|---|---|---|
| Textbook/concept | 40–80 | learnings + triggers only; textbook deleted |
| Vendor API reference | 100–200 | pins, breaking changes, house conventions; recipes/tutorials deleted |
| House workflow | 40–60% of current | workflow steps + return contracts stay; ceremony/templates/examples go |
| Office/media | ≤200 + `reference.md` sibling | dense format reference moves to the sibling with a one-line pointer |

When in doubt, cut; a missing rule can be re-added from git history, but a bloated skill taxes every session that loads it.

## Frontmatter contract (runtime-read keys)

```yaml
---
name: <skill-name>          # required; MUST equal directory name; ^[a-z0-9]+(-[a-z0-9]+)*$, ≤64 chars
description: <1-1024 chars> # required; house style ≤50 words, preserve trigger phrases
license: Apache-2.0         # house default
compatibility: opencode
metadata:                   # optional string map; house sub-keys: protocol, pattern ONLY
category: <registry-group>  # installer-registry-only (build-registry/init/setup counts)
---
```

Unknown frontmatter fields are ignored by OpenCode. After ANY frontmatter change: `node installer/build-registry.mjs` and commit `registry.json`.

## Content structure

Unknown frontmatter fields are ignored by OpenCode. `category` is installer-registry-only (required by this repo's tooling). After any frontmatter change, run `node installer/build-registry.mjs` and commit `registry.json`.

## Content structure

Minimum: `## What I do` (3–7 capability bullets), `## When to use me` (specific scenarios + not-for boundaries). Everything else only if it carries house signal. Skills live at root `skills/<name>/SKILL.md` (source of truth — never deployed copies, never through the `opencode_app/.opencode/` symlink bridge).

## Skill permissions (v2)

Gate skills in the `permissions` array (config.json) or agent frontmatter — NOT inside SKILL.md:

```json
{ "permissions": [
  { "action": "skill", "resource": "*", "effect": "deny" },
  { "action": "skill", "resource": "<prefix>-*", "effect": "allow" } ] }
```

Last matching rule wins; deny-all first, allows after. Agent frontmatter still uses the legacy `permission.skill` map spelling (opencode v2 auto-translates). `tools: skill: false` is deprecated.

## File safety

ALWAYS `read` before `write`/`edit` on existing files — `write` overwrites silently. Use `edit` for targeted changes.

## Verification

```bash
python3 -c "import yaml; yaml.safe_load(open('skills/<name>/SKILL.md'))"  # YAML valid
grep '^name:\|^description:' skills/<name>/SKILL.md                        # required fields
node installer/build-registry.mjs --check                                   # registry in sync
```

> Removed 2026-09: the 7-step ceremony template, prompt templates, bash name-validation scripts, per-issue walkthroughs, and the padded example output — they were the regrowth engine. House contract verified against opencode.ai v2 docs in the repo's AGENTS.md §Skill / Agent Frontmatter Contract.
