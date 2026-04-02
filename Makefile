.PHONY: help setup-cluster deploy-dev deploy-prod cleanup health-check run-tests logs-backend logs-frontend port-forward-grafana port-forward-argocd port-forward-backend port-forward-frontend get-all

help:
	@echo "Available commands:"
	@echo "  make setup-cluster   - Complete cluster setup (monitoring + Argo CD)"
	@echo "  make deploy-dev      - Deploy application to dev"
	@echo "  make deploy-prod     - Deploy application to prod"
	@echo "  make health-check    - Run health checks"
	@echo "  make cleanup         - Clean up all resources"
	@echo "  make run-tests       - Run tests locally"
	@echo "  make logs-backend    - Tail backend logs"
	@echo "  make logs-frontend   - Tail frontend logs"
	@echo "  make port-forward-grafana   - Port forward Grafana"
	@echo "  make port-forward-argocd    - Port forward Argo CD"
	@echo "  make port-forward-backend   - Port forward backend service"
	@echo "  make port-forward-frontend  - Port forward frontend service"
	@echo "  make get-all          - Get all resources in devops-app, monitoring, and argocd namespaces"


setup-cluster:
	@echo "Setting up complete cluster..."
	@chmod +x scripts/setup-cluster.sh
	@./scripts/setup-cluster.sh

deploy-dev:
	@echo "Deploying to development..."
	@cd kubernetes/overlays/dev && kustomize build . | kubectl apply -f -

deploy-prod:
	@echo "Deploying to production..."
	@cd kubernetes/overlays/prod && kustomize build . | kubectl apply -f -

health-check:
	@echo "Running health checks..."
	@chmod +x scripts/health-check.sh
	@./scripts/health-check.sh

cleanup:
	@echo "Starting cleanup..."
	@chmod +x scripts/cleanup.sh
	@./scripts/cleanup.sh

run-tests:
	@echo "Running tests locally..."
	@chmod +x scripts/run-tests.sh
	@./scripts/run-tests.sh

logs-backend:
	@kubectl logs -f -n devops-app deployment/backend

logs-frontend:
	@kubectl logs -f -n devops-app deployment/frontend

port-forward-grafana:
	@kubectl port-forward -n monitoring service/kube-prometheus-stack-grafana 3000:80

port-forward-argocd:
	@kubectl port-forward -n argocd service/argocd-server 8080:443

port-forward-backend:
	@kubectl port-forward -n devops-app service/backend-service 5000:5000

port-forward-frontend:
	@kubectl port-forward -n devops-app service/frontend-service 8080:80

get-all:
	@echo "=== All Resources ==="
	@kubectl get all -n devops-app
	@echo ""
	@echo "=== Monitoring Resources ==="
	@kubectl get all -n monitoring
	@echo ""
	@echo "=== Argo CD Resources ==="
	@kubectl get all -n argocd