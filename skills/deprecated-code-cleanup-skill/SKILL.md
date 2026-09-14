---
name: deprecated-code-cleanup-skill
description: >-
  Find, classify, and remove @deprecated TypeScript/Next.js code via
  dependency-traced analysis — safety tiers, phased removal with typecheck per
  step. Triggers: deprecated cleanup, remove deprecated, dead code cleanup, find
  deprecated.
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Code Quality
---

## What I do

I systematically remove `@deprecated` code from TypeScript/Next.js codebases using a dependency-traced, tier-based methodology proven on real projects (DA-1510: ~800+ lines of dead code removed across ~50 files with zero typecheck/lint errors):

1. **Discover all `@deprecated` markers** across `.ts` and `.tsx` files
2. **Trace the full dependency graph** for each deprecated item using alias imports, relative imports, dynamic imports, and barrel re-exports
3. **Propagate analysis through deprecated chains** — if a deprecated function's only consumer is another deprecated function, both are dead
4. **Classify items into deletion-safety tiers** (Tier 1 dead code → Tier 4 keep/document)
5. **Verify page.tsx reachability** — confirm no active App Router entry point transitively reaches the deprecated code
6. **Execute phased removal** — dead files first, then dead exports, then migration-dependent items, then barrel audit
7. **Run typecheck + lint + build after every phase** to catch breakages immediately
8. **Optionally generate a plan file** documenting all findings, tier classifications, and execution order

## When to use me

Use this skill when:
- You want to remove `@deprecated` functions, interfaces, or modules from a TypeScript/Next.js codebase
- You need to clean up dead code left behind after migrations or refactors
- A major version bump or API consolidation leaves deprecated wrappers behind
- You want to audit and remove unused barrel re-export (`index.ts`) files
- You are preparing a codebase for a release and want to eliminate technical debt safely
- You need a structured, verifiable approach to dead code removal (not just blind deletion)

**Trigger phrases**: "deprecated cleanup", "remove deprecated", "dead code cleanup", "deprecated functions", "remove @deprecated", "cleanup deprecated code", "find deprecated", "deprecated removal"

Ask clarifying questions if the cleanup scope is unclear, if there are protected modules that must not be touched, or if a specific migration path is preferred for Tier 3 items.

## Prerequisites

- TypeScript/Next.js project with source code in `src/` (`.ts`, `.tsx` files)
- `tsc` available (either via `npx tsc` or the project's TypeScript installation)
- `npm run lint` configured (or equivalent ESLint command)
- `npm run build` available for Next.js projects
- Write access to source files
- (Recommended) Git repository with clean working tree for easy rollback
- (Recommended) A JIRA ticket or task identifier for plan file naming (e.g., `DA-1510`)

## Methodology Overview

This skill operates in five phases. Each phase MUST be completed before moving to the next, and verification must pass after every phase.

```
Phase 0: Discovery & Classification (analysis only, no deletions)
    ↓
Phase 1: Dead File Deletion (Tier 1 files — zero importers)
    ↓
Phase 2: Dead Export Removal (Tier 1/2 exports from non-deleted files)
    ↓
Phase 3: Migration-Dependent Deletions (Tier 3 — migrate consumers first)
    ↓
Phase 4: Barrel & Re-export Audit (cleanup index.ts files)
    ↓
Verification Protocol after EVERY phase
```

## Phase 0: Discovery & Classification

### Step 1: Find all `@deprecated` markers

```bash
grep -rn '@deprecated' src/ --include='*.ts' --include='*.tsx'
```

Record every hit: file path, line number, and the deprecated symbol name (function, interface, type, class, const).

### Step 2: Trace ALL consumers for each deprecated item

For each deprecated item, run ALL of the following searches. Missing any one can cause a false "dead code" classification:

**Alias imports** (most common in Next.js with `@/` path alias):
```bash
grep -rn 'from "@/path/to/module"' src/ --include='*.ts' --include='*.tsx'
```

**Relative imports** — CRITICAL, these are easily missed:
```bash
grep -rn 'from "./module"\|from "../module"' src/ --include='*.ts' --include='*.tsx'
```

**Dynamic imports**:
```bash
grep -rn 'import(' src/ --include='*.ts' --include='*.tsx' | grep module
```

**JSDoc references** — these are comment-only, safe to ignore for consumer counting:
```bash
grep -rn '@see.*functionName\|@returns.*TypeName' src/ --include='*.ts' --include='*.tsx'
```

**Barrel re-exports** — check if any `index.ts` re-exports the deprecated symbol:
```bash
grep -rn 'export.*deprecatedSymbol\|export.*from.*deprecated-module' src/ --include='index.ts'
```

> **WARNING**: Relative imports (`./`, `../`) are the #1 cause of false positives. A barrel that shows 0 alias (`@/`) consumers may still have relative-import consumers in the same directory or sibling directories. ALWAYS run `tsc --noEmit` after any deletion to catch these.

### Step 3: Propagate the analysis through deprecated chains

If a deprecated function's ONLY consumer is ANOTHER deprecated function, both can be deleted together. Trace the chain until you reach a terminal condition:

| Chain Endpoint | Classification |
|----------------|---------------|
| Non-deprecated active consumer | CANNOT delete — classify as Tier 3 or 4 |
| Zero consumers | CAN delete — classify as Tier 1 |
| Only other deprecated consumers | CAN delete all together — classify as Tier 1 or 2 |

**Example chain**:
```
deprecatedFunctionA ← only consumer is deprecatedFunctionB
deprecatedFunctionB ← only consumer is deprecatedFunctionC
deprecatedFunctionC ← zero consumers
```
→ All three are dead. Delete `C` first (Tier 1), then `B` (Tier 2), then `A` (Tier 2). Or delete all at once and verify.

### Step 4: Verify page.tsx / layout.tsx reachability

For frontend projects, confirm no App Router entry point can transitively reach the deprecated code:

```bash
# For each deprecated module, check if any active importer chain reaches a page.tsx or layout.tsx
grep -rn 'from.*deprecated-module' src/app/ --include='*.ts' --include='*.tsx'
```

If a `page.tsx` or `layout.tsx` imports a module that (transitively) imports the deprecated code, the deprecated code may still be reachable at runtime. Trace the full import chain before classifying.

### Step 5: Classify into tiers

| Tier | Criteria | Action | Verification |
|------|----------|--------|--------------|
| **Tier 1 — Dead code** | Zero production consumers (alias + relative + dynamic + barrel all return zero) | Delete immediately | `tsc --noEmit` after batch |
| **Tier 2 — Dead once Tier 1 deleted** | Only consumer is Tier 1 dead code | Delete after Tier 1 | `tsc --noEmit` after batch |
| **Tier 3 — Needs migration** | Has active production consumers | Migrate consumers to replacement API, then delete | `tsc --noEmit` per migration |
| **Tier 4 — Keep** | Deprecated but deeply integrated; migration too costly or risky | Document only; retain `@deprecated` marker | No action |

Record the classification for every deprecated item in a table:

```
| Symbol | File | Tier | Consumers | Replacement API | Notes |
|--------|------|------|-----------|-----------------|-------|
```

## Phase 1: Dead File Deletion

**Target**: Tier 1 items that exist in files with zero importers (entire file is dead).

1. Delete entire files that have zero importers
2. Delete associated test files (`*.test.ts`, `*.spec.ts`, `*.test.tsx`) for deleted files
3. After each batch of deletions, run verification:
```bash
npx tsc --noEmit
```
4. If `tsc` reports errors (`TS2307: Cannot find module`), restore the file — it had relative-import consumers that were missed

**Decision tree**:
```
Does the file have ANY importers (alias, relative, dynamic, barrel)?
├── NO → Delete the file + its test file
│        Run tsc --noEmit
│        Errors? → Restore file, reclassify as Tier 3
│        Clean? → Continue
├── YES, but ALL importers are deprecated/deleted → Delete the file
│        Run tsc --noEmit
│        Errors? → Restore file, reclassify as Tier 3
│        Clean? → Continue
└── YES, has active importers → Skip (go to Phase 2 for export-level removal)
```

## Phase 2: Dead Export Removal

**Target**: Tier 1/2 exports from files that are NOT deleted (the file has active exports too).

1. Remove deprecated functions/interfaces from files that also contain active code
2. Clean up unused imports left behind by the removed exports
3. Clean up stale JSDoc references (`@see`, `@returns`, `@param`) that pointed to deleted code
4. Delete or update test files:
   - If a test file ONLY tests deprecated functions being deleted → delete the test file
   - If a test file tests both deprecated and active code → remove only the deprecated test cases
5. Run verification:
```bash
npx tsc --noEmit
npm run lint
```

**Import cleanup checklist** after removing an export:
- [ ] Check if the file's imports are now unused (the deleted function may have been the only consumer of an imported type)
- [ ] Check if any `import { removedFunction }` in other files now fails (shouldn't if Tier 1/2 was correct)
- [ ] Remove now-empty import lines (e.g., `import { } from 'module'`)

## Phase 3: Migration-Dependent Deletions

**Target**: Tier 3 items that have active production consumers.

For each Tier 3 item, follow this sequence INDEPENDENTLY (do not batch):

1. **Read the deprecated item's replacement API** — look for `@deprecated Use X instead` in the JSDoc
2. **Migrate each consumer** to the replacement API:
   - Read the consumer's usage of the deprecated function/interface
   - Understand what the replacement API expects (different signature, different return type, different path)
   - Update the consumer's import and usage
3. **Verify after each individual migration**:
```bash
npx tsc --noEmit
```
4. **Once ALL consumers are migrated**, delete the deprecated item
5. **Verify again after deletion**:
```bash
npx tsc --noEmit
```

> **WARNING**: Do NOT batch-migrate Tier 3 items. Each migration should be verified independently with `tsc --noEmit`. If a migration fails, you need to know exactly which consumer caused the issue. Batching obscures the failure point and makes rollback harder.

**If no replacement API exists**: The deprecated item is effectively Tier 4. Document it and move on. Do NOT delete without a clear replacement path.

## Phase 4: Barrel & Re-export Audit

**Target**: `index.ts` files that may now be dead after Phase 1-3 deletions.

### Scan all barrels with consumer counts

Run BOTH alias and relative import counts for every `index.ts`:

```bash
for f in $(find src/ -name 'index.ts' | sort); do
  barrel_path=$(echo "$f" | sed 's|^src/||;s|/index.ts$||')
  alias_count=$(grep -rn "from [\"']@/${barrel_path}[\"']" src/ --include='*.ts' --include='*.tsx' | grep -v 'index.ts:' | wc -l)
  rel_count=$(grep -rn "from [\"']\\.\\./$(basename $(dirname $f))[\"']\\|from [\"']\\.\\./$(basename $(dirname $f))/" src/ --include='*.ts' --include='*.tsx' | grep -v 'index.ts:' | wc -l)
  total=$((alias_count + rel_count))
  echo "$total $f"
done | sort -n
```

### Barrel classification

| Barrel Type | Consumer Count | Action |
|-------------|---------------|--------|
| Dead barrel | 0 consumers | Delete |
| Low-usage barrel | 1-2 consumers | Inline imports to source files, then delete |
| Barrel with logic | Any | KEEP — defines constants, has side effects (e.g., registering loaders) |
| Cross-path redirect shim | Any | Delete if 0 consumers; inline if 1-2 |

### CRITICAL: Post-barrel-deletion typecheck

After deleting ANY barrel, ALWAYS run:

```bash
npx tsc --noEmit
```

If `tsc` reports `TS2307: Cannot find module '@/path/to/barrel'` or similar, RESTORE the barrel immediately. The TypeScript compiler is the only reliable consumer detector for relative imports.

**Barrel deletion checklist**:
- [ ] Confirmed 0 alias (`@/`) consumers
- [ ] Confirmed 0 relative (`./`, `../`) consumers
- [ ] Confirmed barrel has NO side effects (no code execution on import, only re-exports)
- [ ] Confirmed barrel does NOT define constants or types consumed elsewhere
- [ ] Ran `tsc --noEmit` after deletion — no `TS2307` errors
- [ ] If errors: restored barrel, reclassified

## Verification Protocol

After EVERY phase (Phase 1, 2, 3, and 4), run the full verification suite:

```bash
# 1. Typecheck — catches broken imports, missing types, removed exports still referenced
npx tsc --noEmit

# 2. Lint — catches unused imports, style issues, dead code warnings
npm run lint

# 3. Build — catches Next.js route issues, dead endpoint references, SSR/SSG problems
npm run build
```

**For auth-adjacent changes** (deprecated code near authentication, sessions, tokens):
- Manually verify login flow
- Manually verify token refresh flow
- Manually verify account-switching flow
- Check that no redirect/auth-guard logic was silently removed

**If ANY verification step fails**:
1. Identify the failing file and error
2. Restore the deleted code (or fix the migration)
3. Re-run verification
4. Do NOT proceed to the next phase until all checks pass

## Key Lessons (Warnings)

These lessons come from real cleanup sessions and MUST be followed:

### 1. Relative imports are invisible to `@/` scans

A barrel with 0 `@/` alias consumers may still have `./` or `../` relative import consumers. ALWAYS run `tsc --noEmit` after barrel deletion and restore any barrel that produces `TS2307` errors. This is the single most common cause of broken builds after cleanup.

### 2. Barrels with side effects

Some `index.ts` files execute code on import (e.g., registering loaders, initializing singletons, setting up global handlers). These are NOT pure re-export barrels and must be kept even if they appear to have 0 consumers. Check for:
- Top-level function calls (not inside `export`)
- `registerX()`, `initY()`, or similar initialization calls
- Side-effect imports (`import './polyfill'`)
- Constant definitions that are consumed via direct path

### 3. Deprecated function chains

If `functionA` is deprecated and only called by `functionB` (also deprecated), deleting `functionB` makes `functionA` dead. Always propagate the analysis through the full chain. Deleting only the leaf leaves the parent as orphaned dead code.

### 4. JSDoc references are NOT imports

`@see`, `@returns`, and `@param` tags reference deprecated items in comments. These are NOT real consumers and don't prevent deletion. Clean them up after deletion to avoid dangling references.

### 5. Test files for deleted code

If a test file ONLY tests deprecated functions being deleted, delete the test file too. If it tests both deprecated and active code, update it to remove only the deprecated test cases. Leaving tests for deleted code causes `tsc` errors (cannot find imported function).

### 6. Dynamic imports

`await import("@/module")` is a valid consumer that grep may miss if the path is constructed dynamically or split across template literals. Check for `import(` patterns:

```bash
grep -rn 'import(' src/ --include='*.ts' --include='*.tsx'
```

## Anti-Patterns to Avoid

- **Don't delete barrels without running typecheck** — The TypeScript compiler is the only reliable consumer detector for relative imports. `tsc --noEmit` is your safety net.
- **Don't trust a single scan method** — Always cross-reference alias imports, relative imports, and dynamic imports. Each catches what the others miss.
- **Don't remove `@deprecated` tags from kept items** — Tier 4 items should retain their deprecated markers for future awareness and future cleanup attempts.
- **Don't batch-migrate Tier 3 items** — Each migration should be verified independently with `tsc --noEmit`. Batching obscures failure points.
- **Don't skip verification after any phase** — A single missed broken import can cascade into a failed build hours later.
- **Don't delete code you can't trace** — If you can't find consumers with certainty, classify as Tier 4 and document. Err on the side of caution.
- **Don't forget test cleanup** — Deleted functions leave orphaned test files that fail compilation.

## Output Artifacts

### Plan File (Optional but Recommended)

After Phase 0 analysis, optionally generate a plan file documenting the full cleanup strategy:

**File name**: `PLAN-{TICKET}.md` (e.g., `PLAN-DA-1510.md`)

**Structure**:
```markdown
# Deprecated Code Cleanup — {TICKET}

## Summary
- Total `@deprecated` markers found: N
- Tier 1 (dead code): N items
- Tier 2 (dead after Tier 1): N items
- Tier 3 (needs migration): N items
- Tier 4 (keep/document): N items

## Classification Table

| Symbol | File | Tier | Consumers | Replacement API | Notes |
|--------|------|------|-----------|-----------------|-------|
| deprecatedFuncA | src/lib/utils.ts | 1 | None | — | Safe to delete |
| deprecatedInterfaceB | src/types/old.ts | 3 | src/app/page.tsx | NewInterfaceB | Migrate first |
| ... | ... | ... | ... | ... | ... |

## Dependency Traces

### deprecatedFuncA (Tier 1)
- Alias import search: 0 results
- Relative import search: 0 results
- Dynamic import search: 0 results
- Barrel re-export check: not re-exported
- Conclusion: DEAD CODE — safe to delete

### deprecatedFuncB (Tier 2)
- Alias import search: 1 result (deprecatedFuncA in src/lib/utils.ts)
- deprecatedFuncA is Tier 1 → will be deleted in Phase 1
- Conclusion: Dead once Phase 1 completes — delete in Phase 2

## Execution Order
1. Phase 1: Delete [list of dead files]
2. Phase 2: Remove exports [list] from [files]
3. Phase 3: Migrate [list of consumers] then delete [list]
4. Phase 4: Audit [list of barrels]

## Risk Assessment
- Low risk: [items with clear zero-consumer status]
- Medium risk: [items with relative import ambiguity]
- High risk: [Tier 3 migrations touching auth/critical paths]

## Impact Summary (completed after execution)
- Files deleted: N
- Lines removed: N
- Functions eliminated: N
- Interfaces removed: N
- Barrels deleted: N
- Test files deleted: N
- Typecheck: PASS
- Lint: PASS
- Build: PASS
```

### Execution Report (Generated After Completion)

After the full cleanup is done, generate a brief summary for the PR/ticket:

```
## Deprecated Code Cleanup Report

**Ticket**: {TICKET}
**Date**: {DATE}

### Metrics
- `@deprecated` markers found: {N}
- Items deleted: {N}
- Items migrated: {N}
- Items kept (Tier 4): {N}
- Files deleted: {N}
- Lines removed: ~{N}
- Test files deleted: {N}
- Barrels deleted: {N}

### Verification
- [x] tsc --noEmit: PASS
- [x] npm run lint: PASS
- [x] npm run build: PASS
```

## Best Practices

- **Commit between phases**: If using Git, commit after each successful phase so you can roll back individual phases without losing progress
- **Start with the safest deletions**: Always begin with Tier 1 (zero consumers) before attempting migrations
- **Keep a running count**: Track files deleted and lines removed for the impact summary
- **Document Tier 4 items**: Even if you can't delete them, document WHY they can't be deleted and what migration would be needed in the future
- **Check for circular dependency warnings**: Removing deprecated code can break circular dependency chains in unexpected ways — watch for new circular dependency warnings after deletions
- **Review server action exports separately**: Server actions (`"use server"` functions) may be consumed by client components via import — trace these carefully
- **Check Next.js dynamic route segments**: `src/app/[param]/page.tsx` files may import deprecated utilities for params parsing — these are easy to miss in grep

## Verification Commands

After creating or modifying this skill, verify:

```bash
# Check skill directory exists
ls -la ~/.config/opencode/skills/deprecated-code-cleanup-skill/

# Verify SKILL.md exists
test -f ~/.config/opencode/skills/deprecated-code-cleanup-skill/SKILL.md && echo "OK: SKILL.md exists"

# Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('$HOME/.config/opencode/skills/deprecated-code-cleanup-skill/SKILL.md'))" && echo "OK: YAML valid"

# Check required fields
grep "^name:" ~/.config/opencode/skills/deprecated-code-cleanup-skill/SKILL.md
grep "^description:" ~/.config/opencode/skills/deprecated-code-cleanup-skill/SKILL.md
```

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

1. **Gate check**: confirm env var is set; if unset, follow default behavior above.
2. **Auto-detection**: if this skill is invoked on a task that looks iterative (multiple cycles expected), prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". On "y", continue; on "n", default behavior. Cache the answer for the session.
3. **5-stage loop**: cycle Understand → Hypothesize → Experiment → Evaluate → Log & Iterate. See `autoresearch-core-skill/SKILL.md`.
4. **Evaluator contract**: emit `{"pass":bool,"score":N}` JSON from a mechanical evaluator. Pass determines keep/revert; score logged to `deprecated-cleanup-results.tsv`. See `autoresearch-core-skill/references/evaluator-contract.md`.
5. **Stuck detection**: 3 consecutive non-improving iterations → strategy pivot; 5 consecutive → paradigm shift. See `autoresearch-core-skill/references/stuck-detection.md`.
6. **Audit trail**: append every iteration to `deprecated-cleanup-results.tsv` (8-column: iteration, commit, metric, delta, status, description, timestamp, evaluator_output). See `autoresearch-core-skill/references/audit-trail.md`.
7. **Crash recovery**: syntax errors → fix immediately (don't count); runtime → max 3 fix attempts then skip; timeout → revert + log; OOM → smaller variant. See `autoresearch-core-skill/references/crash-recovery.md`.
8. **Git-as-memory**: commit before each verify; auto-revert (`git reset --hard HEAD~1`) on `pass:false`.
9. **Iteration safety**: bounded-by-default (`Iterations: 25`); safety blocks `.env`, `node_modules/`, `rm -rf`, `git push --force`. See `autoresearch-core-skill/references/iteration-safety.md`.

### Skill-specific override

**Git-as-memory per tier.** Commit before each tier-N removal. After removal, run typecheck (or equivalent build gate). On failure: `git reset --hard HEAD~1` to revert, log to `deprecated-cleanup-results.tsv`, advance to next item. Pass = typecheck succeeds post-removal; score = items removed this iteration.

### Max iterations
- Default: 25 iterations
- Hard cap: 100 (explicit `Iterations: unlimited` overrides)
