---
name: opentofu-neon-explorer-skill
description: Explore and manage Neon Postgres serverless database resources using OpenTofu/Terraform
license: Apache-2.0
compatibility: opencode
category: OpenTofu
---

# OpenTofu Neon Explorer

## What I do

Manage Neon serverless Postgres as code: projects, branches, endpoints, databases, roles — Neon's branch-based workflow (copy-on-write dev branches off main) is the core model.

## When to use me

Provisioning Neon projects; database branching for dev/preview environments; managing endpoints and connection strings programmatically.

## Prerequisites (house chain)

**Complete `opentofu-provider-setup-skill` first.** Neon API key via provider config (env `NEON_API_KEY`).

## House conventions

- **Provider pin**: `kislerdm/neon ~> 0.13.0`; `required_version >= 1.14` (older OpenTofu → provider version conflicts; that conflict is the #1 Common Issue)
- **Model**: `neon_project` → `neon_branch` (main is created with the project; dev branches are children) → `neon_endpoint` (compute per branch; autosuspend controls compute-hour cost) → `neon_database` / `neon_role`
- **File split**: `project.tf`, `branch.tf`, `endpoint.tf`; dev/preview branches suspended when idle
- **Docs**: registry.terraform.io/providers/kislerdm/neon/latest/docs · `tofu init` → `plan` → `apply`

> Removed 2026-09: per-resource HCL recipes, branching tutorials, Common Issues walkthroughs, full examples — provider schema knowledge; kept the pin, the project→branch→endpoint model, and the version-conflict warning.
