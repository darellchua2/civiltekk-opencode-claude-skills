# Anti-pattern: a global in-flight guard bleeds across sessions

**Context**: #418 review round 2 — the auto-continue plugin's own-send echo guard used a single global counter; while a send to session A was in flight, the prompt hook dropped a *real* user message in session B, silently keeping B ESC-latched and its counter stale on a multi-session server.
**Pattern**: Scope any hook-suppression/in-flight guard to the affected entity (per-session `Set<sessionID>`), never a global counter — concurrency guards that outlive or outreach their request suppress unrelated work. Clear asynchronously (next tick) only the entry you added.
**Rationale**: A guard that defends one flow must not censor a different flow; global state couples independent sessions in ways unit tests with a single session cannot see.
**Alternatives Considered**: Widening the suppression window to catch late hook echoes — rejected, it widens the bleed; per-session scope fixes the found bug without speculative widening.
**Confidence**: 0.9
**Scope**: project
