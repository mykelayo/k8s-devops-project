.PHONY: help \
        tf-init tf-plan tf-apply tf-destroy \
        health-check run-tests \
        logs-backend logs-frontend \
        port-forward-grafana port-forward-argocd \
        port-forward-backend port-forward-frontend \
        get-all

help:
	@echo ""
	@echo "Infrastructure"
	@echo "  make tf-init      terraform init"
	@echo "  make tf-plan      terraform plan (export TF_VAR_* secrets first)"
	@echo "  make tf-apply     terraform apply"
	@echo "  make tf-destroy   full teardown via cleanup.sh"
	@echo ""
	@echo "Local dev"
	@echo "  make run-tests    run backend tests + docker builds locally"
	@echo "  make health-check check pod status and ArgoCD sync state"
	@echo ""
	@echo "Logs"
	@echo "  make logs-backend          tail backend pod logs"
	@echo "  make logs-frontend         tail frontend pod logs"
	@echo ""
	@echo "Observability"
	@echo "  make port-forward-grafana  localhost:3000"
	@echo "  make port-forward-argocd   localhost:8085"
	@echo "  make port-forward-backend  localhost:5000"
	@echo "  make port-forward-frontend localhost:8080"
	@echo "  make get-all               list all resources across namespaces"
	@echo ""
	@echo "Deployments are fully automated."
	@echo "push code → CI builds + updates kustomization.yaml → ArgoCD syncs cluster."
	@echo ""

# Infrastructure

tf-init:
	cd terraform && terraform init

tf-plan:
	@echo "Export TF_VAR_github_token, TF_VAR_argocd_admin_password_bcrypt,"
	@echo "TF_VAR_argocd_webhook_secret, TF_VAR_grafana_admin_password,"
	@echo "and TF_VAR_admin_role_arn before running this."
	cd terraform && terraform plan

tf-apply:
	@echo "Step 1: provisioning  ArgoCD, monitoring..."
	cd terraform && terraform apply \
        -target=module.argocd.kubernetes_namespace_v1.argocd \
        -target=module.argocd.helm_release.argocd \
        -target=module.argocd.kubernetes_secret_v1.argocd_repo \
		-auto-approve
	@echo "Step 2: provisioning remaining resources..."
	cd terraform && terraform apply -auto-approve

tf-destroy:
	@chmod +x scripts/cleanup.sh
	@./scripts/cleanup.sh

# Kubeconfig update context

update-context:
	aws eks update-kubeconfig --region us-east-1 --name k8s-devops-project

# Local dev

run-tests:
	@chmod +x scripts/run-tests.sh
	@./scripts/run-tests.sh

health-check:
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh

# Logs

logs-backend:
	kubectl logs -f -n devops-app deployment/backend

logs-frontend:
	kubectl logs -f -n devops-app deployment/frontend

# Port forwards

port-forward-grafana:
	kubectl port-forward -n monitoring service/kube-prometheus-stack-grafana 3000:80

port-forward-argocd:
	kubectl port-forward -n argocd service/argocd-server 8085:80

port-forward-backend:
	kubectl port-forward -n devops-app service/backend 5000:5000

port-forward-frontend:
	kubectl port-forward -n devops-app service/frontend 8080:80

# Observability

get-all:
	@echo "Application (devops-app)..."
	@kubectl get all -n devops-app
	@echo ""
	@echo "Monitoring..."
	@kubectl get all -n monitoring
	@echo ""
	@echo "ArgoCD..."
	@kubectl get all -n argocd
	@echo ""
	@echo "ArgoCD Application status..."
	@kubectl get application -n argocd \
	  -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status