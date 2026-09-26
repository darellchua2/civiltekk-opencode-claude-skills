## Harness binding — OpenCode

- **Project memory**: before responding, recall LEARNINGS via the `memory` tool (scope: project, query: the review topic) AND read any `LEARNINGS/*.md` surfaced by the autoinject manifest.
- **Delegation syntax**: use the Task tool — `subagent_type="explore"` for codebase scanning, `subagent_type="general"` for parallel review of independent files, `subagent_type="language-reviewer-subagent"` for language-specific deep analysis. When delegating to `explore` for structural analysis, request "use codegraph_explore/codegraph_callers" in the prompt.
