#!/bin/bash
set -uo pipefail

BACKUP_DIR="$HOME/backups/inet4031-week9"
FAIL=0

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1"
    FAIL=1
}

echo "===== WEEK 9 HEALTH CHECK ====="

# 1. PostgreSQL readiness
if kubectl exec deployment/db -- sh -c \
    'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' >/dev/null 2>&1; then
    pass "PostgreSQL is ready"
else
    fail "PostgreSQL is not ready"
fi

# 2. PostgreSQL exporter metrics
if kubectl exec deployment/web -- python -c '
import re
import urllib.request

url = "http://postgres-exporter:9187/metrics"
data = urllib.request.urlopen(url, timeout=10).read().decode()
if not re.search(r"(?m)^pg_up(?:\{[^}]*\})?\s+1(?:\.0)?$", data):
    raise SystemExit("Exporter did not report pg_up = 1")
print("Exporter reports pg_up = 1")
' >/dev/null 2>&1; then
    pass "PostgreSQL exporter is reporting metrics"
else
    fail "PostgreSQL exporter check failed"
fi

# 3. Find the latest backup
LATEST=$(ls -t "$BACKUP_DIR"/incidents-*.dump 2>/dev/null | head -n 1 || true)

if [ -z "$LATEST" ]; then
    fail "No backup file found"
else
    pass "Latest backup found: $(basename "$LATEST")"

    # 4. Backup freshness (15-minute target)
    AGE=$(( $(date +%s) - $(stat -f %m "$LATEST") ))
    echo "Backup age: ${AGE} seconds"

    if [ "$AGE" -le 900 ]; then
        pass "Backup is within the 15-minute freshness target"
    else
        fail "Backup is older than 15 minutes"
    fi

    # 5. Backup checksum
    if [ -f "$LATEST.sha256" ] && shasum -a 256 -c "$LATEST.sha256" >/dev/null 2>&1; then
        pass "Backup checksum is valid"
    else
        fail "Backup checksum is missing or invalid"
    fi

    # 6. PostgreSQL archive verification
    if kubectl exec -i deployment/db -- pg_restore --list < "$LATEST" >/dev/null 2>&1; then
        pass "Backup archive can be read by pg_restore"
    else
        fail "Backup archive verification failed"
    fi
fi

# 7. macOS launchd schedule
if launchctl print "gui/$(id -u)/com.inet4031.week9.backup" 2>/dev/null | grep -q "run interval = 300 seconds"; then
    pass "Automatic backup schedule is loaded (every 5 minutes)"
else
    fail "Automatic backup schedule is not loaded or has the wrong interval"
fi

echo "===== HEALTH CHECK COMPLETE ====="

if [ "$FAIL" -ne 0 ]; then
    echo "One or more checks failed."
    exit 1
fi

echo "All checks passed."
