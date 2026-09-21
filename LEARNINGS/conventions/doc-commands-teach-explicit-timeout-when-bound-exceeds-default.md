## Convention: docs teaching long commands must name an explicit shell `timeout`

**Context**: #507 review — `skills/zai-video-skill/SKILL.md` §3 teaches `curl --max-time 600` run verbatim in the foreground; the v2 shell's 2-minute foreground default harness-kills it long before its own bound on slow or 4K downloads.

**Pattern**: any doc'd command whose own bound exceeds the shell's 120000 ms foreground default gets one line naming an explicit `timeout` ≥ that bound (or runs as a background command, which has no default timeout). Audit skill recipes for durations and `--max-time` values over 120 s.
