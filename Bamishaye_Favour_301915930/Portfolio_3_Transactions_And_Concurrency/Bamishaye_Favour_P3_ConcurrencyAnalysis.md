# Portfolio 3: Transactions, Concurrency, and Isolation Analysis

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Favour Bamishaye (ID: 301915930)  
**Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**DBMS:** PostgreSQL 16 / 18 (Apple Silicon `aarch64`, managed via pgAdmin 4 & `psql`)  
**Database:** `nexora_db`  
**Focus Area:** ACID Guarantees, Row-Level Locking, Deadlock Elimination, Concurrency Stress Testing, and Isolation Phenomena  

---

## 1. Executive Summary

In mission-critical fintech and digital banking systems, concurrent transaction processing must guarantee strict financial consistency while sustaining high throughput. Even a momentary race condition, deadlock, or lost update can result in duplicate disbursements, negative wallet balances, or unbacked money creation.

This portfolio evaluates the transaction management, locking protocols, and concurrency architecture of the **Nexora** platform. Key findings from our implementation and empirical testing include:

1. **Deadlock Elimination via Canonical Ordered Locking:**  
   By acquiring row-level locks on sender and receiver accounts in strict numerical sequence (`LEAST(from_id, to_id)` followed by `GREATEST(from_id, to_id)`), circular wait dependencies are rendered mathematically impossible.
2. **Stress-Test Empirical Validation (`pgbench`):**  
   - **Ordered Locking (`transfer_funds`):** Processed **2,000 / 2,000 transactions across 10 concurrent clients with 0 failed transactions (0.000% error rate)** at an average latency of **1.67 ms** and **5,977.72 TPS**.
   - **Unordered Locking (`transfer_funds_unordered`):** Suffered **62 catastrophic deadlocks (3.100% failure rate)**, while average latency surged to **246.09 ms** and throughput collapsed to **39.38 TPS** (a **~150x performance degradation**).
3. **Atomic Conservation of System Money:**  
   Across all stress tests, single-transfer demos, and partial failure rollbacks, system-wide money remained constant at exactly **₦1,000,000,000,000.0000**, with **zero unbalanced double-entry journals** and **zero mismatched accounts**.
4. **Proactive Lock Contention Handling (`lock_timeout`):**  
   Configuring `SET lock_timeout = '2s'` provides a fail-fast mechanism for high-traffic payments, terminating blocked sessions cleanly before queue saturation occurs.

---

## 2. ACID Transaction Architecture in Nexora

Every financial transfer in Nexora is executed via the stored function `transfer_funds()`, implemented in [`sql/01_transfer_function.sql`](sql/01_transfer_function.sql). The function enforces all four ACID properties directly inside the database engine:

```
                           +-------------------------------------+
                           | transfer_funds(from, to, amt, key)  |
                           +-------------------------------------+
                                              |
                          1. Idempotency Check (ON CONFLICT)
                                              |
                          2. Resolve Account IDs (no locks)
                                              |
                          3. Canonical Ordered Locking (FOR UPDATE)
                             LEAST(id_A, id_B) -> GREATEST(id_A, id_B)
                                              |
                          4. Post-Lock Balance & Status Validation
                                              |
                          5. Atomic Updates & Ledger Append
                             UPDATE accounts (Debit/Credit)
                             INSERT ledger_entries (2 lines)
                             UPDATE transactions (COMPLETED)
                                              |
                                     [COMMIT / ROLLBACK]
```

### 2.1. Atomicity (All-or-Nothing)
- **Mechanism:** The function executes within a PostgreSQL transaction block (`BEGIN ... COMMIT`). If an exception is raised at any stage (e.g., `INSUFFICIENT_FUNDS`, `ACCOUNT_NOT_ACTIVE`, or foreign key violation), the entire operation rolls back immediately.
- **Empirical Evidence (`output/03_commit_rollback_output.txt`):**
  - **Demo 1 (Commit):** Transferring ₦100.00 between accounts `2200001001` and `2200001002` moved funds permanently, generating two corresponding ledger entries.
  - **Demo 2 (Explicit Rollback):** Transferring ₦100.00 followed by an immediate `ROLLBACK` restored starting balances identically (`1003257.27` and `1025938.16`), leaving 0 rows in `transactions` for that idempotency key.
  - **Demo 3 (Failure Rollback):** Attempting an invalid transfer of ₦999,999,999.00 raised `INSUFFICIENT_FUNDS`, automatically rolling back the initiated transaction record (`rows_for_failed_key = 0`).

### 2.2. Consistency (System Invariants)
The schema guarantees four foundational financial invariants before and after every transaction commit:
1. **Double-Entry Equilibrium:** Every completed transfer writes exactly one `DEBIT` and one `CREDIT` row to `ledger_entries` such that:
   $$\sum \text{Debits} - \sum \text{Credits} = 0$$
2. **Balance Non-Negativity:** Enforced by `CHECK (balance >= 0)` on `accounts` and validated dynamically in `transfer_funds()` after locks are acquired.
3. **Conservation of Money:** In a closed transfer system, internal transfers reallocate money between accounts but neither create nor destroy currency:
   $$\sum_{a \in \text{accounts}} a.\text{balance} = C \quad (\text{constant})$$
4. **Cache Integrity:** Cached `accounts.balance` must exactly equal the running aggregate of `ledger_entries` for that account.

### 2.3. Isolation (Concurrency Visibility)
- Nexora operates under PostgreSQL's default **Read Committed** isolation level paired with explicit pessimistic locking (`SELECT ... FOR UPDATE`).
- Uncommitted balance changes are invisible to concurrent sessions. Concurrency anomalies such as dirty reads are physically impossible in PostgreSQL, while non-repeatable reads and phantom reads on account balances are prevented because `FOR UPDATE` serializes concurrent transactions on the exact account rows.

### 2.4. Durability (Persistence)
- Once a transaction executes `COMMIT`, changes are flushed to the Write-Ahead Log (WAL) on disk.
- System crashes or server restarts guarantee recovery to the last committed transaction without loss of state.

---

## 3. Idempotency & Partial Failure Handling

### 3.1. Network Retries & Idempotency Keys
In distributed banking environments, client network timeouts often cause payment requests to be retried. If not handled, the customer is billed twice.

Nexora implements atomic idempotency at step 1 of `transfer_funds()`:
```sql
INSERT INTO transactions (idempotency_key, txn_type, status, amount, reference)
VALUES (p_key, 'TRANSFER', 'PENDING', p_amount, p_reference)
ON CONFLICT (idempotency_key) DO NOTHING
RETURNING transaction_id INTO v_txn_id;

IF v_txn_id IS NULL THEN
    -- Request was already registered by an earlier network call
    SELECT transaction_id INTO v_txn_id
    FROM transactions WHERE idempotency_key = p_key;
    RETURN v_txn_id;
END IF;
```

#### Empirical Proof (`Demo 4`):
- Executing `transfer_funds(..., 25.00, :'k')` twice with the same UUID idempotency key:
  - **First Call:** Returned transaction ID `206102`.
  - **Second Call (Retry):** Returned the identical transaction ID `206102`.
  - **Database State:** Exactly 1 transaction record exists for that key; balance debited exactly once (₦25.00).

### 3.2. Sub-Transaction Fault Tolerance via Savepoints
Savepoints allow an application to attempt a speculative transfer or multi-leg transaction without losing earlier successful operations if a subsequent leg fails.

#### Empirical Proof (`Demo 5`):
1. Transferred ₦10.00 from Account 1 to Account 2 (Transaction ID `206104`).
2. Established `SAVEPOINT before_second_transfer;`.
3. Attempted an invalid transfer of ₦999,999,999.00 (raised `INSUFFICIENT_FUNDS`).
4. Executed `ROLLBACK TO SAVEPOINT before_second_transfer;` and `COMMIT;`.
5. **Outcome:** The first transfer persisted permanently; the second transfer was cleanly discarded; the session avoided an abort state.

---

## 4. Concurrency Control: Deadlock Mechanics & Mathematical Proof

### 4.1. The Deadlock Problem in Bidirectional Transfers
Consider two concurrent transactions:
- **Transaction 1 ($T_1$):** Transfers ₦100 from Account $A$ (ID: 10) to Account $B$ (ID: 20).
- **Transaction 2 ($T_2$):** Transfers ₦50 from Account $B$ (ID: 20) to Account $A$ (ID: 10).

In an **unordered locking protocol** (locking the sender first, receiver second):
1. $T_1$ locks Account $A$.
2. $T_2$ locks Account $B$.
3. $T_1$ attempts to lock Account $B$ $\implies$ **Blocked**, waiting for $T_2$.
4. $T_2$ attempts to lock Account $A$ $\implies$ **Blocked**, waiting for $T_1$.

```
     T1 holds Lock(A) --------------> waits for Lock(B) held by T2
        ^                                                    |
        |                                                    |
        +---------------- waits for Lock(A) <----------------+
```

This creates a **circular wait condition** ($T_1 \to T_2 \to T_1$). Neither transaction can proceed. After `deadlock_timeout` (typically 1 second), PostgreSQL's deadlock detection daemon intervenes and forcibly aborts one transaction:
```
ERROR: deadlock detected
DETAIL: Process 41285 waits for ShareLock on transaction 206150; blocked by process 41286.
Process 41286 waits for ExclusiveLock on tuple (0,2) of relation "accounts"; blocked by process 41285.
```

---

### 4.2. Mathematical Proof of Deadlock Elimination via Ordered Locking

To mathematically eliminate deadlocks, we must break Coffman's fourth condition: the **circular wait**.

#### The Total Ordering Algorithm
Let $S = \{a_1, a_2, \dots, a_n\}$ be the set of all accounts uniquely identified by primary keys $a_i \in \mathbb{N}^+$. Define a strict total order $<$ over $S$:
$$a_i < a_j \iff \text{account\_id}(a_i) < \text{account\_id}(a_j)$$

In `transfer_funds()`, locks are acquired strictly according to this order:
```sql
v_first_id  := LEAST(v_from_id, v_to_id);
v_second_id := GREATEST(v_from_id, v_to_id);
PERFORM 1 FROM accounts WHERE account_id = v_first_id  FOR UPDATE;
PERFORM 1 FROM accounts WHERE account_id = v_second_id FOR UPDATE;
```

#### Formal Proof by Contradiction:
1. **Hypothesis:** Assume a set of $k$ transactions $\{T_1, T_2, \dots, T_k\}$ form a deadlock cycle under the ordered locking protocol.
2. By definition of a deadlock cycle in a resource allocation graph, each transaction $T_i$ holds lock $R_i$ and is waiting for lock $R_{i+1}$ held by $T_{i+1}$, with $T_k$ waiting for $R_1$ held by $T_1$:
   $$T_1 \xrightarrow{\text{waits for}} T_2 \xrightarrow{\text{waits for}} \dots \xrightarrow{\text{waits for}} T_k \xrightarrow{\text{waits for}} T_1$$
3. Under our protocol, any transaction that requests resource $Y$ while holding resource $X$ must satisfy:
   $$X < Y$$
4. Therefore, along the wait-for chain:
   $$R_1 < R_2 < R_3 < \dots < R_k < R_1$$
5. Transitivity of strict inequality implies:
   $$R_1 < R_1$$
6. This is a direct contradiction ($\text{False}$).
7. **Conclusion:** No circular wait graph can exist. Ordered locking mathematically eliminates deadlocks between two-party transfers. $\blacksquare$

---

## 5. Empirical Stress Testing Benchmark (`pgbench`)

Using `pgbench` (PostgreSQL 18.6), we subjected both locking implementations to high-concurrency contention across 20 hot accounts (`account_id` 1001 to 1020).

### 5.1. Test Parameters
- **Concurrent Clients:** 10 sessions
- **Worker Threads:** 4 threads
- **Transaction Volume:** 2,000 transfers (200 per client)
- **Hotset Accounts:** 20 wallets (accounts `2200001001` through `2200001020`)
- **Transfer Amounts:** Random ₦1.00 to ₦100.00
- **Random Sender & Receiver:** Guaranteed distinct accounts ($A \neq B$)

---

### 5.2. Comparative Performance Results

| Performance Metric | Ordered Locking (`transfer_funds`) | Unordered Locking (`transfer_funds_unordered`) | Impact of Ordered Locking |
| :--- | :--- | :--- | :--- |
| **Total Transactions Processed** | **2,000 / 2,000** | 1,938 / 2,000 | 100% completion |
| **Failed Transactions** | **0 (0.000%)** | **62 (3.100%)** | **Zero deadlocks** |
| **Average Latency** | **1.673 ms** | **246.090 ms** | **147.1x lower latency** |
| **Transaction Throughput (TPS)** | **5,977.72 TPS** | **39.38 TPS** | **151.8x higher throughput** |
| **Initial Connection Time** | 112.10 ms | 92.16 ms | Comparable setup |
| **Ledger Lines Generated** | 4,000 rows | 7,876 rows (cumulative) | Exactly 2 lines per success |
| **Post-Test Integrity Check** | **PASSED (0 defects)** | **PASSED (0 defects)** | Full transactional rollback |

---

### 5.3. Performance Analysis & Bottlenecks
1. **The Cost of Deadlock Resolution:**  
   In `transfer_funds_unordered`, transactions spent hundreds of milliseconds sleeping and waiting on locks held by opposing transactions. When a cycle formed, execution halted until the PostgreSQL deadlock engine timed out and threw a cancellation exception. This caused average latency to surge from **1.67 ms to 246.09 ms**.
2. **Throughput Collapse:**  
   Lock serialization and aborted transactions reduced throughput from **~5,978 TPS to under 40 TPS**. Ordered locking removed all deadlock interrupts, allowing PostgreSQL to service queue requests with pure row-level lock handoffs.

---

## 6. Financial Integrity & Invariant Audit

Following the high-concurrency stress benchmarks, [`sql/06_integrity_check.sql`](sql/06_integrity_check.sql) was executed to verify the state of `nexora_db`.

```
======================================================================
NEXORA POST-STRESS INTEGRITY AUDIT REPORT
======================================================================
1. Total Money in System (Excl. demo wallets):  1,000,000,000,000.0000 NGN
   Expected: 1,000,000,000,000.0000 NGN          Status: PASSED [EXACT MATCH]

2. Total Stress Transfers Recorded:              3,938 transfers
   Total Stress Ledger Entries Generated:        7,876 entries
   Ledger-to-Transfer Multiplier:                Exactly 2.000x (1 DEBIT, 1 CREDIT)

3. Unbalanced Transactions Count:                0 rows
   Invariant: sum(Debits) - sum(Credits) = 0    Status: PASSED

4. Mismatched Account Balances Count:            0 rows
   Invariant: accounts.balance = ledger sum     Status: PASSED

5. Stuck 'PENDING' Transactions Count:           0 rows
   Invariant: Atomic terminal status             Status: PASSED
======================================================================
```

**Key Takeaway:** Even in the unordered run where 62 transfers aborted due to deadlocks, **zero partial states leaked into the database**. The failed transactions were rolled back completely, leaving no orphaned transaction headers and zero balance discrepancies.

---

## 7. Independent Experiment: Row Lock Timeout (`lock_timeout`)

*Documented in [`own_experiment.md`](own_experiment.md) and evidenced by screenshot `Bamishaye_Favour_301915930_lock_timeout.png`.*

### 7.1. Experimental Hypothesis & Setup
- **Question:** What happens when Session B requests a row lock on an account already held by Session A, but Session B specifies `SET lock_timeout = '2s'`?
- **Pre-Test Prediction:**  
  Session B will wait for exactly 2 seconds. When the timer expires, PostgreSQL will abort Session B's query with a lock timeout error without affecting Session A. Session B's transaction will enter an aborted error state requiring a `ROLLBACK`.

### 7.2. Experimental Execution Protocol
1. **Reset Wallets:** Demo Alice (`9000000001`) reset to ₦500.00 via `sql/02_demo_setup.sql`.
2. **Session A:**
   ```sql
   BEGIN;
   SELECT * FROM accounts WHERE account_number = '9000000001' FOR UPDATE;
   -- Lock acquired; Session A pauses without committing.
   ```
3. **Session B:**
   ```sql
   SET lock_timeout = '2s';
   BEGIN;
   SELECT * FROM accounts WHERE account_number = '9000000001' FOR UPDATE;
   -- Session B attempts lock on the same account.
   ```

### 7.3. Empirical Observations
- **Observed Error in Session B:**
  ```
  ERROR: canceling statement due to lock timeout
  CONTEXT: while locking tuple (0,7) in relation "accounts"
  ```
- **Elapsed Duration:** Exactly **2,002.34 ms** (~2.0 seconds).
- **Session State After Error:**  
  The transaction status prompt changed to `nexora_db (18.6) [ERROR]=#`. Any subsequent SQL commands in Session B failed with:
  ```
  ERROR: current transaction is aborted, commands ignored until end of transaction block
  ```
- **Cleanup:** Session B issued `ROLLBACK; RESET lock_timeout;`. Session A issued `ROLLBACK;`. Account balances remained completely intact at ₦500.00.

### 7.4. Engineering Significance for Payment Systems
1. **Lock Timeout vs. Deadlock Detection:**  
   Deadlocks only occur when cycles form. If Session A holds a lock indefinitely (e.g., waiting on a slow third-party API or network partition), Session B would wait indefinitely under default settings, exhausting connection pools.
2. **Fail-Fast SLA Enforcement:**  
   Setting `lock_timeout = '2s'` ensures mobile banking clients receive an instantaneous HTTP 409 / 503 response ("System busy, please retry") rather than hanging on a spinner until an API gateway timeout occurs.

---

## 8. Concurrency Phenomena & Lost Updates

In addition to deadlocks, multi-user banking systems must guard against **Lost Updates**.

### 8.1. The Lost Update Scenario
Without row locking (`FOR UPDATE`), two concurrent sessions reading the same account balance simultaneously can overwrite each other's changes:

```
Session A: Read balance (500) ------> Compute 500 + 100 = 600 ------> Write balance (600)
Session B: Read balance (500) ------> Compute 500 + 50  = 550 --------------> Write balance (550)
```
- **Net Result:** Session A's deposit of ₦100 is completely lost. Balance is ₦550 instead of ₦650.

### 8.2. Prevention in Nexora
1. **Pessimistic Locking (`FOR UPDATE`):** Session B cannot read or modify the account balance until Session A commits or rolls back.
2. **Post-Lock Balance Reads:** In `transfer_funds()`, `SELECT balance INTO ...` is executed **after** `PERFORM 1 FROM accounts WHERE account_id = ... FOR UPDATE`, guaranteeing that the balance evaluated is the freshest committed value.

---

## 9. Architectural Takeaways & Production Best Practices

1. **Enforce Canonical Ordering Across All Multi-Resource Operations:**  
   Any business operation that touches multiple rows in the same table (transfers, batch settlements, swaps) must sort primary keys before locking: `LEAST(a, b)` then `GREATEST(a, b)`.
2. **Read Balances Only AFTER Row Locks Are Held:**  
   Never validate financial balances based on pre-fetched data. Always acquire the row lock first, then read the balance.
3. **Use `clock_timestamp()` for Real-Time Auditing:**  
   PostgreSQL's `now()` returns the start time of the transaction, which can cause concurrent ledger entries to share identical timestamps. `clock_timestamp()` reflects real wall-clock time, preserving strict chronological sequencing.
4. **Implement Global and Per-Session Lock Timeouts:**  
   Payment processing microservices should explicitly configure `SET lock_timeout = '3s'` to prevent connection pool exhaustion during traffic surges.
5. **Always Pair Application Logic with DB-Level Constraints:**  
   `transfer_funds()` validates `v_from_bal >= p_amount`, but the table's `CHECK (balance >= 0)` serves as the ultimate fail-safe guarantee against software defects.
