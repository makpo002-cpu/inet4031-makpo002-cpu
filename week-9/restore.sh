#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: ./week-9/restore.sh /path/to/backup.dump"
    exit 1
fi

BACKUP="$1"

if [ ! -f "$BACKUP" ] || [ ! -s "$BACKUP" ]; then
    echo "ERROR: Backup file is missing or empty."
    exit 1
fi

echo "Verifying backup archive..."

kubectl exec -i deployment/db -- pg_restore --list < "$BACKUP" >/dev/null

echo "Restoring incidents database..."

kubectl exec -i deployment/db -- pg_restore \
    -U incident_app \
    -d incidents \
    --clean \
    --if-exists \
    --no-owner \
    --exit-on-error \
    < "$BACKUP"

echo "Restore completed."
./week-9/sql.sh
