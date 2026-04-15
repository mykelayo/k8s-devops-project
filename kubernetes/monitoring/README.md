# Monitoring Stack Installation

## Prerequisites
- Helm installed
- kubectl configured
- minikube running

## Add Helm Repositories
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

## Install Prometheus & Grafana Stack
```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin \
  --set grafana.service.type=ClusterIP \
  --set prometheus.prometheusSpec.retention=7d \
  --set grafana.sidecar.datasources.defaultDatasourceEnabled=true \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```

## Install Loki for Logging
```bash
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=5Gi
```

## Verify Installation
```bash
kubectl --namespace monitoring get pods -l "release=kube-prometheus-stack"
kubectl --namespace monitoring get pods -l "release=loki"

helm list -n monitoring
```

## Access UIs
```bash
# Grafana (admin / admin)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

## Grafana - Get Admin Password
```bash
kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

## Loki Data Source in Grafana
Once logged into Grafana, add Loki as a data source:
- URL: `http://loki:3100`