# MIT 8103 – Advanced Database Systems Portfolio

**Student:** Bamishaye Favour (ID: 301915930)  
**Platform Case Study:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**Artifacts:** Portfolios 1–5, Technical Reports, and Academic Declarations  

---

## Academic AI Declaration

In compliance with academic integrity guidelines, the formal AI usage statement is documented in:  
👉 **[AI_declaration.md](AI_declaration.md)**  
*(Details the ethical use of Generative AI for synthetic seeding in PostgreSQL/MongoDB and simulating automated integrity and diagnostic checks).*

---

## Portfolio Modules & Directory Index

| Portfolio Module | Focus Area | Primary DBMS | Key Artifacts & Reports |
| :--- | :--- | :--- | :--- |
| **[Portfolio 1: Database Design & Modelling](portfolio-1-database-design/)** | Relational 3NF modeling, double-entry ledger architecture, controlled denormalisations, constraint unit testing, synthetic data generation. | PostgreSQL 16 | [README.md](portfolio-1-database-design/README.md)<br>[normalisation.md](portfolio-1-database-design/normalisation.md)<br>[case-study.md](portfolio-1-database-design/case-study.md)<br>[nexora.dbml](portfolio-1-database-design/nexora.dbml) |
| **[Portfolio 2: Query Optimisation](portfolio-2-query-optimisation/)** | Baseline execution profiling (`EXPLAIN ANALYZE`), composite/partial/covering B-tree indexing, optimizer cost mechanics, join fan-out trap, write amplification. | PostgreSQL 16 / 18 | [README.md](portfolio-2-query-optimisation/README.md)<br>[performance-analysis.md](portfolio-2-query-optimisation/performance-analysis.md) |
| **[Portfolio 3: Transactions & Concurrency](portfolio-3-transactions-concurrency/)** | ACID transaction lifecycles, deadlock elimination via canonical ordered locking (`LEAST/GREATEST`), `pgbench` concurrency stress testing (5,977 TPS vs deadlocks), `lock_timeout`. | PostgreSQL 16 / 18 | [README.md](portfolio-3-transactions-concurrency/README.md)<br>[analysis.md](portfolio-3-transactions-concurrency/analysis.md)<br>[own_experiment.md](portfolio-3-transactions-concurrency/own_experiment.md) |
| **[Portfolio 4: NoSQL Document Store](portfolio-4-nosql/)** | Polyglot persistence, polymorphic KYC documents, `$jsonSchema` validation, high-velocity append-only audit streams, TTL indexes, multi-stage aggregation pipelines. | MongoDB Atlas / mongosh | [README.md](portfolio-4-nosql/README.md)<br>[nosql-model-design.md](portfolio-4-nosql/nosql-model-design.md)<br>[sql-vs-nosql-rational.md](portfolio-4-nosql/sql-vs-nosql-rational.md) |
| **[Portfolio 5: Distributed & Cloud Systems](portfolio-5-distributed-cloud/)** | Physical streaming replication, persistent replication slots, chaos testing, stale read windows, CAP synchronous hangs, failover (`pg_promote`), 4-shard hash partitioning, MongoDB Atlas 3-node HA. | PostgreSQL 16 (Docker) & MongoDB Atlas | [README.md](portfolio-5-distributed-cloud/README.md)<br>[analysis.md](portfolio-5-distributed-cloud/analysis.md) |
