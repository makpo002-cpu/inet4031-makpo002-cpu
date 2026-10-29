#!/usr/bin/env bash
# Pull-based deploy. If origin/main has a commit this VM has not deployed yet,
# and the deploy gate on GitHub passed for that exact commit, bring this folder
# up to date and apply it to the cluster. Safe to run by hand or from cron.
# Usage: ./week-7/deploy.sh

set -eu

# Same PATH and settings whether you run it by hand or cron runs it.
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
export GIT_TERMINAL_PROMPT=0
export GH_PROMPT_DISABLED=1
export GH_NO_UPDATE_NOTIFIER=1
export TF_IN_AUTOMATION=1

REPO="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$HOME/.deployed-commit"
cd "$REPO"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }
trap 'log "FAILED. Nothing was recorded, so the next run tries again."' ERR

# Take turns: only one deploy at a time.
# Take turns: only one deploy at a time (macOS-compatible).
LOCK_DIR="$HOME/.deploy.lock.d"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "another deploy may be running, skipping"
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

# Is there anything new? A VM that just booted may not have a network yet.
if ! git fetch --quiet origin main; then
  log "WAITING: could not reach GitHub"
  exit 0
fi
NEW="$(git rev-parse origin/main)"
OLD="$(cat "$STATE" 2>/dev/null || true)"

if [ "$NEW" = "$OLD" ]; then
  log "up to date at ${NEW:0:7}"
  exit 0
fi

log "new commit ${NEW:0:7} on origin/main"

# The gate: did the Deploy gate workflow pass for exactly this commit?
if ! gate="$(gh api "repos/{owner}/{repo}/actions/workflows/deploy-gate.yml/runs?head_sha=$NEW&branch=main&event=push&per_page=10" \
    --jq '(.workflow_runs | map(select(.head_sha == "'"$NEW"'" and .event == "push" and .head_branch == "main")) | .[0] // empty) | "\(.status) \(.conclusion)"')"; then
  log "WAITING: could not read the gate result (no network, or gh is not logged in)"
  exit 0
fi
case "$gate" in
  "completed success")
    log "the gate passed" ;;
  "")
    log "WAITING: the gate has not started for ${NEW:0:7}"
    exit 0 ;;
  "completed "*)
    log "BLOCKED: the gate finished as ${gate#completed } for ${NEW:0:7}. A new commit that passes, or a re-run on GitHub, unblocks it."
    exit 1 ;;
  *)
    log "WAITING: the gate is still running ($gate)"
    exit 0 ;;
esac

# A VM that was just booted may not have its cluster up yet.
if ! kubectl get nodes >/dev/null 2>&1; then
  log "WAITING: the cluster is not answering yet (is k3s running?)"
  exit 0
fi

# The guard: refuse to deploy from a folder in the wrong state.
branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" != "main" ]; then
  log "SKIPPED: this folder is on '$branch', not main"
  exit 1
fi

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  log "SKIPPED: tracked files have uncommitted changes"
  git status --short --untracked-files=no
  exit 1
fi

if ! git merge --ff-only --quiet origin/main || [ "$(git rev-parse HEAD)" != "$NEW" ]; then
  log "SKIPPED: this folder has commits that are not on origin/main"
  exit 1
fi

log "deploying ${NEW:0:7}"

log "step 1 of 2: tofu plan and safe apply in week-5"
(
  cd week-5
  umask 077
  PLAN_FILE="$(mktemp "${TMPDIR:-/tmp}/week8-deploy-plan.XXXXXX")"
  KEEP_PLAN=false

  cleanup_plan() {
    if [ "$KEEP_PLAN" != true ]; then
      rm -f "$PLAN_FILE"
    fi
  }
  trap cleanup_plan EXIT

  tofu init -input=false
  tofu plan -input=false -lock-timeout=60s -out="$PLAN_FILE"

  if ! tofu show -json "$PLAN_FILE" | python3 -c '
import json, sys
plan = json.load(sys.stdin)
changes = plan.get("resource_changes", [])
bad = [
    r for r in changes
    if "delete" in r.get("change", {}).get("actions", [])
]
for r in bad:
    print("{}: {}".format(
        r.get("address", "<unknown>"),
        ", ".join(r.get("change", {}).get("actions", []))
    ))
sys.exit(1 if bad else 0)
'; then
    KEEP_PLAN=true
    log "BLOCKED: plan contains destroy/replacement actions or could not be inspected."
    log "Human review required. Private plan saved at: $PLAN_FILE"
    exit 1
  fi

  tofu apply -input=false -lock-timeout=60s "$PLAN_FILE"
)
log "step 2 of 2: helm upgrade for prometheus"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update prometheus-community
helm upgrade --install prometheus prometheus-community/prometheus \
  --version 29.35.0 \
  --namespace monitoring \
  --create-namespace \
  --values week-6/prometheus-values.yaml \
  --wait \
  --rollback-on-failure \
  --timeout 5m

echo "$NEW" > "$STATE"
log "deployed ${NEW:0:7}"
