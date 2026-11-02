# Database Normalisation and Controlled Denormalisation Note

**Project:** Nexora Digital Savings & Financial Management Platform  
**Module:** Portfolio 1 – Database Design and Modelling  
**Artifact:** `normalisation.md`  
**Target Schema:** `02_create_tables.sql` (`nexora_db`)  
**DBMS:** PostgreSQL 16  

---

## 1. Overview of Normalisation Principles

Relational database design relies on **Normalisation**—a formal technique founded on relational algebra to structure tables in a way that minimizes data redundancy, prevents update/insert/delete anomalies, and guarantees functional dependency integrity:

- **First Normal Form (1NF):** Each relation has a primary key; column values are atomic (no repeating groups, arrays, or composite attributes).
- **Second Normal Form (2NF):** Satisfies 1NF, and all non-key attributes are fully functionally dependent on the primary key (no partial dependencies on a composite candidate key).
- **Third Normal Form (3NF):** Satisfies 2NF, and no non-key attribute is transitively dependent on a candidate key. Informally stated by Codd: *"Every non-key attribute must depend on the key, the whole key, and nothing but the key, so help me Codd."*

### The Trade-off: Purity vs. Production Performance
While strict 3NF or Boyce-Codd Normal Form (BCNF) eliminates redundancy in operational OLTP systems, financial applications operating high-throughput double-entry ledgers deliberately introduce **controlled denormalisation**. Redundancy is selectively tolerated when:
1. Deriving values at runtime introduces unacceptable latency or lock contention on hot critical paths (e.g., balance validation).
2. Point-in-time auditability and historical immutability supersede temporal normalization (an immutable snapshot must not mutate when historical entities change).
3. System boundaries separate internal relational entities from asynchronous external networks (e.g., inter-bank clearing networks).

The Nexora schema adheres to 3NF across the core entity graph while deliberately breaching 3NF on four specific columns:
1. `accounts.balance`
2. `ledger_entries.balance_after`
3. `transactions.amount`
4. `beneficiaries.account_name`

---

## 2. Detailed Analysis of Deliberate 3NF Violations

```
                                  +----------------------+
                                  |      customers       |
                                  +----------------------+
                                             |
                      +----------------------+----------------------+
                      | 1:N                                         | 1:N
                      v                                             v
            +-------------------+                         +-------------------+
            |     accounts      |                         |   beneficiaries   |
            +-------------------+                         +-------------------+
            | balance [3NF-1]   |                         | account_name [4]  |
            +-------------------+                         +-------------------+
                      | 1:N
                      v
            +-------------------+       N:1               +-------------------+
            |  ledger_entries   |------------------------>|   transactions    |
            +-------------------+                         +-------------------+
            | balance_after [2] |                         | amount [3NF-3]    |
            +-------------------+                         +-------------------+
```

---

### 2.1. `accounts.balance`

* **Table:** `accounts`
* **Column:** `balance NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (balance >= 0)`

#### Functional Dependency & 3NF Violation Analysis
In formal relational database theory, an account's balance is **not an independent primitive attribute** of an account entity. Instead, it is a derived aggregate computed over the sequence of all ledger postings for that account:

$$\text{balance} = \sum_{\substack{e \in \text{ledger\_entries} \\ e.\text{account\_id} = a.\text{account\_id}}} \Big(\text{CASE WHEN } e.\text{direction} = \text{'CREDIT'} \text{ THEN } e.\text{amount} \text{ ELSE } -e.\text{amount END}\Big)$$

Because `balance` is functionally dependent on the set of historical ledger entries associated with `account_id`, maintaining `balance` directly on `accounts` introduces a **transitive / aggregate dependency** ($a.\text{account\_id} \to \{e.\text{amount}\} \to \text{balance}$). In strict 3NF, the `balance` attribute would be omitted entirely from the `accounts` table and computed via a `VIEW` or an aggregation query on demand.

#### Engineering Justification (Why Denormalise?)
1. **Critical-Path Read Performance:** Balance verification is executed on every single debit attempt (withdrawal, transfer, card charge). Calculating `SUM(amount)` over thousands or millions of ledger rows per transaction would exhaust disk I/O and produce latency spikes incompatible with real-time financial SLAs.
2. **Pessimistic Locking & Concurrency Control:** Enforcing double-entry rules and preventing overdrafts/race conditions (e.g., double-spending) requires locking the account row:
   ```sql
   SELECT balance FROM accounts WHERE account_id = $1 FOR UPDATE;
   ```
   Serializing on a single cached `accounts` row is lightweight. Attempting to lock all past rows in `ledger_entries` to compute a running sum would lock vast swaths of the ledger table and cause catastrophic lock escalation and deadlocks.
3. **Database-Level Constraint Enforcement:** Denormalising `balance` enables the atomic `CHECK (balance >= 0)` constraint, guaranteeing at the database engine level that no race condition can leave an account overdrawn.

#### Mitigations & Integrity Safeguards
- **ACID Transaction Boundaries:** Updates to `accounts.balance` and insertions into `ledger_entries` occur within the exact same database transaction (`BEGIN ... COMMIT`).
- **Periodic Reconciliation Jobs:** Automated batch reconciliation scripts run off-peak to verify that:
  $$\text{accounts.balance} = \sum(\text{credits}) - \sum(\text{debits})$$
  Any discrepancy alerts the engineering and compliance teams immediately.

---

### 2.2. `ledger_entries.balance_after`

* **Table:** `ledger_entries`
* **Column:** `balance_after NUMERIC(19,4) NOT NULL CHECK (balance_after >= 0)`

#### Functional Dependency & 3NF Violation Analysis
In relational normalization, each row in `ledger_entries` represents an atomic financial debit or credit movement (`direction`, `amount`, `created_at`). 

The `balance_after` attribute represents the running balance of the associated account immediately after the line item is posted:

$$\text{balance\_after}_n = \text{balance\_after}_{n-1} \pm \text{amount}_n$$

This value is functionally determined by the ordered sequence of prior entries for that account:

$$\{\text{account\_id}, \text{entry\_id}_{\le n}\} \to \text{balance\_after}_n$$

Storing `balance_after` violates 3NF because it introduces a transitive dependency on previous ledger rows and duplicates data that can theoretically be calculated using SQL window functions (`SUM(amount) OVER (PARTITION BY account_id ORDER BY entry_id)`).

#### Engineering Justification (Why Denormalise?)
1. **Audit Immutability and Point-in-Time Proof:** Double-entry accounting requires an indelible audit trail. `balance_after` provides an immutable cryptographic-style snapshot of what the account balance was at the precise instant the ledger entry was written. Even if historical reporting algorithms change, the historical snapshot is preserved.
2. **Tamper-Evidence & Hash Chaining:** `balance_after` turns the ledger into a continuous verifiable chain. If any historical record is illicitly modified, inserted, or purged, the mathematical continuity:
   $$\text{balance\_after}_{k} = \text{balance\_after}_{k-1} \pm \text{amount}_k$$
   breaks at index $k$, providing immediate forensic proof of unauthorized database tampering.
3. **Statement Generation Performance:** Customer bank statement generation (e.g., retrieving the last 30 days of transactions with opening and closing balances) executes as a straightforward indexed range scan over `ledger_entries` without requiring recursive CTEs or expensive window aggregation across the full historical lifespan of the account.

#### Mitigations & Integrity Safeguards
- **Append-Only Immutability:** Rows in `ledger_entries` are never updated or deleted (`UPDATE` and `DELETE` permissions are revoked on ledger tables in production).
- **System Check Constraints:** The table enforces `CHECK (balance_after >= 0)` to prevent any individual ledger entry from recording an illegal negative state.

---

### 2.3. `transactions.amount`

* **Table:** `transactions`
* **Column:** `amount NUMERIC(19,4) NOT NULL CHECK (amount > 0)`

#### Functional Dependency & 3NF Violation Analysis
In a double-entry ledger architecture, a row in `transactions` serves as an operational business header (intent, idempotency key, transaction type, timestamps). The actual monetary values live inside the child lines in `ledger_entries` (where one transaction yields at least two ledger lines: a credit and a debit).

The total amount of a transaction is functionally determined by its ledger entries:

$$\text{transactions.amount} = \sum_{\substack{e \in \text{ledger\_entries} \\ e.\text{transaction\_id} = t.\text{transaction\_id} \\ e.\text{direction} = \text{'CREDIT'}}} e.\text{amount}$$

Storing `amount` on the `transactions` table duplicates the numeric values stored in `ledger_entries`, creating an aggregate/redundant functional dependency between parent and child tables.

#### Engineering Justification (Why Denormalise?)
1. **Separation of Business Intent from Accounting Implementation:** The `transactions` table captures the user's business intent (e.g., customer initiates a ₦5,000 transfer). The ledger entries represent the mechanical accounting movements (e.g., ₦5,000 debit from sender, ₦5,000 credit to recipient, plus optional fee splits: ₦50 fee debit, ₦50 revenue credit). Storing `amount` on `transactions` records the gross intended amount independently of the underlying ledger breakdown.
2. **High-Throughput Header Indexing & Querying:** User dashboards, payment gateway callbacks, webhook validation, and transaction history feeds query the `transactions` table without needing to `JOIN` or aggregate the high-volume `ledger_entries` table.
3. **Fraud Detection & Rate-Limiting Rules:** Anti-money laundering (AML) and velocity rules (e.g., "flag transactions over ₦1,000,000" or evaluate `risk_score` in `fraud_flags`) evaluate `transactions.amount` instantaneously at the API boundary before or during ledger creation.
4. **Two-Phase Validation (Balancing Proof):** Having the declared `transactions.amount` provides a control sum. The application verifies that the sum of debits equals the sum of credits in `ledger_entries`, and that both equal `transactions.amount`, before transitioning transaction status to `COMPLETED`.

#### Mitigations & Integrity Safeguards
- **Positive Domain Constraint:** Regulated by `CHECK (amount > 0)` to avoid invalid zero or negative transaction values.
- **Idempotency Keys:** Protected by `idempotency_key VARCHAR(64) NOT NULL UNIQUE` to prevent duplicate transaction entries from being created during network retries.

---

### 2.4. `beneficiaries.account_name`

* **Table:** `beneficiaries`
* **Column:** `account_name VARCHAR(150) NOT NULL`

#### Functional Dependency & 3NF Violation Analysis
In classical relational theory, if an account number belongs to a customer, the account holder's name is functionally determined by the account:

$$\{\text{bank\_name}, \text{account\_number}\} \to \text{account\_name}$$

Under pure 3NF:
- If the beneficiary were an internal Nexora customer, storing `account_name` in `beneficiaries` would be a **transitive dependency** through `account_number`:
  $$\text{beneficiary\_id} \to (\text{bank\_name}, \text{account\_number}) \to \text{account\_id} \to \text{customer\_id} \to (\text{first\_name}, \text{last\_name})$$
- Non-key attribute `account_name` depends on non-key attributes `(bank_name, account_number)`, directly violating 3NF.

#### Engineering Justification (Why Denormalise?)
1. **External System Boundary:** In real-world fintech platforms, saved beneficiaries are frequently accounts domiciled at external commercial banks (e.g., Zenith Bank, GTBank, Access Bank). Nexora has no foreign key access to external banking databases; the recipient name is obtained via an asynchronous external Name Inquiry service (e.g., NIP/NIBSS).
2. **Point-in-Time Name Verification Snapshot:** When a customer saves a beneficiary, the name resolved at that specific moment is stored. If an external counterparty updates their legal name or marries years later, the user's historical saved contact list should remain stable and reflective of what was verified when saved.
3. **User Experience & API Latency Elimination:** Displaying a user's transfer contact list in mobile banking must be instant. If `account_name` were not persisted, the application would have to issue live HTTP Name Inquiry requests to external banking APIs for every beneficiary on screen, causing latency, API rate limits, and network failure points.

#### Mitigations & Integrity Safeguards
- **Compound Uniqueness:** A user cannot save the same destination account twice:
  ```sql
  UNIQUE (customer_id, bank_name, account_number)
  ```
- **Cascade Cleanup:** If the customer account is removed, associated beneficiary records are removed via `ON DELETE CASCADE`.

---

## 3. Summary Matrix of Deliberate 3NF Breaches

| Table | Column | 3NF Violation Classification | Functional Dependency Involved | Primary Engineering Rationale | Risk Mitigation Mechanism |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`accounts`** | `balance` | Stored Derived Attribute / Aggregate Dependency | $a.\text{account\_id} \to \{e.\text{amount}\} \to \text{balance}$ | Critical-path balance validation; row-level pessimistic locking (`FOR UPDATE`); preventing race conditions | ACID transactions with `ledger_entries`; `CHECK (balance >= 0)`; automated batch reconciliation |
| **`ledger_entries`**| `balance_after` | Point-in-Time Sequence Dependency | $\{\text{account\_id}, \text{entry\_id}_{\le n}\} \to \text{balance\_after}$ | Immutable audit trail; tamper detection/hash chaining; fast statement generation | Append-only permissions; immutable ledger design; `CHECK (balance_after >= 0)` |
| **`transactions`** | `amount` | Redundant Attribute across Master-Detail | $\{e.\text{amount} \mid e.\text{transaction\_id}\} \to \text{transactions.amount}$ | Business intent preservation; fast transaction listing; AML/fraud rule evaluation | Control sum comparison between header and line items; `CHECK (amount > 0)`; idempotency key |
| **`beneficiaries`** | `account_name` | Transitive Dependency across System Boundary | $(\text{bank\_name}, \text{account\_number}) \to \text{account\_name}$ | External bank boundaries (NIP/NIBSS); immutable name snapshot; eliminating network API calls on UI rendering | `UNIQUE (customer_id, bank_name, account_number)`; pre-save Name Inquiry verification |

---

## 4. Conclusion

The deliberate 3NF breaches in the Nexora database schema are conscious, principled architectural trade-offs. Normalisation eliminates anomalies in static models, but fintech platforms handling high-concurrency double-entry ledgers prioritize **data integrity, ACID concurrency, audit immutability, and sub-millisecond read access**.

By isolating denormalisation to these four specific attributes and enforcing strict database constraints (`CHECK`, `UNIQUE`, foreign key cascades, and transactional atomicity), the system balances relational rigor with real-world financial performance.
