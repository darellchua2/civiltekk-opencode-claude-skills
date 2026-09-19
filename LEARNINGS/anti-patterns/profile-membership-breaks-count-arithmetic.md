# Anti-pattern: profile-membership breaks count arithmetic

Before writing a N→N−k target for a profile/count in a plan, grep which arrays actually contain each removed key — do not infer from one surface.

#408 planned "lean 46→45" assuming `plan-automation-loop-skill` was shipped-only; `deploy/skill-profiles.json` held BOTH deleted skills (lines 35+37), so the correct target was 44. Executed as planned, `skill_profiles.bats:31-36` (every lean key matches a skill dir on disk) fails after the `git rm` — the disk-match test turns any kept key into a hard merge blocker.

Fix pattern: `grep -n "<deleted-key>" deploy/skill-profiles.json opencode_app/opencode.json installer/presets/*.json` before writing the target number; derive the new count from the array contents, not the removal intent.

Evidence: `deploy/skill-profiles.json:35,37` vs PLAN-408 rev 1 step 2.2; caught by architecture review (BLOCK B1), verified on disk.
