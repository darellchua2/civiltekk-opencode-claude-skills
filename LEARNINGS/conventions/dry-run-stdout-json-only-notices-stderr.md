# Dry-run stdout is JSON-only — notices go to stderr

**Category**: conventions
**Confidence**: 0.8
**Scope**: project
**Date**: 2026-09-26

## Pattern

Dry-run stdout is machine-readable JSON only; every notice on a dry-reachable path must go to stderr (`console.error`), never `console.log` (discipline exists since #439, init.mjs:828-830; now load-bearing for #568's aggregated `--target auto --dry-run` doc). Bats merges stderr into `$output`, so JSON-parsing tests strip notices with `sed -n '/^{/,$p'` before `python3 json.load` (tests/init.bats). New code adding stdout output in dry paths — or "simplifying" the sed strip away in tests — silently breaks CLI consumers or the suite. Origin: #568 code review.
