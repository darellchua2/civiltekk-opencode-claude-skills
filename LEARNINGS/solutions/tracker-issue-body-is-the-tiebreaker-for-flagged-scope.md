# Solution: Tracker issue body is the tiebreaker for flagged scope

When a review brief and a PLAN disagree on maintainer-directive scope for a "flagged for reviewer confirmation" inclusion, the tracker issue body is the authoritative tiebreaker — fetch it before emitting a Requirements Gap. #522: the orchestrator brief said the maintainer named 3 ids; the issue's proposed solution named all 4 including the flagged extension, resolving the call with zero repo-side evidence available.

**Confidence:** medium
**Scope:** project
**Evidence:** #522 plan review 2026-09-22 — glm-4.7-flashx inclusion approved via issue-body text, zero repo special-treatment found
**Date:** 2026-09-22
