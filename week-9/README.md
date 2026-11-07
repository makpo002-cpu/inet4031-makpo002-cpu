# Week 9: Database Observability, Backup, and Recovery

## Overview

This lab implements PostgreSQL monitoring, automated database backups,
backup verification, and a tested database recovery process using the
local Docker Desktop Kubernetes environment.

## Components

- `week-5/exporter.tf`: Deploys the PostgreSQL Prometheus exporter.
- `week-5/network.tf`: Restricts database ingress to approved application
  and exporter pods.
- `week-9/sql.sh`: Runs SQL commands against the incidents database.
- `week-9/backup.sh`: Creates and verifies PostgreSQL custom-format backups.
- `week-9/restore.sh`: Restores a database from a backup archive.
- `week-9/check.sh`: Checks database readiness, exporter metrics, backup
  freshness, checksum, archive readability, and the scheduled backup job.

## Monitoring

The PostgreSQL exporter is available inside the cluster at:

`http://postgres-exporter:9187/metrics`

Prometheus queries used for validation:

1. `pg_up`
   - Expected result: `1`, indicating the exporter can connect to PostgreSQL.

2. `pg_database_size_bytes{datname="incidents"} / 1024 / 1024`
   - Observed result: approximately 7.4 MiB.

3. `sum by (relname) (pg_stat_user_tables_n_live_tup)`
   - Observed result: 3 estimated live rows for the `tickets` table.

## Backup configuration

The backup script writes PostgreSQL custom-format archives to:

- Primary: `~/backups/inet4031-week9`
- Secondary: `~/Documents/inet4031-week9-backups`

The script verifies the archive with `pg_restore --list`, creates a
SHA-256 checksum, copies the archive and checksum to the secondary
directory, and retains the newest 12 primary backup archives.

Files are protected with a restrictive umask and script permissions.

A macOS `launchd` job runs the backup script at five-minute intervals
and also runs when the job is loaded. The job is configured to run while
the Mac is available; it does not guarantee backups while the computer
is asleep or powered off.

The secondary copy is on the same Mac. It protects against some
Kubernetes workload or cluster failures, but it is not an independent
off-device or off-site backup.

## Recovery drill

A controlled recovery drill was performed after a verified backup was
created.

- Baseline: 3 rows in `public.tickets`.
- Test: Dropped and recreated the `public` schema.
- Recovery: Restored the database from the verified backup.
- Result: The `tickets` table and all 3 sample rows were recovered.

Measured results:

- Backup age at the start of the drill: 248 seconds.
- Recovery time objective (RTO) observed: 77 seconds.
- Recovered sample records: 3 of 3.

The 248-second backup age is used as a proxy for the potential recovery
point gap. Because no new data had been added after that backup, no
sample ticket transactions were lost in this drill.

## Health-check results

`./week-9/check.sh` completed successfully.

All seven checks passed:

1. PostgreSQL readiness.
2. PostgreSQL exporter metrics.
3. Latest backup file exists.
4. Backup is within the 15-minute freshness target.
5. SHA-256 checksum verification.
6. PostgreSQL archive readability.
7. Five-minute macOS `launchd` schedule is loaded.

## Commands

Run the health checks:

`./week-9/check.sh`

Create a backup:

`./week-9/backup.sh`

List database tables and row counts:

`./week-9/sql.sh`

Run a SQL statement:

`./week-9/sql.sh 'SELECT * FROM tickets;'`

Restore from a selected backup:

`./week-9/restore.sh /path/to/backup.dump`

Only restore a backup when the intended recovery operation has been
reviewed and approved. The restore script modifies the target database.

## Limitations and future improvements

- Move a secondary backup to independent cloud or off-site storage.
- Add backup encryption and documented key management.
- Monitor backup age and backup-job failures through alerting.
- Consider a dedicated always-on host for scheduled backups.
- Continue testing recovery procedures and recording recovery times.
