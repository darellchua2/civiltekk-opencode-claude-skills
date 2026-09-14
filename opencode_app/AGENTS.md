# OpenCode Docker Standalone Configuration

This file contains instructions for OpenCode running in Docker standalone mode.

## Environment

This is a **containerized OpenCode instance** running as a web endpoint. Key differences from user-space mode:

- No local filesystem access beyond `/app` and mounted volumes
- MCP servers that require local GUI apps are disabled
- API keys are injected at runtime via `docker-entrypoint.sh`
- All agents and skills are loaded from `.opencode/` within the container

## Task Delegation Order

1. **Agents/Subagents (First Priority)** - Delegate to specialized subagents
2. **Skills (Second Priority)** - Load skills when no matching subagent exists
3. **Direct Handling (Last Resort)** - Handle directly only when necessary

## Available Agents

Agents are loaded from `.opencode/agents/` — in the container image these are COPY'd from the repository root `agents/` directory at build time; in a local checkout the same path is a sanctioned symlink bridge to the root content.

## Available Skills

Skills are loaded from `.opencode/skills/` — in the container image these are COPY'd from the repository root `skills/` directory at build time; in a local checkout the same path is a sanctioned symlink bridge to the root content.

## Branch Workflow Setup Signal

When any subagent returns `NEEDS_GIT_BRANCH_SETUP: true` in its Return Contract, the primary agent must handle it as follows:

1. **Load** `git-branch-workflow-setup-skill` (extract-then-delegate pattern)
2. **Perform detection** per the skill's §Detection Logic — check for existing release tooling and skip markers
3. **If detection triggers:** use the `question` tool per the skill's §Question Tool Spec to prompt the user (or apply the §Non-Interactive Fallback → Skip)
4. **If the user accepts:** delegate execution to `repo-ops-specialist-subagent` via the Task tool, passing the typed payload from the skill's §Delegation Spec
5. **If the user skips:** write the skip marker (`.opencode/branch-workflow-skipped`) to prevent re-prompting

> **Docker note:** In non-interactive contexts (no active web session, CI), apply the non-interactive fallback (default to Skip). Never block the flow.

## Docker-Specific Notes

- Port: 4096 (internal), mapped to 4097 by default
- Health check: `GET /api/health`
- Auth keys: Injected from environment variables via entrypoint
- Data persistence: `/home/opencode/.local/share/opencode` (named volume)

## CodeGraph MCP Server

[CodeGraph](https://github.com/colbymchenry/codegraph) is a pre-indexed code knowledge graph MCP server. It builds a local SQLite database of symbol relationships and call graphs for instant codebase queries.

> **CodeGraph is a TOOLS-ONLY MCP server.** It exposes tools (`codegraph_explore`, `codegraph_search`, `codegraph_files`, `codegraph_callers`, `codegraph_callees`, `codegraph_impact`, `codegraph_node`, `codegraph_context`, `codegraph_status`) — **not** MCP resources. To "find" anything in the indexed codebase, call these tools directly.
>
> **The `codegraph_*` tools ARE the codegraph interface** — always start a code lookup with `codegraph_status`, then `codegraph_explore` / `codegraph_search` / `codegraph_files`. CodeGraph is tools-only and publishes no resources, so any `codegraph://...` URI is a hallucination: do not call `read_mcp_resource`, `list_mcp_resources`, or `list_mcp_resource_templates` against it (they error). (MCP resource reads are runtime-denied via `permission.read: { "*": "allow", "mcp:*": "deny" }` in opencode.json — opencode maps the MCP-resource tools to the `read` permission internally, so tool-name frontmatter keys like `read_mcp_resource: deny` are silently ignored. **Due to an upstream opencode visibility bug (`session/tools.ts`), `read_mcp_resource` and `list_mcp_resources` remain in the model's tool list even though they are runtime-denied — do NOT attempt to call them; they will waste a step and return `DeniedError`.** If you need to explore code, use the `codegraph_*` tools or the built-in `Read`/`glob`/`grep`.)

### Per-Project Setup

```bash
codegraph init -i
```

This creates a `.codegraph/` directory with an indexed database. Add `.codegraph/` to `.gitignore`.

### MCP Tool Routing

| Capability | Primary | Fallback | Reason |
|---|---|---|---|
| Codebase exploration | `codegraph_explore` / `codegraph_context` | grep/glob chains | Structured graph results, fewer tool calls |
| Symbol lookup | `codegraph_search` / `codegraph_node` | grep | Instant name-based lookup |
| Call tracing | `codegraph_callers` / `callees` | grep imports | Graph-based, transitive |
| Impact analysis | `codegraph_impact` | Manual file search | Traces dependency chains |
| File structure | `codegraph_files` | glob | Indexed, faster |

### Subagent Integration

The following subagents have CodeGraph instructions in their `.md` files and will use CodeGraph automatically when `.codegraph/` exists:

| Subagent | Key CodeGraph Tools |
|---|---|
| `explorer-subagent` | `codegraph_explore`, `codegraph_context`, `codegraph_search`, `codegraph_files` |
| `code-review-subagent` | `codegraph_callers`/`callees` (diff-scope direct callers), `codegraph_search` |
| `architecture-review-subagent` | `codegraph_callers`/`callees`, `codegraph_explore`, `codegraph_impact` |
| `technical-design-specialist-subagent` | `codegraph_explore` (architecture exploration), `codegraph_impact` (design blast-radius validation) |
| `testing-subagent` | `codegraph_files`, `codegraph_search` |
| `linting-subagent` | `codegraph_files`, `codegraph_search` |
| `error-resolver-subagent` | `codegraph_node`, `codegraph_callers`, `codegraph_search` |
| `uiux-reviewer-subagent` | `codegraph_impact` (change radius before suggesting structural changes), `codegraph_search` (component lookup for design-system consistency) |
| `autoresearch-code-subagent` | `codegraph_files`, `codegraph_search` |
| `autoresearch-research-subagent` | `codegraph_search` |

### Built-In Subagent CodeGraph Injection

When spawning built-in `explore` or `general` subagents via the Task tool, if a `.codegraph/` directory exists in the mounted project, include this guidance in the Task prompt:

"CodeGraph is available in this project. Prioritize these tools:
- `codegraph_explore` for multi-symbol exploration
- `codegraph_search` for symbol lookups
- `codegraph_files` for file structure
- `codegraph_context` for task-relevant code context
- `codegraph_callers`/`codegraph_callees` for dependency tracing
- `codegraph_impact` for change radius analysis
Fall back to grep/glob/read only if CodeGraph tools return no results."

This ensures built-in subagents get the same CodeGraph benefits as custom subagents, even when tasks are handled directly without delegating to a specialized subagent.
