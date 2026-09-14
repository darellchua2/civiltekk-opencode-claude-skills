---
name: opentofu-provisioning-workflow-skill
description: Infrastructure as Code development patterns, resource lifecycle management, and state management workflows with OpenTofu
license: Apache-2.0
compatibility: opencode
category: OpenTofu
---

# OpenTofu Provisioning Workflow

## What I do

I guide you through complete Infrastructure as Code (IaC) development workflows using OpenTofu. I help you:

- **Resource Provisioning**: Create, update, and manage infrastructure resources
- **Lifecycle Management**: Handle resource creation, modification, and deletion
- **State Management**: Maintain and troubleshoot Terraform state
- **Best Practices**: Apply IaC best practices from OpenTofu and Terraform documentation
- **Dependency Management**: Handle resource dependencies and ordering
- **Validation and Planning**: Ensure infrastructure changes are safe and predictable

## When to use me

Use this skill when you need to:
- Create new infrastructure resources (VPCs, EC2, databases, etc.)
- Update existing infrastructure configurations
- Plan and preview infrastructure changes before applying
- Troubleshoot state issues or drift
- Implement infrastructure best practices and patterns
- Manage complex resource dependencies
- Perform safe infrastructure updates and rollbacks

## Prerequisites

- **OpenTofu CLI installed**: Install from https://opentofu.org/docs/intro/install/
- **Provider Configured**: Complete `opentofu-provider-setup` skill first for provider authentication and state backend configuration
- **Provider Authentication**: Valid credentials for your cloud provider
- **Understanding of HCL**: HashiCorp Configuration Language basics
- **State Backend**: Remote state backend configured (S3, Azure Storage, GCS)

## Steps

### Step 1: Define Resources

Create `main.tf` with your infrastructure resources:

```hcl
# Example: AWS EC2 instance
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name        = "WebServer"
    Environment = var.environment
  }

  # User data script
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              EOF
}

# Example: VPC and Subnet
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}
```

### Step 2: Define Variables

Create `variables.tf` for reusability:

```hcl
variable "ami_id" {
  description = "ID of AMI to use for EC2 instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}
```

### Step 3: Define Outputs

Create `outputs.tf` to expose values:

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}
```

### Step 4: Create Terraform Variables File (Optional)

Create `terraform.tfvars` for environment-specific values:

```hcl
# terraform.tfvars
ami_id          = "ami-0c55b159cbfafe1f0"
instance_type   = "t2.micro"
environment     = "dev"
vpc_cidr        = "10.0.0.0/16"
project_name    = "my-project"
availability_zone = "us-east-1a"
```

### Step 5: Initialize and Format

```bash
# Initialize (download providers)
tofu init

# Format code for consistency
tofu fmt

# Validate configuration
tofu validate
```

### Step 6: Plan Changes

```bash
# Show execution plan
tofu plan

# Save plan for review or automation
tofu plan -out=tfplan

# Review plan in detail
tofu show tfplan
```

### Step 7: Apply Changes

```bash
# Apply changes interactively
tofu apply

# Apply saved plan
tofu apply tfplan

# Auto-approve (use with caution in automation)
tofu apply -auto-approve
```

### Step 8: Inspect State

```bash
# List all resources in state
tofu state list

# Show specific resource details
tofu state show aws_instance.web_server

# Show current state as JSON
tofu show -json
```

### Step 9: Update Resources

```bash
# Modify configuration and plan changes
tofu plan -out=tfplan

# Review and apply changes
tofu apply tfplan
```

### Step 10: Destroy Resources

```bash
# Plan destruction
tofu plan -destroy

# Destroy all resources in configuration
tofu destroy

# Destroy specific resources
tofu destroy -target=aws_instance.web_server
```

## Best Practices

### Resource Management

1. **Use Descriptive Names**: Make resource names self-documenting
2. **Tag Everything**: Apply consistent tagging for cost tracking and organization
3. **Use Variables**: Avoid hardcoding values; use variables for flexibility
4. **Separate Environments**: Use workspaces or separate state files for dev/staging/prod
5. **Limit Resource Scope**: Keep configurations focused and modular

### State Management

```bash
# Use remote state backends for team collaboration
# Reference: https://www.terraform.io/docs/language/settings/backends/index.html

# State best practices:
# - Enable encryption
# - Enable versioning
# - Use state locking
# - Regular backups
```

### Dependency Management

```hcl
# Implicit dependencies (reference attributes)
resource "aws_security_group" "web" {
  name = "web-security-group"
  # ...
}

resource "aws_instance" "web" {
  vpc_security_group_ids = [aws_security_group.web.id]
  # Depends implicitly on security group
}

# Explicit dependencies
resource "aws_instance" "db" {
  depends_on = [aws_instance.web]
  # ...
}

# Use for_each and count for multiple resources
resource "aws_instance" "servers" {
  count         = 3
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "Server-${count.index + 1}"
  }
}
```

### Dependency & Consumer Analysis

**Before any `tofu apply`, traverse dependency consumers so no cross-stack change is a surprise.** This is the IaC equivalent of the codebase consumer-traversal gate (CodeGraph does NOT index HCL — use the tools below).

**1. Render the resource DAG:**

```bash
# Full dependency graph (DOT output)
tofu graph

# Render to an image if graphviz is available
tofu graph | dot -Tpng > graph.png
```

**2. Detect replace-triggering changes** — read the plan for destructive operations:

```bash
tofu plan -out=tfplan
# Inspect for any line containing "will be replaced" / "must be replaced" / "forces replacement"
tofu show tfplan | grep -iE 'replace|destroy|force'
```

Each `force-replacement` cascades to every resource that depends on it — enumerate those downstream resources before applying.

**3. Grep cross-stack / cross-module consumers** of any changed resource:

```bash
# Module references (single path — `.` already recurses into modules/)
grep -rnE 'module "' .

# Cross-stack state consumption
grep -rn 'terraform_remote_state' .

# Explicit dependencies
grep -rn 'depends_on' .

# Data sources referencing managed/existing resources
grep -rnE 'data "' .

# Outputs that other stacks consume
grep -rnE 'output "' .

# Refactoring-time stale references (moved/removed/import can dangle consumers)
grep -rnE 'moved \{|removed \{|import \{' .
```

**Gate rule**: do not `apply` until, for every changed resource, you have listed (a) its DAG dependents from `tofu graph`, (b) any `force-replacement` cascade, and (c) its module/remote-state/depends_on/data/output consumers from the greps above.

### Validation and Planning

```bash
# Always run plan before apply
tofu plan -out=tfplan
tofu apply tfplan

# Use targeted plans for specific changes
tofu plan -target=aws_instance.web_server

# Use refresh-only to detect drift
tofu apply -refresh-only
```

### Modularization

```hcl
# Create reusable modules
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# modules/vpc/variables.tf
variable "cidr_block" {
  type = string
}

variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

# Use module in main configuration
module "vpc" {
  source = "./modules/vpc"

  cidr_block = var.vpc_cidr
  name       = var.project_name
  tags       = var.common_tags
}
```

### Data Sources

```hcl
# Use data sources to reference existing resources
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  ami = data.aws_ami.amazon_linux_2.id
  # ...
}
```

### Lifecycle Management

```hcl
resource "aws_instance" "web" {
  # Prevent recreation if tags change
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags,
      user_data
    ]
  }

  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = true
  }
}
```

## Common Issues

### Issue: State File Lock

**Symptom**: Error `Error: Error acquiring the state lock`

**Solution**:
```bash
# Check who has the lock
tofu state pull

# Force unlock if necessary (caution!)
tofu force-unlock <LOCK_ID>

# Reference: https://www.terraform.io/docs/language/state/locking.html
```

### Issue: Resource Already Exists

**Symptom**: Error `Error: Error creating ...: ... already exists`

**Solution**:
```bash
# Import existing resource into state
tofu import aws_instance.web_server i-0123456789abcdef0

# Then remove from configuration if needed
tofu state rm aws_instance.web_server
```

### Issue: Plan Shows Destroy and Create

**Symptom**: Plan wants to destroy and recreate resource instead of updating

**Solution**:
```hcl
# Use create_before_destroy lifecycle
resource "aws_instance" "web" {
  lifecycle {
    create_before_destroy = true
  }
}

# Or ignore changes to certain attributes
lifecycle {
  ignore_changes = [tags]
}
```

### Issue: State Drift

**Symptom**: Actual infrastructure differs from state

**Solution**:
```bash
# Refresh state to detect drift
tofu refresh

# Apply only to sync state (no changes)
tofu apply -refresh-only

# For manual drift, use terraform import
tofu import <resource_type>.<resource_name> <resource_id>
```

### Issue: Dependency Cycle

**Symptom**: Error `Error: Cycle: ...`

**Solution**:
```bash
# Review resource dependencies
tofu graph | dot -Tpng > graph.png

# Use explicit dependencies or refactor configuration
resource "aws_instance" "db" {
  depends_on = [aws_instance.web, aws_security_group.db]
  # ...
}
```

### Issue: Timeout During Apply

**Symptom**: Apply operation hangs or times out

**Solution**:
```bash
# Use timeouts in resource configuration
resource "aws_instance" "web" {
  timeouts {
    create = "10m"
    delete = "15m"
  }
  # ...
}

# Run plan in background
tofu apply -auto-parallelism=4 &
```

## Advanced Patterns

These patterns work with any provider. For provider-specific examples, see the explorer skills:
- AWS: `opentofu-aws-explorer`
- Keycloak: `opentofu-keycloak-explorer`
- Kubernetes: `opentofu-kubernetes-explorer`
- Neon: `opentofu-neon-explorer`

### for_each (Map-Based Multiple Resources)

```hcl
variable "buckets" {
  type = map(object({
    acl           = string
    force_destroy = bool
  }))
  default = {
    logs = { acl = "private", force_destroy = false }
    data = { acl = "private", force_destroy = true }
    www  = { acl = "public-read", force_destroy = false }
  }
}

resource "aws_s3_bucket" "this" {
  for_each     = var.buckets
  bucket       = "${var.project_name}-${each.key}"
  force_destroy = each.value.force_destroy
}
```

### for_each with toset

```hcl
variable "environments" {
  type    = set(string)
  default = ["dev", "staging", "prod"]
}

resource "aws_s3_bucket" "env" {
  for_each = var.environments
  bucket   = "${var.project_name}-${each.value}-state"
}
```

### dynamic Blocks

```hcl
variable "ingress_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    { port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" },
    { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" },
  ]
}

resource "aws_security_group" "web" {
  name = "${var.project_name}-web-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### import Block (Bring Existing Resources Under Management)

```hcl
import {
  to = aws_instance.web_server
  id = "i-0123456789abcdef0"
}

import {
  to = aws_s3_bucket.logs
  id = "my-existing-logs-bucket"
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-existing-logs-bucket"
}
```

### moved Block (Safe Resource Renaming)

```hcl
moved {
  from = aws_instance.web
  to   = aws_instance.web_server
}

moved {
  from = aws_s3_bucket.old_name
  to   = aws_s3_bucket.new_name
}
```

### removed Block (Remove from State Without Destroying)

```hcl
removed {
  from = aws_instance.deprecated_server

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3_bucket.archived_data

  lifecycle {
    destroy = false
  }
}
```

### Provider-Agnostic Module Pattern

```hcl
# modules/compute/main.tf
resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = merge(var.tags, {
    Name = "${var.name}-${count.index + 1}"
  })
}

# modules/compute/variables.tf
variable "instance_count" { type = number }
variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "name" { type = string }
variable "tags" { type = map(string); default = {} }

# modules/compute/outputs.tf
output "instance_ids" {
  value = aws_instance.this[*].id
}

# Usage in main config
module "app_servers" {
  source        = "./modules/compute"
  instance_count = 3
  ami_id        = data.aws_ami.latest.id
  instance_type = var.instance_type
  name          = "${var.project_name}-app"
  tags          = var.common_tags
}
```

## Reference Documentation

- **OpenTofu Documentation**: https://opentofu.org/docs/
- **Terraform Language**: https://www.terraform.io/docs/language/
- **Terraform State**: https://www.terraform.io/docs/language/state/
- **Resource Lifecycle**: https://www.terraform.io/docs/language/meta-arguments/lifecycle.html
- **Data Sources**: https://www.terraform.io/docs/language/data-sources/index.html
- **Modules**: https://www.terraform.io/docs/language/modules/develop/index.html
- **import Block**: https://developer.hashicorp.com/terraform/language/import
- **moved Block**: https://developer.hashicorp.com/terraform/language/modules/develop/refactoring
- **removed Block**: https://developer.hashicorp.com/terraform/language/modules/develop/refactoring

## Workflow Commands

```bash
# Complete provisioning workflow
tofu init           # Initialize
tofu fmt            # Format
tofu validate       # Validate
tofu plan -out=tfplan  # Plan
tofu apply tfplan    # Apply
tofu output         # Show outputs
tofu show           # Show state

# Update workflow
tofu plan -out=tfplan -refresh=true
tofu apply tfplan

# Destroy workflow
tofu plan -destroy
tofu destroy
```

## Tips and Tricks

- **Use tofu fmt**: Auto-format code for consistency
- **Run tofu validate**: Catch syntax errors early
- **Review plans**: Always review plans before applying
- **Use workspaces**: Manage multiple environments
- **Module everything**: Create reusable modules for common patterns
- **Tag resources**: For cost tracking and organization
- **Use data sources**: Reference existing infrastructure
- **Import existing resources**: Bring existing resources under management
- **Use moved/removed blocks**: Safe refactoring without state manipulation
- **State isolation**: Use separate state files for different environments
- **Version control**: Store configuration in Git (but not state files!)

## CI/CD Anti-Patterns

### gha-artifact-name-mismatch

**Problem**: In a GitHub Actions plan-then-apply workflow, if the upload and download artifact names don't match exactly, the apply job silently downloads an empty artifact and applies nothing — or fails with a confusing error.

**Solution**: Use a single consistent artifact name (including environment/branch prefix) and pin the artifact action version.

```yaml
# CORRECT — matching artifact names
jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: tofu plan -out=tfplan
      - uses: actions/upload-artifact@v4
        with:
          name: terraform-plan-${{ github.sha }}
          path: tfplan

  apply:
    needs: plan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: terraform-plan-${{ github.sha }}
      - run: tofu apply tfplan
```

```yaml
# WRONG — name mismatch causes silent failure
# upload:  name: plan-file
# download: name: tfplan  ← won't find it
```

**When**: Any GHA workflow that separates plan and apply into different jobs.

### no-rollback-on-deploy

**Problem**: Deploying a new Lambda container image without capturing the previous image means a failed smoke test leaves the service broken with no way to automatically revert.

**Solution**: Capture the previous image URI before deploying, run a smoke test, and rollback on failure.

```bash
#!/bin/bash
set -euo pipefail

FUNCTION_NAME="my-function"
NEW_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"

PREVIOUS_IMAGE=$(aws lambda get-function \
  --function-name "$FUNCTION_NAME" \
  --query 'Code.ImageUri' \
  --output text)

aws lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --image-uri "$NEW_IMAGE"

aws lambda wait function-updated \
  --function-name "$FUNCTION_NAME"

if smoke_test "$FUNCTION_NAME"; then
  echo "Deploy succeeded"
else
  echo "Smoke test failed — rolling back to $PREVIOUS_IMAGE"
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --image-uri "$PREVIOUS_IMAGE"
  aws lambda wait function-updated \
    --function-name "$FUNCTION_NAME"
  exit 1
fi
```

**When**: Any Lambda deployment pipeline that updates function code/images.

## Next Steps

After mastering provisioning workflows, explore:
- Provider-specific skills: `opentofu-aws-explorer`, `opentofu-kubernetes-explorer`, etc.
- **Terraform Modules**: Create reusable infrastructure components
- **CI/CD Integration**: Automate infrastructure provisioning
- **Infrastructure Testing**: Use tools like terratest for testing
