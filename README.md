Here's the updated README:

```markdown
# k8s-devops-project

Kubernetes deployment on AWS EKS with GitOps, CI/CD, and full observability.

## Stack

| Layer | Tool |
|---|---|
| Infrastructure | Terraform (EKS, VPC, ECR, IAM) |
| Container Orchestration | Kubernetes + Kustomize (dev/prod overlays) |
| CI/CD | GitHub Actions |
| GitOps | Argo CD |
| Observability | Prometheus + Grafana + Loki |
| Registry | AWS ECR |

## Architecture

```
GitHub Push
    │
    ▼
GitHub Actions ──► Build & Push image to ECR
    │
    ▼
Update image tag in kustomization.yaml
    │
    ▼
Argo CD detects change ──► Syncs to EKS cluster
    │
    ▼
Prometheus scrapes metrics ──► Grafana dashboards
Loki aggregates logs
```

## Prerequisites

AWS CLI, Terraform, kubectl, Docker, Helm, Kustomize

## Quick Start

```bash
git clone https://github.com/mykelayo/k8s-devops-project.git
cd k8s-devops-project

# Export required secrets
export TF_VAR_github_token=...
export TF_VAR_argocd_admin_password_bcrypt=...
export TF_VAR_argocd_webhook_secret=...
export TF_VAR_admin_role_arn=arn:aws:iam::<account-id>:user/<your-user>

# Provision infrastructure
make tf-apply

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name k8s-devops-project
```

After that, deployments are fully automated — push code and ArgoCD handles the rest.

## Project Structure

```
.
├── app/
│   ├── frontend/          # HTML/CSS/JS frontend
│   └── backend/           # Python Flask API
├── kubernetes/
│   ├── base/              # Base Kubernetes manifests
│   └── overlays/
│       ├── dev/           # Dev environment patches
│       └── prod/          # Prod environment patches
├── terraform/             # EKS cluster, VPC, ECR, IAM
├── scripts/               # setup, health-check, cleanup, tests
├── .github/workflows/     # GitHub Actions CI/CD pipeline
└── Makefile
```

## CI/CD Flow

1. Push to `main` triggers GitHub Actions
2. Builds Docker images and pushes to ECR
3. Updates image tag in `kustomization.yaml`
4. Argo CD detects the change and syncs to the cluster

No manual deploy targets exist — the pipeline handles everything.

## Make Commands

```bash
# Infrastructure
make tf-init      # terraform init
make tf-plan      # terraform plan
make tf-apply     # terraform apply
make tf-destroy   # full teardown via cleanup.sh

# Local dev
make run-tests    # backend tests + docker builds locally
make health-check # pod status and ArgoCD sync state

# Logs
make logs-backend
make logs-frontend

# Port forwards
make port-forward-grafana   # localhost:3000
make port-forward-argocd    # localhost:8080
make port-forward-backend   # localhost:5000
make port-forward-frontend  # localhost:8080

# Observability
make get-all      # all resources across namespaces
```

## Monitoring

Prometheus and Grafana via `kube-prometheus-stack`. Loki for log aggregation.

```bash
make port-forward-grafana   # Grafana → localhost:3000
make port-forward-argocd    # Argo CD UI → localhost:8080
```

## Teardown

```bash
make tf-destroy
```

> EKS and EC2 worker nodes incur AWS costs. Run teardown promptly when done.
```