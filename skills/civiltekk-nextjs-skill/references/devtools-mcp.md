# Route `runtime-diagnosis` — next-devtools-mcp (values)

Values for `civiltekk-nextjs-skill` route `runtime-diagnosis`. The host
SKILL.md carries the METHOD and the hard availability gate + file-based
fallback; this file carries the config values, tool inventory, and
workflows.

**Reference:** https://nextjs.org/docs/app/guides/mcp

## opencode.json Configuration

Add the `next-devtools` MCP server to your project `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "next-devtools": {
        "type": "local",
        "command": ["npx", "-y", "next-devtools-mcp@latest"],
        "disabled": false
      }
    }
  },
  "permissions": [
    { "action": "next-devtools*", "resource": "*", "effect": "allow" }
  ]
}
```

**Notes:**
- OpenCode uses `opencode.json` with the `mcp` key, NOT `.mcp.json` with `mcpServers`.
- Command is array format `["npx", "-y", "pkg"]`, not separate `command` + `args` fields.
- Both `mcp.servers.next-devtools.disabled: false` AND the `permissions` rule `{ "action": "next-devtools*", "resource": "*", "effect": "allow" }` are required.
- MCP endpoint URL (when dev server runs): `http://localhost:3000/_next/mcp`

## Available MCP Tools

| Tool                    | Description                             | Use Case                                |
| ----------------------- | --------------------------------------- | --------------------------------------- |
| `get_errors`              | Build, runtime, and type errors         | Debug compilation and runtime issues    |
| `get_logs`                | Path to dev log file (browser + server) | Access browser console + server output  |
| `get_page_metadata`       | Metadata about specific pages           | Understand page structure and rendering |
| `get_project_metadata`    | Project structure and configuration     | Analyze project setup                   |
| `get_routes`              | All routes grouped by router type       | Map application routing                 |
| `get_server_action_by_id` | Look up Server Actions by ID            | Debug Server Action references          |

## Tool Reference

### get_errors
Retrieves all current errors from the dev server. Use for: build failures, TypeScript errors, runtime errors, hydration mismatches.

### get_logs
Returns the path to the development log file. Use for: browser console errors, SSR/SSG issues, request/response tracing.

### get_page_metadata
Returns metadata about a specific page — route info, component structure, rendering method. Use for: component hierarchy checks, Server vs Client Component verification, route parameter analysis.

### get_project_metadata
Returns overall project structure, Next.js configuration, and dev server URL. Use for: verify configuration, check Next.js version, confirm dev server status.

### get_routes
Returns all routes grouped by router type (App Router, Pages Router). Use for: route mapping, conflict identification, migration planning.

### get_server_action_by_id
Looks up a Server Action by ID to find source file and function name. Use for: debug Server Action references, trace form submissions, verify 'use server' configuration.

## Workflows

### 1. Initial Project Assessment
1. `get_project_metadata` → understand structure
2. `get_routes` → map all routes
3. `get_errors` → identify existing issues

### 2. Error Diagnosis
1. `get_errors` → retrieve current errors
2. Analyze error types (build/runtime/type)
3. Provide specific guidance
4. Suggest fixes following Next.js best practices

### 3. Route Analysis
1. `get_routes` → all routes
2. Identify patterns and conventions
3. Check App Router vs Pages Router usage
4. Suggest route organization improvements

### 4. Page Debugging
1. `get_page_metadata` for specific pages
2. Analyze component structure and rendering
3. Identify Server vs Client Component usage
4. Suggest optimizations

### 5. Server Action Debugging
1. Get Server Action ID from error or form
2. `get_server_action_by_id` → locate implementation
3. Review code for issues
4. Suggest fixes following best practices

## Common Issues & Solutions

### MCP Server Not Connecting
Symptoms: Tools return connection errors.
Solutions: (1) Ensure dev server running (`npm run dev`); (2) Verify `mcp.servers.next-devtools.disabled: false`; (3) Verify the `permissions` rule `{ "action": "next-devtools*", "resource": "*", "effect": "allow" }`; (4) Confirm Next.js 16+; (5) Confirm `next-devtools-mcp@latest`.

### No Errors Returned
Symptoms: `get_errors` returns empty but errors exist.
Solutions: (1) Ensure errors are in running dev server; (2) Check browser console; (3) Use `get_logs` directly.

### Routes Not Showing
Symptoms: `get_routes` returns incomplete list.
Solutions: (1) Verify pages in correct directories; (2) Check for syntax errors; (3) Verify App Router structure.

### Server Action Not Found
Symptoms: `get_server_action_by_id` returns no results.
Solutions: (1) Verify 'use server' directive; (2) Ensure properly exported; (3) Check for typos in action ID.

## Best Practices Guidance

### Server vs Client Components
Use `get_page_metadata` to verify: `'use client'` on interactive components, Server Components for data fetching, proper boundary placement.

### Route Organization
Use `get_routes` to ensure: logical grouping, proper dynamic segments, consistent naming.

### Error Handling
Use `get_errors` to: identify patterns, fix root causes, implement error boundaries.

### Server Actions
Use `get_server_action_by_id` to: verify `'use server'`, check form integration, ensure error handling.

## Documentation References

- Next.js MCP Guide: https://nextjs.org/docs/app/guides/mcp
- Next.js App Router: https://nextjs.org/docs/app
- Server Components: https://nextjs.org/docs/app/building-your-application/rendering/server-components
- Server Actions: https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations
- Routing: https://nextjs.org/docs/app/building-your-application/routing
