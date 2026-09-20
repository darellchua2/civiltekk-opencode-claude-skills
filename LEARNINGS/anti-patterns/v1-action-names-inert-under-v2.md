# v1 frontmatter action names are inert under opencode v2 — rename and probe with a matrix

**Category**: anti-pattern
**Confidence**: 0.95
**Scope**: project
**Date**: 2026-09-20

## Anti-pattern

Agent frontmatter `permissions` rules using v1 action names (`bash`, `task`)
are silently inert under opencode v2 — the actions are `shell` and `subagent`
now. A v1-named deny leaves the tool present and executable; nothing warns.

## Evidence (#482, opencode v2.0.11, probe matrix per
`patterns/permission-probe-2x2-matrix.md`)

- **Cell A** — v1 `bash` deny, child-spawned reviewer: tool `shell` PRESENT,
  `git status --porcelain` executed (exit 0). Inert.
- **Cell B** — v2 `shell` deny, top-level `opencode run --agent`: NOT
  APPLICABLE — the CLI session shape is Code Mode with no shell tool in the
  catalog (`Unknown tool 'shell'`).
- **Cell C** — v2 `shell` deny, child-spawned subagent (agent harness):
  **ENFORCED** — the shell tool is filtered out of the child session's tool
  list entirely. This is the deployment shape every deny rule in
  `agents/*.md` targets.

**Attribution:** same harness, same child shape, only the action name
differs (A inert vs C enforced) → the v2 rename RESTORES subagent deny
enforcement; child-session rule application itself is not wholesale-broken
for tool actions. (Distinct from the `skill`-action inheritance bug filed
upstream as anomalyco/opencode#50149 — skills remained denied even with
agent-level allows during the same session.)

## Fix (shipped in #482)

- `agents/*.md` (34 files): `action: bash` → `action: shell`,
  `action: task` → `action: subagent` (incl. body fenced examples).
- `installer/build-registry.mjs`: `ruleRes("task")` → `ruleRes("subagent")`
  (delegatesTo/requiredBy edges).
- `installer/init.mjs`: KIMI/CLAUDE tool-map keys to v2 names; Kilo emission
  aliases `shell`→`bash`, `subagent`→`task` (Kilo's native keys stay
  v1-style).
- Tests/docs: `tests/test_autoresearch_skills.bats:127`, agent-introspection
  SKILL.md table, `README.md`/`opencode_app/README.md` teaching sites.

## Method note

Probe before AND after any permission-vocabulary change; only the
v2-name × child-spawn cell licenses an enforcement claim. Post-rename, the
regression signal is behavioral: a reviewer subagent must have NO shell
tool, not merely an unused one.

Related: `patterns/permission-probe-2x2-matrix.md`,
`anti-patterns/directory-scoped-rename-sweep-misses-root-docs.md`,
upstream anomalyco/opencode#50149, #33223.
