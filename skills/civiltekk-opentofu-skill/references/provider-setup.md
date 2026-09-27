# Route `first-time-setup` — providers, auth, state backends

Route values for `civiltekk-opentofu-skill` route `first-time-setup`
(method lives in the host `SKILL.md` §Route chain). This route is the
**chain root** — nothing precedes it; every other route assumes its outputs
(provider auth + remote state backend) exist.

Prerequisites: OpenTofu CLI (`tofu version`; install from
https://opentofu.org/docs/intro/install/), a cloud-provider account, basic
HCL knowledge. `tofu` CLI commands need bash (git-bash/WSL on Windows).

## Provider pin table (`versions.tf`)

| Provider | Source | Pin |
|----------|--------|-----|
| AWS | `hashicorp/aws` | `~> 5.0` |
| Azure | `hashicorp/azurerm` | `~> 3.0` |
| GCP | `hashicorp/google` | `~> 5.0` |

```hcl
terraform {
  required_providers {
    aws     = { source = "hashicorp/aws",     version = "~> 5.0" }
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
    google  = { source = "hashicorp/google",  version = "~> 5.0" }
  }
  # backend block: see State-backend selection below
}
```

Pin provider versions (`~>` for minor updates) to avoid breaking changes;
never hardcode credentials — env vars or credential stores only.

## Per-provider auth essentials

### AWS — `hashicorp/aws`

```hcl
provider "aws" {
  region = "us-east-1"
  # Auth: (1) env vars AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY,
  #       (2) shared credentials file ~/.aws/credentials,
  #       (3) assume role:
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  }
}
```

Verify: `aws sts get-caller-identity`. Docs:
registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication.
Credential-vaulting: `aws-vault exec my-profile -- tofu plan`.

### Azure — `hashicorp/azurerm`

```hcl
provider "azurerm" {
  features {}
  # Auth: (1) env vars ARM_CLIENT_ID/ARM_CLIENT_SECRET/ARM_TENANT_ID/ARM_SUBSCRIPTION_ID,
  #       (2) Managed Identity, (3) Service Principal with certificate
}
```

Docs: registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure.

### GCP — `hashicorp/google`

```hcl
provider "google" {
  project = "my-project-id"
  region  = "us-central1"
  # Auth: (1) Application Default Credentials,
  #       (2) service-account key (GOOGLE_CREDENTIALS env var),
  #       (3) Workload Identity
}
```

Docs: registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started.

## State-backend selection

Pick by platform; every backend must be encrypted, with locking where the
platform supports it:

| Platform | Backend | Locking |
|----------|---------|---------|
| AWS | `s3` | DynamoDB table |
| Azure | `azurerm` | blob lease |
| GCP | `gcs` | native |

```hcl
# AWS S3 + DynamoDB locking
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Azure Storage
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-storage-rg"
    storage_account_name = "terraformstate123"
    container_name       = "terraform-state"
    key                  = "prod.terraform.tfstate"
  }
}

# GCS
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "prod"
  }
}
```

Backend rules: separate state per environment (dev/staging/prod), enable
versioning on the state storage, force-unlock only with caution
(`tofu force-unlock <LOCK_ID>`). Initialize and verify:

```bash
tofu init            # pulls providers + configures the backend
tofu init -upgrade   # after bumping a pin
tofu plan -out=tfplan  # proves the provider connection works
```

Common first-time failures: `Failed to query available provider packages` →
`tofu init -upgrade` + check `versions.tf` source/version; `inconsistent
lock file` → `rm -rf .terraform/ .terraform.lock.hcl` + `tofu init
-upgrade`; lock acquisition errors → IAM on the state bucket.

## Learning

### local-terraform-state-production

**Problem**: local state (`terraform.tfstate` on disk) in production means
no locking, no backup, no concurrency safety — two engineers applying
simultaneously corrupt state.

**Solution**: remote backend with locking (S3 + DynamoDB, Azure Storage, or
GCS — blocks above). Migration is downtime-free (the state file moves,
resources stay): `tofu init -migrate-state`.

**When**: any environment shared by more than one person, or any
production/mission-critical workload.

## Reference docs

- OpenTofu: https://opentofu.org/docs/
- Terraform Registry: https://registry.terraform.io/
- Backends:
  https://www.terraform.io/docs/language/settings/backends/index.html
