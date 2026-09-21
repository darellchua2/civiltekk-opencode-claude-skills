# Pattern: Transport-only fallback kills disclaimer drift

Choosing a fallback that reuses the native model id (different transport, same model — e.g. raw HTTP vs provider binding) collapses a whole maintenance class: the "different model" disclaimers that previously had to stay in sync across six docs were deleted, not updated. Replicate when picking fallback models; model divergence forces per-doc caveats that drift on every model change.

**Confidence:** medium
**Scope:** project
**Evidence:** agents/image-analyzer-subagent.md:68,94 + AGENTS.md vision-fallback paragraph + README vision-tier note, all converged on one id in #516 (code review positive observation, 2026-09-21)
**Date:** 2026-09-21
