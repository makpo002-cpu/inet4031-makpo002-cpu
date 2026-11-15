# INET4031 – Week 10: End-to-End Performance Investigation

## 1. Lab Overview

This lab focuses on investigating application performance, identifying bottlenecks, and documenting potential improvements in a Kubernetes-based ticket management application.

The objective is to understand how application performance, database queries, and resource limitations affect the overall system.

## 2. Lab Objectives

- Establish a performance baseline.
- Understand the impact of increased database records.
- Investigate application and database performance.
- Identify inefficient database queries.
- Explore database indexing and query optimization.
- Understand CPU resource throttling.
- Document performance improvements.
- Introduce performance validation into a CI/CD workflow.

## 3. System Environment

The project uses the following technologies:

- Kubernetes – Container orchestration.
- PostgreSQL – Relational database.
- Prometheus – Performance monitoring.
- PostgreSQL Exporter – Database metrics collection.
- Python – Application and supporting scripts.
- GitHub Actions – Continuous integration.

## 4. Performance Investigation

### Stage 1: Performance Baseline
Establish the application's initial performance measurements to understand its normal operating behavior.

### Stage 2: Increased Workload
Examine how increasing the database to 10,000 tickets can affect application performance.

### Stage 3: Database Investigation
Use monitoring information and PostgreSQL metrics to identify potential database bottlenecks.

### Stage 4: Query Optimization
Investigate limiting the homepage query to 50 tickets to reduce unnecessary database retrieval.

### Stage 5: Database Indexing
Explore how appropriate database indexes can improve query performance and reduce retrieval time.

### Stage 6: CPU Resource Investigation
Examine how CPU resource limits and throttling can affect application responsiveness.

### Stage 7: Performance Validation
Explore performance checks and the use of GitHub Actions to help prevent performance regressions.

## 5. Expected Outcomes

- Better understanding of application performance.
- Identification of database bottlenecks.
- Improved understanding of SQL query optimization.
- Understanding of database indexing.
- Awareness of Kubernetes resource constraints.
- Familiarity with performance validation practices.

## 6. Conclusion

This lab demonstrates the importance of application performance monitoring, database optimization, and infrastructure resource management.

By investigating database queries, indexing strategies, CPU resource allocation, and performance validation, developers can better understand system bottlenecks and improve application reliability and responsiveness.
