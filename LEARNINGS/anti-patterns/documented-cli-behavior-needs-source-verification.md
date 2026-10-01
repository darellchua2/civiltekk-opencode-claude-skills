# Anti-pattern: prose restating CLI behavior ships unverified against the implementing source

- **Category**: anti-pattern
- **Confidence**: 0.7
- **Scope**: project
- **Added**: 2026-10-02 (#657 code review)

## Anti-pattern

Authoring skill/docs prose that restates installer (or any CLI) behavior —
flags, destination paths, degradation rules — from README claims or memory,
without grepping the implementing source for each assertion. The #657
install.md scope table claimed `claude .claude/ (workspace: agents
.claude/agents/)` as a project destination; `TARGETS` (`installer/init.mjs`)
gives claude NO project dirs — `--project --target claude` degrades to the
opencode dirs with a "no project destination" note, and `.claude/agents` is
copilot's project dir. The PLAN's Done-when verified the COMMANDS against
`init.mjs:11-26` but not the DESTINATION claims — command verification does
not cover behavior claims.

## Rule

Every prose assertion about CLI behavior gets verified against the
implementing source before shipping: grep the claim's distinctive token
(destination dir, flag name, note string) in the implementing file. For
installer destinations that source is the `TARGETS` table, not README. A
PLAN step that produces such prose should name the source table in its
Done-when ("verified against TARGETS"), not just the CLI usage header.

## Consequence if missed

Users follow the documented destination, get a different one silently (the
installer only prints a note), and trust in the skill drops on first use —
the exact failure the assistant skill exists to prevent.

## Evidence

#657 review Major finding (feat/657, fixed in the review-fix commit):
`skills/civiltekk-install-assistant/references/install.md` §3 vs
`installer/init.mjs:82-96` (TARGETS) + `:867-868` (degradation note).

Related: `anti-patterns/command-description-parallel-restatement-drift.md`
(same genus — parallel teaching surfaces; this is the creation-side rule,
that one is the maintenance-side rule).
