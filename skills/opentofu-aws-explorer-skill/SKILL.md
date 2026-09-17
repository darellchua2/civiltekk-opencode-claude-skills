---
name: opentofu-aws-explorer-skill
description: Explore and manage AWS cloud infrastructure resources using OpenTofu/Terraform
license: Apache-2.0
compatibility: opencode
category: OpenTofu
---

# OpenTofu AWS Explorer

## What I do

Manage AWS infrastructure as code with the AWS provider for OpenTofu/Terraform: compute (EC2/Lambda/ECS), networking (VPC/subnets/SGs), storage (S3/EBS/EFS), databases (RDS/DynamoDB/ElastiCache), security (IAM/KMS/WAF).

## When to use me

Provisioning or restructuring AWS resources as code; multi-tier architectures; IAM/networking hardening.

## Prerequisites (house chain)

**Complete `opentofu-provider-setup-skill` first** — provider authentication and state backend live there. OpenTofu/Terraform interchangeable (OpenTofu is provider-compatible).

## House conventions

- **Provider pin**: `hashicorp/aws ~> 5.0.0`; docs at registry.terraform.io/providers/hashicorp/aws/latest/docs (authoritative, version-matched)
- **Workflow**: `tofu init` → `tofu plan` → review → `tofu apply` → verify with `tofu state list` / console
- **Well-Architected reference**: docs.aws.amazon.com/wellarchitected

## Learnings

### lambda-function-url-with-cname

**Problem**: Route53 `ALIAS` (A-alias) records do NOT support Lambda Function URL targets (alias targets are ALBs/CloudFront/API Gateway only; Lambda URLs have no hosted zone).
**Solution**: Use a plain `CNAME` record (`records = [aws_lambda_function_url.api.function_url]`). If you need ALIAS semantics, put CloudFront or API Gateway in front of the Lambda.

**Next**: `opentofu-kubernetes-explorer-skill` (cluster resources).

> Removed 2026-09: per-resource HCL recipes (VPC/EC2/S3/RDS/IAM/ECS walkthroughs), Best Practices lists, Common Issues triage, full examples, Tips — provider schema knowledge the model has; kept the pin, the prerequisite chain, and the Route53/Lambda-URL gotcha.
