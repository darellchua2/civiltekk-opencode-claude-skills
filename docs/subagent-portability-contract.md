# Subagent Portability Contract

The authoring standard for `agents/` definitions in this repo, so one source file serves every install target. Companion to `docs/harness-landscape-2026-09.md` (why) and `AGENTS.md` §Portability contract (the skills-side original this contract mirrors). Scope: **agents only** — the skills-side equivalent (`skills/<name>/overlays/`) is future work and must not start under the skill-isolation contract (#437) without its own ticket.

## The three layers

> **If the installer can know it at write time, the installer writes it. If only the runtime can know it, the LCD body carries the fallback.**

| Layer | Where it lives | Carries |
|---|---|---|
| 1. LCD core | `agents/<stem>.md` | Harness-neutral identity, workflow, universal return contract, `Other/none:` fallback rows, runtime fallbacks (vision recipe, LEARNINGS glob) |
| 2. Install-time composition | `agents/overlays/<stem>.<target>.md` + one shared helper | Harness-specific ergonomics: tool names, invocation syntax, deploy-time model pins, provider auth prose |
| 3. Runtime self-selection | the LCD's fallback rows | Only what no installer can know: model availability, granted permissions, MCP state at spawn |

The LCD core alone must **work** everywhere — it is what the `agents` (verbatim) target, a hand `git clone`, ZCode's importer, and any future unknown harness receive.

## LCD core rules

- **Frontmatter** stays the OpenCode v2 superset (`description`, `mode`, `steps`, `permissions` rule array, no `model:`) — every other target is a known lossy projection of it. The one sanctioned exception: a **capability-neutral `description`** (no provider/model pins; say what the agent can do, not which model it runs on).
- **Body skeleton**: Identity → Capability bindings (as fallback rows) → Workflow → Return contract. The return contract (`Status / Output / Summary / Issues`, plus reviewer additions) is universal and never moves to an overlay.
- **No harness-only invocation snippets in the core** — no `subagent_type=`, no `via Task tool`, no tool-name-denial clauses tied to one harness ("the `question` tool is deny'd"), no provider/model pins in prose. Enforced mechanically by the moved-token gate (below).
- **Headless clause** is phrased as a capability fact: "no interactive clarification channel exists in a subagent session — proceed on stated assumptions" — true in every harness.
- **Every core contains an `Other/none:` fallback row per capability** (delegation → inline; clarification → stated assumptions; memory → glob `LEARNINGS/*.md`; vision → bundled HTTP recipe). Asserted by the guard tests.
- **Runtime fallbacks stay in the core** even when harness-specific (e.g. image-analyzer's Z.AI vision recipe): they are the degrade path for deploys without the native capability.

## Binding matrix

Two tiers. **An overlay suffix is valid only where a composition path exists** — a guard test fails any overlay whose target has no `TARGETS` row.

| Tier | Targets | Overlay files |
|---|---|---|
| **Composable** | `opencode`, `claude`, `kimi`, `kilo` (have `TARGETS` rows + composition paths) | Yes — `<target>.md` overlays compose |
| **Composable, never composes** | `agents` (verbatim interchange mode) | **None — `.agents.md` overlays are invalid** and guard-blocked |
| **Documented-only** | `zcode`, `copilot`, `codex`, `pi`, M365 Copilot | None — landscape doc may describe their mechanisms; no overlay files |

Notes per documented-only harness: **copilot** needs none (reads `~/.claude/agents/` natively — the claude artifact covers it); **zcode** forbids nested subagents (its agents would need core-only + importer flow — Portability phase 2); **pi** has no native subagents (RPC/SDK embedding is the documented delegation route); **codex/M365** use different definition formats (`.toml` profiles / declarative agents).

## Overlay convention

- Location: `agents/overlays/<stem>.<target>.md` (e.g. `agents/overlays/code-review-subagent.opencode.md`).
- Content: **fragments, not documents** — no H1 title, no frontmatter; prose meant to be appended after the core body, separated by one blank line.
- An overlay exists only when the target genuinely needs different words than the core; absent overlay = target receives the core unchanged.

## Composition pipeline

Fixed order, implemented **once** in a shared helper (`installer/overlay.mjs`), consumed by **both** agent write paths:

```
source agents/<stem>.md
  → frontmatter transform   (per-target: model-injected | claude-translate | kimi-translate | kilo-translate)
  → body concat             (core + agents/overlays/<stem>.<target>.md, blank-line separated)
  → model injection         (renderAgent: compose BEFORE injectModel)
  → config emit             (opencode.json / kilo.jsonc permission blocks)
```

- Write paths: npx `add` (`installer/init.mjs` agent loop) and full deploy (`deploy/setup.sh` → `installer/resolve-models.mjs` `renderAgent`, including its `RESOLVER_CONFIG_ONLY` sub-mode which routes through init.mjs).
- `renderAgent` composes before `injectModel`; `injectModel` touches only frontmatter, so the seams' orderings converge on identical bytes — asserted for the **opencode target** (the only target both seams produce).
- Verbatim mode (`agents` target) never composes; helper refuses targets without a `TARGETS` row.
- Manifest hash tracking (#379) hashes final written bytes — composed output is tracked with zero manifest changes.

## Moved-token manifests (mechanical parity floor)

"Behavior-equivalent" is gate-checked in two tiers:

1. **Mechanical (blocking, in `tests/agent_lcd_pilot.bats`)** — per agent, a manifest of moved tokens: each token must be **absent from the LCD core** and **present in the composed output** of its owning target, produced by invoking the shared helper directly (hermetic, no full install). Matching is case-insensitive. Tokens name *invocation-shaped* content, not legitimate negative mentions ("NEVER call `question`" is legal in a core; `subagent_type=` is not).
2. **Meaning-parity (human, recorded)** — per agent, a verdict recorded in the Appendix: composed opencode output reorganizes the original prose without losing instructions. Verdicts are durable artifacts, not commit messages.

Initial manifests (finalized as each pilot retrofit lands):

| Agent | Banned in core (→ lives in overlay) | Required in core | Required in opencode overlay |
|---|---|---|---|
| code-review-subagent | `subagent_type=`, `via the Task tool`, `the `memory` tool` | `Patterns applied/violated`, `BLOCK`, `Other/none:` | `subagent_type=`, `language-reviewer-subagent` |
| image-analyzer-subagent | `zai-coding-plan/glm-5.3-flash` (pin), `permission.task` | fallback-recipe marker (`ZAI_API_KEY`), `Other/none:` | `zai-coding-plan/glm-5.3-flash` |
| requirements-specialist-subagent | `subagent_type=`, "`question` tool is NOT available" | `Mode R`, `Return Contract`, `Other/none:` | `subagent_type=` |

## Pilot coverage (per-target outcome)

| Target | Pilot output | Why |
|---|---|---|
| opencode | core + `.opencode.md` overlay | Full parity with pre-retrofit behavior (byte-identity asserted across both seams) |
| claude | core + minimal `.claude.md` overlay (~5–15 lines: Task binding + capability rows) | LCD-only would be a regression — claude's current bodies carry mostly-valid Task-tool wording |
| kimi / kilo | core only | Strict improvement: current translated bodies reference mechanisms those harnesses lack; fallback rows replace them |
| agents (verbatim) | core only | Neutral interchange copy — never composes |
| zcode / copilot / codex / pi / M365 | core only | Documented-only (see matrix); phase-2 follow-up covers zcode/copilot TARGETS rows + kimi/kilo overlays |

## Lossy-translation registry

What each target drops, by design — degradation must be explicit, never silent:

| Concern | opencode | claude | kimi/kilo | agents | documented-only |
|---|---|---|---|---|---|
| Model tiering | tier-injected at deploy | provider default | provider/model pin (kilo) | none (verbatim) | n/a — core carries fallback rows |
| Permission granularity | full rules array | tools/disallowedTools (lossy, warned) | allow/ask/deny globs (lossy, warned) | verbatim | n/a |
| Nested delegation | allowed (gated by `subagent` rules) | allowed | allowed (`permission.task`) | verbatim | zcode: forbidden — inline fallback |
| Skill gating in frontmatter | `action: skill` rules | dropped (warned) | kilo: `permission.skill` map | verbatim | n/a |
| MCP at spawn | per config | per config | per config | verbatim | zcode: only servers connected at session start |

## Appendix — parity verdicts

Preliminary verdicts from advisory pre-composition (2.4) are marked `preliminary`; the authoritative gate (composer-invoked, byte-identity + token gate) replaces them.

- **code-review-subagent**: preliminary PASS — composed core+opencode-overlay restores memory-tool recall, explore/general/language-reviewer Task syntax, codegraph delegation request; core retains checklist, rubric, direct-caller gate, return contract, ponytail lens, voice; token greps green. _preliminary — superseded by 3.4_
- **image-analyzer-subagent**: preliminary PASS — model pin, auth.json expectation, permission-rule delegability restored via overlay; core retains recipe, output budget, procedure, return contract; description de-pin is intentional (4.1 expects exactly that diff). _preliminary — superseded by 3.4_
- **requirements-specialist-subagent**: preliminary PASS — question-deny explanation and Task syntax restored via overlay; headless clause generalized semantics-preserving; modes A/B/R, routing tree, workflow intact. _preliminary — superseded by 3.4_
