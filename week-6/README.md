# Week 6, GitHub Actions and Observability

## What this does
- A GitHub Actions workflow (`.github/workflows/opentofu-checks.yml`) that runs `tofu fmt -check`, `tofu init`, and `tofu validate` on pull requests that change `week-5/`.
- Prometheus installed with Helm on the local Kubernetes cluster, plus `pq.sh`, a small script that runs PromQL queries.

## Requirements
- Helm
- The Week 5 stack running on Kubernetes
- `gh` signed in with the `workflow` scope to push workflow files

## Install Prometheus

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  --version 29.35.0 \
  --namespace monitoring \
  --create-namespace \
  --values week-6/prometheus-values.yaml
```

## Ask it a question

```bash
kubectl port-forward --namespace monitoring service/prometheus-server 9090:80
./week-6/pq.sh 'up'
```

Run the port-forward in its own terminal and the script in another.

## Remove it

```bash
helm uninstall prometheus --namespace monitoring
```

## Known limitation

Prometheus keeps its data on temporary storage, so restarting its pod erases the history. Prometheus has no login, so keep the port-forward bound to your local machine.
