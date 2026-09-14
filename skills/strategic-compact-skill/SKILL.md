---
name: strategic-compact-skill
description: Suggest optimal context compaction strategies for AI agent sessions, preserving critical information while reducing token usage
license: Apache-2.0
compatibility: opencode
category: Agent Optimization
---

## What I do

I analyze AI agent session context and suggest when and how to compact it efficiently:

1. **Context Analysis**: Assess current session size, complexity, and information density
2. **Criticality Assessment**: Identify which context is essential vs. expendable
3. **Compaction Strategy**: Recommend what to keep, summarize, or discard
4. **Summary Generation**: Create compact summaries that preserve actionable information
5. **Session Planning**: Suggest optimal session breakpoints for complex multi-step tasks

## When to use me

Use this skill when:
- A session is becoming long and context window is filling up
- You want to preserve important decisions before context gets too large
- You're working on a multi-step task that spans multiple interaction rounds
- An agent is struggling with context length limits
- You want to start a new session but carry forward essential information

**Trigger phrases**:
- "compact context"
- "summarize session"
- "reduce context"
- "what can we drop"
- "session getting long"
- "preserve key decisions"

## Core Workflow

### Step 1: Assess Session Context

Analyze the current session for compaction opportunities:

| Metric | What to Measure |
|--------|----------------|
| **Token estimate** | Approximate context size |
| **Unique topics** | Number of distinct topics discussed |
| **Open tasks** | Incomplete items that need tracking |
| **Decisions made** | Architectural or design decisions |
| **Files modified** | What code has been changed |
| **Errors resolved** | Problems that were fixed and how |

### Step 2: Classify Information

Categorize all session content by retention priority:

#### Tier 1: Must Keep (Critical)
- Current task description and acceptance criteria
- Uncommitted changes and their purpose
- Active debugging state (current hypothesis, what's been tried)
- Blockers and dependencies
- Authentication/security context

#### Tier 2: Should Keep (Important)
- Architecture decisions and rationale
- Key file locations and their purposes
- API contracts and data models
- Test results and coverage status
- Partial solutions with reasoning

#### Tier 3: Can Summarize (Compressible)
- Exploration paths that didn't pan out (just note "tried X, didn't work because Y")
- Detailed code reviews (keep findings, drop the back-and-forth)
- Error resolution steps (keep solution, drop the debugging process)
- File contents that are unchanged (just note file paths)

#### Tier 4: Can Discard (Expendable)
- Greetings and pleasantries
- Redundant explanations
- Abandoned approaches with no learning value
- Intermediate calculations or formatting iterations
- Content available in files (reference the file instead of keeping content)

### Step 3: Generate Compaction Strategy

Create a structured compaction plan:

```markdown
## Compaction Strategy

### Keep Full Context
- Task: Implement user authentication with OAuth2
- Acceptance criteria: [3 bullet points]
- Files changed: src/auth/oauth.ts, src/middleware/session.ts
- Current state: OAuth flow implemented, session management in progress

### Summarize
- Debugging OAuth redirect issue → Root cause: callback URL mismatch. Fixed by updating redirect_uri config.
- Explored 3 auth libraries → Chose next-auth for Next.js integration. Others rejected: passport (Express-focused), clerk (vendor lock-in).

### Discard
- Initial project setup discussion
- Formatting debates
- Earlier code iterations (current code in files)
```

### Step 4: Execute Compaction

Apply the compaction strategy:

1. **Generate summary**: Create a compact session brief
2. **Preserve in memory**: Store critical information in `LEARNINGS/` markdown or project config
3. **Update AGENTS.md**: Add relevant findings to project instructions if applicable
4. **Plan next session**: Define starting point for continued work

### Step 5: Validate Compaction

Ensure nothing critical was lost:

- [ ] All active tasks still tracked
- [ ] All open files still referenced
- [ ] All decisions preserved with rationale
- [ ] All errors/solutions documented
- [ ] Next steps are clear

## Compaction Templates

### Session Brief Template

```markdown
## Session Brief (Compacted)

### Active Task
[One-line description of what's being worked on]

### State
- [x] Completed: [what's done]
- [ ] In Progress: [what's current]
- [ ] Remaining: [what's left]

### Key Decisions
1. [Decision]: [Why] → [Impact]
2. [Decision]: [Why] → [Impact]

### Files
| File | Status | Notes |
|------|--------|-------|
| path/to/file | Modified | What changed and why |
| path/to/file | Created | Purpose |
| path/to/file | Unchanged | Relevant context |

### Blockers
- [Any blockers or dependencies]

### Next Steps
1. [Immediate next action]
2. [Following action]
3. [Final steps]
```

### Multi-Session Planning Template

For tasks that span multiple sessions:

```markdown
## Multi-Session Plan

### Session 1 (Complete)
- [x] Setup project structure
- [x] Install dependencies
- Key decisions: [list]

### Session 2 (Current)
- [x] Implement data models
- [ ] Add API endpoints
- [ ] Write tests

### Session 3 (Planned)
- [ ] Integration testing
- [ ] Documentation
- [ ] Deploy
```

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `continuous-learning` | Preserve learned patterns during compaction (Tier 1) |
| `verification-loop` | Compaction preserves verification state and checkpoints |
| `eval-harness` | Eval results are Tier 2 (keep summaries) |
| `plan-updater` | PLAN.md files serve as natural compaction targets |

## Best Practices

### When to Compact

- **Proactively**: Before reaching 70% context capacity
- **Between tasks**: When switching from one subtask to another
- **After debugging**: Once a problem is solved, compact the debugging process
- **Before PR creation**: Compact to just changes and rationale

### What to Always Preserve

- Uncommitted work (describe what's been changed)
- Active error states (if debugging is ongoing)
- Architecture decisions (with reasoning)
- Acceptance criteria (for current task)
- File paths of modified files

### Common Mistakes

- Over-compacting: losing the "why" behind decisions
- Under-compacting: keeping too much raw conversation
- Not planning ahead: compacting reactively instead of proactively
- Ignoring dependencies: dropping context that other skills/agents need

## Example Usage

### Proactive compaction mid-session

```
"Context is getting long, compact what we can"
```

The skill will:
1. Assess current context size and content
2. Classify information into tiers
3. Generate summary for Tier 2/3 items
4. Present compaction plan for approval
5. Execute compaction and validate

### End-of-session handoff

```
"Summarize this session for the next one"
```

The skill will:
1. Generate a complete session brief
2. Document all decisions and rationale
3. List files changed with purposes
4. Define clear next steps
5. Store for retrieval in next session

## References

- `continuous-learning` - Extract patterns before compacting
- `verification-loop` - Verify compaction didn't lose critical info
- `eval-harness` - Evaluate compaction quality
