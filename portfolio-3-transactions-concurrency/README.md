# Portfolio 3: Transactions, Concurrency, and Isolation

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Favour Bamishaye (ID: 301915930)  
**Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**DBMS:** PostgreSQL 16 / 18 (administered via pgAdmin 4 & `psql`)  
**Database:** `nexora_db`  
**Scale:** ~5,000 customers, 6,000 wallets, 206,000+ transactions, 400,000+ ledger entries  

---

## 1. Overview

Portfolio 3 examines **transaction management, concurrency control, and isolation guarantees** within the simulated **Nexora** double-entry payments engine.

In financial applications, concurrent transfers must execute with strict atomicity and consistency. Lacking proper synchronization, concurrent requests risk lost updates, double-spending, and deadlocks. This portfolio implements and empirically validates:
1. **The `transfer_funds()` stored procedure:** An atomic, idempotent, deadlock-safe double-entry fund transfer engine.
2. **ACID Lifecycle Demonstrations:** Controlled tests proving atomicity, commit persistence, rollback restoration, automatic failure rollback, and savepoint sub-transactions.
3. **Deadlock Elimination via Canonical Ordered Locking:** Mathematical elimination of circular wait conditions using `LEAST/GREATEST` primary key ordering.
4. **Empirical Stress Testing with `pgbench`:** Comparing ordered locking (5,977.72 TPS, 0% failure) against naive unordered locking (39.38 TPS, 62 deadlocks).
5. **System Invariant & Conservation Auditing:** Verifying that total system currency (₦1,000,000,000,000.00) is conserved across all concurrent workloads.
6. **Independent Experiment on `lock_timeout`:** Evaluating fail-fast timeout mechanisms to prevent connection pool starvation.

For detailed mathematical proofs, plan breakdowns, and transaction diagrams, see the full analysis report:  
👉 **[analysis.md](analysis.md)**  
👉 **[own_experiment.md](own_experiment.md)**

---

## 2. Directory Structure

```
portfolio-3-transactions-concurrency/
├── README.md                      # This portfolio overview and execution guide
├── analysis.md                    # In-depth technical report on transactions & concurrency
├── own_experiment.md              # Independent experiment on lock_timeout
├── sql/                           # SQL routines, DDL, and pgbench benchmark scripts
│   ├── 01_transfer_function.sql   # transfer_funds() and transfer_funds_unordered()
│   ├── 02_demo_setup.sql          # Creates Demo Alice and Bob wallets (reset to 500.00)
│   ├── 03_commit_rollback_demo.sql# Interactive psql script demonstrating ACID & savepoints
│   ├── 04_stress_ordered.pgbench  # pgbench script for canonical ordered locking
│   ├── 05_stress_unordered.pgbench# pgbench script for flawed unordered locking
│   └── 06_integrity_check.sql     # 5 diagnostic queries checking invariants & ledger balance
├── output/                        # Raw terminal outputs and benchmark logs
│   ├── 03_commit_rollback_output.txt
│   ├── integrity_before.txt
│   ├── stress_ordered.txt
│   ├── integrity_after_ordered.txt
│   ├── stress_unordered.txt
│   └── integrity_after_unordered.txt
└── screenshots/                   # Visual verification screenshots from pgAdmin & psql
```

---

## 3. SQL & Benchmark Scripts Manifest

| File | Purpose | Description |
| :--- | :--- | :--- |
| [`sql/01_transfer_function.sql`](sql/01_transfer_function.sql) | DDL / Stored Functions | Defines `transfer_funds()` (canonical ordered locking) and `transfer_funds_unordered()` (demonstration function exposing deadlock vulnerability). |
| [`sql/02_demo_setup.sql`](sql/02_demo_setup.sql) | Test Environment | Inserts or resets Demo Alice (`9000000001`) and Demo Bob (`9000000002`) to ₦500.00 each for isolated lock tests. |
| [`sql/03_commit_rollback_demo.sql`](sql/03_commit_rollback_demo.sql) | ACID Verification | Interactive `psql` runner testing 5 core transactional behaviors: explicit COMMIT, explicit ROLLBACK, automatic rollback on failure, idempotency replay, and SAVEPOINTS. |
| [`sql/04_stress_ordered.pgbench`](sql/04_stress_ordered.pgbench) | Concurrency Benchmark | Generates random bidirectional P2P transfers across 20 accounts using deadlock-safe `transfer_funds()`. |
| [`sql/05_stress_unordered.pgbench`](sql/05_stress_unordered.pgbench) | Stress Vulnerability | Runs identical transfer traffic using `transfer_funds_unordered()` to demonstrate circular wait deadlocks. |
| [`sql/06_integrity_check.sql`](sql/06_integrity_check.sql) | Post-Test Audit | Runs 5 system invariant checks: total system money conservation, stress ledger counts, double-entry balancing ($\sum \text{Debits} = \sum \text{Credits}$), cached balance agreement, and pending transaction audit. |

---

## 4. How to Run the Portfolio 3 Suite

Execute the scripts using `psql` and `pgbench`:

```bash
# 1. Deploy the transfer functions
psql -d nexora_db -f sql/01_transfer_function.sql

# 2. Run the ACID lifecycle and rollback demonstrations
psql -d nexora_db -f sql/03_commit_rollback_demo.sql > output/03_commit_rollback_output.txt

# 3. Check baseline system integrity before stress tests
psql -d nexora_db -f sql/06_integrity_check.sql > output/integrity_before.txt

# 4. Run the Deadlock-Safe Stress Test (10 clients, 4 threads, 2000 transactions)
pgbench -d nexora_db -f sql/04_stress_ordered.pgbench -c 10 -j 4 -t 200 > output/stress_ordered.txt

# 5. Check system integrity after ordered stress run
psql -d nexora_db -f sql/06_integrity_check.sql > output/integrity_after_ordered.txt

# 6. Run the Unordered Stress Test (demonstrating deadlock failures)
pgbench -d nexora_db -f sql/05_stress_unordered.pgbench -c 10 -j 4 -t 200 > output/stress_unordered.txt

# 7. Check final system integrity after unordered run
psql -d nexora_db -f sql/06_integrity_check.sql > output/integrity_after_unordered.txt
```

---

## 5. Key Experimental Findings

### 5.1. Concurrency Stress Benchmark (`pgbench`)

| Metric | Ordered Locking (`transfer_funds`) | Unordered Locking (`transfer_funds_unordered`) | Variance / Impact |
| :--- | :--- | :--- | :--- |
| **Transactions Processed** | **2,000 / 2,000 (100%)** | 1,938 / 2,000 (96.9%) | Ordered locking achieved 100% completion |
| **Failed Transactions** | **0 (0.000%)** | **62 (3.100%)** | **Zero deadlocks with ordered locking** |
| **Average Latency** | **1.673 ms** | **246.090 ms** | **147.1x lower latency** |
| **Throughput (TPS)** | **5,977.72 TPS** | **39.38 TPS** | **151.8x higher throughput** |
| **Deadlock Root Cause** | Eliminated via `LEAST / GREATEST` | Circular wait ($A \to B$ vs. $B \to A$) | Mathematical DAG enforcement prevents cycles |

### 5.2. System Invariant & Integrity Verification

Across all runs (baseline, ordered, and unordered stress tests):
- **Total Money in System:** Exactly **₦1,000,000,000,000.0000** (conserved across all transfers).
- **Unbalanced Transactions:** **0** (every transaction has $\sum \text{Debits} - \sum \text{Credits} = 0$).
- **Mismatched Balances:** **0** (cached `accounts.balance` matches ledger totals for all accounts).
- **Stuck Pending Transactions:** **0** (all transactions achieved terminal `COMPLETED` or were cleanly rolled back).

---

## 6. Screenshots & Visual Evidence Catalog

Visual evidence captured during terminal and pgAdmin 4 execution is located in [`screenshots/`](screenshots/):

| Screenshot File | Step & Operational Verification |
| :--- | :--- |
| `Bamishaye_Favour_301915930_STF.png` | Deployment of `transfer_funds()` stored procedure in pgAdmin. |
| `Bamishaye_Favour_301915930_transfer_demo.png` | Single transfer demonstration verifying balance and double-entry ledger lines. |
| `Bamishaye_Favour_301915930_commit_rollback_output.png` | Execution of `03_commit_rollback_demo.sql` (commit, rollback, idempotency, and savepoints). |
| `Bamishaye_Favour_301915930_integrity_before.png` | Baseline integrity check verifying ₦1T system money and 0 errors. |
| `Bamishaye_Favour_301915930_stress_ordered.png` | `pgbench` ordered stress test output showing 5,977.72 TPS and 0 failed transactions. |
| `Bamishaye_Favour_301915930_integrity_after_ordered.png` | Integrity audit after ordered stress test (2,000 transfers, 4,000 ledger lines, 0 errors). |
| `Bamishaye_Favour_301915930_unordered_locking.png` | `pgbench` unordered stress test showing deadlocks, 62 failed transactions, and 39.38 TPS. |
| `Bamishaye_Favour_301915930_integrity_after_unordered_locking.png` | Integrity audit confirming complete rollback of failed transactions. |
| `Bamishaye_Favour_301915930_lock_timeout.png` | Independent experiment demonstrating `lock_timeout = '2s'` fail-fast cancellation. |
| `Bamishaye_Favour_301915930_experiment_lost_update_01.png` | Concurrency experiment showing concurrent balance reads. |
| `Bamishaye_Favour_301915930_experiment_lost_update_02.png` | Concurrency experiment demonstrating lost update prevention via `FOR UPDATE`. |
