# PLAN: Phase 3 — Multi-app install targets (`--target opencode|claude`)

**Branch**: feat/377
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/377
**Base**: main (bc1f6d2 — post-#378 layout; ticket's `deploy/init.mjs` refs are stale, now `installer/init.mjs`)

## Acceptance Criteria

From ticket #377, re-validated against `origin/main` @ `bc1f6d2` (line refs re-anchored):

- [ ] `add <skill> --target claude` writes only `~/.claude/skills/<skill>/` (verified with fake HOME)
- [ ] `add <agent> --target claude` warns + writes nothing under the claude dir, exit 0
- [ ] `--format claude` alias still accepted (with deprecation warning)
- [ ] bats cases for all three behaviors
- [ ] `--target both` + agent selection: opencode gets agent, claude skips it with the same warning (no silent divergence)
- [ ] Registry drift check + full bats suite stay green (no frontmatter changes)

**Re-validation deltas:** `deploy/init.mjs:739-744` → `installer/init.mjs:736-758` (`writeClaudeFormat`, agent loop :739-745); flag parse `parseArgs` :65-83 (`--format` value-flag, no BOOL change needed — `--target` parses the same way); validation :564-568; project-scope note :553-554; help :962; README §"Claude Code compatibility (`--format`)" :224-239. No existing `--format` bats cases — all three ticket ACs are new tests. Fake-HOME pattern established in `tests/init.bats:151` (`export HOME="$TMP_PROJ/home"`).

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` flag layer (`cmdAdd` :533-560, `writeUserScopeInstall` :562-629) | — | CLI users, bats suite, dry-run JSON output | high |
| `installer/init.mjs` `writeClaudeFormat` :736-758 | flag layer precedes (warning wording shared) | `~/.claude/skills/` consumers (Claude Code) | high |
| `installer/init.mjs` manifest write :605-614 | flag layer | `cmdRemove` :760+ (uninstall ledger), `--prune` | med |
| `installer/init.mjs` help :962 | flag layer | humans, README cross-refs | low |
| `README.md` §Claude Code compatibility :224-239 | behavior lands first | humans; docs-consistency checks | low |
| `tests/init.bats` (3 new cases) | implementation precedes | CI bats suite | low |
| Out of scope (ticket): project-scope `.claude/skills/`, `~/.claude/agents/` converter, non-Claude apps | — | — | — |

## Implementation Phases

### Phase 1: `--target` flag + `--format` deprecated alias

- [ ] **1.1** `installer/init.mjs` `cmdAdd`: after parse, map alias — if `opts.format` set: if `opts.target` also set → `die("cannot use --format and --target together (--format is deprecated; use --target)")`; else `opts.target = opts.format` + stderr `warning: --format is deprecated; use --target (values: opencode, claude, both)`. Update the project-scope note :553-554 to reference `--target`.
    — **Why:** The ticket keeps `--format` working (public command compat) while moving the canonical name to `--target`; conflict-die prevents silent ambiguity at the trust boundary.
    — **Done when:** `node --check`; `--format claude` maps to target with warning; `--format claude --target both` dies exit≠0.
    — **Consumers affected:** CLI users; `--project` note text.

- [ ] **1.2** `writeUserScopeInstall`: `const target = opts.target || "opencode"`; validate `["opencode","claude","both"]` → `die(\`invalid target '${target}'. Use: opencode, claude, or both.\`, 2)`; `doOc`/`doClaude` derive from target; dry-run JSON field `format` → `target` (preview output, not a parsed contract — no bats test reads it today). In the dry-run branch, when `doClaude && sel.agents.length` print the same agent-skip warning to stderr (REQ-1: preview must reflect the skip, not just the real install).
    — **Why:** Core flag semantics; value set unchanged so the alias needs no value translation beyond the name; a preview that hides the skip lies about what install does.
    — **Done when:** `--target claude` and `--target opencode` dry-runs print correct `target` + `destination`; `--target bogus` dies exit 2; `add tdd-subagent --target claude --dry-run` shows the skip warning.
    — **Consumers affected:** every `add` invocation (user scope).

### Phase 2: Claude target installs skills only

- [ ] **2.1** `writeClaudeFormat`: delete the agent loop (:739-745); when `sel.agents.length > 0` print `warning: N agent(s) skipped — Claude Code target installs skills only (agents are opencode-specific)` to **stderr** (`console.error`, REQ-2 — the bats case asserts stderr; not `console.log` like the existing :757 count line); count = skills only. Keep `stripModelLine` and the remove-side cleanup (:787-789) untouched.
    — **Why:** Fixes the ticket's named bug — agents written as SKILL.md into `~/.claude/skills/` are silently ignored by Claude Code; the warning makes the skip visible instead of silent, and stderr keeps it out of the success-path stdout stream.
    — **Done when:** `add <agent> --target claude` exits 0, prints warning on stderr, claude dir has no entries; `--target both` with agent: opencode agent written + same warning.
    — **Consumers affected:** Claude Code users; `--target both` flows.

- [ ] **2.2** Manifest write: record `sel.agents` in the manifest only when `doOc` (agents were actually installed somewhere); skills always recorded.
    — **Why:** The manifest is the uninstall ledger (`cmdRemove` decides agent-vs-skill from it, :773); claude-only installs never place agents anywhere, so recording them corrupts `remove` bookkeeping.
    — **Done when:** after `add <agent> --target claude`, manifest `agents` is empty and `skills` lists pulled-in skills; after `--target both`, both recorded.
    — **Consumers affected:** `cmdRemove`, `--prune`.

**Phase gate:** `node --check installer/init.mjs`; fake-HOME manual runs of all four behaviors (skill→claude, agent→claude, agent→both, format-alias); `node installer/build-registry.mjs --check`.

### Phase 3: Help + README

- [ ] **3.1** Help :962: replace `--format` line with `--target <t>  (add) install target: opencode (default), claude, or both (--format = deprecated alias)`; keep adjacent lines untouched.
    — **Why:** Help must show the new canonical flag while teaching the alias exists.
    — **Done when:** `node installer/init.mjs --help | grep -q -- '--target'` and `--format` still mentioned.
    — **Consumers affected:** humans reading help.

- [ ] **3.2** README §:224-239: retitle to `--target`, commands use `--target claude` / `--target both`, table header "Target", swap the `--target both` example to a **skill** name (REQ-3 — an agent example would showcase a warning-producing flow), add one line: `--format is a deprecated alias for --target (prints a warning, values unchanged)`. Also update `AGENTS.md:10` which still names `--format claude|both` as canonical (REQ-4).
    — **Why:** Public docs must match the shipped CLI; the deprecated alias note keeps old links/notes interpretable.
    — **Done when:** grep shows no `--format` usage examples except the deprecation note; section title says `--target`; AGENTS.md references `--target`.
    — **Consumers affected:** humans; doc-consistency skill sweeps.

### Phase 4: Bats cases

- [ ] **4.1** `tests/init.bats`, 3 new cases using the `export HOME="$TMP_PROJ/home"` pattern: (a) `add <skill> --target claude` → `$HOME/.claude/skills/<skill>/SKILL.md` exists AND `$HOME/.config/opencode/skills/<skill>` absent; (b) `add <agent> --target claude` → exit 0, stderr matches `agent\(s\) skipped`, `$HOME/.claude/skills/<agent>` absent; (c) `--format claude` → stderr matches `deprecated` + install lands in claude dir.
    — **Why:** The ticket's ACs demand executable proof of all three behaviors; fake HOME isolates the runner's real `~/.claude`.
    — **Done when:** `bats tests/init.bats` green including the 3 new cases.
    — **Consumers affected:** CI bats suite.

**Phase gate:** full `bats tests/*.bats` suite green; registry drift check clean.

## Technical Notes

- `--target` needs no `parseArgs` change — it's a value flag like `--format` (only BOOL_FLAGS members are valueless, :64).
- Value set stays `opencode|claude|both` — the alias maps names, not values.
- Future apps (Codex/Cursor/Gemini) are just new entries in the target map; SKILL.md is app-agnostic (Agent Skills standard) — out of scope per ticket.
- `USER_CLAUDE_SKILLS` unchanged; remove-side claude cleanup already unconditional and correct for skills-only.

## Dependencies

- None — branch cut from `bc1f6d2` which includes #378 (installer/ split) and #389.
- Unblocks nothing upstream; #380/#379 are independent phases.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing `--format` users (public npx flow) | Alias maps values verbatim + deprecation warning; bats case (c) proves it |
| Dry-run JSON field rename (`format`→`target`) surprises scripters | Preview output, documented in PR body; no known parser (checked bats + repo) |
| Manifest agent bookkeeping drift for claude-only installs | 2.2 scopes agents to `doOc`; verified in phase gate manual run |
| Warning text drift between code and test regex | Test matches stable substring `agent(s) skipped` |
