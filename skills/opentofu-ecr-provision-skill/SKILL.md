---
name: opentofu-ecr-provision-skill
description: Provision AWS Elastic Container Registry (ECR) repositories with GitHub OIDC integration following BETEKK standards
license: Apache-2.0
compatibility: opencode
category: OpenTofu
---

# OpenTofu ECR Provision (BETEKK standard)

Provision ECR repositories + GitHub-Actions OIDC IAM roles per BETEKK standards. Reference implementation: `ecr/betekk_probe_engine_main/`.

## When to use me

New ECR repo for container images; GitHub Actions CI/CD → ECR (OIDC, no long-lived keys); migrating repos to BETEKK patterns.

## Prerequisites (house chain)

**Complete `opentofu-provider-setup-skill` first** — AWS auth + S3 state backend live there.

## BETEKK standards (the deltas that matter)

- **Pins**: `hashicorp/aws ~> 5.0`; `required_version ~> 1.8`
- **Variables**: `environment` (dev/uat/prod), `project_prefix` — BETEKK naming conventions throughout
- **ECR**: lifecycle policy (expire untagged images), image scanning on push, immutability per repo policy
- **GitHub OIDC**: IAM role with OIDC trust policy scoped to the repo (condition on `repo` claim: `org/repo:ref:refs/heads/main`), pull-through permissions split from push; OIDC provider created once per account
- **Structure**: reusable modules for ECR + IAM; state in S3 with locking

## Learnings

### ecr-lowercase-naming

**Problem**: ECR names allow only `[a-z0-9_-]`; BETEKK `name_prefix` uses `upper()` (e.g. `"BETEKK"`), which ECR rejects.
**Solution**: derive a lowercase local — `locals { ecr_prefix = lower(var.name_prefix) }` — and build repo names from it. Applies wherever IAM-role naming (uppercase-tolerant) and ECR naming (lowercase-only) share a prefix.

> Removed 2026-09: full HCL listings (variables/ECR/OIDC-role/backend blocks), step-by-step provisioning walkthroughs, Common Issues triage — kept the BETEKK deltas, pins, OIDC trust scoping, and the lowercase learning.
