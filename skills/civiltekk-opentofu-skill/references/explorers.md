# Route `explore` — platform explorers (AWS · Kubernetes · Neon · Keycloak)

Route values for `civiltekk-opentofu-skill` route `explore` (method lives in
the host `SKILL.md`). Every section assumes `first-time-setup` outputs exist
(§Route chain) and any change follows `references/workflow.md` discipline.
OpenTofu/Terraform are interchangeable (OpenTofu is provider-compatible).
`tofu` CLI commands need bash (git-bash/WSL on Windows).

## AWS

Manage AWS infrastructure as code with the AWS provider: compute
(EC2/Lambda/ECS), networking (VPC/subnets/SGs), storage (S3/EBS/EFS),
databases (RDS/DynamoDB/ElastiCache), security (IAM/KMS/WAF).

**When**: provisioning or restructuring AWS resources as code; multi-tier
architectures; IAM/networking hardening.

**Conventions**:
- **Provider pin**: `hashicorp/aws ~> 5.0.0`; docs at
  registry.terraform.io/providers/hashicorp/aws/latest/docs
  (authoritative, version-matched)
- **Workflow**: `tofu init` → `tofu plan` → review → `tofu apply` → verify
  with `tofu state list` / console
- **Well-Architected reference**: docs.aws.amazon.com/wellarchitected

**Learning — `lambda-function-url-with-cname`**: Route53 `ALIAS` (A-alias)
records do NOT support Lambda Function URL targets (alias targets are
ALBs/CloudFront/API Gateway only; Lambda URLs have no hosted zone). Use a
plain `CNAME` record (`records =
[aws_lambda_function_url.api.function_url]`). If you need ALIAS semantics,
put CloudFront or API Gateway in front of the Lambda.

## Kubernetes

Manage Kubernetes resources as code with the Kubernetes/Helm providers:
namespaces, config, deployments, services, ingress, storage, Helm releases.

**When**: Kubernetes resource management as code (pods, deployments,
services, configmaps, secrets); ingress controllers, load balancers,
persistent storage, storage classes; Helm chart deployment via OpenTofu.

**Version pins** (`versions.tf`) — current house pins, update deliberately:

```hcl
terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.24.0" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.11.0" }
  }
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "terraform-state"
    key            = "kubernetes/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Provider connection** (`provider.tf`) — pick one method:
1. Default kubeconfig (`~/.kube/config`) — local dev, single cluster
2. `config_path = var.kubeconfig_path`
3. `config_context = "my-cluster-context"`
4. EKS direct: `host`/`cluster_ca_certificate`/`token` from
   `data.aws_eks_cluster` + `data.aws_eks_cluster_auth`

**Resource conventions**: every resource gets labels incl. `managedBy =
"terraform"`; namespaces per concern (app, monitoring, ingress); secrets
NEVER in ConfigMaps (Kubernetes Secrets only); RollingUpdate with
`max_unavailable = 0`; resources always declare requests+limits;
liveness+readiness probes on every deployment; Helm chart versions pinned;
TLS terminates at ingress (cert-manager).

**Workflow**: `tofu init` → `tofu plan` → review → `tofu apply` → verify
with `kubectl get events --sort-by='.lastTimestamp'` / `kubectl describe`
when things pend.

**Provider docs** (authoritative, version-matched):
- Kubernetes: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
- Helm: https://registry.terraform.io/providers/hashicorp/helm/latest/docs

## Neon

Manage Neon serverless Postgres as code: projects, branches, endpoints,
databases, roles — Neon's branch-based workflow (copy-on-write dev branches
off main) is the core model.

**When**: provisioning Neon projects; database branching for dev/preview
environments; managing endpoints and connection strings programmatically.

**Conventions**:
- **Provider pin**: `kislerdm/neon ~> 0.13.0`; `required_version >= 1.14`
  (older OpenTofu → provider version conflicts; that conflict is the #1
  Common Issue). Neon API key via provider config (env `NEON_API_KEY`).
- **Model**: `neon_project` → `neon_branch` (main is created with the
  project; dev branches are children) → `neon_endpoint` (compute per
  branch; autosuspend controls compute-hour cost) → `neon_database` /
  `neon_role`
- **File split**: `project.tf`, `branch.tf`, `endpoint.tf`; dev/preview
  branches suspended when idle
- **Docs**: registry.terraform.io/providers/kislerdm/neon/latest/docs

## Keycloak

Manage Keycloak IAM as code: realms, clients, client scopes, realm roles,
users/groups, identity providers, authentication flows.

**When**: provisioning or auditing Keycloak configuration as code;
SSO/social-login wiring; realm lifecycle.

**Conventions**:
- **Provider pin**: `keycloak/keycloak ~> 5.0.0`; `required_version >= 1.0`.
  Docs: registry.terraform.io/providers/keycloak/keycloak/latest/docs
- **Production auth**: service-account credentials, never admin;
  least-privilege grants; secrets via env/secret manager; HTTPS always
- **File split**: `realm.tf`, `clients.tf`, `users.tf` (one concern per
  file); dev/staging/prod in separate state files or workspaces
- **Client rules**: PKCE for SPAs; minimal scopes; redirect URIs restricted
  to trusted origins; configure logout (front/backchannel)
- **Workflow**: `tofu init` → `tofu plan` → review → `tofu apply`
