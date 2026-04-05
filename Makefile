.PHONY: help \
        tf-init tf-plan tf-apply tf-destroy \
        health-check run-tests cleanup \
        logs-backend logs-frontend \
        port-forward-grafana port-forward-argocd \
        port-forward-backend port-forward-frontend \
        get-all

# Help 

help:
	@echo ""
	@echo "Infrastructure"
	@echo "  make tf-init      terraform init"
	@echo "  make tf-plan      terraform plan (set TF_VAR_* secrets first)"
	@echo "  make tf-apply     terraform apply"
	@echo "  make tf-destroy   full teardown via cleanup.sh"
	@echo ""
	@echo "Local dev"
	@echo "  make run-tests    run backend tests + docker builds locally"
	@echo "  make health-check check pod status and ArgoCD sync state"
	@echo ""
	@echo "Observability"
	@echo "  make logs-backend          tail backend pod logs"
	@echo "  make logs-frontend         tail frontend pod logs"
	@echo "  make port-forward-grafana  localhost:3000"
	@echo "  make port-forward-argocd   localhost:8080"
	@echo "  make port-forward-backend  localhost:5000"
	@echo "  make port-forward-frontend localhost:8080"
	@echo "  make get-all               list all resources across namespaces"
	@echo ""
	@echo "NOTE: There are no manual deploy targets."
	@echo "Deployments happen automatically:"
	@echo "  push code → CI builds + updates kustomization.yaml → ArgoCD syncs cluster."
	@echo ""

# Infrastructure 

tf-init:
	cd terraform && terraform init

tf-plan:
	@echo "Make sure TF_VAR_github_token, TF_VAR_argocd_admin_password_bcrypt,"
	@echo "and TF_VAR_argocd_webhook_secret are exported before running this."
	cd terraform && terraform plan

tf-apply:
	@echo "First-time apply on a new cluster requires two steps."
	@echo "See terraform/modules/argocd/main.tf for instructions."
	@echo ""
	@echo "Continuing with full apply..."
	cd terraform && terraform apply

tf-destroy:
	@chmod +x scripts/cleanup.sh
	@./scripts/cleanup.sh

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
	kubectl port-forward -n argocd service/argocd-server 8080:80

port-forward-backend:
	kubectl port-forward -n devops-app service/backend-service 5000:5000

port-forward-frontend:
	kubectl port-forward -n devops-app service/frontend-service 8080:80

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
	@kubectl get application k8s-devops-project -n argocd \
	  -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
