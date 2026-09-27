# PLAN: skill-generalizer load-weight audit + 50-word description discipline

**Branch**: feat/605
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/605
**Base**: main

## Acceptance Criteria

- [ ] Frontmatter description ≤50 words, trigger phrases preserved verbatim
- [ ] Load-weight detector pass present with signature/mechanism/test/disposition, wired into workflow + decision tree
- [ ] Doctrine revised: router carries contract; step mechanics may move behind load rules; gates/tolerances/schemas never leave
- [ ] Output contract + verification gate cover the weight line, load-rule WHEN+WHAT, no-preload, README non-duplication
- [ ] 4 new anti-patterns wired
- [ ] `node installer/build-registry.mjs` re-run; `registry.json` committed (frontmatter changed)
- [ ] `tests/test_skill_isolation.bats` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/skill-generalizer/SKILL.md` | — | `installer/build-registry.mjs` (frontmatter/description extraction), OpenCode runtime skill loader (description trigger matching), `tests/test_skill_isolation.bats` (fenced-block scan) | low |
| `installer/registry.json` | `node installer/build-registry.mjs` after Phase 1 | `installer/init.mjs` (install warnings), deploy/setup.sh skill counts | low |

## Implementation Phases

### Phase 1: SKILL.md restructure (content edits, single file)

- [ ] **1.1** Rewrite the frontmatter `description` to ≤50 words (hard cap 1,024 chars), stripping origin references, preserving every trigger phrase verbatim (`generalize skill`, `de-specify skill`, `make skill generic`, `skill audit for specificity`, `skill consistency review`, `split region-specific rules into reference files`)
    — **Why:** the description is the trigger surface and the single highest-leverage token line; this frontmatter change is also what forces the registry rebuild (AC 6, Phase 2).
    — **Done when:** word count of the description value ≤50; `grep -c` each trigger phrase ≥1; char count ≤1024.
    — **Consumers affected:** `installer/build-registry.mjs` (re-extracts description), runtime trigger matching.
- [ ] **1.2** Add the second failure mode to the intro: skills gain *weight* as well as specificity — the whole body is injected at load; detail needed at one step is dead weight at every other; an oversized body costs more context than it returns
    — **Why:** frames the new detector; without the mechanism stated, the pass reads as arbitrary size policing.
    — **Done when:** intro names both failure modes (specificity accretion + post-load weight) in ≤6 lines.
    — **Consumers affected:** none (prose).
- [ ] **1.3** Extend the mermaid decision tree with disposition **(e) routerize**: a body-weight branch (detail inline / over ceiling → (e)) feeding the shared verification node
    — **Why:** the skill's own architecture rule — every detector is wired into the decision tree, never special-cased inline.
    — **Done when:** mermaid contains an (e) node reachable from a weight question; all five dispositions reach the verification gate node; syntax stays valid (node/edge shapes unchanged).
    — **Consumers affected:** none (diagram).
- [ ] **1.4** Insert new pass 6 **"Load-weight audit"** after pass 5; renumber old passes 6–8 → 7–9 (contradiction, cross-reference, verification)
    — **Why:** restructure must precede the contradiction/cross-reference passes so they validate the new file set; per the skill's extension rule the pass carries signature / mechanism / test / disposition.
    — **Done when:** pass 6 names all four labeled detector terms — SIGNATURE (inline step mechanics, vocabularies, walkthroughs, human docs; body near/over ~10KB · ~2.5k tokens), MECHANISM (the whole body is injected at load; detail needed at one step is dead weight at every other), TEST (token estimate: words ×1.3 or chars ÷4; section-shape grep), DISPOSITION (doctrine-first routerize: router keeps contract — identity, one-screen summary, load table `Read|When|Use`, hard-rule one-liners, gates; step mechanics → `references/phases/<id>-<name>.md`; topic detail → `references/<topic>.md` lookup-on-miss; verbatim artifacts → `templates/`; human docs → `README.md`) — plus the judgment statement (a one-screen skill is not force-split) and the ceiling (~10KB / ~2.5k tokens) as backstop that forces the question, not the reason to split; `grep -n "^[0-9]*\. \*\*"` shows 9 sequential passes; no stale internal pass-number references remain.
    — **Done when:** (covered above — single checkable signal: 9 passes, 0 stale refs.)
    — **Consumers affected:** pass-number references in the workflow list only.
- [ ] **1.5** Revise §Side files doctrine with a whole-file restatement sweep (three sites): (i) "what never moves" becomes gates / tolerances / schemas / the decision tree — step mechanics MAY move behind load rules, but gates/tolerances/schemas never leave, router one-liner or not; (ii) the "What moves" list gains step mechanics, verbatim artifacts, and human docs alongside values/citations/glossaries/conventions; (iii) the §Anti-patterns "Modularizing the method" bullet is restated as: *"Exiling the contract — gates, tolerances, schemas, and the decision tree fracture in exile, router one-liner or not; step mechanics may move behind load rules only once the router carries their contract (load-table row + hard-rule one-liner) — a step exiled without its router line is the same fracture."*; and (iv) the domain-side-file "NO method content" contract is explicitly scoped *(d)-only*: *"phase files (e) and templates/ carry mechanics and artifacts by design, each behind its own WHEN+WHAT load rule."* Also add `references/phases/`, `templates/`, and `README.md` (human docs, never read at load) to the structure list; state the mandatory WHEN+WHAT load-rule contract for every side file
    — **Why:** the current "method steps never move" wording actively prevents the router pattern this ticket teaches (AC 3) — and the doctrine is restated in three places (never-moves list, what-moves list, anti-pattern bullet), so flipping one site leaves the revised skill failing its own contradiction pass.
    — **Done when:** `grep -c "workflow step exiled" skills/skill-generalizer/SKILL.md` = 0; never-moves list contains gates/tolerances/schemas/decision-tree and not "method steps"; the what-moves bullet names step mechanics, verbatim artifacts, and human docs; the side-file contract is labeled (d)-scoped; phases/, templates/, README.md each appear with a one-line role; README marked human-facing.
    — **Consumers affected:** none (method text consumed by future generalization runs).
- [ ] **1.6** Extend §Output contract: deliverables include the router-shaped main file + load-ruled side files (+ README when human docs moved); add the weight line — body chars/~tokens before→after and description word count before→after
    — **Why:** AC 4; makes the weight reduction auditable per run instead of implicit.
    — **Done when:** the output contract lists both additions verbatim-checkable.
    — **Consumers affected:** none.
- [ ] **1.7** Extend the verification pass (now 9): router under ceiling or justified in one sentence; every load-table file exists and carries WHEN+WHAT; no preload instructions ("read all references first"); description ≤50 words with triggers preserved; README duplicates no router rule
    — **Why:** AC 4; a gate that is not in the verification list is a suggestion.
    — **Done when:** all five checks appear in the verification pass.
    — **Consumers affected:** none.
- [ ] **1.8** Add 4 anti-patterns: monolithic load; preload-all load rules; README mirroring the router (link, don't duplicate); trimming the description into unfindable (cutting words by deleting trigger phrases)
    — **Why:** AC 5; each anti-pattern traces to the new pass (cross-reference audit rule: every workflow step with a failure mode has its anti-pattern).
    — **Done when:** §Anti-patterns contains all four, each one traceable to pass 6 or the description discipline.
    — **Consumers affected:** none.

### Phase 2: Regeneration + exit gate

- [ ] **2.1** Run `node installer/build-registry.mjs`; inspect `git diff installer/registry.json` — expected delta confined to the skill-generalizer entry (description field); commit the regenerated file together with the Phase 1 edits
    — **Why:** AC 6; the frontmatter contract mandates registry rebuild after any frontmatter change; committing together keeps the entry and its source atomic.
    — **Done when:** registry diff confined to the `generatedAt` timestamp + the skill-generalizer entry's `description` value; any other hunk = stale registry (per Risks: still commit, explain in the commit body); both files in one commit; lockfile untouched.
    — **Consumers affected:** `installer/init.mjs`, deploy/setup.sh counts (unchanged — no skills added/removed).
- [ ] **2.2** Full exit gate: `bats tests/test_skill_isolation.bats` green; `node installer/build-registry.mjs --check` green (CI release.yml:50 parity — normalizes `generatedAt`, proves committed registry ↔ frontmatter); scoped suite for count/frontmatter guards green (`tests/test_count_drift.bats` and any portability/frontmatter guard found via `ls tests | grep -iE "portab|frontmatter|skill"`); description self-check re-run (≤50 words, triggers, ≤1024 chars); append the `GATE <short-sha> tier=full` memo line to this PLAN's trace block
    — **Why:** AC 7 + the pipeline's exit-gate rule (last gate is full); this memo line is Step 10a's PR citation.
    — **Done when:** all listed checks exit 0; memo line present with the final tree SHA.
    — **Consumers affected:** PR creation citation (Step 10a).

## AC coverage

AC1 ← 1.1 · AC2 ← 1.3+1.4 · AC3 ← 1.5 · AC4 ← 1.6+1.7 · AC5 ← 1.8 · AC6 ← 2.1 · AC7 ← 2.2

## Technical Notes

- Content-only edit: no new files besides this PLAN; no new bash fenced blocks (portability rule 3 untouched).
- Ceiling numbers are evidence-based from the two exemplars: ticketing-skill router 13.9KB, floorplan-to-3d router 9.1KB with ~52KB behind load rules.
- Renumber hazard: pass numbers are referenced inline ("pass 3", "side file (pass 3)") — grep after 1.4.

## Dependencies

None. Single-ticket run; no `blocked-by:`.

## Risks & Mitigation

- Renumbering breaks internal pass references → grep "pass [0-9]" after step 1.4 (in 1.4's Done-when).
- Registry diff exceeds the single entry → inspect before commit (2.1 Done-when); unexpected entries = stale registry, still correct to commit but must be explained in the commit body.
- Mermaid edit breaks rendering → keep node/edge syntax shapes identical; only add nodes/edges.
