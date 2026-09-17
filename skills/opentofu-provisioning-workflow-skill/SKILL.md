---
name: opentofu-provisioning-workflow-skill
description: Infrastructure as Code development patterns, resource lifecycle management, and state management workflows with OpenTofu
license: Apache-2.0
compatibility: opencode
category: OpenTofu
---

## What I do

IaC development workflow with OpenTofu: provisioning, lifecycle (create/modify/replace/delete), state management and drift, dependency ordering, safe plan→apply discipline.

## When to use me

Creating/updating infrastructure; pre-apply planning; state troubleshooting; safe update/rollback procedures.

## Prerequisites (house chain)

**Complete `opentofu-provider-setup-skill` first** — provider auth + remote state backend (S3/Azure/GCS) live there. Domain skills: `opentofu-aws-explorer-skill`, `opentofu-kubernetes-explorer-skill`, `opentofu-keycloak-explorer-skill`, `opentofu-neon-explorer-skill`, `opentofu-ecr-provision-skill`.

## Workflow (canonical commands)

`tofu init` → `tofu fmt` → `tofu validate` → `tofu plan -out=tfplan` → review → `tofu apply tfplan` → `tofu output` / `tofu show`. Update: `tofu plan -out=tfplan -refresh=true` → apply. Destroy: `tofu plan -destroy` → `tofu destroy`.

## House rules

- **Plan file discipline**: always `plan -out` then `apply tfplan` — NEVER bare `tofu apply` (it re-plans against drifted state). Review the plan output before applying; unknown-value warnings are investigated, not ignored.
- **Lifecycle**: rely on `lifecycle { create_before_destroy }` for replacement-sensitive resources; `prevent_destroy` on stateful resources (databases, buckets with data); explicit `depends_on` only when the dependency is invisible to the graph.
- **State**: remote backend with locking (mandatory for teams); `tofu state list`/`show`/`mv` for surgical fixes; drift = `plan -refresh=true` diff, reconcile by import or code change — never `apply` over unexplained drift. Never edit state by hand.
- **Imports**: `tofu import` for adopting existing resources; verify with plan showing no diff before the next apply.

## CI/CD anti-patterns

### `gha-artifact-name-mismatch`
Plan-then-apply split across GHA jobs: if `upload-artifact` and `download-artifact` names don't match exactly, the apply job downloads an empty artifact and applies nothing (or fails confusingly). Use one consistent name including `${{ github.sha }}` and pin both action versions.

### `no-rollback-on-deploy`
Deploying a new Lambda container image without capturing the previous URI leaves a failed smoke test un-recoverable automatically. Capture previous image (`aws lambda get-function --query 'Code.ImageUri'`) before `update-function-code`, smoke-test after `wait function-updated`, and restore the previous URI on failure.

> Removed 2026-09: step-by-step HCL provisioning walkthroughs (EC2/VPC/RDS recipes), Best Practices essays, Common Issues triage, advanced pattern catalog, Tips lists — provider-schema knowledge covered by the explorer skills; kept the workflow contract, state/lifecycle rules, and the two CI/CD anti-patterns.
