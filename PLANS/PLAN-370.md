# PLAN: MCP enable-pack flips dead permission keys

**Branch**: feat/370
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/370
**Base**: main

## Acceptance Criteria
- [x] All 5 MCP packs (markitdown, docling, chrome-devtools, nextjs, autodesk) write `permission: {"<server>*": "allow"}` at the permission root with string enum values; no nested `permission.tool`, no top-level `tools` in any pack (voice pack is tui-only — no permission key — excluded by design)
- [x] Source `opencode_app/opencode.json` opt-in denies migrated from `permission.tool` to root-level `permission` patterns
- [x] `--enable-pack markitdown` installs the launcher (gated on `ENABLE_PACK`, dry-run skips, installed-check avoids double pip; mirrored in `setup.ps1` with rc symmetry)
- [x] SKILL.md + office-document-primary-agent.md + opencode_app/README.md corrected; `--help` verify suggestion replaced with `opencode mcp list`
- [x] Bats regression test: pack permission patterns are root-level string enums; install hook present
- [x] E2E smoke (automated): temp-HOME fresh deploy + `--enable-pack markitdown` → binary installed, deployed config has `mcp.markitdown.enabled: true` + root `permission["markitdown*"]: "allow"`, `opencode mcp list` lists the server. Live `convert_to_markdown` on a sample docx/pdf verified manually in-session after merge (needs a full agent session — not automatable in CI)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/packs/pack-{markitdown,docling,chrome-devtools,nextjs,autodesk}.json` | Final-state co-dependency with Phase 2 (source root denies ↔ pack allow overlays). **Temporal order is packs-first**: interim state (inert denies + enforcing pack allows) ≈ today's default allow-all — safe; the reverse order would strand pack users on enforced denies | `deploy/merge-packs.mjs`, `validate_enable_pack`, setup.sh/ps1 help text, `tests/test_docling_skill.bats` (L76/L84 pack+merge assertions), new bats test | med |
| `opencode_app/opencode.json` (permission block) | Phase 1 (pack allows must exist before denies enforce) | setup.sh config copy → deployed config, opencode runtime, `tests/test_docling_skill.bats` (L55 source assertion), `tests/test_mcp_count_consistency.bats` (no permission assertions — verified), merge-packs.mjs (merge base), `deploy/apply-skill-profile.mjs` (rewrites ONLY `permission.skill` — L78 — root pattern keys survive; verified) | high (inert denies become real denies) |
| `deploy/merge-packs.mjs` (dry-run snapshot + header) | Phase 1 pack format | setup.sh `run_pack_merger`, setup.ps1 `Invoke-PackMerger`, Dockerfile (calls merge-packs directly, L73-80), standalone CLI users | low |
| `deploy/setup.sh` (`run_pack_merger` hook, `install_local_mcp_launchers` installed-check, usage text) | Phase 1 (pack no longer references tools) | `--enable-pack` users, CI bats | low |
| `deploy/setup.ps1` (`Invoke-PackMerger` hook + rc check, `Install-LocalMcpLaunchers`, help text) | Phase 1 | Windows users | low |
| `opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md`, `opencode_app/.opencode/agents/office-document-primary-agent.md`, `opencode_app/README.md` (~L87) | Phases 1-2 (docs must match shipped keys) | runtime skill/agent loading, installer registry (category only) | low |
| `tests/test_pack_permissions.bats` (new) | Phases 1-5 | CI | low |

**Rollback note:** Phases 1 and 2 revert as a pair — reverting Phase 1 alone (keeping Phase 2) leaves pack users denied.

## Implementation Phases

### Phase 1: Fix the five pack files
- [x] **1.1** Rewrite `deploy/packs/pack-markitdown.json` to `{"mcp":{"markitdown":{"enabled":true}},"permission":{"markitdown*":"allow"}}`; update `$comment` to state the root-permission key (string enum, deprecated `tools` removed) and that `--enable-pack markitdown` now installs the launcher
    — **Why:** top-level `tools` is deprecated since v1.1.1 and loses conflicts to explicit `permission`; the string value is what the schema enum (`ask|allow|deny`) requires
    — **Done when:** `node -e` asserts `p.permission["markitdown*"]==="allow"`, `p.tools===undefined`, `p.permission.tool===undefined`, `$comment` is the first key
    — **Consumers affected:** merge-packs.mjs merge output, deployed config after `--enable-pack markitdown`
    — **Done:** pack rewritten with root allow + updated $comment; files: deploy/packs/pack-markitdown.json; fixes: none
- [x] **1.2** Same rewrite for `deploy/packs/pack-docling.json` (`permission:{"docling*":"allow"}`), replacing the inert `permission.tool: true` and its stale `$comment`; in the same commit update the pack-shape and merged-output assertions in `tests/test_docling_skill.bats` (L76 pack boolean → root string enum; L84 merged assertion → root allow)
    — **Why:** #310's fix targets a key opencode never reads; boolean `true` is schema-invalid; the test certifying the bug must change in the same commit to keep CI green
    — **Done when:** node assertions pass for the pack; `tests/test_docling_skill.bats` L76/L84 pass against the new pack while L55 (source assertion) still passes untouched
    — **Consumers affected:** `--enable-pack docling` merges; CI
    — **Done:** pack rewritten; test assertions updated to root string enum; files: deploy/packs/pack-docling.json, tests/test_docling_skill.bats; fixes: fix-on-fail a1 — dropped `'tool' not in d['permission']` from the merged-output assertion (source config keeps permission.tool until Phase 2; asserting its absence mid-pipeline was wrong)
- [x] **1.3** Same rewrite for `deploy/packs/pack-chrome-devtools.json` and `deploy/packs/pack-nextjs.json` (`chrome-devtools*` / `next-devtools*` → `"allow"`), updating `$comment`s
    — **Why:** same deprecated-key bug; prevents identical reports for those packs
    — **Done when:** node assertions pass for both packs
    — **Consumers affected:** `--enable-pack chrome-devtools|nextjs` merges
    — **Done:** both packs rewritten with root allows + updated $comments; files: deploy/packs/pack-chrome-devtools.json, deploy/packs/pack-nextjs.json; fixes: none
- [x] **1.4** Same rewrite for `deploy/packs/pack-autodesk.json` (`"autodesk-*"` entries → `"allow"` at root permission, `$comment` first)
    — **Why:** review found the same `tools` block (pack-autodesk.json:36-41); without it no "no tools in any pack" gate can ever pass; additive-only — autodesk servers are pack-only (not in base config, per test_mcp_count_consistency.bats:71-79) so there is no deny to flip
    — **Done when:** node asserts all `autodesk-*` entries are root-level `"allow"`; `! grep -rq '"tools"' deploy/packs/` exits 0 across all packs
    — **Consumers affected:** `--enable-pack autodesk` merges
    — **Done:** tools block → root permission allows; files: deploy/packs/pack-autodesk.json; fixes: fix-on-fail a1 — escaped quotes inside $comment string (unescaped quotes broke JSON.parse)
- [x] **1.5** Constraint check across all rewrites: `$comment` stays the FIRST key in every pack
    — **Why:** merge-packs.mjs `stripJsonComments` (L77-80) removes whole-line `$comment` entries only; `$comment` placed last leaves a trailing comma and the merge dies on parse error
    — **Done when:** node parse of every pack succeeds AND first key of each pack JSON is `$comment`
    — **Consumers affected:** merge-packs.mjs parse path
    — **Done:** node loop over 5 packs asserts $comment-first + parse + shapes; grep -rq '"tools"' deploy/packs/ empty; files: (verification only); fixes: none

### Phase 2: Migrate the source config deny block
- [x] **2.1** In `opencode_app/opencode.json`, move the 7 pattern entries out of `permission.tool` (L142-150) to the `permission` root (siblings of `read`/`skill`), preserving values (`codegraph*`/`atlassian*`/`zai-web-reader*`/`zai-web-search*` allow; `markitdown*`/`docling*`/`next-devtools*` deny), delete the `tool` sub-object, and update `tests/test_docling_skill.bats` L55 (source assertion) to the root-level key in the same commit
    — **Why:** `permission.tool` matches nothing in opencode's permission engine; root-level patterns are the documented mechanism, making the intended opt-in denies actually enforce; no comments may be added (JSONC-in-opencode.json anti-pattern breaks CI)
    — **Done when:** node asserts `permission["markitdown*"]==="deny"` and `permission.tool===undefined`; `read`/`skill` blocks byte-identical; JSON parses; `bats tests/test_docling_skill.bats tests/test_mcp_count_consistency.bats` green
    — **Consumers affected:** fresh deploys (real denies), pack merges (allow wins, Phase 1), apply-skill-profile (untouched — writes only permission.skill)
    — **Done:** 7 entries flattened to permission root at the former tool-block position, `tool` sub-object deleted; test_docling_skill.bats L55 assertion now reads `d['permission']['docling*'] == 'deny'`; files: opencode_app/opencode.json, tests/test_docling_skill.bats; fixes: none (first try — read/skill verified byte-identical to origin/main via JSON.stringify compare rather than guessed key counts; full suite 318/318 green)

### Phase 3: merge-packs.mjs snapshot + header
- [x] **3.1** Add `permission: config.permission || {}` to the before/after dry-run diff snapshots (L181-185, L241-244); update header comment (L6) to describe `mcp.<server>.enabled` + root `permission` allows
    — **Why:** snapshot only tracks `mcp`+`tools`; with packs now writing `permission`, the `changed:` report would falsely say "nothing (already merged)"
    — **Done when:** `node --check deploy/merge-packs.mjs` passes; dry-run merge simulation reports `changed: yes` against a config with root denies
    — **Consumers affected:** setup.sh/ps1 dry-run output, standalone CLI users, Docker build path
    — **Done:** snapshots track `mcp`+`permission`; header comment updated to "root `permission` pattern key"; files: deploy/merge-packs.mjs; fixes: fix-on-fail a1 — used `--packs` (not `--pack`) flag and `--packs-dir` in the sim; dry-run reported changed:yes vs root-deny config, real merge flipped deny→allow

### Phase 4: Install-on-enable hook (setup.sh + setup.ps1)
- [x] **4.1** In `install_local_mcp_launchers` (deploy/setup.sh:2570): early-exit `python3 -m pip show markitdown-local-mcp >/dev/null 2>&1 && return 0` after the prereq checks; then in `run_pack_merger` (L3312) after the merge rc check: `if [ "$DRY_RUN" != true ] && echo "$ENABLE_PACK" | grep -qw "markitdown"; then install_local_mcp_launchers; fi`
    — **Why:** the installer only ran during full-setup config copy (L2468), so `--enable-pack markitdown` never installed the binary — the reproduced root cause; docling/voice set the gating precedent (L2618/2688); the installed-check prevents a double network `--force-reinstall` when full setup already ran it at L2468 while preserving refresh-on-upgrade semantics for stale installs
    — **Done when:** `bash -n` passes; grep shows the installed-check and the gate inside `run_pack_merger`; dry-run path leaves the `$DRY_RUN` guard intact
    — **Consumers affected:** `--enable-pack markitdown` users (real deploys); Docker path (bakes its own launcher, never reaches this hook; idempotent if it did, non-fatal offline)
    — **Done:** installed-check inserted before the source-dir check (early-exit on `pip show` success); rc-gated hook added in `run_pack_merger` gated on `$DRY_RUN != true` + `grep -qw markitdown`; files: deploy/setup.sh; fixes: none (first try; hook asserts pass)
- [x] **4.2** Mirror in `deploy/setup.ps1` `Invoke-PackMerger` (after the node merge call): capture `$LASTEXITCODE` from the merge and only when it is 0, `-not $DryRun`, and `$EnablePack -match '(^|,)markitdown(,|$)'` → `Install-LocalMcpLaunchers`; add the same installed-check inside `Install-LocalMcpLaunchers` (ps1:2083)
    — **Why:** repo sync rules require the Windows mirror; ps1's merge call has no rc check (unlike sh) so the hook must gate on `$LASTEXITCODE` for symmetry with the sh shell
    — **Done when:** grep shows the rc-gated hook in setup.ps1 following the merge call and the installed-check in `Install-LocalMcpLaunchers`
    — **Consumers affected:** Windows `-EnablePack markitdown` users
    — **Done:** `$mergeRc = $LASTEXITCODE` + rc gate + `(-not $DryRun) -and ($EnablePack -match '(^|,)markitdown(,|$)')` hook calling `Install-LocalMcpLaunchers`; installed-check added via python/python3 probe; files: deploy/setup.ps1; fixes: none (first try)
- [x] **4.3** Update help text in both scripts (setup.sh ~L577-578, setup.ps1 ~L921-922): replace "and tools.<ns>* flags ON" with "and sets permission `\"<ns>*\": \"allow\"`"
    — **Why:** help text would otherwise teach the removed key
    — **Done when:** `grep -c "tools.<ns>" deploy/setup.sh deploy/setup.ps1` returns 0 for both
    — **Consumers affected:** `--help` readers
    — **Done:** help text + run_pack_merger function comment updated in setup.sh (L577, L3312) and setup.ps1 (L921); no stale `tools.<ns>* flags ON` remains; files: deploy/setup.sh, deploy/setup.ps1; fixes: fix-on-fail a1 — missed the run_pack_merger header comment (setup.sh L3312) carrying the same stale phrase; caught by the assert script

### Phase 5: Docs
- [x] **5.1** Rewrite `markitdown-mcp-skill/SKILL.md`: L14 (both-blocks phrasing), L29 (state table row), config block ~L35-64 (root `permission` example), L60 (two-flip step 2), L64 (`--help` → `opencode mcp list`), L183-190 troubleshooting (root-permission flip + behavior-change note: opt-in denies now enforce; use the pack to allow)
    — **Why:** the skill teaches the exact dead keys this ticket removes; it is the documented enable path; the troubleshooting row is the durable home for the release behavior-change note (releases are semantic-release automated — no hand-edited changelog)
    — **Done when:** `grep -n 'tools\.\?"markitdown\|permission.tool\|--help' SKILL.md` returns no stale hits; new examples show `permission:{"markitdown*":"allow"}`
    — **Consumers affected:** markitdown-mcp-skill runtime copies (redeploy), installer registry metadata untouched (frontmatter unchanged)
    — **Done:** L14 blocks phrasing, L29 table row, config block example, two-flip→three-gates rewrite, --help→`opencode mcp list` + restart note, troubleshooting root-permission gates + new "Tool denied after upgrading" migration row; files: opencode_app/.opencode/skills/markitdown-mcp-skill/SKILL.md; fixes: none. Note: 2 intentional grep hits remain (L60 explains why legacy keys are dead; L194 IS the mandated behavior-change note) — step cannot both mandate a `permission.tool` migration note and zero mentions of `permission.tool`; interpreted as "no stale instructions," which holds.
- [x] **5.2** Update `office-document-primary-agent.md` note (~L69): session-inherited access now governed by root `permission["markitdown*"]` + `mcp.markitdown.enabled`; flip guidance matches SKILL.md
    — **Why:** agent prompt would instruct users to edit a key that does nothing
    — **Done when:** grep finds no `tools["markitdown*"]` guidance in the agent file
    — **Consumers affected:** office-document-primary-agent runtime prompt
    — **Done:** note rewritten to root-permission pattern + `--enable-pack markitdown` guidance + restart; files: opencode_app/.opencode/agents/office-document-primary-agent.md; fixes: none
- [x] **5.3** Update `opencode_app/README.md` ~L87: merger description changes from "only merges each pack's `mcp` + `tools` keys" to root-`permission` allow flips (also fixing the pre-existing inaccuracy — it deep-merges all non-tui keys)
    — **Why:** same docs-teach-dead-keys class the ticket targets; found in review
    — **Done when:** grep finds no `tools` merge claim in opencode_app/README.md
    — **Consumers affected:** Docker/app README readers
    — **Done:** merger description now `mcp` + `permission` keys with root-pattern allow flips; files: opencode_app/README.md; fixes: none

### Iteration 2 (re-review findings, commit pending)
- [x] **9.4** setup.sh: drop duplicate `rm -f "$pip_err"` that ran before `tail -n 3` (tail read an unlinked file → bogus offline error)
    — **Why:** iteration-1 diagnostics fix was self-defeating on setup.sh; the warn never carried pip stderr
    — **Done when:** else-branch order is warn → tail → rm; tail prints real pip output when file exists
    — **Consumers affected:** offline-deploy diagnostics (setup.sh only; ps1 was already correct)
    — **Done:** duplicate rm removed; files: deploy/setup.sh; fixes: n/a (this is the fix)
- [x] **9.5** MIGRATION.md:218 dead-key residue + guard scope: rewrite `tools.*` phrasing to root-permission allow; widen `no_doc_teaches_dead_permission_keys` to repo-root docs + Dockerfile (two explicit greps), add backtick-`tools.*` variant, fix assertion to stripped-hits check (append newline made `$hits` never empty)
    — **Why:** live dead-key instruction survived outside the guard's sweep; guard could never catch its own class
    — **Done when:** MIGRATION.md teaches root permission; guard green at 329/329 with widened scope
    — **Consumers affected:** migration-doc readers; CI suite
    — **Done:** MIGRATION.md rewritten; guard paths/pattern/pattern-assertion fixed (incl. `\`tools\.\*\`` backtick form — bare `tools\.\*` false-positived on CAD prose `tools.**`); files: MIGRATION.md, tests/test_pack_permissions.bats; fixes: 2 (newline-never-empty assertion; backtick constrain)

### Phase 6: Regression test, gates, E2E smoke
- [x] **6.1** Add `tests/test_pack_permissions.bats` (modeled on test_voice_pack.bats): explicitly enumerate the 5 MCP packs (no dir glob — voice is tui-only and legitimately has no permission key); assert pack shapes (root string-enum permission, no `tools`/`permission.tool`, `$comment` first), merge-packs simulation flipping a root deny to allow, installed-check + install-gate presence in setup.sh + rc-gated hook in setup.ps1
    — **Why:** the packs had zero key-structure coverage; this class of bug shipped twice (#269, #310)
    — **Done when:** `bats tests/test_pack_permissions.bats` all green
    — **Consumers affected:** CI suite
    — **Done:** 8 tests: pack shapes (all 5 packs: $comment-first, root permission, string "allow", wildcard patterns, no tools/permission.tool), server enable flags, merge flips root deny→allow + enabled, unrelated patterns preserved, setup.sh installed-check + dry-run-gated hook, setup.ps1 rc-gate + EnablePack regex + installer probe; files: tests/test_pack_permissions.bats; fixes: replaced fragile ps1 regex grep with fixed-string `,)markitdown(,` match
- [x] **6.2** Run full gates: `bash -n deploy/setup.sh`, `node --check deploy/merge-packs.mjs`, `bats tests/`
    — **Why:** repo verification gates; `test_mcp_count_consistency.bats` guards against count drift (no MCP added/removed, so counts stay)
    — **Done when:** all three commands exit 0
    — **Consumers affected:** CI
    — **Done:** bash -n OK, node --check OK, full bats 326/326 green (318 prior + 8 new); files: none; fixes: none
- [x] **6.3** E2E smoke: in a throwaway env (`HOME=$(mktemp -d)`) run `./deploy/setup.sh -y --enable-pack markitdown`, then assert: `markitdown-local-mcp` resolvable via the temp PATH, deployed config has `mcp.markitdown.enabled: true` + root `permission["markitdown*"]: "allow"` + no `permission.tool`, and `HOME=<temp> opencode mcp list` lists markitdown as connected/disabled per config (spawn path proven). Record output; live `convert_to_markdown` on a sample docx/pdf is verified manually in-session post-merge (requires a full opencode agent session — out of CI scope, stated in ticket AC)
    — **Why:** ticket AC #6 is the only user-visible proof the documented enable path now works end-to-end
    — **Done when:** all smoke assertions pass in the throwaway env; main checkout untouched (fetch-only policy preserved)
    — **Consumers affected:** release confidence; no persistent files
    — **Done:** smoke green in throwaway HOME: setup -y --enable-pack markitdown exit 0; binary in <temp>/.local/bin; config enabled:true + root allow + no permission.tool + no legacy tools key; `opencode mcp list` → "✓ markitdown connected"; files: deploy/setup.sh, deploy/setup.ps1, tests/test_pack_permissions.bats; fixes: (a1) PEP 668 externally-managed-environment blocks pip --user on Debian 12+/Ubuntu 23.04+ — the true root cause of the original "never installed" symptom; installers now detect it in pip stderr and retry with --break-system-packages (--user keeps ~/.local isolation); (a2) JSON-RPC spawn probe inconclusive (empty stdout on stdin EOF) — canonical `opencode mcp list < /dev/null` used as spawn proof instead; live convert_to_markdown = manual post-merge per AC

## Technical Notes
- Permission semantics (docs + source, 2026-09-09): patterns at the `permission` root; last matching rule wins; default allow-all; string enum only (`ask|allow|deny`); explicit `permission` overlays legacy `tools`-derived entries.
- `merge-packs.mjs` deep-merges every non-`tui` pack key — root `permission` passes through unmodified; strips `$comment` (whole-line only; keep `$comment` first).
- `install_local_mcp_launchers` is function-defined before `run_pack_merger` executes (call sites at L2468 prove ordering); pip `--user` lands on PATH (`~/.local/bin`), non-fatal offline.
- MCP servers boot at process start; no hot-reload — users must restart opencode after enabling.
- Behavior change: source-config opt-in denies (`markitdown*`, `docling*`, `next-devtools*`) become enforcing at the root; packs flip them to allow on `--enable-pack`. Note ships via SKILL.md troubleshooting (5.1) + PR body (releases are semantic-release; no hand-edited changelog).
- Sync rules: no MCP servers added/removed, no skill/agent count changes → setup.sh/README counts and registry.json untouched.

## Dependencies
None external; all vendored.

## Risks & Mitigation
- **Real denies break hand-enabled setups** — users who flipped `mcp.<server>.enabled` manually without packs would hit enforced denies after redeploy. Mitigation: packs flip allow; SKILL.md troubleshooting row (5.1); PR-body note.
- **Windows path unverifiable in CI (Linux)** — ps1 changes are grep-asserted only. Mitigation: exact mirror of the sh gates including rc check; voice-pack precedent (ps1:1904) uses the same regex form.
- **`changed:` under-report regression** — covered by Phase 3 snapshot update + test assertion on merge output.
- **Double launcher install on full-setup path** — mitigated by the pip-show installed-check (4.1/4.2).
- **Phase 1↔2 revert coupling** — documented in Rollback note; revert as a pair.

## Post-review fixes (pipeline Step 9, code-review iteration 1)
- [x] **9.1** ps1 `$LASTEXITCODE` clobber: hook in Invoke-PackMerger + all Install-LocalMcpLaunchers early returns now reset `$global:LASTEXITCODE = 0` (best-effort must not fail the caller's rc check); bats `setup_ps1_hook_resets_lastexitcode_for_caller`.
    — **Why:** reviewer Major 1 — pip rc=1 (normal not-installed/offline) aborted Windows deploys with a false "Provider-pack application failed"
    — **Done when:** reset present in both functions + new bats assertion green
    — **Consumers affected:** Invoke-DeployAgents (setup.ps1:~2290), config-copy caller
    — **Done:** 4 resets + test; files: deploy/setup.ps1, tests/test_pack_permissions.bats; fixes: none beyond the finding
- [x] **9.2** Dead-key doc residue sweep (9 sites: docling-mcp-skill:69, nextjs-devtools-mcp-skill:16/29/47-56/125, nextjs-specialist:79, uiux-reviewer:105, responsive-audit:126, documentation-subagent:62, Dockerfile:69) + class guard `no_doc_teaches_dead_permission_keys` (grep sweep, markitdown SKILL.md whitelisted for its migration note).
    — **Why:** reviewer Major 2 — enforcing root denies make stale instructions actively harmful at merge time
    — **Done when:** sweep test green
    — **Consumers affected:** sibling skill/agent runtime prompts, Dockerfile comment readers
    — **Done:** all sites rewritten to root-permission allow form; files: 7 docs + Dockerfile + test; fixes: none beyond the finding
- [x] **9.3** Minors: ps1 duplicate python probe consolidated; pip retry output captured and surfaced in the failure warn (both scripts, setup.sh appends retry stderr to $pip_err + tail in warn + rm in else branch); setup.sh csv `grep -qw` safety note added.
    — **Why:** reviewer NOTEs — diagnostics lost on double failure, probe duplication
    — **Done when:** lint green, warn carries pip output
    — **Consumers affected:** offline-failure debugging UX
    — **Done:** files: deploy/setup.sh, deploy/setup.ps1; fixes: none beyond the finding
