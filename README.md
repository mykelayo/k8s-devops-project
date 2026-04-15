K8s DevOps project that deploys a full-stack web application on AWS EKS using GitOps principles. Infrastructure is provisioned with Terraform, deployments are managed by Argo CD, and the entire pipeline from code push to running cluster is automated.

---

## Stack

| Layer | Tool |
|---|---|
| Cloud | AWS (EKS, ECR, VPC, IAM) |
| Infrastructure as Code | Terraform |
| Containerization | Docker |
| Container Orchestration | Kubernetes |
| Manifest Management | Kustomize |
| CI | GitHub Actions |
| GitOps | Argo CD |
| Observability | Prometheus + Grafana + Loki + Promtail |

---

## How It Works

The project follows a GitOps model, the Git repository is the single source of truth for both infrastructure and application state. No manual `kubectl apply` or `helm install` commands are needed after the initial `terraform apply`.

```
Developer pushes to main
        │
        ▼
GitHub Actions
  ├── Lint + test backend code
  ├── Scan Dockerfile for misconfigurations
  ├── Scan Python dependencies for CVEs
  ├── Validate Kustomize overlays
  ├── Build and push images to ECR (tagged with commit SHA)
  └── Scan built images for CVEs
        │
        ▼
CI commits updated image tags to kustomization.yaml
        │
        ▼
Argo CD detects the change in Git
        │
        ▼
Argo CD syncs the cluster, rolling update with zero downtime
        │
        ▼
Prometheus scrapes metrics to Grafana dashboards
Loki + Promtail aggregate logs from all pods
```

---

## Project Structure

```
.
├── app/
│   ├── backend/               # Python Flask API
│   │   ├── main.py            # API endpoints
│   │   ├── requirements.txt
│   │   ├── Dockerfile
│   │   └── tests/
│   ├── frontend/              # Static HTML/CSS/JS served by nginx
│   │   ├── src/
│   │   ├── nginx.conf
│   │   └── Dockerfile
│   └── docker-compose.yml     # Local development
│
├── kubernetes/
│   ├── base/                  # Base manifests shared across environments
│   │   ├── deployment-backend.yaml
│   │   ├── deployment-frontend.yaml
│   │   ├── service-backend.yaml
│   │   ├── service-frontend.yaml
│   │   ├── ingress.yaml
│   │   ├── configmap.yaml
│   │   ├── hpa.yaml
│   │   ├── pdb.yaml
│   │   ├── networkpolicies.yaml
│   │   └── kustomization.yaml
│   ├── overlays/
│   │   ├── dev/               # Dev patches — replica counts, debug log level
│   │   └── prod/              # Prod patches — higher replicas, info log level
│   └── monitoring/            # ServiceMonitor, PrometheusRules, Grafana dashboards
│
├── terraform/
│   ├── main.tf                # Root module — wires everything together
│   ├── provider.tf            # AWS, Kubernetes, Helm providers
│   ├── outputs.tf
│   └── modules/
│       ├── networking/        # VPC, public/private subnets, NAT gateways
│       ├── eks/               # EKS cluster, managed node group, Load Balancer Controller
│       ├── ecr/               # ECR repositories for backend and frontend
│       ├── argocd/            # Argo CD install + Application resources
│       └── monitoring/        # kube-prometheus-stack + Loki stack via Helm
│
├── scripts/
│   ├── health-check.sh        # Check pod status and Argo CD sync state
│   ├── run-tests.sh           # Run backend tests and Docker builds locally
│   └── cleanup.sh             # Pre-destroy cleanup then terraform destroy
│
├── .github/workflows/
│   └── ci.yml                 # Full CI pipeline
│
└── Makefile                   # All commands in one place
```

---

## Prerequisites

Make sure the following tools are installed and configured before you begin.

| Tool | Purpose |
|---|---|
| AWS CLI | Authenticate with AWS |
| Terraform >= 1.7 | Provision infrastructure |
| kubectl | Interact with the cluster |
| Docker | Build images locally |
| Helm | Required by Terraform providers |
| Kustomize | Validate overlays locally |

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/mykelayo/k8s-devops-project.git
cd k8s-devops-project
```

### 2. Configure GitHub Actions secrets and variables

In your GitHub repository settings, add the following:

**Secrets** (`Settings → Secrets and variables → Actions → Secrets`):

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key for CI |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key for CI |

**Variables** (`Settings → Secrets and variables → Actions → Variables`):

| Variable | Description |
|---|---|
| `ECR_BACKEND_NAME` | ECR repository name for the backend |
| `ECR_FRONTEND_NAME` | ECR repository name for the frontend |

### 3. Export Terraform variables

```bash
export TF_VAR_github_token=...                    # Fine-grained GitHub PAT (repo read access)
export TF_VAR_argocd_admin_password_bcrypt=...    # bcrypt hash of your chosen ArgoCD password
export TF_VAR_argocd_webhook_secret=...           # Shared secret for GitHub → ArgoCD webhook
export TF_VAR_grafana_admin_password=...          # Grafana admin password
export TF_VAR_admin_role_arn=...                  # IAM ARN to grant cluster admin access
```

To generate a bcrypt hash for the ArgoCD password:
```bash
htpasswd -nbBC 10 "" your-password | tr -d ':\n' | sed 's/$2y/$2a/'
```

### 4. Provision infrastructure

```bash
make tf-init
make tf-apply
```

This provisions the VPC, EKS cluster, ECR repositories, installs Argo CD and the monitoring stack via Helm, and registers the ArgoCD Application pointing at `kubernetes/overlays/dev`. The full apply takes approximately 30-45 minutes.

### 5. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name k8s-devops-project
```

### 6. Verify everything is running

```bash
make health-check
make get-all
```

From this point on, every push to `main` triggers the CI pipeline and Argo CD handles deploying to the cluster automatically.

---

## Local Development

Run the full stack locally with Docker Compose:

```bash
cd app
docker compose up
```

- Frontend: http://localhost:8080
- Backend API: http://localhost:5000

Run backend tests locally:

```bash
make run-tests
```

---

## Observability

All observability tooling is provisioned automatically by Terraform. Access the UIs via port forwarding:

```bash
make port-forward-grafana   # Grafana    → http://localhost:3000
make port-forward-argocd    # Argo CD    → http://localhost:8085
```

Retrieve the Grafana admin password:

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d
```

**What's monitored:**
- Pod status and replica counts across all namespaces
- Backend API request rate and error rate
- CPU and memory usage per pod
- Logs from all pods via Loki + Promtail, queryable in Grafana

---

## Environments

| Environment | Overlay | Replicas (backend/frontend) | Log Level |
|---|---|---|---|
| dev | `kubernetes/overlays/dev` | 2 / 2 | DEBUG |
| prod | `kubernetes/overlays/prod` | 5 / 3 | INFO |

CI deploys to `dev` automatically on every push to `main`. Promoting to `prod` requires pointing the ArgoCD Application at `kubernetes/overlays/prod` or creating a second Application for prod.

---

## Teardown

```bash
export PROJECT_NAME=k8s-devops-project
make tf-destroy
```

The cleanup script handles the correct teardown order, deletes the Argo CD Application first while the controller is still running, then uninstalls Helm releases, removes namespaces, and finally runs `terraform destroy` to tear down all AWS infrastructure.

> EKS worker nodes and NAT gateways incur AWS costs. Run teardown promptly when the cluster is no longer needed.

---

## Make Reference

```bash
# Infrastructure
make tf-init          # initialise Terraform
make tf-plan          # preview infrastructure changes
make tf-apply         # provision or update infrastructure
make tf-destroy       # full teardown

# Local dev
make run-tests        # backend tests + docker builds
make health-check     # pod status and Argo CD sync state

# Logs
make logs-backend     # tail backend pod logs
make logs-frontend    # tail frontend pod logs

# Port forwards
make port-forward-grafana    # localhost:3000
make port-forward-argocd     # localhost:8085
make port-forward-backend    # localhost:5000
make port-forward-frontend   # localhost:8080

# Observability
make get-all          # list all resources across namespaces
```