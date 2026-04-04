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
Update K8s manifests in repo
    │
    ▼
Argo CD detects change ──► Syncs to EKS cluster
    │
    ▼
Prometheus scrapes metrics ──► Grafana dashboards
Loki aggregates logs
```

## Prerequisites

AWS CLI, Terraform, kubectl, Docker, Helm, Kustomize. 

## Quick Start

```bash
git clone https://github.com/mykelayo/k8s-devops-project.git
cd k8s-devops-project

# 1. Provision EKS cluster
cd terraform && terraform init && terraform apply -auto-approve

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name k8s-devops-project

# 3. Deploy app, monitoring, and Argo CD
make setup-cluster

# 4. Deploy application
make deploy-dev
```

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

## Common Commands

```bash
make deploy-dev            # Deploy to dev
make deploy-prod           # Deploy to prod
make health-check          # Run health checks
make logs-backend          # Tail backend logs
make logs-frontend         # Tail frontend logs
make port-forward-grafana  # Grafana → localhost:3000
make port-forward-argocd   # Argo CD UI → localhost:8080
make get-all               # View all resources across namespaces
make cleanup               # Tear down all resources
```

## CI/CD Flow

1. Push to `main` triggers GitHub Actions
2. Workflow builds Docker images and pushes to ECR
3. Workflow updates image tags in Kubernetes manifests
4. Argo CD detects the manifest change and syncs to the cluster

## Monitoring

Prometheus and Grafana are installed via the `kube-prometheus-stack` Helm chart. Loki handles log aggregation. Access Grafana at `localhost:3000` via `make port-forward-grafana`.

Default credentials are printed during `make setup-cluster`.

## Teardown

```bash
make cleanup
cd terraform && terraform destroy -auto-approve
```

> Heads up: EKS and EC2 worker nodes incur AWS costs. Run `terraform destroy` promptly when done.