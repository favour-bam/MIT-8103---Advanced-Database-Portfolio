# Portfolio 2: Query Optimisation and Performance Analysis

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Favour Bamishaye (ID: 301915930)  
**Platform:** Nexora – Digital Savings & Financial Management Platform (Simulated)  
**DBMS:** PostgreSQL 16 / 18 (Apple Silicon `aarch64`, managed via pgAdmin 4 & `psql`)  
**Database:** `nexora_db`  
**Dataset Scale:** ~5,000 customers, 6,000 accounts, 206,000 transactions, 404,162 ledger entries  

---

## 1. Executive Summary

This study evaluates the query performance, execution plans, and indexing strategies for the **Nexora** double-entry financial platform. High-volume fintech applications demand sub-10ms latencies on user-facing endpoints (e.g., retrieving transaction history) while simultaneously running multi-month aggregation reports and end-of-day reconciliation audits.

By methodically analyzing query execution plans via `EXPLAIN (ANALYZE, BUFFERS)` before and after targeted index engineering, we achieved:
- **Up to 131x execution speedup** on core multi-table relational joins (from 66.96 ms down to 0.51 ms).
- **Over 58x execution speedup** on mobile account statement generation (from 591.66 ms down to 10.16 ms).
- **Up to 98% reduction in buffer memory I/O** (e.g., buffer hits falling from 3,223 pages to 65 pages on daily aggregation).
- **Zero-disk spill sorting** on end-of-day reconciliation through incremental index sorting.
- **Quantification of index write overhead and storage footprint** (~36% storage increase on the ledger).

---

## 2. Benchmark Environment & Planner Configuration

All benchmarks were captured directly from `nexora_db` using PostgreSQL cost and buffer telemetry.

### 2.1. Planner Configuration Settings (`SHOW ...`)

| Parameter | Configured Value | Description & Planner Impact |
| :--- | :--- | :--- |
| `block_size` | `8192` (8 KB) | Standard PostgreSQL disk page allocation. |
| `shared_buffers` | `128 MB` | Dedicated shared memory pool for cached table and index pages. |
| `work_mem` | `4 MB` | Memory available for internal sort and hash operations before spilling to temporary disk. |
| `seq_page_cost` | `1.0` | Cost of sequentially reading one disk page. Baseline metric. |
| `random_page_cost` | `4.0` | Cost of non-sequential disk access. 4x higher than sequential scans, modeling rotational disk seek latency. |
| `cpu_tuple_cost` | `0.01` | CPU processing cost per row retrieved. |

### 2.2. Table & Relation Sizing (`05_planner_experiments.sql`)

Prior to index creation, the baseline table and constraint footprint was recorded as follows:

| Relation Name | Type | 8 KB Pages (`relpages`) | Estimated Rows (`reltuples`) | Total Size |
| :--- | :--- | :--- | :--- | :--- |
| **`ledger_entries`** | Table | 4,167 | 404,162 | **33 MB** |
| **`transactions`** | Table | 3,147 | 206,096 | **25 MB** |
| `ledger_entries_transaction_id_account_id_direction_key` | Index (Unique) | 2,010 | 404,162 | 16 MB |
| `transactions_idempotency_key_key` | Index (Unique) | 1,552 | 206,096 | 12 MB |
| `ledger_entries_pkey` | Index (PK) | 1,111 | 404,162 | 8.8 MB |
| `transactions_pkey` | Index (PK) | 567 | 206,096 | 4.5 MB |
| `beneficiaries` | Table | 153 | 15,000 | 1.2 MB |
| `accounts` | Table | 124 | 6,001 | 992 KB |
| `customers` | Table | 69 | 5,001 | 552 KB |
| `kyc_records` | Table | 59 | 5,100 | 472 KB |

---

## 3. The 9 Benchmark Queries & Business Rationale

The benchmark evaluates 9 representative operational queries representing different transactional and reporting workloads:

1. **`Q1` Account Statement:** Customer opens transaction history on mobile app (50 most recent ledger entries for an account).
2. **`Q2` Daily Transfer Totals:** Finance executive dashboard displaying daily completed transfer sums over the last 30 days.
3. **`Q3` Customer Largest Transfers:** Customer support investigating disputes by joining customer accounts, debits, and transaction headers.
4. **`Q4` Large Transfer Fraud Analysis:** Compliance team's 90-day review list of accounts with high-frequency transfers $\ge$ ₦4,000.
5. **`Q5` Idempotency Lookup (Control):** API gateway checking if an incoming transfer idempotency key was already processed.
6. **`Q6` End-of-Day Balance Reconciliation:** Audit query verifying that cached `accounts.balance` equals `balance_after` of the latest ledger row.
7. **`Q7` Unbalanced Journals Audit:** Core accounting invariant query verifying $\sum \text{Debits} = \sum \text{Credits}$ for all completed transactions.
8. **`Q8` Net Transfer Movement (Reversal-Aware):** Treasury report aggregating net completed, reversed, and failed transfers over 90 days.
9. **`Q9` Join Fan-Out Trap (Correctness):** Pedagogical benchmark showing the danger of summing 1:N joined headers.

---

## 4. Index Architecture & Engineering Design

Five custom indexes were designed and deployed via `03_create_indexes.sql`:

```sql
-- Index 1: Composite B-tree for time-ordered account queries (Q1, Q3, Q6)
CREATE INDEX idx_ledger_account_created
   ON ledger_entries (account_id, created_at DESC);

-- Index 2: Foreign key index for customer-to-account lookups (Q3)
CREATE INDEX idx_accounts_customer
   ON accounts (customer_id);

-- Index 3: Partial covering index for completed transfers in last 30 days (Q2)
CREATE INDEX idx_txn_completed_transfers_time
   ON transactions (initiated_at) INCLUDE (amount)
   WHERE txn_type = 'TRANSFER' AND status = 'COMPLETED';

-- Index 4: Selective partial covering index for high-value debits (Q4)
CREATE INDEX idx_ledger_large_debits
   ON ledger_entries (created_at) INCLUDE (account_id, amount)
   WHERE direction = 'DEBIT' AND amount >= 4000;

-- Index 5: Multi-status covering index for treasury movement (Q8)
CREATE INDEX idx_txn_type_time_cover
   ON transactions (txn_type, initiated_at) INCLUDE (status, amount);
```

### Architectural Principles Applied:
- **Equality Precedes Range/Sort:** In `idx_ledger_account_created`, `account_id` (exact match equality) comes first, followed by `created_at DESC`. This allows PostgreSQL to seek directly to the account's branch in the B-tree and stream pre-sorted records without invoking an in-memory quicksort.
- **Foreign Key Indexing:** PostgreSQL does **not** automatically index foreign key columns. `idx_accounts_customer` resolves the sequential scan bottleneck when traversing `customers -> accounts`.
- **Partial Indexing:** Restricting `idx_txn_completed_transfers_time` to `WHERE txn_type = 'TRANSFER' AND status = 'COMPLETED'` reduced the index tree size to just 2 MB, excluding irrelevant deposits, bill payments, and failed attempts.
- **Index-Only Scans (`INCLUDE` clause):** By appending `INCLUDE (amount)` to B-tree leaf pages, PostgreSQL reads the aggregate payload directly from the index without touching the heap table pages (`Heap Fetches: 0`).

---

## 5. Before vs. After Performance Analysis

### 5.1. Comparative Summary Matrix

| Query | Metric | Baseline (Before) | Optimized (After) | Improvement Factor |
| :--- | :--- | :--- | :--- | :--- |
| **Q1: Account Statement** | Exec Time<br>Buffer Hits<br>Cost Estimate | 591.66 ms<br>4,416 pages<br>7,512.32..7,518.14 | **10.16 ms**<br>**256 pages**<br>9.14..625.52 | **58.2x faster**<br>**94.2% I/O reduction**<br>Cost down by 91.7% |
| **Q2: Daily Transfer Totals** | Exec Time<br>Buffer Hits<br>Cost Estimate | 389.22 ms<br>3,223 pages<br>6,509.05..8,685.96 | **22.82 ms**<br>**65 pages**<br>1,648.43..2,039.85 | **17.1x faster**<br>**98.0% I/O reduction**<br>Cost down by 76.5% |
| **Q3: Customer Largest Transfers** | Exec Time<br>Buffer Hits<br>Cost Estimate | 66.96 ms<br>4,660 pages<br>7,704.70..7,704.72 | **0.51 ms**<br>**179 pages**<br>278.73..278.75 | **131.0x faster**<br>**96.2% I/O reduction**<br>Cost down by 96.4% |
| **Q4: Large Transfer Fraud** | Exec Time<br>Buffer Hits<br>Cost Estimate | 39.61 ms<br>4,542 pages<br>10,583.10..10,583.12 | **41.03 ms**<br>**176 pages**<br>955.79..955.81 | **96.1% I/O reduction**<br>CPU-bound aggregation<br>Cost down by 91.0% |
| **Q5: Idempotency (Control)** | Exec Time<br>Buffer Hits | 0.019 ms<br>4 pages | 0.039 ms<br>4 pages | Sub-millisecond (baseline constraint index) |
| **Q6: Balance Reconciliation** | Exec Time<br>Sort Spill | 292.96 ms<br>19.6 MB spill to disk | 394.33 ms<br>**0 KB spill (Incremental)** | Zero-disk sort eliminates disk I/O thrashing |
| **Q7: Unbalanced Journals** | Exec Time<br>Buffer Hits | 530.94 ms<br>12,165 pages | **326.71 ms**<br>12,165 pages | **1.62x faster** via Merge Left Join alignment |
| **Q8: Net Movement (Reversals)**| Exec Time<br>Buffer Hits<br>Cost Estimate | 30.10 ms<br>3,147 pages<br>6,357.90..6,357.91 | **10.31 ms**<br>**409 pages**<br>3,756.04..3,756.05 | **2.92x faster**<br>**87.0% I/O reduction**<br>Cost down by 40.9% |

---

## 6. Deep Dive: Query Execution Plans

### 6.1. Q1 – Account Statement (`q01_account_statement.sql`)

```
BEFORE:  Parallel Seq Scan (404k ledger rows) -> Quicksort (28 rows/worker) -> Gather Merge -> Limit [591.66 ms]
AFTER:   Index Scan using idx_ledger_account_created -> Nested Loop -> Index Scan transactions_pkey [10.16 ms]
```

#### Detailed Breakdown
- **Before:** Lacking an index on `(account_id, created_at)`, PostgreSQL was forced to launch 2 parallel worker processes to perform a `Parallel Seq Scan` on all 404,162 rows of `ledger_entries`. The filter discarded 134,702 rows per worker, after which the gathered tuples were sorted in memory using quicksort. Execution took **591.66 ms** across 4,416 buffer pages.
- **After:** The composite index `idx_ledger_account_created (account_id, created_at DESC)` allowed PostgreSQL to perform an **Index Scan** directly on the target account. Because the index leaf nodes are already sorted by `created_at DESC`, the executor retrieved the first 50 rows in exact order without sorting! Buffer accesses dropped to **256 pages** and execution time plummeted to **10.16 ms** (a **58.2x improvement**).

---

### 6.2. Q2 – Daily Completed Transfer Totals (`q02_daily_transfer_totals.sql`)

```
BEFORE:  Parallel Seq Scan (206k txns) -> Filter (status, date) -> Sort -> GroupAggregate [389.22 ms]
AFTER:   Index Only Scan using idx_txn_completed_transfers_time -> Sort -> GroupAggregate [22.82 ms]
```

#### Detailed Breakdown
- **Before:** Scanning `transactions` required parallel sequential reads of 3,147 disk pages, filtering out 63,393 rows per worker that were not completed transfers within the 30-day window. Execution required **389.22 ms**.
- **After:** The query planner picked `idx_txn_completed_transfers_time`. Because the index is partial (`WHERE txn_type = 'TRANSFER' AND status = 'COMPLETED'`), the index only indexes the relevant subset. Because it includes `amount` via the `INCLUDE` clause, PostgreSQL executed an **Index Only Scan** with **zero heap fetches** (`Heap Fetches: 0`). Total buffer hits fell from 3,223 to **65 pages** (a **98% I/O reduction**), and latency dropped to **22.82 ms** (**17.1x speedup**).

---

### 6.3. Q3 – Customer Largest Transfers (`q03_customer_largest_transfers.sql`)

```
BEFORE:  Parallel Seq Scan (ledger_entries) + Seq Scan (accounts) -> Hash Join -> Top-N Heapsort [66.96 ms]
AFTER:   Index Scan (idx_accounts_customer) -> Bitmap Scan (idx_ledger_account_created) -> Nested Loop [0.51 ms]
```

#### Detailed Breakdown
- **Before:** `accounts` was scanned sequentially to find `customer_id = 1001` (6,000 rows filtered), and `ledger_entries` was scanned sequentially in parallel to filter `direction = 'DEBIT'` (67,360 rows per worker). These were hash joined and sorted via Top-N heapsort, taking **66.96 ms** and 4,660 buffer hits.
- **After:** PostgreSQL used `idx_accounts_customer` to immediately find the customer's account in 3 buffer hits, then performed a `Bitmap Index Scan` on `idx_ledger_account_created` to isolate only that account's ledger lines. It joined with `transactions_pkey` via a rapid Nested Loop. Execution time dropped to **0.511 ms** (**131x speedup**), with buffer hits reduced by **96.2%**.

---

### 6.4. Q4 – Large Transfer Fraud Analysis (`q04_large_transfer_fraud.sql`)

```
BEFORE:  Parallel Seq Scan (404k ledger rows) -> Hash Join accounts -> HashAggregate [39.61 ms, 4542 buffers]
AFTER:   Index Only Scan (idx_ledger_large_debits) -> Hash Join accounts -> HashAggregate [41.03 ms, 176 buffers]
```

#### Detailed Breakdown
- **Analysis of Trade-off:** The query filters for `amount >= 4000` and `created_at >= now() - interval '90 days'`. Before optimization, the engine performed a sequential scan over 4,167 pages, filtering out 131,408 non-matching rows per worker.
- **With Partial Index:** `idx_ledger_large_debits` reduced the buffer reads from 4,542 pages down to **176 pages** (**96.1% I/O reduction**). The execution time remained approximately 40 ms because the execution bottleneck transitioned entirely from I/O to CPU: hashing and aggregating 4,185 distinct customer groups in `HashAggregate` (1.68 MB memory). In a real production system where data exceeds RAM cache, saving 4,366 physical page reads per query is the difference between a responsive system and disk I/O saturation.

---

### 6.5. Q5 – Idempotency Lookup (Control Benchmark)

- `SELECT * FROM transactions WHERE idempotency_key = 'seed-xfer-12345';`
- Executed in **0.019 ms** (before) and **0.039 ms** (after).
- **Core Insight:** In `02_create_tables.sql`, `idempotency_key` was defined with a `UNIQUE` constraint. PostgreSQL automatically provisions a unique B-tree index (`transactions_idempotency_key_key`) to enforce uniqueness. This query serves as an experimental control, proving that constraint declarations intrinsically deliver high-performance indexing without manual index intervention.

---

### 6.6. Q6 – Balance Reconciliation & Sorting Mechanics (`q06_balance_reconciliation.sql`)

#### Memory Spills vs. Incremental Sorts
In `Q6`, the subquery calculates `DISTINCT ON (account_id) account_id, balance_after ORDER BY account_id, created_at DESC, entry_id DESC`:
- **Before:** To sort all 404,162 ledger entries without a suitable index, PostgreSQL exceeded `work_mem` (4 MB) and spilled **19,672 KB (19.6 MB)** of temporary data to disk using an **external merge sort** (`temp read=2459, written=2467`). Disk-based sorting is a major cause of disk write amplification.
- **After:** With `idx_ledger_account_created`, PostgreSQL detected that the records were already presorted by `(account_id, created_at)`. The query planner switched to an **Incremental Sort** (`Sort Method: quicksort, Peak Memory: 26 KB`). It performed localized sorting on tiny subsets sharing the same timestamp, completely eliminating temporary disk writes!

---

### 6.7. Q7 – Unbalanced Journals Audit (`q07_unbalanced_journals.sql`)

- The query verifies that total debits equal total credits for every completed or reversed transaction.
- **Result:** **0 rows returned**, confirming that the double-entry accounting invariant holds true across the entire 206,000 transaction dataset.
- **Execution Mechanism:** Both `transactions` and `ledger_entries` possessed indexes whose leading column was `transaction_id`. PostgreSQL executed a synchronized **Merge Left Join** in **326.71 ms** (down from 530.94 ms), scanning both relations in lockstep without building an expensive in-memory hash table.

---

### 6.8. Q8 – Net Movement & Covering Index Mechanics (`q08_net_movement_reversals.sql`)

- The query calculates conditional aggregates for `COMPLETED`, `REVERSED`, and `FAILED` transfers.
- **Why Partial Index `idx_txn_completed_transfers_time` Failed to Serve Q8:** A partial index can only be chosen if the query's `WHERE` clause logically implies the index's `WHERE` predicate. Because Q8 demands rows with status `REVERSED` and `FAILED`, the planner could not use the partial index.
- **The Solution:** A dedicated covering index `idx_txn_type_time_cover (txn_type, initiated_at) INCLUDE (status, amount)` was created. This index enabled an **Index Only Scan**, accelerating execution from **30.10 ms to 10.31 ms** (~3x faster) and trimming buffer hits from 3,147 to **409 pages**.

---

### 6.9. Q9 – The Join Fan-Out Trap (`q09_join_fanout_trap.sql`)

This query diagnoses a subtle yet common bug in double-entry financial reporting:

```sql
SELECT
   (SELECT sum(t.amount)
      FROM transactions t
      JOIN ledger_entries l ON l.transaction_id = t.transaction_id
     WHERE t.txn_type = 'TRANSFER' AND t.status = 'COMPLETED'
       AND t.initiated_at >= now() - interval '30 days') AS fan_out_total,
   (SELECT sum(t.amount)
      FROM transactions t
     WHERE t.txn_type = 'TRANSFER' AND t.status = 'COMPLETED'
       AND t.initiated_at >= now() - interval '30 days') AS correct_total;
```

#### Diagnostic Finding:
- **`fan_out_total`:** ₦79,481,250.00
- **`correct_total`:** ₦39,740,625.00
- **Mathematical Ratio:** Exactly **2.000x**.
- **Root Cause:** Double-entry architecture requires each transfer transaction to produce at least two ledger records (one `DEBIT` and one `CREDIT`). A naive `JOIN` between `transactions` and `ledger_entries` duplicates each transaction row across its child lines. Summing `transactions.amount` on the joined relation doubles the reported revenue. Financial aggregation queries must either aggregate directly on the parent table or aggregate ledger entries filtered by a single direction (`direction = 'DEBIT'`).

---

## 7. Planner Experiments & Selectivity Thresholds

Using `05_planner_experiments.sql` and `plans/planner.txt`, planner decision-making was evaluated under controlled GUC flags.

### 7.1. Planner Cost Model & Forced Sequential Scans
By disabling index scans (`SET enable_indexscan = off; SET enable_bitmapscan = off; SET enable_indexonlyscan = off;`), the planner was forced to fall back on sequential scans:
- **Q1 Forced Plan:** Cost jumped from 625 to **11,805**. Execution time surged from **10.16 ms to 1,460.94 ms** (a 143x slowdown) because the engine had to execute a parallel hash join across the entire 404k-row ledger table.

### 7.2. Selectivity Tipping Point Experiment
To demonstrate how PostgreSQL decides between an **Index Scan** and a **Sequential Scan**, a temporary index was placed on `customers(status)`:

```sql
EXPLAIN (ANALYZE) SELECT * FROM customers WHERE status = 'SUSPENDED'; -- rare (50 rows, ~1%)
EXPLAIN (ANALYZE) SELECT * FROM customers WHERE status = 'ACTIVE';    -- common (4,951 rows, ~99%)
```

#### Empirical Results:
1. **`status = 'SUSPENDED'` (High Selectivity, 1% of table):**
   - **Plan Chosen:** `Index Scan using tmp_customers_status`
   - **Cost:** `0.28..14.63`
   - **Mechanism:** Because only 50 rows match out of 5,001, traversing the B-tree to pick individual heap tuples costs significantly less than reading every page of the table.
2. **`status = 'ACTIVE'` (Low Selectivity, 99% of table):**
   - **Plan Chosen:** `Seq Scan on customers`
   - **Cost:** `0.00..131.51`
   - **Mechanism:** Reading 4,951 rows via an index would require 4,951 random page lookups (`random_page_cost = 4.0`), creating massive I/O overhead. The planner correctly recognized that reading all 69 sequential pages (`seq_page_cost = 1.0`) in a single pass is over 10x cheaper than using the index.

---

## 8. Index Maintenance, Storage & Write Overhead

While secondary indexes accelerate reads, they introduce two costs: **disk storage overhead** and **write amplification** during inserts and updates.

### 8.1. Storage Footprint of Indexes (`03_create_indexes.sql`)

| Index Name | Target Table | Type / Features | Disk Size |
| :--- | :--- | :--- | :--- |
| `idx_ledger_account_created` | `ledger_entries` | Composite B-tree (`account_id, created_at DESC`) | **12 MB** |
| `idx_txn_type_time_cover` | `transactions` | Multi-column Covering (`INCLUDE status, amount`) | **8.1 MB** |
| `idx_txn_completed_transfers_time`| `transactions` | Partial Covering (`WHERE status='COMPLETED'`) | **2.2 MB** |
| `idx_ledger_large_debits` | `ledger_entries` | Highly Selective Partial (`WHERE amount >= 4000`) | **800 KB** |
| `idx_accounts_customer` | `accounts` | Foreign Key B-tree | **176 KB** |
| **Total Secondary Index Size** | — | — | **~23.3 MB** |

### 8.2. Write Overhead Benchmark (`06_write_cost.sql`)

A controlled experiment compared the insertion of 404,162 ledger rows into two tables: one without secondary indexes and one with secondary indexes:

```sql
SELECT 'no indexes' AS copy, pg_size_pretty(pg_total_relation_size('le_no_index')) AS total_size
UNION ALL
SELECT 'with indexes', pg_size_pretty(pg_total_relation_size('le_with_index'));
```

#### Results:
- **Table Without Secondary Indexes:** **33 MB**
- **Table With Secondary Indexes:** **45 MB**
- **Observed Overhead:**
  - **Storage Increase:** +12 MB (+36.4% disk space).
  - **Write Amplification:** For every newly inserted row into `ledger_entries`, PostgreSQL must update the table heap block plus the B-tree leaf blocks of every active index. However, because `idx_ledger_large_debits` is a partial index (`amount >= 4000`), it is only written to for a tiny fraction (~2.5%) of transactions, minimizing ongoing write penalties.

---

## 9. Architectural Takeaways & Recommendations

1. **Always Index Foreign Keys in OLTP Schemas:** PostgreSQL automatically creates indexes for `PRIMARY KEY` and `UNIQUE` constraints, but **never** for `REFERENCES` foreign keys. Failing to index `accounts.customer_id` caused full sequential table scans on simple customer lookups.
2. **Leverage Covering Indexes for Dashboards:** Adding `INCLUDE (amount)` transformed high-frequency dashboard queries into `Index Only Scans`, completely eliminating heap table page access.
3. **Use Partial Indexes for Skewed and Status-Driven Tables:** Restricting indexes to `status = 'COMPLETED'` or `amount >= 4000` reduced index storage by up to 80% while keeping write amplification near zero for ordinary transaction flows.
4. **Order Multi-Column Indexes by Equality First, Range/Sort Second:** The composite index `(account_id, created_at DESC)` eliminated both the sequential scan and the in-memory quicksort, enabling instantaneous pagination on mobile transaction feeds.
5. **Beware the Join Fan-Out Trap in Ledgers:** Never compute arithmetic aggregates on parent transaction amounts across 1:N ledger joins without grouping or directional filtering.
