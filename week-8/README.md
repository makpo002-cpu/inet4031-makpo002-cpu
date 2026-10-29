# Week 8: Security Hardening and Shifting Left

## Objective

Harden the web and database workloads, run security checks before merging changes, and prevent automated deployment from deleting or replacing infrastructure without human review.

## Implemented Security Controls

- Configured the web container to run as a non-root user.
- Disabled privilege escalation and dropped Linux capabilities.
- Added CPU and memory requests and limits to the web and database Deployments.
- Added a NetworkPolicy restricting database ingress to web pods on TCP port 5432.
- Configured GitHub Actions to run OpenTofu validation, Prometheus Helm chart rendering, and Checkov security scanning.
- Pinned Checkov to version 3.3.26.
- Added deployment guard logic to block plans containing deletion or replacement actions.
- Configured a GitHub ruleset requiring pull requests and three status checks, with no bypass actors.

## Verification Results

- OpenTofu validation passed.
- Prometheus Helm chart rendering passed.
- The privilege-escalation test caused the security scan to fail. After restoring the secure setting, the scan passed, and the test pull request was closed without merging.
- The GitHub ruleset was verified as active and configured to require all three checks.
- Simulated plan data containing deletion and creation actions was blocked by the deletion-guard logic.
- A database volume rename test plan showed that the persistent volume claim would be replaced. The plan was not applied.
- The database persistent volume claim remained Bound with its original 1 Gi capacity.
- The web and database Deployments were available, and the database pod was running without restarts.
- The database NetworkPolicy was present.
- The OpenTofu state file and deployment commit-state file had permissions set to 600.

## Limitations and Safety

- The full deployment script was not run against a destructive plan; only the guard logic was tested with simulated plan data.
- The database volume rename was not applied, preserving the existing volume.
- No dedicated deployment log file was found in the checked locations.
- These checks do not establish that every possible security risk has been eliminated.

**Safety rule:** Never apply a plan that deletes or replaces the database volume without reviewing and explicitly approving the change.
