# Own Experiment: Lock Timeout

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Favour Bamishaye (ID: 301915930)  
**Database:** `nexora_db`  
**Focus:** Concurrency, Lock Contention, and Fail-Fast Error Handling  

---

## 1. Question
What happens when a database session attempts to acquire a row lock on an account that is already locked by another session, but has explicitly set a 2-second lock timeout (`SET lock_timeout = '2s'`)?

---

## 2. Prediction (Formulated BEFORE Running)
- **What I expect Tab B to do:** Tab B will attempt to acquire an exclusive row lock on the row currently held by Tab A and pause execution while waiting for Tab A to release the lock.
- **When I expect the error to appear:** The error will not appear immediately. It will appear after exactly 2 seconds of waiting.
- **What state I expect Tab B's transaction to be in afterwards:** Tab B's active transaction will be placed into an aborted error state (`[ERROR]`), preventing any further statements from running until an explicit `ROLLBACK` is issued. Tab A should remain unaffected.

---

## 3. Setup
- **Database:** `nexora_db`
- **Wallet Used:** Demo Alice (`account_number = '9000000001'`), reset to ₦500.00 prior to execution via [`sql/02_demo_setup.sql`](sql/02_demo_setup.sql).
- **Configuration Parameter Tested:** `SET lock_timeout = '2s';`

---

## 4. Steps Executed

| Step | Session / Tab | Command / Action | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | **Tab A** | `BEGIN; SELECT * FROM accounts WHERE account_number = '9000000001' FOR UPDATE;` | Acquires an exclusive row lock on Alice's wallet without committing. |
| **2** | **Tab B** | `SET lock_timeout = '2s'; BEGIN; SELECT * FROM accounts WHERE account_number = '9000000001' FOR UPDATE;` | Attempts to acquire a lock on the same wallet with a 2-second timeout. |
| **3** | **Tab B** | *(Waits 2 seconds)* $\implies$ Receives lock timeout error. Then executes: `ROLLBACK; RESET lock_timeout;` | Observes error, clears transaction error state, and resets session parameter. |
| **4** | **Tab A** | `ROLLBACK;` | Releases initial row lock. |

---

## 5. Empirical Observations

- **Exact Error Message Received in Tab B:**
  ```text
  ERROR: canceling statement due to lock timeout
  CONTEXT: while locking tuple (0,7) in relation "accounts"
  ```
- **How Long Tab B Waited Before Error:** Exactly **2.002 seconds** (~2,000 ms).
- **Tab B Prompt After Error:** The interactive prompt changed from `nexora_db=#` to `nexora_db (18.6) [ERROR]=#`, indicating an aborted transaction block.
- **Behavior on Subsequent Queries:** Any query executed in Tab B before issuing `ROLLBACK` immediately returned:
  ```text
  ERROR: current transaction is aborted, commands ignored until end of transaction block
  ```

---

## 6. Comparison: Default Behavior Without `lock_timeout`
When `lock_timeout` is left at default (`0`, meaning disabled):
- Tab B hangs indefinitely waiting for Tab A to either `COMMIT` or `ROLLBACK`.
- If Tab A remains open for minutes or hours (e.g. an unhandled network partition or hanging backend thread), Tab B remains frozen, holding database connection resources open and degrading system capacity.

---

## 7. Was My Prediction Right?
**Yes, completely.**  
Tab B waited exactly 2 seconds before throwing a lock timeout error. Tab A remained entirely unaffected and held its lock until it explicitly rolled back. Tab B's transaction was aborted and required a `ROLLBACK` to recover.

---

## 8. Engineering Significance for Payments Systems

1. **How an Application Should Handle This Error:**  
   The application backend should catch the PostgreSQL error code `55P03` (`lock_not_available`) and return an immediate, clean response to the client (e.g., `HTTP 409 Conflict` or `HTTP 503 Service Unavailable`: *"Account is currently processing another transaction. Please retry shortly."*) rather than letting client HTTP connections hang.
2. **How This Differs from a Deadlock:**  
   - A **deadlock** requires a circular wait cycle ($T_1 \to T_2 \to T_1$). It is detected by PostgreSQL's background deadlock engine (governed by `deadlock_timeout`).
   - A **lock timeout** is a proactive, single-party deadline. It triggers even when there is no circular dependency, simply because a requested resource is held by someone else for longer than permitted.
3. **When to Use Lock Timeouts in Payment Architectures:**  
   In digital payment platforms processing thousands of transfers per second:
   - High-traffic checkout endpoints must prevent connection pool starvation.
   - Setting `lock_timeout = '2s'` or `'3s'` guarantees that slow or hung transactions fail fast, protecting database thread pools from exhaustion.

---

## 9. Visual Evidence
- **Screenshot Artifact:** [`screenshots/Bamishaye_Favour_301915930_lock_timeout.png`](screenshots/Bamishaye_Favour_301915930_lock_timeout.png)
