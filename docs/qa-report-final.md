# INET4031 Cybersecurity Governance Capstone
## Final Quality Assurance Report

**Assessment date:** November 22, 2026  
**Environment:** macOS Intel with Docker Desktop Kubernetes  
**Repository:** inet4031-makpo002-cpu

## 1. Executive Summary

The capstone implemented and evaluated security controls across the
application image, source repository, Kubernetes workloads, RBAC,
network policy configuration, and security governance documentation.

Automated scans identified one fixable HIGH image vulnerability.
The Docker image was rebuilt with an updated zlib package. The
subsequent image scan reported 50 HIGH findings and zero CRITICAL
findings, compared with 51 HIGH and zero CRITICAL findings in the
baseline scan.

Gitleaks scanned the Git history and detected no committed secrets.
Trivy reported zero HIGH or CRITICAL Kubernetes manifest
misconfigurations in the selected default-namespace resources.

Several workload recommendations remain open. NetworkPolicy
enforcement could not be verified because the local Docker Desktop
kindnet networking environment did not demonstrate the expected
allow/block behavior.

## 2. Test Environment

The assessment was performed locally on macOS Intel using Docker
Desktop Kubernetes.

Tools included:

- Trivy 0.76.2
- Gitleaks 8.30.1
- kube-score 1.20.0
- OpenTofu 1.13.1
- kubectl client 1.36.1
- Helm 4.3.1
- Docker 29.7.2
- Python 3.9.6
- Git 2.39.5

The local Kubernetes context was `docker-desktop`. The CNI was
identified as `kindnet`.

## 3. Image Vulnerability Testing

The baseline Trivy scan was saved under:

`capstone/cybersecurity-governance/scans/before/20261122-125516/`

Baseline results:

- HIGH findings: 51
- CRITICAL findings: 0
- Identified fixable issue: CVE-2026-85091 in zlib

The Flask image Dockerfile was updated to upgrade the installed
zlib package during the image build. A separate image tagged
`week-4-web:capstone-fixed` was built.

The follow-up scan was saved under:

`capstone/cybersecurity-governance/scans/after/20261122-130454/`

Follow-up results:

- HIGH findings: 50
- CRITICAL findings: 0
- Reduction: one HIGH finding, approximately 1.96%
- CVE-2026-85091 no longer appeared in the follow-up scan.

The remaining HIGH findings require additional dependency and
base-image review. The fixed image was scanned but was not deployed
to the running Kubernetes web deployment during this assessment.
The running deployment therefore must not be assumed to use the
fixed image.

## 4. Repository and Secret Scanning

Gitleaks scanned the repository's Git history.

Result:

- 30 commits scanned.
- Zero detected leaks.
- No unresolved Gitleaks findings were reported.

Terraform variable and state files were checked for restrictive
owner-only permissions and Git ignore coverage. No secret values
are included in this report.

A clean Gitleaks result means no leaks were detected by this scan;
it does not prove that credentials were never exposed elsewhere.

## 5. Kubernetes Workload Review

The web workload was reviewed for container security settings.

Verified web workload settings included:

- Non-root execution.
- Explicit user and group ID 10001.
- Privilege escalation disabled.
- All Linux capabilities dropped.
- Read-only root filesystem.
- RuntimeDefault seccomp profile.

kube-score identified additional recommendations for the database,
PostgreSQL exporter, and web workloads. These include readiness
probes, resource settings for ephemeral storage, image pull policy,
and additional security-context improvements.

The database UID/GID recommendations require testing against
persistent-volume ownership and application behavior before
implementation.

The web workload still uses a mutable `latest` image tag. This
remains an open control issue.

## 6. Kubernetes Manifest Scan

Trivy scanned exported Deployments, Services, and NetworkPolicy
resources from the default namespace.

Result:

- HIGH misconfigurations: 0
- CRITICAL misconfigurations: 0

The scan covered the selected exported resources in the default
namespace, not every resource in every Kubernetes namespace.

## 7. RBAC Testing

Eight `kubectl auth can-i` authorization checks were performed
across application and monitoring identities.

Observed results included:

- The default application service account was denied the tested
  pod, deployment, secret, and pod-creation permissions.
- The Prometheus service account could get pods and services.
- The Prometheus service account was denied secret access.

Detailed results are recorded in:

`capstone/cybersecurity-governance/evidence/rbac-checks.txt`

These checks cover the tested permissions and identities; they
are not a complete audit of every Kubernetes authorization path.

## 8. NetworkPolicy Testing

A database ingress NetworkPolicy was configured to allow traffic
on TCP port 5432 from the web and PostgreSQL exporter pod selectors.

Connectivity tests did not establish reliable authorized and
unauthorized behavior. The local Docker Desktop kindnet CNI did
not demonstrate NetworkPolicy enforcement during testing.

Therefore, enforcement is classified as UNVERIFIED and is tracked
as an accepted risk. The existence of a NetworkPolicy resource
does not establish that the network plugin enforces it.

A separate Kubernetes environment with confirmed NetworkPolicy
support is required to complete positive and negative enforcement
tests.

## 9. Automated Security Scan Script

The capstone script is:

`capstone/cybersecurity-governance/scripts/run-security-scans.sh`

The script was executed successfully and created timestamped
evidence under:

`capstone/cybersecurity-governance/evidence/`

The latest recorded run was:

`run-20261122-132817`

Recorded execution time was approximately 18.1 seconds.

The script collects image, Terraform, Kubernetes manifest,
Gitleaks, kube-score, RBAC, NetworkPolicy status, and tool-version
evidence.

A successful script exit does not mean every security check passed.
Some tools report findings that require manual review; kube-score
reported recommendations requiring review.

## 10. Governance Documentation

The project includes:

- A cybersecurity controls inventory with 18 controls.
- A risk register containing nine risks with likelihood, impact,
  risk scores, owners, and treatments.
- An access control policy.
- A vulnerability management policy.
- A secrets handling policy.
- A technical runbook.
- An architecture document.
- A tool-version inventory.
- A rebuild limitations document.

## 11. Outstanding Issues

The following items remain open:

1. Fifty HIGH image vulnerability findings remain.
2. The fixed Flask image has not been deployed to Kubernetes.
3. The web deployment still uses a mutable `latest` image tag.
4. Database and exporter hardening recommendations need review.
5. NetworkPolicy enforcement remains unverified.
6. The local Docker Desktop environment differs from the
   Ubuntu/k3s environment specified in the original lab.
7. Trivy Terraform scanning did not have Terraform variable
   values available; results must be interpreted with that
   limitation.

## 12. Final Assessment

The project demonstrates practical security scanning, remediation
of one fixable image vulnerability, Git history secret scanning,
workload hardening, RBAC verification, governance documentation,
and repeatable evidence collection.

The results also identify controls that cannot be claimed as
verified. In particular, NetworkPolicy enforcement and deployment
of the fixed image remain incomplete. These limitations are
documented for review rather than represented as successful tests.

**Overall conclusion:** The capstone has a working local security
assessment workflow and documented governance controls. Remaining
risks and environment limitations require follow-up before the
system can be considered fully hardened.
