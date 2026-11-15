# Week 10 – Performance Testing, Database Optimization, and Monitoring

## Overview

This lab focused on identifying application performance bottlenecks, measuring system behavior under load, optimizing database queries, monitoring Kubernetes resources, and preventing performance regressions through automated testing.

The work builds on the existing Kubernetes application and PostgreSQL infrastructure. It combines load testing, database analysis, Prometheus monitoring, resource-limit experiments, and a GitHub Actions performance gate.

## Objectives

- Establish application performance baselines.
- Measure response times under increasing workloads.
- Identify database and application bottlenecks.
- Optimize database queries and reduce unnecessary data retrieval.
- Monitor CPU, memory, and database activity.
- Observe the effects of CPU throttling.
- Automate performance checks through GitHub Actions.

## Implementation

### 1. Load testing with k6

Used k6 to generate application traffic and evaluate performance under different workloads.

The load-testing scripts cover:

- Baseline application performance.
- Increased traffic and seeded database workloads.
- Ramped load testing.
- Response-time thresholds and performance checks.

The tests help identify changes in response time, throughput, and application stability as demand increases.

### 2. Database monitoring with PostgreSQL

Enabled PostgreSQL's `pg_stat_statements` extension to collect query execution statistics.

The extension provides information about:

- Query execution counts.
- Total execution time.
- Mean execution time.
- Frequently executed and expensive queries.

The extension was enabled through the PostgreSQL deployment configuration.

### 3. Database performance analysis

Seeded the tickets table with additional records to evaluate how database size affects query performance.

The resulting database contained **10,003 tickets**.

The query execution plan showed:

- A sequential scan of the tickets table.
- A sort operation using the `id DESC` ordering.
- Approximately 44.397 ms total execution time for the measured 10,003-row query.

The initial small-table query took approximately 1.188 ms, illustrating how a query that performs well with a small dataset can become more expensive as the dataset grows.

Used `EXPLAIN (ANALYZE, BUFFERS)` and PostgreSQL statistics to investigate query behavior and evaluate optimization opportunities.

### 4. Application optimization

Updated the homepage query in `week-4/app/app.py` to limit the number of tickets returned:

```sql
SELECT * FROM tickets ORDER BY id DESC LIMIT 50;
```

This prevents the homepage from retrieving the entire tickets table when only the most recent 50 records are needed.

The change reduces unnecessary database retrieval and the amount of data the application must process and render.

### 5. Prometheus and PostgreSQL exporter

Configured Prometheus monitoring and PostgreSQL exporter access.

The exporter exposes PostgreSQL metrics through its metrics endpoint, including database activity and buffer statistics.

The database monitoring configuration includes:

- PostgreSQL exporter deployment.
- Exporter service on port `9187`.
- Network policy access for the exporter.
- PostgreSQL query statistics.
- Prometheus metric collection.

### 6. Kubernetes resource limits and CPU throttling

Evaluated how CPU resource limits affect application performance.

The throttling experiment compares application behavior under normal CPU resources and a reduced CPU limit.

The purpose is to distinguish between CPU throttling as a direct cause of slower responses and throttling that occurs alongside another performance bottleneck.

The experiment also demonstrates why resource limits should be evaluated using both CPU utilization and application performance measurements.

### 7. Automated performance checks

Added automated performance testing through the GitHub Actions workflow.

The performance gate uses k6 to check application response-time thresholds and help identify regressions before changes are merged.

This makes performance testing part of the development workflow rather than relying exclusively on manual testing.

## Files and Configuration

| File | Purpose |
|---|---|
| `week-10/sql.sh` | Database setup and SQL performance operations |
| `week-10/run-k6.sh` | Runs k6 load tests |
| `week-10/k6-stat.sh` | Collects and displays k6 statistics |
| `week-10/throttle.sh` | Tests CPU throttling and resource restoration |
| `week-10/check.sh` | Runs performance checks |
| `week-10/smoke-test.js` | Basic application performance test |
| `week-10/ramped-test.js` | Ramped-load performance test |
| `week-10/README.md` | Week 10 documentation |
| `.github/workflows/load-test.yml` | Automated performance testing workflow |
| `week-4/app/app.py` | Homepage query optimization |
| `week-5/db.tf` | PostgreSQL and exporter infrastructure configuration |
| `week-5/network.tf` | Database network policy configuration |

## Validation

The following results were observed during the lab:

- PostgreSQL accepted connections on port `5432`.
- The tickets table contained 10,003 records after seeding.
- The `pg_stat_statements` extension was installed and enabled.
- PostgreSQL query execution plans were collected.
- The PostgreSQL exporter exposed database metrics.
- OpenTofu formatting and validation completed successfully.
- The infrastructure apply completed with two resources changed and zero resources added or destroyed.
- The `performance-tools` Git branch was pushed successfully.

Additional k6 and GitHub Actions results should be reviewed in their respective test outputs and workflow runs.

## Lessons Learned

This lab demonstrated that application performance depends on more than database execution time. Application processing, resource limits, network communication, and the amount of data retrieved can all contribute to response time.

It also demonstrated the importance of measuring performance with realistic data volumes. A query that appears efficient with a few records may become a bottleneck as the database grows.

Monitoring tools such as Prometheus and PostgreSQL statistics provide useful evidence for diagnosing problems instead of relying on assumptions. Finally, automated performance checks help make performance a continuous part of application development and deployment.

## Conclusion

Week 10 brought together load testing, database optimization, infrastructure monitoring, and automated performance validation. The application was updated to retrieve only the most recent 50 tickets, PostgreSQL query monitoring was configured, and performance testing was incorporated into the development workflow.

The overall goal was to build an application that is not only functional, but also measurable, efficient, and more resilient as workload increases.