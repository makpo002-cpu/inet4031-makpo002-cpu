#!/bin/bash
set -euo pipefail
umask 077

BACKUP_DIR="$HOME/backups/inet4031-week9"
SECONDARY_DIR="$HOME/Documents/inet4031-week9-backups"
LOCK_DIR="$BACKUP_DIR/.backup.lock"

mkdir -p "$BACKUP_DIR" "$SECONDARY_DIR"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "Another backup may already be running. Exiting."
    exit 1
fi

cleanup() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

STAMP=$(date -u +"%Y%m%dT%H%M%SZ")
BACKUP="$BACKUP_DIR/incidents-$STAMP.dump"
TEMP="$BACKUP.tmp"

echo "Starting PostgreSQL backup: $STAMP"

if ! kubectl exec deployment/db -- sh -c \
    'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$TEMP"; then
    rm -f "$TEMP"
    echo "ERROR: PostgreSQL dump failed."
    exit 1
fi

if ! kubectl exec deployment/db -- pg_restore --version >/dev/null; then
    rm -f "$TEMP"
    echo "ERROR: pg_restore is unavailable."
    exit 1
fi

if ! kubectl exec -i deployment/db -- pg_restore --list < "$TEMP" > /dev/null; then
    rm -f "$TEMP"
    echo "ERROR: Backup verification failed."
    exit 1
fi

mv "$TEMP" "$BACKUP"
shasum -a 256 "$BACKUP" > "$BACKUP.sha256"

cp "$BACKUP" "$SECONDARY_DIR/"
cp "$BACKUP.sha256" "$SECONDARY_DIR/"

echo "Backup verified successfully."
echo "Primary: $BACKUP"
echo "Secondary: $SECONDARY_DIR/$(basename "$BACKUP")"

echo "Keeping the newest 12 primary backups..."
ls -1t "$BACKUP_DIR"/incidents-*.dump 2>/dev/null | tail -n +13 | while IFS= read -r old; do
    rm -f "$old" "$old.sha256"
done
echo "Backup completed."
