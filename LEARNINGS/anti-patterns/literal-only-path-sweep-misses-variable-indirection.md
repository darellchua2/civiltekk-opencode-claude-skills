# Literal-only stale-path greps miss variable indirection

- **Category**: anti-pattern
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-15
- **Summary**: Path-move sweeps that grep only literal `deploy/<file>` strings miss references built from shell variables. #378 moved `provider-models.json` to `installer/` but `deploy/setup.sh:3008` read it as `${DEPLOY_DIR}/provider-models.json` — every PLAN grep gate returned 0 while the `-f` presence test silently flipped to skip, disabling the exposed-model guard on Linux/macOS (the ps1 mirror at `setup.ps1:1884` WAS repointed → platform divergence). When auditing a move, enumerate every variable that resolves into the moved dir (`DEPLOY_DIR`, `$DeployDir`, `Join-Path $DeployDir …`) and grep uses of THAT variable too, not just literal paths.

## Evidence

- Branch `feat/378`: PLAN-378 steps 2.1/5.4 grep gates (literal `deploy/(init\.mjs|…|provider-(models|presets)|…)`) all clean, yet `run_resolver()` kept resolving the guard file through `DEPLOY_DIR`; 13 bats files stayed green because no test asserts the `--provider-models` arg. Caught only by reading the resolver call sites in review.
- Same family as the #384 backslash lesson: the sweep shape must match the reference shape — literal, backslash, AND variable-indirection forms.
