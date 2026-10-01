# civiltekk-coding-harness-setup-skill

Cross-harness project setup: detects which coding-agent harness(es) a repo
carries (OpenCode v1/v2, pi, Claude Code, Codex) and provisions a parity
surface — neutral `.agents/skills/`, canonical `AGENTS.md` with per-harness
shims, per-harness config deltas, MCP only where supported.

## Use

Invoke the skill by name or trigger phrase ("set up harness for this repo",
"harness parity") in the target repo's primary session. The SKILL.md router
is the single method source — this README never restates its rules.

## Install

```bash
npx github:darellchua2/civiltekk-opencode-claude-skills add civiltekk-coding-harness-setup-skill
```

## Adding a harness profile

1. Copy any file in `references/harnesses/` as the skeleton (pi.md is the
   simplest).
2. Replace the values with the new harness's documented dirs, config syntax,
   and MCP support — every value needs a citation or a *verify locally* note.
3. Add one row to the router's Step 3 load table (Read | When | Use).
4. Reconcile against `docs/harness-landscape-2026-09.md` (in-repo research
   baseline) and the harness's live docs.

## References

- Router/method: [`SKILL.md`](SKILL.md)
- Harness landscape baseline: [`docs/harness-landscape-2026-09.md`](../../../docs/harness-landscape-2026-09.md)
