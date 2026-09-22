# Skill snippet paths resolve via env vars, never cwd-relative paths

- **Category**: pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #511

## Pattern

SKILL.md (and agent-doc) python snippets resolve their engine via
`os.environ['SKILL_DIR']` (the skill-dir root; loaders print it), and
prerequisite siblings via
`os.environ.get('DEP_SKILL_DIR', os.path.join(os.environ['SKILL_DIR'], os.pardir, '<dep-skill>'))`
+ `os.path.normpath`. Never cwd-relative literals like `.opencode/skills/…` —
they break on every non-project install target (`--target
claude/agents/kimi/kilo`, user-level). Established #511 across the three pptx
skills + `agents/pptx-specialist-subagent.md` (which uses
`TEMPLATE_SKILL_DIR`/`SLIDE_SKILL_DIR`/`MODIFIER_SKILL_DIR` for its three-way
routing). Enforcement: the #515 guard + the repo-wide literal census.

## Why env vars, not shell interpolation

`os.environ` reads survive double-quoted `python -c` bodies and quoted heredocs
where `'$VAR'` expansion does not. Missing export must fail loud
(`KeyError: 'SKILL_DIR'`) by design — a silent cwd default ships the same bug
back. Sibling resolution is contractual: `requiresSkills`
(installer/dependency-map.json) co-installs prerequisites side-by-side at every
target.
