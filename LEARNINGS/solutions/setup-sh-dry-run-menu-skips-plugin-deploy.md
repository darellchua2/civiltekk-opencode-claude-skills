# `setup.sh --dry-run` under non-interactive stdin takes the skills-only path — plugin deploy is never previewed

- **Category**: solution
- **Confidence**: 0.95
- **Scope**: project
- **Added**: 2026-09-20 (#448 plan review)

## Problem

`./deploy/setup.sh --dry-run` run headless (stdin at EOF, e.g. `</dev/null` in CI) resolves the
interactive menu to Skills-Only Setup: the flow exits via "Skills deployment complete!" and
**never calls `deploy_plugins()`** (deploy/setup.sh:4303) — zero `[DRY-RUN] Would execute: cp -r …/plugins/`
lines are printed, yet the script still exits 0. A dry-run gate grepping for a plugin copy line
false-fails (or gets "fixed" into a false green). The menu only renders when `AUTO_ACCEPT=false`
(deploy/setup.sh:~4216); `-y` skips it into the full-setup path.

Second trap in the same gate: `run_cmd` (deploy/setup.sh:974) echoes the **expanded absolute**
`$HOME/.config/opencode/plugins/` destination — a grep for the literal `~/.config/opencode/plugins/`
can never match.

## Rule

Plugin-deploy dry-run gates must run `./deploy/setup.sh --dry-run -y` (or feed menu option 3) and
grep the expanded-path shape, e.g.
`grep -E "\[DRY-RUN\] Would execute: cp -r .*plugins/<name>\.ts .*/\.config/opencode/plugins/$"`.
Verified empirically 2026-09-20 (sandboxed HOME): plain `--dry-run` → 0 plugin lines;
`--dry-run -y` → 8 `cp -r …/plugins/` lines.
