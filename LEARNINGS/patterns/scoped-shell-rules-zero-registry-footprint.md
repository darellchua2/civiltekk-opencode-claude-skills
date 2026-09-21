# Scoped shell allow rules have zero footprint in every generated artifact

- **Category**: pattern
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-09-22 (#524 plan review)

## Pattern

Scoped shell permission rules (`action: shell`, non-`*` resources like
`git diff*`) in agent frontmatter touch nothing generated:

- `installer/build-registry.mjs` derives edges only from `skill`/`subagent`
  action rules with non-`*` resources (:180-182), and the serialized registry
  object carries no permissions (:236-242) — a scoped-shell edit leaves a
  `generatedAt`-only diff (tier-4 proven against a synthetic post-edit
  fixture, #524).
- `installer/init.mjs` kimi/claude translation drops non-`*` shell resources
  with a "no equivalent — dropped" warning (:959-963); Bash stays denied on
  those targets via the `*` deny. Documented lossy contract, not a failure.
- The only mechanical consumer of a scoped-shell change is
  `tests/test_reviewer_no_writes.bats` (block-scoped awk guard — shell-allow
  blocks never set the edit flag; proven green) plus the verbatim deploy
  copies in `deploy/setup.sh` / `opencode_app/Dockerfile`.

## Guidance

Reviewers of scoped-shell edits: traverse tests + the deploy chain, skip
registry-drift theories. Authors: deny `*` first, allows after (opencode v2
last-matching-rule-wins; the docs' catch-all-first idiom). Prefix allows
(`git diff*`) also match chained commands (`git diff; curl …`) — they express
read-intent, not a security boundary; the boundary remains `edit: deny`.
Frame agent-facing prose accordingly.

## Evidence

#524 plan review (architecture, tier-4): registry parser + no-write guard run
against a synthetic post-1.1 fixture; registry-visible fields byte-identical;
docs re-verified 2026-09-22 (opencode.ai/docs/permissions). In-repo
precedent: `agents/opencode-tooling-subagent.md:173-178`.

Related: `solutions/build-registry-plain-run-churns-generatedat.md`.
