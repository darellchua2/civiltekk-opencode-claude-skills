---
name: opentofu-keycloak-explorer-skill
description: Explore and manage Keycloak identity and access management resources using OpenTofu/Terraform
license: Apache-2.0
compatibility: opencode
category: OpenTofu
---

# OpenTofu Keycloak Explorer

## What I do

Manage Keycloak IAM as code: realms, clients, client scopes, realm roles, users/groups, identity providers, authentication flows.

## When to use me

Provisioning or auditing Keycloak configuration as code; SSO/social-login wiring; realm lifecycle.

## Prerequisites (house chain)

**Complete `opentofu-provider-setup-skill` first** — authentication and state backend live there. OpenTofu/Terraform interchangeable.

## House conventions

- **Provider pin**: `keycloak/keycloak ~> 5.0.0`; `required_version >= 1.0`. Docs: registry.terraform.io/providers/keycloak/keycloak/latest/docs
- **Production auth**: service-account credentials, never admin; least-privilege grants; secrets via env/secret manager; HTTPS always
- **File split**: `realm.tf`, `clients.tf`, `users.tf` (one concern per file); dev/staging/prod in separate state files or workspaces
- **Client rules**: PKCE for SPAs; minimal scopes; redirect URIs restricted to trusted origins; configure logout (front/backchannel)
- **Workflow**: `tofu init` → `tofu plan` → review → `tofu apply`

> Removed 2026-09: per-resource HCL walkthroughs (realm/client/role/user/idp/flow recipes), Best Practices essays, Common Issues triage, full examples — provider schema knowledge; kept the pin, the chain, and the client/security rules.
