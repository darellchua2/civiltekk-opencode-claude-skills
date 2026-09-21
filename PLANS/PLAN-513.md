# PLAN: Cross-platform shell snippets and install docs

**Branch**: feat/513
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/513
**Base**: main

## Acceptance Criteria
- [ ] Every listed file either has the cross-platform variant or the one-line bash requirement
- [ ] Identified false positives are byte-identical to before
- [ ] No apt/brew-only install doc remains without a Windows row (or an explicit "use WSL" note) in the listed files

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/security-audit-skill/SKILL.md` | — | vibeguard operators verifying masking | low |
| `skills/opencode-repo-setup-skill/SKILL.md` | jq merge semantics (existing) | repo-setup agents on jq-less machines | med |
| `skills/ascii-diagram-creator-skill/SKILL.md` | ImageMagick | diagram creators on Windows | low |
| `skills/cad-bambu-labs-skill/SKILL.md` | script CLI (unchanged) | print-flow agents | low |
| `skills/office-thumbnail-skill/SKILL.md`, `skills/xlsx-specialist-skill/SKILL.md`, `skills/pdf-specialist-skill/SKILL.md` | LibreOffice/poppler availability | office-doc converters on Windows | low |
| `skills/version-bump-standard-skill/SKILL.md`, `skills/autoresearch-core-skill/SKILL.md` | — | release/loop agents | low |
| zai ×4 (NO edit — #512 already added the bash+curl+jq declaration) | #512 merged | — | none |
| False positives: docker-containerization, amplify-nextjs, mermaid (Docker route), pptx test fixture | — | #515 guard exempt list | none |

## Implementation Phases

### Phase 1: env-prefix + jq portability

- [ ] **1.1** `skills/security-audit-skill/SKILL.md` (:73 smoke test) — add the PowerShell variant line: "`$env:OPENCODE_VIBEGUARD_DEBUG=1; opencode` (PowerShell)".
    — **Why:** `VAR=1 cmd` env-prefix is bash-only; Windows operators otherwise can't run the smoke test.
    — **Done when:** both variants present at the smoke-test step.
    — **Consumers affected:** security-audit operators on Windows.
- [ ] **1.2** `skills/opencode-repo-setup-skill/SKILL.md` (:89–97 merge procedure) — add a `node -e` alternative performing the same deep-merge (read opencode.json + delta.json, `Object.assign`-style recursive merge writing mcp keys, existing file as base), marked "when `jq` is unavailable".
    — **Why:** jq is not preinstalled on Windows; Node is guaranteed (installer is npx-based).
    — **Done when:** the node alternative sits beside the jq command with identical merge semantics.
    — **Consumers affected:** repo-setup agents on jq-less machines.

### Phase 2: `/tmp` literals + Windows install rows

- [ ] **2.1** `skills/ascii-diagram-creator-skill/SKILL.md` — replace the `/tmp/workflow.txt` heredoc + convert reference (:84–93) with a repo-relative temp name (`diagrams/workflow.txt`, cleaned up after convert), and add a Windows row to the imagemagick install block (:279–282: `winget install ImageMagick.ImageMagick` — or "use WSL").
    — **Why:** `/tmp` is unix-only; install docs skipped Windows entirely.
    — **Done when:** no `/tmp/` literal remains in the file; Windows row present.
    — **Consumers affected:** diagram creators on Windows.
- [ ] **2.2** `skills/cad-bambu-labs-skill/SKILL.md` (:103, :115) — parameterize `--gcode /tmp/job.gcode` to `--gcode <output.gcode>` with a note that the path is the slicer-export location (any OS temp dir works).
    — **Why:** the snippet hardcodes a unix path for a user-produced file.
    — **Done when:** no `/tmp/` literal remains in the file; both send examples parameterized.
    — **Consumers affected:** print-flow agents on Windows.
- [ ] **2.3** `skills/office-thumbnail-skill/SKILL.md` (:36–40) — add Windows rows to the LibreOffice + Poppler install blocks (`winget install TheDocumentFoundation.LibreOffice` / `winget install osmosis.poppler` or "use WSL").
    — **Why:** apt-only install docs.
    — **Done when:** Windows row present under each install block.
    — **Consumers affected:** office-thumbnail users on Windows.
- [ ] **2.4** `skills/xlsx-specialist-skill/SKILL.md` (:362–365) — add the Windows LibreOffice row (winget or WSL note).
    — **Why:** same as 2.3.
    — **Done when:** Windows row present.
    — **Consumers affected:** xlsx users on Windows.
- [ ] **2.5** `skills/pdf-specialist-skill/SKILL.md` (:24) — extend the poppler/qpdf parenthetical with "Windows: `winget install` or WSL".
    — **Why:** apt/brew-only.
    — **Done when:** Windows mention present.
    — **Consumers affected:** pdf users on Windows.

### Phase 3: bash-requirement declarations

- [ ] **3.1** `skills/version-bump-standard-skill/SKILL.md` — add one line near the scripts usage: "Scripts are bash + `gh` — Windows: run under git-bash/WSL."
    — **Why:** 5 `.sh` scripts otherwise read as universally runnable.
    — **Done when:** declaration present.
    — **Consumers affected:** release operators on Windows.
- [ ] **3.2** `skills/autoresearch-core-skill/SKILL.md` — add one OS note near the loop script reference: "`autoresearch-loop.sh` requires bash (git-bash/WSL on Windows)."
    — **Why:** same class; the loop is the skill's core.
    — **Done when:** declaration present.
    — **Consumers affected:** overnight-loop operators on Windows.
- [ ] **3.3** zai ×4 — verify the #512 credential note already carries the bash+curl+jq declaration; NO further edit.
    — **Why:** the ticket's zai declaration item was satisfied by the merged #512 binding note; re-editing would duplicate it.
    — **Done when:** `rg -c 'bash \+ curl \+ jq' skills/zai-*/SKILL.md` ≥1 in each of the four.
    — **Consumers affected:** none.

### Phase 4: verification

- [ ] **4.1** False-positive integrity + exit gate: `git diff origin/main...HEAD -- skills/docker-containerization-skill skills/amplify-nextjs-deployment-skill skills/mermaid-diagram-creator-skill` empty; `skills/pptx-template-modifier-skill/scripts/tests/test_vision_extractor.py` untouched; `gh-cli-setup-skill` untouched; full bats suite + build-registry.
    — **Why:** the ticket's explicit do-not-touch list; registry must not move (no frontmatter edits).
    — **Done when:** all diffs empty; full suite green.
    — **Consumers affected:** installer (registry byte-identical).

## Technical Notes
- PowerShell env-prefix: `$env:OPENCODE_VIBEGUARD_DEBUG=1; opencode` (semicolon statement separator).
- Node merge one-liner keeps jq's semantics: existing file is base, delta wins on conflicts, recursive for objects.
- Windows install rows use `winget` IDs where unambiguous; otherwise the explicit "use WSL" escape hatch — never invent unverifiable IDs.
- zai declaration already shipped in #512 ("Recipe execution needs bash + curl + jq") — recorded, not duplicated.

## Dependencies
- blocked-by: #510 (conventions — merged); zai item satisfied by #512 (merged).

## Risks & Mitigation
- *winget ID drift* → only well-known IDs used; every block also carries the "use WSL" fallback.
- *Node merge diverges from jq `*` semantics* → the alternative is documented as deep-merge with delta-wins; agents validate with the existing diff-check step either way.
