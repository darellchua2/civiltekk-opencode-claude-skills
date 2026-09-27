# Route `plan-apply` — provisioning workflow, lifecycle, state

Route values for `civiltekk-opentofu-skill` route `plan-apply` (method lives
in the host `SKILL.md`). Assumes `first-time-setup` outputs exist
(§Route chain). `tofu` CLI commands need bash (git-bash/WSL on Windows).

## What I do

IaC development workflow with OpenTofu: provisioning, lifecycle
(create/modify/replace/delete), state management and drift, dependency
ordering, safe plan→apply discipline.

## When to use me

Creating/updating infrastructure; pre-apply planning; state troubleshooting;
safe update/rollback procedures.

## Workflow (canonical commands)

`tofu init` → `tofu fmt` → `tofu validate` → `tofu plan -out=tfplan` →
review → `tofu apply tfplan` → `tofu output` / `tofu show`. Update:
`tofu plan -out=tfplan -refresh=true` → apply. Destroy:
`tofu plan -destroy` → `tofu destroy`.

## House rules

- **Plan file discipline**: always `plan -out` then `apply tfplan` — NEVER
  bare `tofu apply` (it re-plans against drifted state). Review the plan
  output before applying; unknown-value warnings are investigated, not
  ignored.
- **Lifecycle**: rely on `lifecycle { create_before_destroy }` for
  replacement-sensitive resources; `prevent_destroy` on stateful resources
  (databases, buckets with data); explicit `depends_on` only when the
  dependency is invisible to the graph.
- **State**: remote backend with locking (mandatory for teams); `tofu state
  list`/`show`/`mv` for surgical fixes; drift = `plan -refresh=true` diff,
  reconcile by import or code change — never `apply` over unexplained
  drift. Never edit state by hand.
- **Imports**: `tofu import` for adopting existing resources; verify with
  plan showing no diff before the next apply.

## CI/CD anti-patterns

### `gha-artifact-name-mismatch`

Plan-then-apply split across GHA jobs: if `upload-artifact` and
`download-artifact` names don't match exactly, the apply job downloads an
empty artifact and applies nothing (or fails confusingly). Use one
consistent name including `${{ github.sha }}` and pin both action versions.

### `no-rollback-on-deploy`

Deploying a new Lambda container image without capturing the previous URI
leaves a failed smoke test un-recoverable automatically. Capture previous
image (`aws lambda get-function --query 'Code.ImageUri'`) before
`update-function-code`, smoke-test after `wait function-updated`, and
restore the previous URI on failure.
