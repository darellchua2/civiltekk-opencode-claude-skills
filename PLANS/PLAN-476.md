# PLAN: Add multi-ticket sequence handoff to create-ticket

**Branch**: feat/476
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/476
**Base**: main

## Acceptance Criteria
- [ ] Multi-ticket creation prints a copy-pasteable `/run-worktree-pipeline` line in suggested order
- [ ] Each position carries a one-line rationale; inferred orders labeled as inferred
- [ ] User-stated dependencies produce `blocked-by: <ref>` body lines in dependent tickets at creation time
- [ ] `worktree-pipeline-skill` unchanged (it already executes in given order and honors `blocked-by`)
- [ ] `tests/test_skill_isolation.bats` stays green after the edit

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. CodeGraph unavailable in this worktree (index not gitignored — skipped at Step 4); map built via rg/grep._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/ticket-creation-skill/SKILL.md` | — | Primary agent runtime (loads the skill at `/create-ticket`); `worktree-pipeline-skill` Step 3 prose (names it as the new-ticket path); `installer/registry.json` (frontmatter-derived — untouched, no frontmatter change) | low |

Single node, doc-only: no code imports, no cross-module callers. The pipeline's
skip-guard (`worktree-pipeline-skill` Step 1) is a **consumer of the emitted
artifact** (the `blocked-by: <ref>` body line), not of this file — the format
contract below is what keeps them in agreement.

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: Sequence handoff spec in SKILL.md
- [x] **1.1** Insert a "Multi-ticket sequence handoff" subsection after Step 4 in `skills/ticket-creation-skill/SKILL.md` specifying: whenever >1 ticket was created (parent + sub-issues or batch), emit a copy-pasteable `/run-worktree-pipeline <refs in suggested order>` block with a one-line rationale per position
    — **Why:** AC-1/AC-2 are behavioral specs that must live where Step 4 ends so the agent sees them at creation time; without them the multi-ticket run prints refs with no order guidance.
    — **Done when:** SKILL.md contains the subsection with the exact copy-paste block format and the one-line-rationale requirement.
    — **Consumers affected:** primary agent runtime at multi-ticket creation.
    — **Done:** inserted as "Step 4b: Multi-ticket sequence handoff" with the exact block format; files: skills/ticket-creation-skill/SKILL.md; fixes: none
- [x] **1.2** Add the order-derivation priority to the same subsection: (1) user-stated dependencies, (2) intake/sub-item order, (3) content inference — inference always labeled "inferred"
    — **Why:** AC-2 requires rationales and honest labeling; a stated priority order prevents silent fabrication of sequencing.
    — **Done when:** subsection lists the three-tier priority with the inference-labeling rule.
    — **Consumers affected:** primary agent runtime; user reading the emitted rationale.
    — **Done:** three-tier priority list with the "never present inferred as user-stated" rule; files: skills/ticket-creation-skill/SKILL.md; fixes: none
- [x] **1.3** Add the `blocked-by:` recording rules to the same subsection: when the user states a dependency, write `blocked-by: <ref>` into the dependent ticket's body at creation under a `### Dependencies` heading — at creation time if the blocker ref already exists, otherwise a follow-up body append (`gh issue edit --body` / Jira edit); GitHub `#N`, JIRA `PROJ-N`
    — **Why:** AC-3; the ref shapes must match the pipeline Step 1 ticket regex and `blocked-by:` guard so the skip-enforcer agrees with the suggestion.
    — **Done when:** subsection documents both timing paths, the `### Dependencies` placement, and both platform ref formats.
    — **Consumers affected:** created ticket bodies; `worktree-pipeline-skill` Step 1 skip-guard (agreement, no edit to it).
    — **Done:** blocked-by rules added (timing paths, `### Dependencies` heading, both ref formats, plain-body-line note); files: skills/ticket-creation-skill/SKILL.md; fixes: none
- [x] **1.4** Extend the "Example Usage" section with a multi-ticket scenario showing the `blocked-by:` line and the emitted sequence block
    — **Why:** a normative rule with a stale example is a documented failure mode (LEARNINGS `rule-added-example-stale`); the example anchors agent behavior.
    — **Done when:** Example Usage contains a multi-ticket run ending in both artifacts.
    — **Consumers affected:** agents following the example path.
    — **Done:** multi-ticket example appended showing `blocked-by:` write-out and the suggested-sequence block; files: skills/ticket-creation-skill/SKILL.md; fixes: none

### Phase 2: Verify
- [ ] **2.1** Run `bats tests/test_skill_isolation.bats` and confirm green
    — **Why:** AC-5; the isolation guard is the mechanical gate for any `skills/` edit.
    — **Done when:** bats exits 0 with all isolation tests passing.
    — **Consumers affected:** skill isolation contract enforcement (#437).

## Technical Notes
- No frontmatter change → no `installer/build-registry.mjs` rerun, no `registry.json` commit.
- `worktree-pipeline-skill` stays untouched (AC-4): it already executes tickets in the order given and skips on unmet `blocked-by:`.
- Ref-format contract: pipeline Step 1 regex `^(#\d+|[\w.-]+/[\w.-]+#\d+|[A-Z][A-Z0-9]+-\d+)$`; emitted `blocked-by:` refs must satisfy it.
- Source-of-truth edit only — the deployed `~/.config/opencode/` copy takes effect on the next `./deploy/setup.sh` run (never edit deployed copies).
- Verification command: `bats tests/test_skill_isolation.bats` (repo has a committed test suite; no new test file needed — doc-only change).

## Dependencies
None external. No `blocked-by:` tickets.

## Risks & Mitigation
- **Guard false-positive on new prose** (isolation guard greps for cross-skill path patterns): the file already references `worktree-pipeline-skill` in prose, so additive prose of the same shape is low risk; mitigated by Phase 2 running the guard before commit of fixes.
- **Suggested order drifts from execution reality** (someone pastes refs in a different order): mitigated by the `blocked-by:` body lines — the pipeline's skip-guard, not the suggestion, is the enforcer.

## Gate trace

GATE 5e88a85 lint=t typecheck=n.a build=n.a unit=t e2e=n.a

