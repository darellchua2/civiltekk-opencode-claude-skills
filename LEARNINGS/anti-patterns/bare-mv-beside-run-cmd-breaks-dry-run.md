# A bare mv beside run_cmd breaks the --dry-run contract

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Evidence**: deploy/setup.sh `run_cmd` suppresses execution under DRY_RUN (setup.sh:970-985) and the config copy routes through it (setup.sh:2482), but the legacy migrate block's bare `mv` (setup.sh:2445,2448) and setup.ps1's unguarded `Move-Item` (setup.ps1:1712,1715) mutate for real in preview mode — flagged in the #432 review, fixed for the new jsonc parks via `run_cmd mv` / `if (-not $DryRun)` (feat/432 commit 9130a36/ec59536).

In the deploy scripts' config phase, every new filesystem mutation must route through `run_cmd` (bash) or an `if (-not $DryRun)` guard (PowerShell) — "preview all actions without making changes" is the documented contract (setup.sh:39). The legacy migrate block was the known leaky precedent NOT to copy. **Resolved 2026-09-21 (#506):** the bash migrate block is now `run_cmd`-wrapped (`deploy/setup.sh:2605-2653`), and the ps1 `Move-Item` sites are gone entirely — #474 replaced the native ps1 with a thin launcher that delegates to bash. The rule stands for all new mutation sites.
