---
name: continuous-learning-skill
description: "Extract and store reusable patterns, decisions, insights from coding sessions — project scoping, memory-hygiene procedure."
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Agent Optimization
---

## What I do

I extract and persist actionable knowledge from coding sessions using an instinct-based learning model with confidence scoring and project scoping:

1. **Pattern Extraction**: Identify recurring code patterns, architectural decisions, and problem-solving approaches
2. **Instinct Model**: Store learnings as atomic "instincts" with confidence scores (0.3-0.9) that evolve over time
3. **Project Scoping**: Isolate project-specific knowledge from universal patterns to prevent cross-project contamination
4. **Markdown Storage**: Save to `LEARNINGS/` markdown files (git-committed, reviewable; auto-injected as a manifest each session)
5. **Instinct Evolution**: Cluster related instincts into skills, commands, or agent improvements
6. **Cross-Session Learning**: Build a knowledge base that improves agent performance over time

## What's New in v2

| Feature | v1 | v2 |
|---------|----|----|
| Granularity | Full patterns | Atomic "instincts" with confidence scoring |
| Scoping | All learnings global | Project-scoped + global instincts |
| Confidence | low/medium/high text | Numeric 0.3-0.9 weighted score |
| Evolution | Store only | Instincts can evolve into skills/agents |
| Cross-project | Contamination risk | Isolated by default, promoted when seen in 2+ projects |
| Retrieval | Search only | Search + confidence-weighted application |

## When to use me

Use this skill when:
- A coding session produces reusable patterns or decisions worth preserving
- A code review or architecture review identifies systemic patterns
- You want agents to learn from past sessions and avoid repeating mistakes
- You need to document architectural decisions made during implementation
- A complex debugging session reveals non-obvious solutions worth recording
- A review agent detects the same issue in 3+ files (systemic pattern)
- You want to promote project-specific patterns to global knowledge

**Trigger phrases**:
- "learn from this session"
- "extract patterns"
- "save what we learned"
- "capture this decision"
- "remember this approach"
- "promote to global"
- "evolve instincts"

## The Instinct Model

An instinct is a small, atomic learned behavior:

```
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.7
domain: "code-style"
source: "session-observation"
scope: project
project_id: "my-react-app"
```

**Properties:**
- **Atomic** — one trigger, one action
- **Confidence-weighted** — 0.3 = tentative, 0.9 = near certain
- **Domain-tagged** — code-style, testing, git, debugging, workflow, architecture, security
- **Scope-aware** — `project` (default) or `global`
- **Evidence-backed** — tracks what observations created it

### Confidence Scoring

| Score | Meaning | Behavior |
|-------|---------|----------|
| 0.3 | Tentative | Suggested but not enforced |
| 0.5 | Moderate | Applied when relevant |
| 0.7 | Strong | Auto-approved for application |
| 0.9 | Near-certain | Core behavior |

**Confidence increases** when:
- Pattern is repeatedly observed
- User doesn't correct the suggested behavior
- Similar instincts from other sources agree

**Confidence decreases** when:
- User explicitly corrects the behavior
- Pattern isn't observed for extended periods
- Contradicting evidence appears

## Storage Strategy

> The former `memory` tool (opencode-superlocalmemory plugin) has no OpenCode v2 release — the
> plugin was removed. `LEARNINGS/` markdown is the single store; the auto-inject plugin surfaces
> a manifest (titles + paths) in the system prompt each session, and `memory`-style recall is a
> `glob`+`read` on that manifest. Re-evaluate the split-store design if a v2-compatible memory
> plugin ships.

### `LEARNINGS/` markdown files (curated, reviewable, git-committed, auto-injected)

| Property | Detail |
|----------|--------|
| Location (project) | `LEARNINGS/<category>/<slug>.md` at repo root |
| Location (user) | `~/.config/opencode/learnings/<category>/<slug>.md` |
| Discovery | auto-injected manifest (titles + paths) at session start; `glob`+`read` on demand |
| Best for | Quick facts and anti-patterns (one-liners) AND detailed patterns/ADRs — file size scales to content |
| Strength | Human-readable, git-history, PR-reviewable, survives provider changes |

**When a short entry is enough (single instinct, one file):**
- Quick capture during active development
- Simple decisions ("Chose Zod for validation")
- Anti-patterns ("Avoid mutable default args in Python")
- Solutions ("Fix race condition with mutex")
- Facts about the project ("Uses Drizzle ORM, not Prisma")
- Atomic instincts with confidence scores
- Complex architectural decisions with trade-offs
- Detailed pattern descriptions with code examples
- Team conventions that need documentation
- Evolved instinct clusters (multiple instincts merged into a skill)
- Knowledge that benefits from human review and version history

## Scope Decision Guide

| Pattern Type | Scope | Examples |
|-------------|-------|---------|
| Language/framework conventions | **project** | "Use React hooks", "Follow Django REST patterns" |
| File structure preferences | **project** | "Tests in `__tests__/`", "Components in src/components/" |
| Code style | **project** | "Use functional style", "Prefer dataclasses" |
| Error handling strategies | **project** | "Use Result type for errors" |
| Security practices | **global** | "Validate user input", "Sanitize SQL" |
| General best practices | **global** | "Write tests first", "Always handle errors" |
| Tool workflow preferences | **global** | "Grep before Edit", "Read before Write" |
| Git practices | **global** | "Conventional commits", "Small focused commits" |

### Project Detection

Automatically determine project scope:
1. Git remote URL — hashed for portable project ID
2. Git repo path — fallback for machine-specific ID
3. Global fallback — if no project detected, instincts go to global scope

### Instinct Promotion (Project → Global)

When the same instinct appears in multiple projects with high confidence, promote to global scope:

**Auto-promotion criteria:**
- Same instinct ID observed in 2+ projects
- Average confidence >= 0.8

**How to promote:**
- Review the instinct's evidence across projects
- If criteria met, re-save with `scope: global`
- Remove project-scoped duplicates

## Storage Locations

```
Project-level (auto-provisioned, git-committed, shared with team):
  <project-root>/LEARNINGS/
  ├── _index.md                 # Auto-generated index
  ├── patterns/                 # Reusable approaches worth replicating
  ├── decisions/                # "We chose X over Y because..." (ADR-lite)
  ├── anti-patterns/            # Things to avoid
  ├── solutions/                # Non-obvious fixes worth remembering
  └── conventions/              # Team-agreed coding standards

User-level (created by setup.sh/setup.ps1, personal, cross-project):
  ~/.config/opencode/learnings/
  ├── _index.md
  ├── patterns/
  ├── decisions/
  ├── anti-patterns/
  ├── solutions/
  └── conventions/

Searchable memory (manifest auto-injected at session start; recall = glob+read on LEARNINGS/)
```

### Auto-Provisioning

The `LEARNINGS/` directory does NOT need to exist before this skill runs. When writing a markdown learning file, **first check if the directory structure exists, and create it if missing**:

1. Check if `<project-root>/LEARNINGS/` exists (use `glob` for `LEARNINGS/_index.md`)
2. If missing, create the full structure:
   - `LEARNINGS/_index.md` (from template below)
   - `LEARNINGS/patterns/`, `LEARNINGS/decisions/`, `LEARNINGS/anti-patterns/`, `LEARNINGS/solutions/`, `LEARNINGS/conventions/`
   - Each subfolder gets a `.gitkeep` file
3. Then write the learning file to the appropriate subfolder
4. Then append to `_index.md`

**`_index.md` template for auto-provisioning:**
```markdown
# LEARNINGS Index

<!-- AUTO-GENERATED — manual edits to the listing below will be overwritten on next learning write -->

## Folder Structure

| Folder | Purpose | Example |
|--------|---------|---------|
| `patterns/` | Reusable code/architecture patterns worth replicating | `event-driven-modules.md` |
| `decisions/` | Architectural decisions with rationale (ADR-lite) | `sqlite-over-postgres-local.md` |
| `anti-patterns/` | Things to avoid, with explanations | `mutable-default-args-python.md` |
| `solutions/` | Non-obvious fixes and workarounds worth remembering | `race-condition-mutex-fix.md` |
| `conventions/` | Team-agreed coding standards and naming rules | `kebab-case-files.md` |

## Entries

<!-- Entries are appended here automatically when new learnings are saved -->

<!-- No entries yet -->
```

**Important**: the auto-inject plugin surfaces a LEARNINGS manifest at session start (title + path per file). Agents discover learnings through:
1. AGENTS.md instructions (auto-loaded at session start) — tells agents where to look
2. The injected manifest — primary retrieval pointer
3. Explicit `glob`/`read` tool calls — for detailed markdown review

## Core Workflow

### Step 1: Analyze Session Context

Review the current session for extractable knowledge:

- Files created or modified
- Decisions made and rationale
- Errors encountered and solutions applied
- Patterns used (design patterns, code structures, naming conventions)
- Dependencies added or configured
- Configuration changes and why
- User corrections (high-value signal — indicates wrong assumption)

### Step 2: Extract Instincts

Break findings into atomic instincts:

```
Instinct 1:
  id: prefer-explicit-errors
  trigger: "when handling errors"
  action: "Use explicit error types instead of generic Error"
  confidence: 0.7
  domain: "code-style"
  scope: project
  evidence: "User corrected generic Error to CustomError in 3 places"

Instinct 2:
  id: always-validate-input
  trigger: "when accepting user input"
  action: "Validate with zod schema before processing"
  confidence: 0.9
  domain: "security"
  scope: global
  evidence: "Applied consistently across 5 endpoints"
```

### Step 3: Categorize Findings

Classify extracted knowledge into categories:

| Category | Folder | Examples | Default Storage |
|----------|--------|----------|----------------|
| **Pattern** | `patterns/` | "Repository pattern for data access", "Error boundary in React" | long-form entry |
| **Decision** | `decisions/` | "Chose SQLite over PostgreSQL for local-first" | long-form entry |
| **Solution** | `solutions/` | "Fix race condition with mutex" | short-form entry |
| **Convention** | `conventions/` | "Use kebab-case for file names" | long-form entry |
| **Anti-pattern** | `anti-patterns/` | "Avoid mutable global state in tests" | short-form entry |

### Step 4: Write the Learning File (ALWAYS)

Every learning is written to `LEARNINGS/<category>/<slug>.md` (the single store — the former `memory` tool has no v2 plugin):

Format for the entry body:
```
[Category]: [Title]
Scope: [project|global]
Confidence: [0.3-0.9]
Trigger: [when this applies]
Action: [what to do]
Context: [when/where this applies]
Detail: [what the pattern/decision is]
Rationale: [why this approach]
Evidence: [what observations support this]
Files: [related file paths, if any]
```

### Step 5: Write Markdown File (IF warranted)

For complex learnings or evolved instinct clusters, also create a markdown file:

```markdown
## [Category]: [Title]

**Context**: When/where this applies
**Pattern**: What the pattern or decision is
**Rationale**: Why this approach was chosen
**Alternatives Considered**: What else was evaluated
**Trade-offs**: Pros and cons of this approach
**Code Example**: (if applicable)
**References**: Related files, docs, or external links
**Confidence**: 0.3-0.9
**Scope**: project | global
**Date**: YYYY-MM-DD
```

### Step 6: Update Index

After writing a markdown file, append an entry to the relevant `_index.md`:

```markdown
### [Title]

- **Category**: pattern | decision | anti-pattern | solution | convention
- **File**: `<category>/<slug>.md`
- **Confidence**: 0.3-0.9
- **Scope**: project | global
- **Summary**: One-line summary
- **Date**: YYYY-MM-DD
```

### Step 7: Suggest Applications

After storing, suggest where this knowledge could be applied:

- Similar codebases or projects
- Future sessions with related tasks
- Skills or agents that could benefit from this knowledge
- Whether the instinct should be promoted to global scope

## Instinct Evolution

Related instincts can be clustered and evolved into higher-level artifacts:

### Evolution Path

```
Raw observations (session activity)
    ↓
Atomic instincts (individual learned behaviors)
    ↓
Clustered instincts (related behaviors grouped)
    ↓
Evolved artifacts:
  - Skills (workflow definitions)
  - Conventions (coding standards)
  - Agent improvements (behavior modifications)
```

### When to Evolve

- 3+ instincts in the same domain with confidence >= 0.7
- A pattern recurs across multiple sessions
- User explicitly requests consolidation ("make a skill from these patterns")

### How to Evolve

1. Identify a cluster of related instincts
2. Extract the common workflow or pattern
3. Draft a new skill section, convention entry, or agent modification
4. Store the evolved artifact as a markdown file
5. Link back to the source instincts for traceability

## Post-Review Integration

When invoked by review agents (architecture-review, code-review), follow this behavior:

1. **Detect systemic patterns**: If the same issue appears in 3+ files, create an instinct
2. **Capture decisions**: If the review recommends an architectural approach, record it
3. **Record anti-patterns**: If the review finds code that should be avoided, save it
4. **Note good patterns**: If the review finds exemplary code, flag it for replication
5. **Track confidence**: Each observation increases confidence; corrections decrease it
6. **Write the learning file**: `LEARNINGS/<category>/<slug>.md` — one entry per instinct; short-form for quick capture, long-form for detailed analysis

## Learning Formats

### Short-Form Instinct (Quick Capture — single LEARNINGS entry)

```
Decision: Use path aliases for imports
Scope: project
Confidence: 0.7
Trigger: when setting up new TypeScript project
Action: Configure @/ aliases in tsconfig.json
Why: Avoids ../../../ relative paths, cleaner imports
Evidence: Applied successfully in current project
```

### Long-Form (Detailed Analysis — LEARNINGS entry with full structure)

```markdown
## Pattern: Event-Driven Module Communication

### Context
Modules need to communicate without tight coupling. Direct imports
create circular dependency issues in a growing codebase.

### Pattern
Use an event bus for cross-module communication:
- Publisher modules emit typed events
- Subscriber modules listen for specific event types
- No direct imports between modules

### Rationale
- Decouples modules completely
- Easy to add new subscribers without modifying publishers
- Testable in isolation
- Trade-off: harder to trace execution flow

### Code Example
[Relevant code snippet]

### Instincts Extracted
- prefer-event-driven-comm (0.7, project)
- avoid-circular-imports (0.8, global)

### References
- src/events/bus.ts
- src/modules/user/events.ts
```

## Retrieval Guide

When an agent needs to recall past learnings:

1. **First**: Search memory by relevance
   ```
   memory(mode: "search", query: "authentication pattern", scope: "project")
   ```

2. **Filter by confidence**: Apply instincts with confidence >= 0.7 automatically; suggest those with 0.3-0.6

3. **For details**: Read the markdown file referenced in the memory result
   ```
   read(filePath: "LEARNINGS/patterns/event-driven-modules.md")
   ```

4. **For browsing**: Glob the learnings directory
   ```
   glob(pattern: "LEARNINGS/**/*.md")
   ```

5. **Check scope**: Only apply project-scoped instincts in the matching project; global instincts apply everywhere

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `verification-loop` | Verify learned patterns are correctly applied |
| `strategic-compact` | Compact session context but preserve high-confidence instincts |
| `eval-harness` | Evaluate if learned patterns improve code quality |
| `context-budget` | Audit whether stored learnings are consuming too much context |
| `search-first` | Search-first decisions feed into continuous learning as instincts |
| `code-smells` | Patterns may reference anti-patterns detected by this skill |
| `design-patterns` | Learned patterns may align with or extend GoF patterns |

## Best Practices

### What to Capture

- Non-obvious solutions (things you had to research)
- Project-specific conventions discovered during development
- Performance optimizations and their measured impact
- Error patterns and their resolutions
- Architecture decisions and their trade-offs
- Systemic code review findings (same issue in 3+ files)
- User corrections (highest-value signal — indicates wrong assumption)

### What NOT to Capture

- Trivial or obvious code patterns
- Things already well-documented in standard references
- Temporary workarounds without long-term value
- Sensitive information (API keys, credentials, internal URLs)

### Confidence Calibration

- Start new instincts at 0.5 (moderate)
- Increase by 0.1 for each additional observation
- Decrease by 0.2 for user corrections
- Floor at 0.3, ceiling at 0.9
- Promote to global only at >= 0.8

### Quality Criteria

- Each instinct should be **actionable**: someone can apply it
- Include **trigger context**: when/where this applies
- Provide **rationale**: why this approach was chosen
- Set **confidence**: how certain are we this is correct
- Track **evidence**: what observations support this instinct

## Example Usage

### Mid-Session Capture

```
"Extract what we learned about the authentication flow"
```

The skill will:
1. Review the session's auth-related changes
2. Extract atomic instincts (e.g., "use middleware for auth checks" at 0.7)
3. Save to memory with project scope
4. Save markdown file if the decision is complex
5. Update index if markdown file was created

### Post-Review Capture

```
"After code review, save the recurring null-check pattern as an anti-pattern"
```

The skill will:
1. Review the findings from the code review
2. Extract instincts with confidence based on occurrence count
3. Save anti-patterns to LEARNINGS entries
4. Save good patterns for replication
5. Suggest evolution if 3+ instincts cluster in same domain

### Promote to Global

```
"Promote the 'always validate input' instinct to global scope"
```

The skill will:
1. Check the instinct's evidence across projects
2. Verify confidence >= 0.8
3. Re-save with `scope: global`
4. Remove project-scoped duplicate

### Evolve Instincts

```
"Evolve the testing-related instincts into a convention"
```

The skill will:
1. Find all instincts in the "testing" domain
2. Cluster related instincts
3. Draft a convention entry
4. Store as markdown in `LEARNINGS/conventions/`
5. Link back to source instincts

## References

- `strategic-compact` - Manages context window efficiently
- `verification-loop` - Verifies implementations against requirements
- `eval-harness` - Evaluates code and skill quality
- `context-budget` - Audit learning overhead
- `search-first` - Research decisions feed into learning

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

1. **Gate check**: confirm env var is set; if unset, follow default behavior above.
2. **Auto-detection**: if this skill is invoked on a task that looks iterative (multiple cycles expected), prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". On "y", continue; on "n", default behavior. Cache the answer for the session.
3. **5-stage loop**: cycle Understand → Hypothesize → Experiment → Evaluate → Log & Iterate. See `autoresearch-core-skill/SKILL.md`.
4. **Evaluator contract**: emit `{"pass":bool,"score":N}` JSON from a mechanical evaluator. Pass determines keep/revert; score logged to `continuous-learning-results.tsv`. See `autoresearch-core-skill/references/evaluator-contract.md`.
5. **Stuck detection**: 3 consecutive non-improving iterations → strategy pivot; 5 consecutive → paradigm shift. See `autoresearch-core-skill/references/stuck-detection.md`.
6. **Audit trail**: append every iteration to `continuous-learning-results.tsv` (8-column: iteration, commit, metric, delta, status, description, timestamp, evaluator_output). See `autoresearch-core-skill/references/audit-trail.md`.
7. **Crash recovery**: syntax errors → fix immediately (don't count); runtime → max 3 fix attempts then skip; timeout → revert + log; OOM → smaller variant. See `autoresearch-core-skill/references/crash-recovery.md`.
8. **Git-as-memory**: commit before each verify; auto-revert (`git reset --hard HEAD~1`) on `pass:false`.
9. **Iteration safety**: bounded-by-default (`Iterations: 25`); safety blocks `.env`, `node_modules/`, `rm -rf`, `git push --force`. See `autoresearch-core-skill/references/iteration-safety.md`.

### Skill-specific override

**Mechanical confidence validation.** Subjective confidence scores (0.0-1.0) are REPLACED by mechanical `{"pass":bool,"score":N}` from a validation eval: does the learned pattern reproduce on a held-out test set / second codebase / different scenario? Pass = reproduces; score = reproduction rate (0-100).

### Max iterations
- Default: 25 iterations
- Hard cap: 100 (explicit `Iterations: unlimited` overrides)
