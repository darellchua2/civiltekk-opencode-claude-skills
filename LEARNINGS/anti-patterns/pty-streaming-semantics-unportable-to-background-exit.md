## Pattern: PTY streaming semantics are unportable to v2 background exit notifications

**Context**: #507 review — the rewritten Strategy A promised per-iteration results from a persistent `--ui` watch runner started with `background: true`, plus sentinel-file early-stop. Verified against opencode.ai/v2/docs/tools: a background command notifies the session ONCE, when it finishes; a watcher that never exits never notifies; there is no stream-read of a running command and no kill API.

**Pattern**: rewording PTY-era prompts onto `background: true` without redesigning the event model yields unexecutable instructions. Correct mapping: per-run EXITING background commands (one notification per pass, results inside it), long-runners only as servers queried out-of-band (`show-report` over HTTP), stop via foreground `pkill -f`.

**Alternatives Considered**: keeping the watcher and sourcing results from the report server — viable but more moving parts; per-run exiting commands are the boring fix (deletion bias).
