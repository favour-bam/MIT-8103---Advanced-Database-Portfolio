# Portfolio 1: Database Design and Modelling

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Favour Bamishaye (ID: 301915930)  
**Case Study:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**DBMS:** PostgreSQL 16 (administered via pgAdmin 4)  
**Database Name:** `nexora_db`  

---

## 1. Overview

This portfolio contains the complete database design, implementation, constraint testing, and synthetic data seeding for **Nexora**, a high-concurrency digital savings and wallet management platform. The design models real-world fintech requirements, including:
- Customer lifecycle and multi-stage KYC verification.
- Dual-wallet structures and card management.
- Multi-party peer-to-peer (P2P) transfers, deposits, bill payments, and transaction reversals.
- Strict double-entry accounting with an immutable ledger (`ledger_entries`).
- Automated risk scoring and fraud flagging (`fraud_flags`).

---

## 2. Directory Structure & Key Documents

| File / Directory | Description |
| :--- | :--- |
| [case-study.md](case-study.md) | Business case study describing Nexora's operational model, user personas, key entities, and platform workflows. |
| [nexora.dbml](nexora.dbml) | DBML (Database Markup Language) schema definition for ER diagram visualization (e.g. via [dbdiagram.io](https://dbdiagram.io)). |
| [normalisation.md](normalisation.md) | Detailed relational normalization report explaining the 3NF baseline and documenting the 4 intentional, controlled denormalisations (`accounts.balance`, `ledger_entries.balance_after`, `transactions.amount`, `beneficiaries.account_name`). |
| [screenshots/](screenshots/) | Execution evidence from pgAdmin 4 demonstrating database creation, schema tables, constraint enforcement, and seed data verification. |

---

## 3. SQL Scripts (Execution Order)

Execute the scripts in the following numerical sequence:

### `00_create_database.sql`
- **Purpose:** Initializes the PostgreSQL database instance.
- **Action:** Creates `nexora_db`.

### `01_verify_setup.sql`
- **Purpose:** Environment sanity check.
- **Action:** Confirms the connected database (`nexora_db`), active database user, and PostgreSQL 16 engine version.

### `02_create_tables.sql`
- **Purpose:** Core Data Definition Language (DDL) script.
- **Action:** Builds the complete relational schema within an atomic transaction block (`BEGIN ... COMMIT`):
  - `customers`: Profiles, registration timestamps, customer categories (`INDIVIDUAL`, `MERCHANT`), and statuses.
  - `kyc_records`: Multi-submission identity document tracking (`NIN`, `BVN`, `PASSPORT`, `DRIVERS_LICENCE`) with status checks.
  - `accounts`: Wallets in NGN with regex-validated 10-digit account numbers and non-negative balance checks (`CHECK (balance >= 0)`).
  - `beneficiaries`: Saved external/internal transfer counterparties with composite uniqueness (`customer_id`, `bank_name`, `account_number`).
  - `cards`: Debit and virtual payment cards with PCI-DSS safe 4-digit masking.
  - `transactions`: Business intent headers with UUID/hash idempotency keys and self-referencing reversal links (`reversal_of`).
  - `ledger_entries`: Double-entry accounting line items ensuring every transaction produces balanced `DEBIT` and `CREDIT` entries.
  - `fraud_flags`: Suspicious activity logs with risk scores (0–100) and review statuses.

### `03_constraint_tests.sql`
- **Purpose:** Automated constraint validation suite.
- **Action:** Runs 10 isolated PL/pgSQL unit tests against database constraints:
  - **Test 1:** Negative balance rejection (`CHECK balance >= 0`).
  - **Test 2:** Malformed 10-digit account number rejection (regex check).
  - **Test 3:** Zero-amount transaction rejection (`CHECK amount > 0`).
  - **Test 4:** Reversal transaction without parent transaction rejection.
  - **Test 5:** Duplicate email rejection (`UNIQUE` violation).
  - **Test 6:** Repeated idempotency key rejection (preventing double debits).
  - **Test 7:** Account creation for non-existent customer rejection (`FOREIGN KEY`).
  - **Test 8:** Deletion of customer with existing financial history blocked (`ON DELETE RESTRICT`).
  - **Test 9:** Out-of-bounds fraud risk score rejection (`CHECK risk_score BETWEEN 0 AND 100`).
  - **Test 10:** Duplicate ledger line rejection (`UNIQUE (transaction_id, account_id, direction)`).

### `04_seed_data.sql`
- **Purpose:** High-volume deterministic synthetic data generator.
- **Action:** Uses `setseed(0.42)` for reproducible generation of realistic production-scale data:
  - 1 internal settlement merchant customer and account (`1000000000`) with a 1,000,000,000,000 NGN liquidity pool.
  - 5,000 customer accounts across individual and merchant tiers.
  - KYC verification records (including realistic resubmissions for rejected documents).
  - ~6,000 active and frozen wallets, ~3,000 payment cards, and ~15,000 saved beneficiaries.
  - Opening deposits of 1,000,000 NGN for all customer wallets.
  - 200,000 wallet-to-wallet P2P transfers spanning the last 360 days (including ~2% failed transfers and ~100 reversed transactions).
  - Double-entry ledger postings with running `balance_after` calculations for all completed transactions.
  - Synchronized `accounts.balance` updates matching latest ledger state.
  - Flagged suspicious transfers in `fraud_flags`.

### `05_verify_seed.sql`
- **Purpose:** Post-seed data integrity and reconciliation audit.
- **Action:** Validates database consistency through 7 diagnostic checks:
  1. Row counts across all 8 tables.
  2. Transaction counts grouped by transaction type and status (`COMPLETED`, `FAILED`, `REVERSED`).
  3. Double-entry arithmetic verification: confirms zero unbalanced transactions ($\sum \text{Debits} - \sum \text{Credits} = 0$).
  4. Cached balance reconciliation: verifies `accounts.balance` matches the sum of ledger entries for all accounts.
  5. Audit of completed/reversed transactions with missing ledger entries (expected: 0).
  6. Audit of failed transactions to guarantee no ledger entries were created (expected: 0).
  7. Performance preview: identifies the 5 busiest accounts by ledger entry volume for subsequent query optimization (Portfolio 2).

---

## 4. Controlled 3NF Denormalisation Summary

While the schema adheres strictly to 3NF/BCNF across core relations, four deliberate denormalisations were implemented to meet critical financial engineering requirements:

1. **`accounts.balance`:** Stored derived aggregate of `ledger_entries`. Eliminates costly runtime `SUM()` aggregations on high-throughput read paths and enables lightweight row-level pessimistic locking (`SELECT ... FOR UPDATE`).
2. **`ledger_entries.balance_after`:** Running balance snapshot per entry. Guarantees tamper-evident audit history and sub-millisecond statement generation without recursive CTEs.
3. **`transactions.amount`:** Preserves customer business intent on the transaction header separately from multi-line accounting splits, enabling rapid indexing and instant AML velocity checks.
4. **`beneficiaries.account_name`:** Point-in-time recipient name snapshot. Isolates the database from external banking network latency (NIP/NIBSS) and stabilizes customer contact lists.

*(For detailed mathematical proofs and dependency analysis, see [normalisation.md](normalisation.md).)*

---

## 5. Verification & Screenshots

Screenshots evidencing setup, schema creation, constraint testing, and seed verification in pgAdmin 4 are located in the [screenshots/](screenshots/) folder:
- **Setup Verification:** `Bamishaye_Favour_301915930_01setup.png`
- **Entity Relationship Model:** `Bamishaye_Favour_301915930_er_diagram.png`
- **Schema Creation:** `Bamishaye_Favour_301915930_table01.png`, `Bamishaye_Favour_301915930_table02.png`
- **Seed Execution:** `Bamishaye_Favour_301915930_seed_data.png`
- **Seed Verification & Balancing:** `Bamishaye_Favour_301915930_verify_seed_data.png`, `Bamishaye_Favour_301915930_verify_table_account_data.png`