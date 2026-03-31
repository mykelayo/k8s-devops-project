# Cloud-Native DevOps Platform on Kubernetes

## Project Overview
A DevOps pipeline demonstrating GitOps, Infrastructure as Code, and cloud-native observability.

## Architecture
[GitHub] → [GitHub Actions CI] → [Container Registry] → [Argo CD] → [EKS Cluster]
                                                                           ↓
[Developer] ← [Monitoring Stack] ← [Application] ← [Ingress Controller]
                (Prometheus/Grafana/Loki)

## Prerequisites
- AWS Account (Free Tier)
- Terraform v1.5+
- kubectl v1.29+
- GitHub Account
- Docker Desktop

## Quick Start
### 1. Infrastructure Setup
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve