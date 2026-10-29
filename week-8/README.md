# Week 8: Security Hardening and Shifting Left

## Objective

Harden the web and database workloads, run security checks before merging
changes, and prevent automated deployment from deleting infrastructure
without human review.

## Implemented

- Web container runs as a non-root user.
- Container privilege escalation is disabled and Linux capabilities are dropped.
- Web and database Deployments have CPU and memory requests and limits.
- NetworkPolicy restricts database ingress to web pods on TCP port 5432.
- GitHub Actions runs OpenTofu validation, Helm rendering, and Checkov security
  scanning on pull requests and pushes to main.
- Checkov is pinned to version 3.3.26.
- The deployment script saves an OpenTofu plan and blocks deletion or
  replacement actions for human review.
- ruleset.json defines the required pull-request checks and has no bypass actors.

## Verification

- OpenTofu formatting and validation passed.
- Helm chart rendering passed.
- Checkov and the deployment gate passed in GitHub Actions.
- The OpenTofu deletion guard was tested with simulated plan data.

## Remaining Verification

- Confirm the GitHub ruleset is active and enforces all three required checks.
- Demonstrate that a pull request enabling privilege escalation fails the
  security gate and cannot be merged.
- Demonstrate that a database-volume rename is blocked by the deployment script.
- Revert the volume-rename change and verify the database volume was preserved.
- Verify state-file and deployment-log permissions in the available environment.

## Safety

Do not run tofu apply on a plan that deletes or replaces the database volume.
Do not run the deployment script during the destructive-change test without
first confirming the deletion guard is active.
