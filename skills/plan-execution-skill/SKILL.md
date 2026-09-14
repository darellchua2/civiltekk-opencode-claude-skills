---
name: plan-execution-skill
description: Execute PLAN.md phases with automatic progress tracking. Parses plan, executes tasks sequentially, and auto-invokes plan-updater after each phase completion.
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Git/Workflow
---

## What I do

I provide automatic PLAN.md execution with integrated progress tracking:

1. **Detect Current PLAN**: Extract branch name and find matching PLAN file
2. **Parse Plan Structure**: Read phases, tasks, and acceptance criteria
3. **Execute Phases**: Work through plan tasks in order
4. **Auto-Update Progress**: Invoke `plan-updater` after each phase completes
5. **Track Completion**: Mark tasks complete and commit progress automatically

## When to use me

Use this skill when:
- You say "implement the plan" or "execute the plan"
- Working on a branch with a PLAN.md file
- Want automatic progress tracking during development
- Need systematic phase-by-phase execution

**Trigger phrases**:
- "implement the plan"
- "execute the plan"
- "work on the plan"
- "continue with the plan"
- "resume plan execution"

## Subagents That Should Use This Skill

| Subagent | When to Invoke |
|----------|----------------|
| Any subagent | When user says "implement the plan" |

## Core Workflow

### Step 0: Verbatim playbook discipline (anti-drift)

Before executing, transcribe the matched PLAN's steps into the session todolist VERBATIM, ahead of any task-specific todos:

- Copy plan steps word-for-word — no paraphrasing, reordering, or merging during transcription.
- A step you decide to skip STAYS in the todolist, annotated `skip: <reason>`. Silently deleting it is drift.
- Task-specific todos are appended AFTER the transcribed plan steps, never interleaved.
- At each phase boundary, diff the todolist against the PLAN file: every deviation must be a visible `skip:` entry or a completed step.

### Step 1: Detect Current PLAN

Identify the PLAN file for the current branch:

```bash
BRANCH_NAME=$(git branch --show-current)

# GitHub pattern: GIT-123
if [[ "$BRANCH_NAME" =~ ^GIT-([0-9]+)$ ]]; then
  ISSUE_NUM="${BASH_REMATCH[1]}"
  PLAN_FILE="PLANS/PLAN-GIT-${ISSUE_NUM}.md"
  PLAN_TYPE="github"
fi

# JIRA pattern: PROJECT-123
if [[ "$BRANCH_NAME" =~ ^([A-Z]+-[0-9]+)$ ]]; then
  PLAN_ID="${BASH_REMATCH[1]}"
  PLAN_FILE="PLANS/PLAN-${PLAN_ID}.md"
  PLAN_TYPE="jira"
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "No PLAN file found for branch: $BRANCH_NAME"
  echo "Expected: $PLAN_FILE"
  exit 1
fi

echo "Found PLAN: $PLAN_FILE"
```

### Step 2: Parse Plan Structure

Extract phases, atomic steps, and the dependency map from PLAN.md:

```bash
# Extract phase headers
PHASES=$(grep -n "^### Phase" "$PLAN_FILE")

# Extract all atomic steps with checkboxes (steps use the **N.M** marker)
TASKS=$(grep -n "^- \[ \]" "$PLAN_FILE")

# Extract completed steps
COMPLETED=$(grep -n "^- \[x\]" "$PLAN_FILE")

echo "Found phases: $(echo "$PHASES" | wc -l)"
echo "Total steps: $(echo "$TASKS" | wc -l)"
echo "Completed: $(echo "$COMPLETED" | wc -l)"
```

**Parse the atomic-step block.** Each step carries a rationale triple that MUST be read before execution:

```text
- [ ] **N.M** <atomic action>
    — **Why:** <rationale>
    — **Done when:** <checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>
```

Parse out, per step: `action`, `why`, `done_when`, `consumers`.

**Read the Dependency & Consumer Map first.** Use the built-in `Read` tool to open the PLAN file and review its `## Dependency & Consumer Map` section so execution order and blast radius are known up front. A step whose `consumers` are non-trivial requires its consumers to be surfaced to the executor (and, where applicable, verified post-change) before the step's target is mutated.

### Step 3: Analyze Current State

Determine which phase to work on:

```bash
# Find first incomplete phase — awk tracks the most recent ### Phase header
# (robust to 4-line atomic steps; the old -A 10 window missed the 4th+ step)
CURRENT_PHASE=$(awk '/^### Phase/{phase=$0} /^- \[ \]/{print phase; exit}' "$PLAN_FILE")

# Find first incomplete atomic step
NEXT_STEP=$(grep "^- \[ \]" "$PLAN_FILE" | head -1)

echo "Current phase: $CURRENT_PHASE"
echo "Next step: $NEXT_STEP"
```

### Step 4: Execute Tasks

Work through steps systematically:

**Strategy**:
1. **Surface consumers first** — before touching a step's target, use the `Read` tool to review its `Consumers affected` line and the Dependency & Consumer Map. Do not mutate a target whose consumers have not been surfaced.
2. Group related steps (e.g., all tests together)
3. Delegate to specialized subagents when appropriate:
   - Testing steps → `testing-subagent`
   - Refactoring steps → `code-review-subagent`
   - Code review steps → `code-review-subagent`
   - Build/deploy steps → Parent agent
4. Execute simple steps directly
5. **Verify the `Done when` signal passes** before marking a step `[x]` — a step is complete only when its objective completion check is satisfied, not when the code "looks done".

**Example delegation logic**:
```markdown
If task involves:
- "test" or "spec" → testing-subagent
- "refactor" or "DRY" → code-review-subagent
- "review" or "clean" → code-review-subagent
- "document" → documentation-subagent
- "build" or "deploy" → Handle directly
```

### Step 5: Auto-Update After Each Phase

After completing a phase, automatically invoke `plan-updater`:

```markdown
After Phase X completes:

1. Check if phase tasks are complete
2. Invoke plan-updater skill
   - This will update checkboxes
   - Commit progress with semantic message
3. Confirm update applied
4. Move to next phase
```

**Automatic triggers**:
- All tasks in phase marked complete
- Acceptance criteria for phase met
- Tests pass for phase deliverables

### Step 6: Final Validation

When all phases complete:

```bash
# Verify all acceptance criteria met
ACCEPTANCE_CRITERIA=$(grep "## Acceptance Criteria" -A 20 "$PLAN_FILE" | grep "^\- \[ \]")

if [ -z "$ACCEPTANCE_CRITERIA" ]; then
  echo "All acceptance criteria met!"
  echo "Invoking final plan-updater..."
  # plan-updater skill
else
  echo "Remaining acceptance criteria:"
  echo "$ACCEPTANCE_CRITERIA"
fi
```

### Step 7: Progress Reporting

Provide status updates during execution:

```markdown
## Plan Execution Status

**Branch**: GIT-123
**PLAN**: PLANS/PLAN-GIT-123.md

### Phase Progress
- [x] Phase 1: <name> (atomic steps complete)
- [x] Phase 2: <name> (atomic steps complete)
- [ ] Phase 3: <name> ← Currently here
- [ ] Phase 4: <name>
- [ ] Phase 5: <name>

### Recent Progress
- Completed Phase 2 implementation
- Updated PLAN with progress (commit: abc1234)
- Starting Phase 3 testing

### Next Steps
1. Execute Phase 3 tasks
2. Auto-invoke plan-updater after completion
3. Proceed to Phase 4
```

## PLAN File Structure

I expect PLAN files to follow this structure:

```markdown
# Plan: Ticket Title

## Ticket Reference
- Platform: GitHub/JIRA
- ID: TICKET-ID

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## Dependency & Consumer Map

| Node | Depends on | Consumers | Change risk |
|------|-----------|-----------|-------------|
| file/module | — | caller-A | low/med/high |

## Implementation Phases

### Phase 1: <name>
- [ ] **1.1** <atomic action>
    — **Why:** <rationale>
    — **Done when:** <checkable signal>
    — **Consumers affected:** <consumers or "none">

### Phase 2: <name>
- [ ] **2.1** <atomic action>
    — **Why:** <rationale>
    — **Done when:** <checkable signal>
    — **Consumers affected:** <consumers or "none">
```

## Delegation Strategy

When executing plan, delegate appropriately:

| Task Type | Delegate To | Reason |
|-----------|-------------|---------|
| Test generation | `testing-subagent` | Specialized test frameworks |
| Refactoring | `code-review-subagent` | SOLID/clean code expertise |
| Code review | `code-review-subagent` | Comprehensive quality analysis |
| Documentation | `documentation-subagent` | Industry-standard docs |
| Build/deploy | Parent agent | Requires full bash access |
| Simple implementation | Direct handle | Straightforward changes |

**Delegation pattern**:
```markdown
1. Identify task type
2. Select appropriate subagent
3. Spawn subagent with task description
4. Wait for completion
5. Verify results
6. Mark task complete in PLAN
```

## Automatic Update Triggers

I invoke `plan-updater` automatically when:

1. **Phase completion**: All phase tasks marked complete
2. **Milestone reached**: Significant deliverable finished
3. **Before PR**: If PR workflow starts
4. **User request**: "update plan" or "sync plan"

**Update process**:
```markdown
Auto-update flow:
1. Detect phase complete
2. Invoke plan-updater skill
3. Skill updates checkboxes
4. Skill commits: docs(plan): update PLAN-GIT-123.md
5. Confirm commit applied
6. Continue execution
```

## Error Handling

### PLAN File Not Found

```bash
if [ ! -f "$PLAN_FILE" ]; then
  echo "No PLAN file found for current branch: $BRANCH_NAME"
  echo "No PLAN file? Author one via `worktree-pipeline-skill` §PLAN Authoring (or /run-worktree-pipeline)."
  exit 1
fi
```

### Phase Execution Fails

```bash
# If task execution fails:
1. Log error with context
2. Ask user for guidance
3. Mark task as blocked in PLAN
4. Continue with other tasks if possible
5. Provide summary for manual fix
```

### Plan-updater Fails

```bash
# If plan-updater skill fails:
1. Try manual update
2. Commit PLAN manually
3. Warn user about sync gap
4. Continue execution
```

## Best Practices

### Phase Execution Order

1. **Follow PLAN order**: Don't skip ahead
2. **Complete phase before moving**: Ensure all tasks done
3. **Verify acceptance**: Check criteria after each phase
4. **Update progress**: Auto-invoke plan-updater

### Task Completion Criteria

A step is complete only when its **`Done when`** signal passes. Concretely:
- The step's stated `Done when` check is objectively satisfied
- Code changes committed
- Tests pass (if applicable)
- Documentation updated (if needed)
- Review done (if required)
- Any `Consumers affected` that could break were checked post-change

### When to Stop

Stop execution if:
- **Blocker encountered**: Task cannot be completed
- **User intervention needed**: Requires human decision
- **Plan complete**: All phases and criteria done
- **User requests pause**: "stop plan" or "pause"

## Example Usage

### User says "Implement the plan"

```markdown
User: Implement the plan

Agent: Found PLAN: PLANS/PLAN-GIT-123.md

**Plan Status**:
- 2 of 5 phases complete
- 8 of 20 tasks complete

**Next**: Phase 3 - Testing

Starting Phase 3 execution...

[Executes testing tasks]
[Invokes plan-updater automatically]
[Commits: docs(plan): update PLAN-GIT-123.md with Phase 3 progress]

Phase 3 complete! Updated PLAN with progress.
Next: Phase 4 - <next phase name>
```

### User says "Continue with the plan"

```markdown
User: Continue with the plan

Agent: Found PLAN: PLANS/PLAN-GIT-123.md

**Current Phase**: Phase 3 - Testing
**Next Task**: - [ ] Write unit tests for new functionality

[Executes task]
[Invokes plan-updater automatically]
[Commits: docs(plan): update PLAN-GIT-123.md]

Task complete! Next task in Phase 3...
```

### User says "What's the plan status?"

```markdown
User: What's the plan status?

Agent: **PLAN Execution Status**

**Branch**: GIT-123
**PLAN**: PLANS/PLAN-GIT-123.md

### Phase Progress
- [x] Phase 1: <name> (100%)
- [x] Phase 2: <name> (100%)
- [ ] Phase 3: <name> (40%)
- [ ] Phase 4: <name> (0%)
- [ ] Phase 5: <name> (0%)

### Acceptance Criteria
- [x] Users can register with email/password
- [x] Users can login and receive JWT token
- [ ] Protected routes validate JWT ← Pending
- [ ] 24h token expiry works ← Pending

### Last Update
- Commit: abc1234 docs(plan): update PLAN-GIT-123.md
- Time: 2024-01-25 14:30

### Next Steps
1. Complete Phase 3 remaining atomic steps
2. Meet remaining acceptance criteria
3. Execute Phase 4 atomic steps
```

## Integration with Planning Workflows

This skill integrates with:

| Workflow | Integration Point |
|-----------|------------------|
| worktree-pipeline-skill | Authors the PLANs this skill executes (§PLAN Authoring) |
| pr-workflow-subagent | Provides final status before PR creation |
| plan-updater | Auto-invoked for progress tracking |

## References

- `worktree-pipeline-skill` - PLAN authoring (adopt/generate/atomicity-gate) inside the ticket-to-PR pipeline; `- `ticket-creation-skill` - Creates the GitHub/JIRA tickets
- `plan-updater` - Updates PLAN.md files with progress
- `git-semantic-commits` - Commit message formatting
- `testing-subagent` - Test generation and execution
- `repo-ops-specialist-subagent` - Git repository operations (release workflows, branch protection, labels)

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

### Auto-detection
If invoked on an iterative task, prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". Cache answer for session.

### Skill-specific patterns

**Bounded-by-default.** Plans default to `Iterations: N` (where N = number of phases in the plan). Hard cap 100 iterations. **Stuck detection:** 3 consecutive phase failures → pivot to alternate approach; 5 → escalate to user. See `stuck-detection.md`.

### Citations
- `autoresearch-core-skill/references/stuck-detection.md`

### Imperative gating
When `AUTORESEARCH_PROTOCOL` is unset, this section is descriptive only. Default behavior is documented in all sections above.
