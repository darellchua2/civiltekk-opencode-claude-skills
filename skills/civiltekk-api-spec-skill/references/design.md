# Author route (values)

Design APIs: REST conventions, OpenAPI generation (FastAPI auto / Next
manual), GraphQL schemas, versioning, pagination, rate limiting, error
envelopes. Standard practice applied with house judgment — the write-time
rules live in the host's §Authoring Quality Gate; the house patterns and
defaults below are this route's values.

## House patterns

### `multi-source-response-schema-drift`
When a response is assembled from multiple sources (fast cache/DB path vs slow Temporal-workflow path), adding a field to one path only causes invisible data loss — consumers see the field sometimes, no error anywhere. **Rule:** update ALL paths producing the response and validate output through one shared schema (`normalizeReport()` style zod parse on every return path).

### `schema-output-contract-gap`
A declared `output_schema` next to a handler is a contract: every key in `properties` MUST appear in every return dict from `execute()`, and every `required` key MUST be non-null on every return path. Tests that mock the happy path never catch the lie — it surfaces as downstream `KeyError` or a dropped UI field. **Rule:** add a contract test computing `missing = schema_props - return_keys` (and null-required check), run against EVERY return path including error/404 paths.

### `placeholder-swap-validation`
When request bodies contain file-reference fields (`s3://…`, presigned URLs, `cds://…`), JSON-Schema validation either rejects valid URIs or degrades to accepting any string. **Rule:** swap file-reference values for a stable placeholder BEFORE validation, restore originals in a `finally` block — validates request shape without coupling the schema to every transport scheme.

### `async-api-blocking-poll-pattern`
Long-running operations: accept `202 Accepted` + status resource immediately; client polls the status endpoint (`200` in-progress with progress metadata → `303`/final result on completion) — never hold the request open. Cancel = `DELETE` on the status resource.

## House defaults (terse)

REST: plural nouns, nesting ≤2, collection filters as query params; cursor pagination for large/offset-shifting datasets, offset only for small static ones; one standard error envelope (code/message/details/requestId) across the stack. Versioning: URL major-version for public APIs; rate-limit headers (`X-RateLimit-*` + `Retry-After`) on 429. GraphQL: schema-first, N+1 via DataLoader batching.

> Removed 2026-09 (as api-design-skill): REST naming/status-code walkthroughs, FastAPI/Next OpenAPI generation tutorials, pagination/error-handler code listings, GraphQL schema tutorials, versioning/rate-limiting essays — textbook API knowledge; kept the Authoring Quality Gate verbatim (external anchor), the four house patterns, and the terse defaults.
