## **Main Documentation Files**

```
# Kubernetes DevOps Project - Documentation

## Project Overview
This documentation provides a complete step-by-step guide to deploy a production-ready Kubernetes application with GitOps, monitoring, and CI/CD on AWS EKS.

## Table of Contents
1. Prerequisites - Tools and accounts needed
2. Infrastructure Setup - Terraform for EKS
3. Application Deployment - Deploy to Kubernetes
4. CI/CD Pipeline - GitHub Actions setup
5. Monitoring Stack - Prometheus + Grafana + Loki
6. GitOps with Argo CD - Automated deployments
7. Troubleshooting - Common issues
8. Cleanup - Remove all resources

## Quick Start
```bash
# Clone the repository
git clone https://github.com/mykelayo/k8s-devops-project.git
cd k8s-devops-project

# Setup all infrastructure and applications
make install-all

# Access the application
make frontend
```

## Architecture
![Architecture](screenshots/architecture.png)

## Project Contents
- Infrastructure as Code with Terraform
- Kubernetes deployments and services
- CI/CD with GitHub Actions
- GitOps with Argo CD
- Monitoring with Prometheus/Grafana
- Log aggregation with Loki
- AWS EKS management
```

---

### **`01-prerequisites`**

```markdown
# Prerequisites

## Required Accounts
- [AWS Account](https://aws.amazon.com/free/) (Free tier works)
- [GitHub Account](https://github.com/)

## Required Tools

### Install AWS CLI
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip

# Verify
aws --version
```

### Install Terraform
```bash
# macOS
brew install terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify
terraform --version
```

### Install kubectl
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

### Install Docker
```bash
# macOS
brew install docker

# Linux
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Verify
docker --version
```

### Install Helm
```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

### Install Kustomize
```bash
# macOS
brew install kustomize

# Linux
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Verify
kustomize version
```

## Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter region: us-east-1
# Output format: json
```

## Verify All Tools
```bash
./scripts/verify-tools.sh
```

---

### **`02-infrastructure-setup`**

```markdown
# Infrastructure Setup with Terraform

## Step 1: Initialize Terraform
```bash
cd terraform
terraform init
```

## Step 2: Review and Apply
```bash
# Review what will be created
terraform plan

# Apply the infrastructure
terraform apply -auto-approve
```
## Step 3: Configure kubectl
```bash
# Update kubeconfig for EKS
aws eks update-kubeconfig --region us-east-1 --name devops-project-cluster

# Verify cluster access
kubectl get nodes
```
## Step 4: Verify Infrastructure
```bash
# Check all resources
kubectl get all -A

# Get cluster info
kubectl cluster-info
```

## Infrastructure Created
- VPC with public/private subnets
- EKS Cluster (control plane)
- 2 Worker nodes (t3.medium)
- ECR repositories
- IAM roles and policies

## Estimated Time: 10-15 minutes
## Cost: Within AWS Free Tier
```

---

### **`docs/03-application-deployment.md`**

```markdown
# Application Deployment

## Step 1: Build and Test Locally
```bash
# Test with Docker Compose
cd app
docker compose up

# Access the app
# Frontend: http://localhost:8080
# Backend API: http://localhost:5000/api/info
```
![Local App](screenshots/local-app.png)

## Step 2: Push to ECR
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_urls | cut -d'/' -f1)

# Build and push backend
cd app/backend
docker build -t backend:latest .
docker tag backend:latest $(terraform output -raw ecr_repository_urls_backend)
docker push $(terraform output -raw ecr_repository_urls_backend)

# Build and push frontend
cd ../frontend
docker build -t frontend:latest .
docker tag frontend:latest $(terraform output -raw ecr_repository_urls_frontend)
docker push $(terraform output -raw ecr_repository_urls_frontend)
```

## Step 3: Deploy to Kubernetes
```bash
# Deploy using kustomize
kubectl apply -k kubernetes/overlays/dev

# Check deployment status
kubectl get pods -n devops-app -w
```

## Step 4: Access the Application
```bash
# Port forward to local machine
kubectl port-forward -n devops-app svc/frontend-service 8080:80

# Open browser to http://localhost:8080
```
![Application UI](screenshots/application-ui.png)

## Verify Deployment
```bash
# Check all resources
kubectl get all -n devops-app

# View logs
kubectl logs -f -n devops-app deployment/backend
kubectl logs -f -n devops-app deployment/frontend
```
```

---

### **`docs/06-gitops-argocd.md`**

```markdown
# GitOps with Argo CD

## What is GitOps?
GitOps is a way to manage Kubernetes clusters using Git as the single source of truth. Argo CD watches your GitHub repository and automatically syncs changes to your cluster.

## Installation
```bash
# Run the Argo CD installation script
./scripts/install-argocd.sh

# Or use make
make install-argocd
```

## Access Argo CD UI
```bash
# Port forward to local machine
make argocd

# Open browser to https://localhost:8080
# Username: admin
# Password: (from script output)
```
![Argo CD Login](screenshots/argocd-login.png)

## Argo CD Dashboard
After login, you'll see your application:
![Argo CD UI](screenshots/argocd-ui.png)

## How GitOps Works
1. **Developer pushes code to GitHub**
2. **GitHub Actions builds and pushes to ECR**
3. **GitHub Actions updates Kubernetes manifests**
4. **Argo CD detects changes in GitHub**
5. **Argo CD automatically syncs to cluster**

## Manual Sync (if auto-sync is off)
```bash
# Sync via CLI
argocd app sync devops-app

# Or click "Sync" in UI
```

## Rollback with Argo CD
```bash
# View history
argocd app history devops-app

# Rollback to previous version
argocd app rollback devops-app <revision-id>
```
![Argo CD Rollback](screenshots/argocd-rollback.png)

## Verify GitOps is Working
```bash
# Make a change to manifests
echo "# test" >> kubernetes/overlays/dev/kustomization.yaml

# Commit and push
git add .
git commit -m "Test GitOps"
git push

# Watch Argo CD sync automatically
kubectl get applications -n argocd devops-app -w
```
```

---

### **`docs/08-cleanup.md`**

```markdown
# Cleanup Resources

## Warning: This will delete ALL resources and incur costs if not done properly.

## Step 1: Delete Kubernetes Resources
```bash
# Delete Argo CD applications
kubectl delete application devops-app -n argocd

# Delete namespaces
kubectl delete namespace devops-app
kubectl delete namespace monitoring
kubectl delete namespace argocd

# Uninstall Helm charts
helm uninstall kube-prometheus-stack -n monitoring
helm uninstall loki -n monitoring
```

## Step 2: Destroy Terraform Infrastructure
```bash
cd terraform

# List resources that will be destroyed
terraform plan -destroy

# Destroy everything
terraform destroy -auto-approve
```

## Step 3: Clean Local Resources
```bash
# Remove Docker images
docker system prune -a

# Remove Terraform state files
rm -rf terraform/.terraform
rm -rf terraform/*.tfstate*
```

## Step 4: One-Command Cleanup
```bash
# Use the cleanup script
make cleanup

# Or run directly
./scripts/cleanup.sh
```

## Verify Cleanup
```bash
# Check for remaining resources
aws eks list-clusters
aws ecr describe-repositories
kubectl get namespaces
```

## Cost Check
After cleanup, verify no resources are running:
```bash
# Check AWS billing
aws ce get-cost-and-usage --time-period Start=2026-01-01,End=2026-04-31
```

## **Quick Start Execution**

Now you can run everything with one command:

```bash
# Make the script executable
chmod +x scripts/run-full-project.sh

# Run the complete project
./scripts/run-full-project.sh
```

Or run step by step:

```bash
# Step 1: Deploy infrastructure
cd terraform && terraform init && terraform apply -auto-approve

# Step 2: Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name devops-project-cluster

# Step 3: Build and push images
cd app && docker compose build
# Push to ECR (use the push commands from earlier)

# Step 4: Deploy to Kubernetes
kubectl apply -k kubernetes/overlays/dev

# Step 5: Install monitoring
make install-monitoring

# Step 6: Install Argo CD
make install-argocd
```