# Week 7: Continuous Delivery from Git

## Overview

This lab implements a pull-based continuous delivery workflow using
GitHub Actions, OpenTofu, Helm, and Kubernetes. The deployment script
checks GitHub for new commits and deploys only after the deployment
gate succeeds.

## Repository Structure

- `.github/workflows/deploy-gate.yml` — validates OpenTofu and renders
  the Prometheus Helm chart.
- `week-5/` — OpenTofu Kubernetes resources.
- `week-6/prometheus-values.yaml` — Prometheus Helm configuration.
- `week-7/deploy.sh` — deployment script with safety checks.

## Deployment Gate

The GitHub Actions deployment gate runs for pull requests targeting
`main` and pushes to `main` when relevant Week 5, Week 6, or workflow
files change.

The gate performs two jobs:

1. **OpenTofu format and validate:** checks formatting, initializes
   OpenTofu without a backend, and validates the configuration.
2. **Render Prometheus chart:** renders the Prometheus Helm chart and
   checks that Kubernetes manifests were generated.

Changes are reviewed through pull requests before being merged.

## Deployment Script

Run the deployment script from the repository root:

```bash
./week-7/deploy.sh
```

The script:

1. Acquires a lock to avoid concurrent deployments.
2. Fetches the latest commit from `origin/main`.
3. Checks whether that commit has already been deployed.
4. Confirms the deployment gate passed for the exact commit.
5. Checks cluster availability and repository state.
6. Applies the OpenTofu configuration.
7. Upgrades Prometheus using Helm.
8. Records the deployed commit in `~/.deployed-commit`.

The script includes checks for deployment failures, uncommitted tracked
changes, and branches other than `main`. It uses a directory lock
compatible with macOS.

## Verification Commands

Check Kubernetes deployments and pods:

```bash
kubectl get deployments
kubectl get pods
```

Check the Prometheus release and configured values:

```bash
helm status prometheus -n monitoring
helm get values prometheus -n monitoring
```

Check the last recorded deployed commit:

```bash
cat ~/.deployed-commit
```

Check OpenTofu formatting and configuration:

```bash
cd week-5
tofu fmt -check -diff
tofu init -backend=false -input=false
tofu validate
cd ..
```

## Lab Changes and Rollback

The scaling test changed the web deployment from one replica to three
and Prometheus retention from two days to three days.

The changes were reviewed and merged through pull request #8. The
rollback restored one web replica and two days of Prometheus retention
through pull request #9.

After the rollback was merged, the deployment script confirmed the
deployment gate passed and successfully applied the restored settings.
The final deployment was recorded at commit `b54c7f5`.

## Test Results

- OpenTofu format and validation checks passed in GitHub Actions.
- Prometheus chart rendering passed in GitHub Actions.
- The scaling configuration was deployed and verified with three
  available web replicas and three-day Prometheus retention.
- A local formatting-error test confirmed that `tofu fmt -check -diff`
  detects incorrectly formatted OpenTofu code.
- The rollback deployment completed successfully.

## Notes

Prometheus persistence is disabled in this lab configuration, so
Prometheus data can be lost if its pod is terminated or restarted.
This setup is intended for lab use, not production data retention.
