# Contributing

This is a shared skills collection — contributions of skills, agents, docs, and fixes are welcome. This guide orients you; the authoritative rules live in [`AGENTS.md`](./AGENTS.md) and this file deliberately does not repeat them.

## Proposing changes

- **Bugs and feature requests** — use the issue templates: [bug report](https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/new?template=bug_report.yml) or [feature request](https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/new?template=feature_request.yml). Both enforce a search-first check.
- **Small fixes** (typos, docs, a skill's copy) — PR directly, referencing the issue if one exists.
- **Structural changes** (new/removed skill or agent, installer or deploy behavior, config shape) — open an issue first so the sync surface (see below) can be agreed before you write the change.

## Adding a skill or agent

Adding a catalog item touches more than its own directory. Work through this checklist:

1. **Sync rules** — read `AGENTS.md` § *Adding Skills or Subagents — Sync Rules*. Adding or removing anything updates `deploy/setup.sh`, `deploy/setup.ps1`, `README.md` (counts and listings), and possibly `opencode_app/README.md`. The counts are guarded by tests; never hand-edit a count without re-deriving it from disk.
2. **Frontmatter** — follow `AGENTS.md` § *Skill / Agent Frontmatter Contract*: `name` must equal the directory name, `description` has a bounded length, `license: Apache-2.0` for new skills, and the `metadata` portability sub-keys where applicable (exact limits live in the contract). After any frontmatter change run `node installer/build-registry.mjs` and commit the regenerated `installer/registry.json`.
3. **Self-containment** — the Skill Isolation Contract (`AGENTS.md` § *Skill Isolation Contract*) requires every skill directory to be fully self-contained (scripts, schemas, fixtures inside its own tree) because `npx … add <name>` copies exactly one directory. Cross-skill duplication of helpers is intentional; do **not** factor shared code out of skills. `tests/test_skill_isolation.bats` enforces this mechanically.
4. **Portability** — skills install to multiple harnesses (`--target claude/kimi/kilo/agents`). Write bash snippets with an explicit bash-requirement note (or as `node -e` one-liners) and present harness-specific mechanisms as capability-binding blocks with a portable fallback — see the Portability contract under `AGENTS.md` § *Skill / Agent Frontmatter Contract*.

## Running the tests

```bash
git submodule update --init                       # bats-core lives at tests/lib/bats-core
export PATH="$PWD/tests/lib/bats-core/bin:$PATH"  # same wiring CI uses
bats tests/                                        # or a subset: bats tests/test_skill_isolation.bats
```

The suite runs in CI on every PR. Guards you are most likely to trip:

- **Count drift** — `setup.sh` counts skills/agents dynamically (pinned to disk by `test_count_drift.bats`), and README count literals are pinned by tests too (`test_markitdown_skill.bats`, `test_mcp_count_consistency.bats`). If a count check fails, re-derive the number from disk — do not edit the test.
- **Skill isolation** — banned references between skill trees; see the checklist above.
- **Portability** — capability-binding and bash-rule conventions.

## Commit conventions

Conventional Commits (`feat(scope): …`, `fix(scope): …`, `docs: …`, `chore: …`), one concern per commit — style-only changes never ride along with logic. CI publishes releases via semantic-release from these messages.

## Multi-target awareness

The same `SKILL.md` body runs under OpenCode (native), Claude Code, Kimi Code, Kilo Code, and the cross-tool `~/.agents/` standard, with per-target translation happening at install time (some frontmatter semantics are lossy — the installer warns). When in doubt about a construct, check how it lands in the non-opencode targets before relying on it.

## License

Apache-2.0 — see [`LICENSE`](./LICENSE). Contributions are accepted under the same license.
