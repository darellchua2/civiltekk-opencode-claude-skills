# Subagent briefs can misdescribe the subagent's own toolset — probe, don't trust

**Category**: pattern
**Confidence**: 0.7
**Scope**: project
**Date**: 2026-09-20

## Pattern

A parent-spawned brief may assert things about the subagent's own runtime
("you have no shell") that are false — permission denies can be inert (v1
action names), tool lists vary by harness shape, and the brief writer is
working from assumptions. The subagent should probe one cheap tool call
before degrading its verification plan to read-only.

## Context

#482 Step 9: the review brief told `code-review-subagent` "you have NO
shell, the diff is embedded" — but the deployed agent still carried the
(inert) v1 `bash` deny, so its shell tool was present. The reviewer probed,
found shell available, and re-ran all 27 bats suites + registry checks
itself, upgrading the review from trust-the-claims to independently
verified. The same round, a sibling brief named the wrong tree (see
`embedded-diff-hunks-unverifiable-probe-git-head-first.md`) — briefs are
untrusted input in both directions: about the code AND about the reader.

## Method

1. Read the brief's runtime claims as hypotheses, not facts.
2. One cheap probe (a `--version`, a `git status`) settles it.
3. If the probe contradicts the brief, use the stronger capability and say
   so in the report.

Related: `anti-patterns/embedded-diff-hunks-unverifiable-probe-git-head-first.md`,
`anti-patterns/v1-action-names-inert-under-v2.md`.
