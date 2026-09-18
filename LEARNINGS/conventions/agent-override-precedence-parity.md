# agentModel (init.mjs) and resolveAgent (resolve-models.mjs) are a precedence-parity pair

- **Category**: convention
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-09-19 (#401 code review)

## Rule

`installer/init.mjs` `agentModel` (~:280) must mirror `installer/resolve-models.mjs`
`resolveAgent` (~:205) at the two agent-overrides levels: project pin
(`<project>/.opencode/agent-overrides.json`) > global pin (`~/.config/opencode/agent-overrides.json`)
> tier chain. Deliberate divergence (documented in the PR body): init.mjs's generated project
`models.json` tiers are NOT a precedence input — feeding the artifact back would freeze stale values.

## Sync surface

Any change to one side's guard shape, file location, or throw-vs-ignore policy for malformed JSON
(both `readJsonMaybe`s throw on parse errors — keep that identical) must land in the same commit as
the other side, plus a fake-HOME bats case at each precedence level (see tests/init.bats #401a/b/c:
exact-value `^model: <pin>$` greps, per-test `mktemp -d`, `HOME` exported before the node spawn).

## Evidence

#401: agentModel :280-286 vs resolveAgent :205-216 — identical truthy guards and order; user-scope
callers (:659 add, :939 cmdUpdate) stay on the default `projectOverrides = null`.
