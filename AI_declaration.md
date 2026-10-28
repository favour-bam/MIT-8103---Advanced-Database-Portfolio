# Academic Artificial Intelligence (AI) Declaration

**Course:** MIT 8103 – Advanced Database Systems  
**Student Name:** Bamishaye Favour  
**Student ID:** 301915930  
**Project Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**Date of Submission:** 28th October 2026  
**Artifact:** `AI_declaration.md`  

---

## 1. Formal Declaration of Generative AI Usage

In accordance with institutional academic integrity policies and professional engineering standards, I, **Bamishaye Favour (Student ID: 301915930)**, hereby declare that Generative Artificial Intelligence (AI) tools were utilized in a controlled, assistive, and ethical capacity during the design, implementation, and evaluation of **Portfolios 1 through 5**.

The core architectural models, relational entity designs (3NF and controlled denormalisation), transactional concurrency controls, performance benchmarks, and theoretical analyses represent my own original intellectual work and understanding. AI was employed specifically as an accelerator for:
1. **Generating large-scale synthetic seed data** for PostgreSQL and MongoDB to simulate realistic production workloads.
2. **Authoring and simulating automated diagnostic checks, constraint tests, and database integrity validation scripts** across all five portfolios.

---

## 2. Detailed Scope of AI Assistance Across Portfolios

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              AI ASSISTANCE BREAKDOWN                                   │
├──────────────┬──────────────────────────────┬──────────────────────────────────────────┤
│ Portfolio    │ Area of Application          │ Purpose & Specific Artifacts             │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ **Port 1**   │ • PostgreSQL Synthetic Seed  │ Formulated `04_seed_data.sql` with       │
│              │ • Constraint & Health Checks │ `setseed(0.42)` (5k customers, 6k wallets│
│              │                              │ 206k transactions, 400k+ ledger entries).│
│              │                              │ Simulated 10 PL/pgSQL constraint tests   │
│              │                              │ (`03_constraint_tests.sql`) and 7 audits.│
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ **Port 2**   │ • Query Profiling Automation │ Assisted in generating diagnostic scripts│
│              │ • Write Amplification Checks │ for capturing `EXPLAIN (ANALYZE, BUFFERS)│
│              │                              │ and quantifying secondary index overhead │
│              │                              │ (`01_capture_plans.sql`, `write_cost`).  │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ **Port 3**   │ • Concurrency Stress Tests   │ Generated synthetic concurrency workloads│
│              │ • Invariant Audit Scripts    │ (`.pgbench` scripts) and simulated money │
│              │                              │ conservation checks (`06_integrity_check`│
│              │                              │ proving constant ₦1,000,000,000,000.00). │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ **Port 4**   │ • MongoDB Synthetic Seed     │ Formulated deterministic LCG script      │
│              │ • Schema Validation Checks   │ (`02_seed_data.js`, `seedState = 42`) for│
│              │ • Aggregation Diagnostics    │ 5k KYC profiles and 100k audit events.   │
│              │                              │ Generated validation error simulations.  │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ **Port 5**   │ • Replication Diagnostics    │ Assisted in authoring replication health │
│              │ • Chaos & Lag Simulation     │ checks (`01_primary_checks.sql`,         │
│              │ • Cloud Quorum Checks        │ `02_replica_checks.sql`), replica freeze │
│              │                              │ routines, and Atlas test script (04).    │
└──────────────┴──────────────────────────────┴──────────────────────────────────────────┘
```

---

## 3. Specific Declarations by Functional Area

### 3.1. Synthetic Seed Data Generation (PostgreSQL & MongoDB)
Generating realistic, production-scale financial data manually is impractical and prone to unrealistic uniformity. AI was leveraged to formulate mathematical data generators:

- **PostgreSQL Seeding (`04_seed_data.sql`, `nexora_dump.sql`):**
  - **Tool Role:** Generated PL/pgSQL iterative routines utilizing PostgreSQL’s deterministic pseudorandom generator `setseed(0.42)`.
  - **Data Shape Produced:** Created 1 internal liquidity provider, 5,000 realistic individual and merchant customer profiles, 6,003 accounts, KYC records with realistic verification states, 206,096 wallet transactions spanning a 360-day historical window, and 412,046 double-entry ledger entries.
  - **Student Verification:** Audited double-entry balance arithmetic, foreign key consistency, non-negative balances, and verified that all account balances exactly matched their corresponding ledger sums.

- **MongoDB Seeding (`02_seed_data.js`):**
  - **Tool Role:** Formulated a deterministic Linear Congruential Generator (LCG) script with `seedState = 42` to produce polymorphic document structures in `mongosh`.
  - **Data Shape Produced:** Generated 5,000 multi-tiered `kyc_profiles` (Tier 1 BVN, Tier 2 NIN/Driver's License, Tier 3 Passport/Utility Bills) and 100,000 heterogeneous `audit_events` distributed across 6 distinct event types (`LOGIN_SUCCESS`, `LOGIN_FAILED`, `PIN_CHANGED`, `TRANSFER_INITIATED`, `KYC_UPGRADED`, `FRAUD_FLAG`).
  - **Student Verification:** Ran count validations, verified document schema conformance, and confirmed array length distributions.

---

### 3.2. Automated Diagnostic Checks & Integrity Simulations
AI was utilized to design, simulate, and structure comprehensive automated test suites to validate database robustness under failure conditions:

- **Constraint Enforcement & Boundary Testing:**
  - Automated unit tests in Portfolio 1 (`03_constraint_tests.sql`) simulating negative balance updates (`CHECK balance >= 0`), malformed account number regexes, zero-amount transfers, and orphan ledger deletions (`ON DELETE RESTRICT`).
  - Negative testing in Portfolio 4 (`01_schema_validation.js`) intentionally inserting invalid KYC documents to verify that MongoDB’s `$jsonSchema` engine rejects malformed documents with error code `121` (`DocumentValidationFailure`).

- **Mathematical Conservation & Double-Entry Ledger Reconciliation:**
  - Verification queries in Portfolio 1 (`05_verify_seed.sql`) and Portfolio 3 (`06_integrity_check.sql`) verifying that total system money remained conserved at exactly ₦1,000,000,000,000.00, and confirming zero unbalanced journal entries ($\sum \text{Debits} - \sum \text{Credits} = 0$).

- **Concurrency, Stress, and Deadlock Testing:**
  - Designed `pgbench` stress scripts in Portfolio 3 (`04_stress_ordered.pgbench` and `05_stress_unordered.pgbench`) simulating 10 concurrent database sessions, demonstrating how canonical ordered locking eliminates deadlocks while unordered locking causes 62 deadlocks and throughput collapse.

- **Distributed Replication, Partitioning & Cloud Quorum Checks:**
  - Formulated healthcheck queries (`01_primary_checks.sql` and `02_replica_checks.sql`) in Portfolio 5 to inspect `pg_stat_replication`, physical replication slots (`replica1_slot`), and WAL Log Sequence Numbers (LSN).
  - Simulated replication lag and stale reads by freezing the standby container via `docker pause`, capturing catch-up convergence upon unfreezing.
  - Simulated CAP availability degradation (write hang) under synchronous replication mode.
  - Scripted partition pruning tests (`03_partitioning.sql`) and cloud quorum checks on MongoDB Atlas (`04_atlas_cloud_check.js`) verifying `w: 'majority'`, `readPref('secondary')`, and `readConcern('majority')`.

---

## 4. Human-in-the-Loop Verification & Originality Confirmation

Every script, query, configuration file, and diagnostic test assisted by Generative AI was subjected to strict **Human-in-the-Loop (HITL)** engineering oversight:

1. **Independent Verification:** All code and SQL/MQL logic was reviewed line-by-line, debugged, and validated against official PostgreSQL 16 and MongoDB Atlas technical documentation.
2. **Empirical Execution:** All scripts were executed on physical test environments (Apple Silicon macOS running PostgreSQL 16 via pgAdmin/psql, Docker Compose multi-container clusters, and live MongoDB Atlas cloud clusters).
3. **Evidence Authenticity:** Every screenshot in the `screenshots/` directories and every execution transcript in the `output/` directories reflects an authentic, un-manipulated empirical run conducted by the student.
4. **Analytical Authorship:** All explanations, architectural justifications, theoretical proofs, and conclusions presented in the `README.md`, `normalisation.md`, `performance-analysis.md`, `analysis.md`, `nosql-model-design.md`, and `sql-vs-nosql-rational.md` documents were authored, synthesized, and defended by the student.

---

## 5. Affirmation

I affirm that the description above accurately and honestly reflects the nature and extent of Generative AI usage in this course project. I accept full personal and academic responsibility for the integrity, correctness, and presentation of all submitted work.

**Student Name:** Bamishaye Favour  
**Student ID:** 301915930  
**Signature:** *Bamishaye Favour*  
**Date:** October 28, 2026  
