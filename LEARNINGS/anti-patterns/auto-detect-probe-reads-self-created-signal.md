# Auto-detect probes must not read signals the tool itself synthesizes

**Category**: anti-patterns
**Confidence**: 0.85
**Scope**: project
**Date**: 2026-09-25

## Pattern

A detection probe that reads a directory its own writer creates unconditionally self-inflates. #564's `--target auto` probed `existsSync(~/.config/opencode)`, but `writeUserScopeInstall` does `mkdir(~/.config/opencode, { recursive: true })` for the shared manifest on EVERY user-scope add — including `--target claude/kimi/kilo`. First auto run on a non-opencode machine permanently added opencode to all future detections; any existing `--target claude` user already had the dir, so their very first auto run was wrong. Fix: content-aware probe — root must contain something other than `.skill-manifest.json` (`dirHasContent(USER_OC, ".skill-manifest.json")`). Rule: an auto-detect signal must be state the tool cannot synthesize as a side effect — probe content, not the root, or exclude manifest-only markers. Origin: #564 code review (Major).

## Anti-pattern signaled by

Detection tests that only run auto once per sandboxed HOME — the inflation appears on the SECOND run. Pin with an install-then-auto sequence asserting the synthetic signal is ignored.
