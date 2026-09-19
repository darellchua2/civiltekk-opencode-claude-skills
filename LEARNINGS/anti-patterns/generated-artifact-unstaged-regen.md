# Anti-pattern: regenerated artifact left unstaged after phase work

`node installer/build-registry.mjs` writes `installer/registry.json` on disk; if the phase commit doesn't `git add` it, the branch ships main's stale registry while local gates pass (they read disk). #408 merged-state caught it only at code review — the reviewer's diff-alphabetical-skip noticed `installer/registry.json` missing between `pack-devops.json` and `opencode_app/README.md`.

Rule: after ANY generated-artifact regen in a phase, `git status --porcelain -- <artifact>` must be empty before the phase commit; and the phase commit message should name the artifact. Better: end-of-phase check `git diff main...HEAD --stat -- installer/registry.json` non-empty whenever skill/agent sets changed.

Consequence if missed: CI `build-registry.mjs --check` fails on next push; `opencode-init add <removed-skill>` resolves a skill that no longer exists on disk.

Evidence: #408 review Critical (PR #422, fixed in e6ac9d5); recurrence family of `phase-commit-ci-gate-ordering`.
