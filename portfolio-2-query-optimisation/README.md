# Portfolio 2: Query Optimisation and Performance Tuning

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Favour Bamishaye (ID: 301915930)  
**Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**DBMS:** PostgreSQL 16 / 18 (managed via pgAdmin 4 & `psql`)  
**Database:** `nexora_db`  
**Scale:** ~5,000 customers, 6,001 accounts, 206,096 transactions, 404,162 ledger entries  

---

## 1. Overview

Portfolio 2 focuses on evaluating, diagnosing, and optimizing database performance for the simulated **Nexora** double-entry financial platform. 

The portfolio benchmarks 9 representative queries spanning real-time mobile customer endpoints, executive treasury dashboards, AML fraud detection, compliance reconciliation, and accounting integrity audits. Through systematic `EXPLAIN (ANALYZE, BUFFERS)` profiling, we evaluate:
- The performance limitations of baseline unindexed schemas (table scans, in-memory quicksorts, disk-based external merge sorts).
- Advanced B-tree indexing techniques: composite ordering (`equality, sort DESC`), foreign key indexing, partial indexing, and covering indexes with `INCLUDE` clauses for zero-heap `Index Only Scans`.
- PostgreSQL cost planner mechanics, cost constants, GUC optimizer toggles, and selectivity tipping points.
- The join fan-out trap in double-entry ledgers.
- The storage and write amplification trade-offs of secondary indexes.

For the exhaustive mathematical analysis, plan breakdowns, and planner experiments, see the full report:  
👉 **[performance-analysis.md](performance-analysis.md)**

---

## 2. Directory Structure

```
portfolio-2-query-optimisation/
├── README.md                     # This portfolio guide and index
├── performance-analysis.md       # Comprehensive performance benchmarking report
├── queries/                      # The 9 benchmark queries (Q1 to Q9)
│   ├── q01_account_statement.sql
│   ├── q02_daily_transfer_totals.sql
│   ├── q03_customer_largest_transfers.sql
│   ├── q04_large_transfer_fraud.sql
│   ├── q05_idempotency_lookup.sql
│   ├── q06_balance_reconciliation.sql
│   ├── q07_unbalanced_journals.sql
│   ├── q08_net_movement_reversals.sql
│   └── q09_join_fanout_trap.sql
├── sql/                          # Benchmarking, index management, and planner test scripts
│   ├── 01_capture_plans.sql      # Captures EXPLAIN (ANALYZE, BUFFERS) for all queries
│   ├── 02_query_results.sql      # Executes queries to verify output correctness
│   ├── 03_create_indexes.sql     # Deploys optimized secondary, partial, and covering indexes
│   ├── 04_drop_indexes.sql       # Drops custom indexes to reset baseline
│   ├── 05_planner_experiments.sql# GUC toggle and selectivity experiments
│   └── 06_write_cost.sql         # Quantifies storage and write amplification overhead
├── plans/                        # Raw execution plan outputs and logs
│   ├── before.txt                # Baseline execution plans (unindexed)
│   ├── after.txt                 # Optimized execution plans (indexed)
│   ├── planner.txt               # Cost settings, table stats, and planner experiments
│   └── results.txt               # Query execution results
└── screenshots/                  # pgAdmin 4 visual verification screenshots
```

---

## 3. The 9 Benchmark Queries

| Query | File | Business Workload & Description |
| :--- | :--- | :--- |
| **Q1** | [`q01_account_statement.sql`](queries/q01_account_statement.sql) | Mobile account statement: 50 most recent ledger entries for an account with transaction details. |
| **Q2** | [`q02_daily_transfer_totals.sql`](queries/q02_daily_transfer_totals.sql) | Finance executive dashboard: daily completed transfer volumes and amounts over the last 30 days. |
| **Q3** | [`q03_customer_largest_transfers.sql`](queries/q03_customer_largest_transfers.sql) | Dispute resolution: 10 largest outgoing debit transfers for a customer across a 3-table join. |
| **Q4** | [`q04_large_transfer_fraud.sql`](queries/q04_large_transfer_fraud.sql) | AML compliance review: customers with the most high-value debits ($\ge$ ₦4,000) over 90 days. |
| **Q5** | [`q05_idempotency_lookup.sql`](queries/q05_idempotency_lookup.sql) | **Control query:** API idempotency key check (demonstrates intrinsic indexes created by constraints). |
| **Q6** | [`q06_balance_reconciliation.sql`](queries/q06_balance_reconciliation.sql) | Audit query: compares cached `accounts.balance` against the latest `balance_after` in `ledger_entries`. |
| **Q7** | [`q07_unbalanced_journals.sql`](queries/q07_unbalanced_journals.sql) | Accounting invariant audit: verifies that $\sum \text{Debits} = \sum \text{Credits}$ for every transaction. |
| **Q8** | [`q08_net_movement_reversals.sql`](queries/q08_net_movement_reversals.sql) | Treasury report: net completed transfers, reversed transfers, and failed transfers over 90 days. |
| **Q9** | [`q09_join_fanout_trap.sql`](queries/q09_join_fanout_trap.sql) | **Correctness diagnostic:** demonstrates the join fan-out trap when summing 1:N joined ledgers. |

---

## 4. Execution & Benchmarking Workflow

To reproduce the benchmark results using `psql` or pgAdmin 4, execute the scripts in the following order:

```bash
# 1. Reset database to baseline (drop any existing secondary indexes)
psql -d nexora_db -f sql/04_drop_indexes.sql

# 2. Capture baseline execution plans (outputs to plans/before.txt)
psql -d nexora_db -f sql/01_capture_plans.sql > plans/before.txt

# 3. Create optimized secondary, partial, and covering indexes
psql -d nexora_db -f sql/03_create_indexes.sql

# 4. Capture optimized execution plans (outputs to plans/after.txt)
psql -d nexora_db -f sql/01_capture_plans.sql > plans/after.txt

# 5. Run planner experiments & selectivity tests (outputs to plans/planner.txt)
psql -d nexora_db -f sql/05_planner_experiments.sql > plans/planner.txt

# 6. Evaluate index write overhead and storage consumption
psql -d nexora_db -f sql/06_write_cost.sql
```

---

## 5. Performance Optimization Highlights

| Query | Baseline Execution Time | Optimized Execution Time | Speedup Factor | Buffer Memory I/O Reduction | Key Optimization Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Q1** | 591.66 ms | **10.16 ms** | **58.2x** | **94.2%** (4,416 $\to$ 256 buffers) | Composite B-tree index `(account_id, created_at DESC)` eliminates table scan and quicksort. |
| **Q2** | 389.22 ms | **22.82 ms** | **17.1x** | **98.0%** (3,223 $\to$ 65 buffers) | Partial covering index `(initiated_at) INCLUDE (amount)` enables zero-heap Index Only Scan. |
| **Q3** | 66.96 ms | **0.51 ms** | **131.0x** | **96.2%** (4,660 $\to$ 179 buffers) | Foreign key index on `accounts(customer_id)` converts table scan to direct index lookup. |
| **Q4** | 39.61 ms | **41.03 ms** | CPU-bound | **96.1%** (4,542 $\to$ 176 buffers) | Partial index on debits $\ge$ 4000 reduces scanned pages by 96%, shifting query from I/O to memory. |
| **Q5** | 0.019 ms | **0.039 ms** | 1.0x | 0% (4 buffers) | Control query: already indexed by `UNIQUE (idempotency_key)` constraint. |
| **Q6** | 292.96 ms | **394.33 ms** | Disk save | **100% disk sort eliminated** | Incremental sort replaces 19.6 MB temporary disk spill with in-memory 26 KB quicksort. |
| **Q7** | 530.94 ms | **326.71 ms** | **1.62x** | Aligned | Merge Left Join leverages natural composite key ordering on `transaction_id`. |
| **Q8** | 30.10 ms | **10.31 ms** | **2.92x** | **87.0%** (3,147 $\to$ 409 buffers) | Multi-column covering index `(txn_type, initiated_at) INCLUDE (status, amount)`. |

---

## 6. Deployed Secondary Indexes Catalog

```sql
-- 1. High-frequency account history index (12 MB)
CREATE INDEX idx_ledger_account_created
   ON ledger_entries (account_id, created_at DESC);

-- 2. Foreign key lookup index (176 KB)
CREATE INDEX idx_accounts_customer
   ON accounts (customer_id);

-- 3. Compact partial covering index for completed transfers (2.2 MB)
CREATE INDEX idx_txn_completed_transfers_time
   ON transactions (initiated_at) INCLUDE (amount)
   WHERE txn_type = 'TRANSFER' AND status = 'COMPLETED';

-- 4. Selective partial covering index for high-value AML debits (800 KB)
CREATE INDEX idx_ledger_large_debits
   ON ledger_entries (created_at) INCLUDE (account_id, amount)
   WHERE direction = 'DEBIT' AND amount >= 4000;

-- 5. Multi-status covering index for treasury movement (8.1 MB)
CREATE INDEX idx_txn_type_time_cover
   ON transactions (txn_type, initiated_at) INCLUDE (status, amount);
```

---

## 7. Screenshots & Evidence Catalog

Visual verification screenshots captured in pgAdmin 4 are organized in the [`screenshots/`](screenshots/) directory:

| Screenshot File | Content & Verification Step |
| :--- | :--- |
| `Bamishaye_Favour_301915930_baseline_plans.png` | Baseline unindexed execution plans (Sequential Scans and high execution costs). |
| `Bamishaye_Favour_301915930_indexes.png` | Deployment of the 5 custom secondary and partial indexes in pgAdmin. |
| `Bamishaye_Favour_301915930_after_indexes.png` | Optimized execution plans showing Index Scans, Index Only Scans, and reduced costs. |
| `Bamishaye_Favour_301915930_account_statement.png` | Q1 account statement query execution and row outputs. |
| `Bamishaye_Favour_301915930_account_statement_plan.png` | Q1 graphical/text execution plan comparing sequential scan vs. index scan. |
| `Bamishaye_Favour_301915930_account_statement_analyze.png` | Q1 `EXPLAIN ANALYZE` metrics showing drop to 10.16 ms. |
| `Bamishaye_Favour_301915930_customer_largest_transfer.png` | Q3 customer largest transfer query execution. |
| `Bamishaye_Favour_301915930_customer_largest_transfers_before_plan.png` | Q3 before optimization execution plan (Hash Join + Seq Scans). |
| `Bamishaye_Favour_301915930_customer_largest_transfers_before_analysis.png` | Q3 before optimization `EXPLAIN ANALYZE` execution time (66.96 ms). |
| `Bamishaye_Favour_301915930_customer_largest_transfers_after_plan.png` | Q3 after optimization execution plan (Index Scans + Nested Loops). |
| `Bamishaye_Favour_301915930_customer_largest_transfers_after_analyze.png` | Q3 after optimization `EXPLAIN ANALYZE` execution time (0.51 ms). |
| `Bamishaye_Favour_301915930_daily_transfer.png` | Q2 daily transfer totals query execution and 30-day grouped outputs. |
| `Bamishaye_Favour_301915930_idempotency_lookup.png` | Q5 idempotency key lookup verifying sub-millisecond constraint index scan. |
| `Bamishaye_Favour_301915930_balanvce_reconciliation.png` | Q6 balance reconciliation query returning 0 mismatched rows. |
| `Bamishaye_Favour_301915930_unbalanced_journals.png` | Q7 accounting double-entry invariant audit returning 0 unbalanced rows. |
| `Bamishaye_Favour_301915930_net_movement_reversals.png` | Q8 net transfer movement with reversal handling. |
| `Bamishaye_Favour_301915930_join_fanout_trap.png` | Q9 demonstration of the join fan-out trap (showing exact 2x duplicate total). |
| `Bamishaye_Favour_301915930_write_cost_measurement.png` | `06_write_cost.sql` table size comparison measuring index write footprint (33 MB vs 45 MB). |
| `Bamishaye_Favour_301915930_two_runner_scripts.png` | Runner script execution in terminal/pgAdmin. |
| `Bamishaye_Favour_301915930_data_check.png` | Post-seed data validation and table row count sanity check. |
