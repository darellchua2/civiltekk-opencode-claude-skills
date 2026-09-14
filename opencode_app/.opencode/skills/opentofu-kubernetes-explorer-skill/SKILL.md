---
name: opentofu-kubernetes-explorer-skill
description: Explore and manage Kubernetes clusters and resources using OpenTofu/Terraform
license: Apache-2.0
compatibility: opencode
category: OpenTofu
---

# OpenTofu Kubernetes Explorer

## What I do

Manage Kubernetes resources as code with the Kubernetes/Helm providers for OpenTofu: namespaces, config, deployments, services, ingress, storage, Helm releases.

## When to use me

- Kubernetes resource management as code (pods, deployments, services, configmaps, secrets)
- Ingress controllers, load balancers, persistent storage, storage classes
- Helm chart deployment via OpenTofu

## Prerequisites (house chain)

**Complete `opentofu-provider-setup-skill` first** — provider authentication and state backend live there; this skill assumes they're done. OpenTofu/Terraform are interchangeable here (OpenTofu is provider-compatible).

## House conventions

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
4. EKS direct: `host`/`cluster_ca_certificate`/`token` from `data.aws_eks_cluster` + `data.aws_eks_cluster_auth`

**Resource conventions**: every resource gets labels incl. `managedBy = "terraform"`; namespaces per concern (app, monitoring, ingress); secrets NEVER in ConfigMaps (Kubernetes Secrets only); RollingUpdate with `max_unavailable = 0`; resources always declare requests+limits; liveness+readiness probes on every deployment; Helm chart versions pinned; TLS terminates at ingress (cert-manager).

**Workflow**: `tofu init` → `tofu plan` → review → `tofu apply` → verify with `kubectl get events --sort-by='.lastTimestamp'` / `kubectl describe` when things pend.

**Provider docs** (authoritative, version-matched):
- Kubernetes provider: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
- Helm provider: https://registry.terraform.io/providers/hashicorp/helm/latest/docs

> Removed 2026-09: the 15-step HCL-per-resource tutorial (namespace/configmap/secret/deployment/service/ingress/PV/HPA/helm/variables/outputs), kubectl triage recipes, and full examples — the model knows the provider schema; this file keeps the house pins, backend, connection methods, and resource conventions.
