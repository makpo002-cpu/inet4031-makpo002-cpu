#!/bin/bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
    kubectl exec -i deployment/db -- sh -c \
        'exec psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' <<'SQL'
SELECT format(
    'SELECT %L AS table_name, count(*) AS row_count FROM %I.%I;',
    tablename, schemaname, tablename
)
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
\gexec
SQL
else
    kubectl exec deployment/db -- sh -c \
        'exec psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "$1"' \
        sh "$1"
fi
