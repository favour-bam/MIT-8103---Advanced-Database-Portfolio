# MIT 8103 – Advanced Database Systems Portfolio

**Course:** MIT 8103 – Advanced Database Systems (40 Marks Continuous Assessment)  
**Session:** 2026/2027 Academic Session (September Cohort) – First Semester  
**Awarding Institution:** Miva Open University — School of Post Graduate Studies  
**Degree Program:** Master of Information Technology (M.Sc. / MIT)  
**Student Name:** Bamishaye Favour  
**Student ID:** 301915930  
**Student Email:** `f.bamishaye5930@miva.edu.ng`  
**GitHub Repository URL:** [https://github.com/favour-bam/MIT-8103---Advanced-Database-Portfolio](https://github.com/favour-bam/MIT-8103---Advanced-Database-Portfolio)  
**Assessment Type:** Individual Practical Database Portfolio (LMS + GitHub)  

---

## 1. Selected Database Case Study & Organisation Statement

In compliance with Section 2 of the MIT 8103 course specifications, the platform case study below is utilized consistently across all five portfolio modules:

1. **Organisation Name & Scenario:**  
   **Nexora – Digital Savings and Financial Management Platform (Simulated)**. A next-generation fintech application engineered to provide retail customers and small merchants with disciplined savings goals, digital debit/virtual cards, high-velocity peer-to-peer (P2P) transfers, automated interest calculations, and compliance audit reporting.

2. **Nature of the Business and System:**  
   Nexora operates an immutable, double-entry financial accounting ledger. Unlike standard CRUD applications, balances in Nexora cannot be modified arbitrarily; every financial movement produces matching, self-balancing debit and credit journal lines ($\sum \text{Debits} - \sum \text{Credits} = 0$).

3. **Users of the Database:**  
   - **Retail Customers & Merchants:** Open savings accounts, initiate P2P transfers, lock funds in savings goals, and retrieve historical account statements.
   - **Finance & Treasury Officers:** Reconcile daily settlement totals, audit journal ledger balance invariants, and execute reversals.
   - **AML & Compliance Officers:** Monitor real-time fraud risk scores, investigate flagged transactions, and inspect immutable audit logs.
   - **System Administrators & Services:** Manage primary-replica replication slots, maintain partitions, and schedule background session TTL cleanups.

4. **Major Data to be Stored:**  
   - Core customer profiles, authentication credentials, and KYC verification records.
   - Multi-currency wallet accounts, balances, and savings goal targets.
   - Issued debit and virtual card records (tokenized with 4-digit masking).
   - Saved beneficiary recipient mappings.
   - Transaction header records with unique idempotency keys.
   - Double-entry ledger entries with immutable point-in-time balance snapshots.
   - Real-time AML fraud flags and risk ratings.
   - MongoDB document collections: polymorphic KYC documents, append-only security telemetry audit logs (100k events), and auto-expiring login sessions.

5. **Key Operations Supported:**  
   - Atomic, deadlock-free P2P wallet transfers with row-level canonical ordered locking (`LEAST/GREATEST`).
   - Real-time account statement generation and multi-table join reconciliations.
   - End-of-day mathematical balance conservation audits.
   - Automated identity verification and document schema validation (`$jsonSchema`).
   - High-throughput append-only audit event logging and 4 analytical aggregation pipelines.
   - High-availability physical streaming replication, chaos testing (lag simulation), failover promotion (`pg_promote`), and 4-shard horizontal hash partitioning.

---

## 2. Assessment Mark Allocation & Rubric Mapping

This portfolio satisfies both institutional mark schemes (Component Activity breakdown and Marking Criteria Rubric):

### 2.1. Component Activity Mark Allocation (Section 3)
| Component | Activity Description | Primary Engine | Assigned Marks |
| :--- | :--- | :--- | :---: |
| **Portfolio 1** | Database Design and Modelling | PostgreSQL 16 | **7 Marks** |
| **Portfolio 2** | Query Processing and Optimisation | PostgreSQL 16 / 18 | **7 Marks** |
| **Portfolio 3** | Transactions and Concurrency | PostgreSQL 16 / 18 | **7 Marks** |
| **Portfolio 4** | NoSQL and Advanced Data Models | MongoDB Atlas / mongosh | **7 Marks** |
| **Portfolio 5** | Distributed and Cloud Database Exercise | PostgreSQL (Docker) & MongoDB Atlas | **6 Marks** |
| **Final Documentation** | 2–3 Page Report, GitHub Organisation & Reflection | Multi-Artifact Synthesis | **6 Marks** |
| **TOTAL** | **Continuous Assessment Score** | | **40 Marks** |

### 2.2. Marking Criteria Rubric (Section 9)
| Criteria | Focus Area & Specific Evidence | Marks |
| :--- | :--- | :---: |
| **Technical Correctness** | Double-entry ledger balance invariants ($\sum \text{Debits} = \sum \text{Credits}$), non-negative constraints (`CHECK balance >= 0`), regex validations, canonical ordered locking (`LEAST/GREATEST`), MongoDB `$jsonSchema` validation rejecting code `121`. | **8 Marks** |
| **Database Design Quality** | Formal 3NF relational schema decomposition, architectural defense of 4 controlled denormalisations, DBML model, high-res ERD diagram, polyglot persistence design. | **6 Marks** |
| **Practical Implementation** | Deterministic synthetic seeding (`setseed(0.42)`, 5k customers, 206k txns, 412k ledgers, 100k audit events), `pgbench` stress tests, Docker multi-container replication cluster, 66+ authentic screenshots. | **8 Marks** |
| **Query & Performance Analysis** | 9 benchmark queries profiled via `EXPLAIN (ANALYZE, BUFFERS)`, composite/partial/covering B-tree indexing, 131x join acceleration, 58x query speedup, write amplification overhead quantified. | **5 Marks** |
| **Advanced Database Concepts** | ACID transaction lifecycles, deadlock elimination theorems, fail-fast `lock_timeout`, physical streaming replication, CAP synchronous write-hang vs. AP lag, 4-shard hash partitioning, Atlas majority quorums. | **5 Marks** |
| **Documentation & GitHub Organisation** | Modular directory layout matching university guidelines, strict `Surname_Firstname_DocumentType` naming (0 spaces), semantic commit history, and comprehensive READMEs. | **5 Marks** |
| **Technical Reflection & Understanding** | Critical evaluation of relational vs. NoSQL trade-offs, concurrency race conditions, independent empirical research on `lock_timeout` under contention, and ethical AI declaration. | **3 Marks** |
| **TOTAL** | | **40 Marks** |

---

## 3. Repository Structure & Directory Index

```
MIT-8103---Advanced-Database-Portfolio/
├── README.md                                  # Master repository index & case study statement
├── Bamishaye_Favour_README.txt                # Standalone evaluator plain-text catalog
├── Bamishaye_Favour_Final_Report.md           # 2–3 page Final Synthesis Report
├── Bamishaye_Favour_AI_Use_Declaration.md     # Institutional Generative AI Declaration
├── Bamishaye_Favour_References.md             # Formal academic & industry bibliography
├── package_submission.sh                      # Automated reproducible LMS packaging script
│
├── portfolio-1-database-design/               # PORTFOLIO 1: DESIGN & MODELLING (7M)
│   ├── README.md                              # Portfolio guide & module overview
│   ├── case-study.md                          # Detailed Nexora business specification
│   ├── normalisation.md                       # 3NF derivations & 4 controlled denorms
│   ├── nexora.dbml                            # Machine-readable DBML schema definition
│   ├── 00_create_database.sql                 # Database creation DDL
│   ├── 01_verify_setup.sql                    # Initial environment check
│   ├── 02_create_tables.sql                   # 8 tables, constraints, regexes, foreign keys
│   ├── 03_constraint_tests.sql                # 10 PL/pgSQL constraint test harness
│   ├── 04_seed_data.sql                       # Deterministic synthetic data generator
│   ├── 05_verify_seed.sql                     # Seed verification & money conservation audit
│   └── screenshots/                           # High-res ERD & setup verification screenshots
│
├── portfolio-2-query-optimisation/            # PORTFOLIO 2: QUERY OPTIMISATION (7M)
│   ├── README.md                              # Query catalog & planner guide
│   ├── performance-analysis.md                # Benchmarking report & plan comparisons
│   ├── queries/                               # 9 benchmark queries (Q1 to Q9)
│   ├── sql/                                   # Index DDLs, plan capture, & write cost scripts
│   ├── plans/                                 # Raw execution plan logs (before, after, planner)
│   └── screenshots/                           # 21 pgAdmin execution plan screenshots
│
├── portfolio-3-transactions-concurrency/      # PORTFOLIO 3: TRANSACTIONS & CONCURRENCY (7M)
│   ├── README.md                              # ACID transaction guide & concurrency overview
│   ├── analysis.md                            # Mathematical proof of deadlock elimination
│   ├── own_experiment.md                      # Independent research on lock_timeout
│   ├── sql/                                   # transfer_funds(), demo, pgbench scripts
│   ├── output/                                # Raw pgbench logs (5,977 TPS vs 62 deadlocks)
│   └── screenshots/                           # 12 screenshots of ACID demos & stress tests
│
├── portfolio-4-nosql/                         # PORTFOLIO 4: NOSQL DOCUMENT STORE (7M)
│   ├── README.md                              # Polyglot architecture & MongoDB guide
│   ├── nosql-model-design.md                  # Document modeling & embedding vs referencing
│   ├── sql-vs-nosql-rational.md               # Architectural rationale for polyglot persistence
│   ├── script/                                # $jsonSchema validation, LCG seed, aggregations
│   ├── output/                                # Aggregation and index profiling outputs
│   └── screenshots/                           # 9 MongoDB Atlas & Compass screenshots
│
└── portfolio-5-distributed-cloud/             # PORTFOLIO 5: DISTRIBUTED & CLOUD (6M)
    ├── README.md                              # Multi-container cluster guide & failover runbook
    ├── analysis.md                            # Streaming replication, CAP/PACELC proofs, lag
    ├── docker-compose.yml                     # Primary and Hot Standby multi-container topology
    ├── replica-entrypoint.sh                  # Hot standby automated bootstrap script
    ├── primary-init/                          # Primary replication slot initialization
    ├── 01_primary_checks.sql                  # Primary replication slot diagnostic queries
    ├── 02_replica_checks.sql                  # Standby recovery status diagnostic queries
    ├── 03_partitioning.sql                    # 4-shard declarative hash partitioning DDL
    ├── 04_atlas_cloud_check.js                # MongoDB Atlas distributed quorum script
    ├── nexora_dump.sql                        # Full database backup dump (59 MB)
    ├── output/                                # Replication and partitioning terminal logs
    └── screenshots/                           # 17 Docker, psql, and Atlas screenshots
```

---

## 4. Evaluator Verification Runbook

Assessing faculty can verify all five portfolios sequentially using standard CLI tools:

```bash
# STEP 1: Verify Portfolio 1 (Schema & Constraints)
createdb nexora_db
psql -d nexora_db -f portfolio-1-database-design/02_create_tables.sql
psql -d nexora_db -f portfolio-1-database-design/03_constraint_tests.sql
psql -d nexora_db -f portfolio-1-database-design/04_seed_data.sql
psql -d nexora_db -f portfolio-1-database-design/05_verify_seed.sql

# STEP 2: Verify Portfolio 2 (Query Optimisation)
psql -d nexora_db -f portfolio-2-query-optimisation/sql/01_capture_plans.sql
psql -d nexora_db -f portfolio-2-query-optimisation/sql/03_create_indexes.sql
psql -d nexora_db -f portfolio-2-query-optimisation/sql/01_capture_plans.sql
psql -d nexora_db -f portfolio-2-query-optimisation/sql/06_write_cost.sql

# STEP 3: Verify Portfolio 3 (ACID Transactions & Deadlock Elimination)
psql -d nexora_db -f portfolio-3-transactions-concurrency/sql/01_transfer_function.sql
psql -d nexora_db -f portfolio-3-transactions-concurrency/sql/03_commit_rollback_demo.sql
pgbench -d nexora_db -c 10 -j 2 -t 200 -f portfolio-3-transactions-concurrency/sql/04_stress_ordered.pgbench
pgbench -d nexora_db -c 10 -j 2 -t 200 -f portfolio-3-transactions-concurrency/sql/05_stress_unordered.pgbench
psql -d nexora_db -f portfolio-3-transactions-concurrency/sql/06_integrity_check.sql

# STEP 4: Verify Portfolio 4 (MongoDB Atlas NoSQL Store)
mongosh "<YOUR_ATLAS_URI>/nexora_db" portfolio-4-nosql/script/01_schema_validation.js
mongosh "<YOUR_ATLAS_URI>/nexora_db" portfolio-4-nosql/script/02_seed_data.js
mongosh "<YOUR_ATLAS_URI>/nexora_db" portfolio-4-nosql/script/03_crud_and_aggregation.js
mongosh "<YOUR_ATLAS_URI>/nexora_db" portfolio-4-nosql/script/04_indexes_explain.js

# STEP 5: Verify Portfolio 5 (Distributed Streaming Replication)
cd portfolio-5-distributed-cloud
docker compose up -d
sleep 3
psql -h localhost -p 5433 -U postgres -d nexora_db -f 01_primary_checks.sql
psql -h localhost -p 5434 -U postgres -d nexora_db -f 02_replica_checks.sql
psql -h localhost -p 5433 -U postgres -d nexora_db -f 03_partitioning.sql
docker compose down -v
```

---

## 5. Academic Governance & Provenance Links

- **Institutional Generative AI Declaration:**  
  👉 [Bamishaye_Favour_AI_Use_Declaration.md](Bamishaye_Favour_AI_Use_Declaration.md) *(Strictly adheres to Section 11 of university guidelines).*
- **Academic and Industry Bibliography:**  
  👉 [Bamishaye_Favour_References.md](Bamishaye_Favour_References.md) *(16 formal citations including Codd, Gray, Coffman, Brewer, Kleppmann).*
- **Final Synthesis Report:**  
  👉 [Bamishaye_Favour_Final_Report.md](Bamishaye_Favour_Final_Report.md) *(2–3 page executive summary and technical reflection).*
- **Standalone Submission Catalog:**  
  👉 [Bamishaye_Favour_README.txt](Bamishaye_Favour_README.txt) *(Plain-text submission index for Field 3).*
- **GitHub Repository Access:**  
  Live repository URL: [https://github.com/favour-bam/MIT-8103---Advanced-Database-Portfolio](https://github.com/favour-bam/MIT-8103---Advanced-Database-Portfolio) (Publicly accessible to assessor).
