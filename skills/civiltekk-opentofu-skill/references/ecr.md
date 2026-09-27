# Route `ecr-provision` — ECR + GitHub OIDC (BETEKK standard)

Route values for `civiltekk-opentofu-skill` route `ecr-provision` (method
lives in the host `SKILL.md`). Assumes `first-time-setup` outputs exist —
AWS auth + S3 state backend (§Route chain). `tofu` CLI commands need bash
(git-bash/WSL on Windows).

Provision ECR repositories + GitHub-Actions OIDC IAM roles per BETEKK
standards. Reference implementation: `ecr/betekk_probe_engine_main/`.

## When to use me

New ECR repo for container images; GitHub Actions CI/CD → ECR (OIDC, no
long-lived keys); migrating repos to BETEKK patterns.

## BETEKK standards (the deltas that matter)

- **Pins**: `hashicorp/aws ~> 5.0`; `required_version ~> 1.8`
- **Variables**: `environment` (dev/uat/prod), `project_prefix` — BETEKK
  naming conventions throughout
- **ECR**: lifecycle policy (expire untagged images), image scanning on
  push, immutability per repo policy
- **GitHub OIDC**: IAM role with OIDC trust policy scoped to the repo
  (condition on `repo` claim: `org/repo:ref:refs/heads/main`),
  pull-through permissions split from push; OIDC provider created once per
  account
- **Structure**: reusable modules for ECR + IAM; state in S3 with locking

## Learning

### ecr-lowercase-naming

**Problem**: ECR names allow only `[a-z0-9_-]`; BETEKK `name_prefix` uses
`upper()` (e.g. `"BETEKK"`), which ECR rejects.

**Solution**: derive a lowercase local — `locals { ecr_prefix =
lower(var.name_prefix) }` — and build repo names from it. Applies wherever
IAM-role naming (uppercase-tolerant) and ECR naming (lowercase-only) share
a prefix.
