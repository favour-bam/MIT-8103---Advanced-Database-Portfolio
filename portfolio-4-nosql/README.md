# Portfolio 4: NoSQL Document Store (MongoDB)

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Bamishaye Favour (ID: 301915930)  
**Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**DBMS:** MongoDB (Atlas Cloud Cluster / `mongosh` 2.x)  
**Database:** `nexora_db`  
**Scale:** 5,000 KYC profiles, 100,000 audit log events, ephemeral login sessions  

---

## 1. Architectural Overview & Polyglot Persistence

In modern enterprise fintech platforms like **Nexora**, a single database engine cannot optimally satisfy all workload characteristics. While PostgreSQL powers Nexora's relational core (Portfolios 1–3) for strict double-entry ledger accounting, ACID transfers, and regulatory reconciliation, **MongoDB** is deployed as a complementary document store under a **Polyglot Persistence** architecture.

For exhaustive data modeling theory, embedding vs. referencing trade-offs, and schema design decisions, see:  
👉 **[nosql-model-design.md](nosql-model-design.md)**

```
                           ┌─────────────────────────────────────────┐
                           │         Nexora Fintech Platform         │
                           └────────────────────┬────────────────────┘
                                                │
                       ┌────────────────────────┴────────────────────────┐
                       ▼                                                 ▼
        ┌─────────────────────────────┐                   ┌─────────────────────────────┐
        │  PostgreSQL 16 (Relational) │                   │  MongoDB Atlas (Document)   │
        ├─────────────────────────────┤                   ├─────────────────────────────┤
        │ • Customer Core Entities    │                   │ • Polymorphic KYC Profiles  │
        │ • Double-Entry Ledgers      │                   │ • Append-Only Audit Logs    │
        │ • ACID Fund Transfers       │                   │ • High-Velocity Events      │
        │ • Non-negative Balances     │                   │ • Auto-Expiring Sessions    │
        └─────────────────────────────┘                   └─────────────────────────────┘
```

### Why MongoDB for Nexora's Secondary Domains?

1. **Polymorphic KYC Document Modeling (`kyc_profiles`):**  
   Identity verification documents inherently exhibit structural divergence: a **Passport** carries international travel authority, country code, and expiry dates; a **Driver’s Licence** contains state-of-issue and license endorsements; a **BVN** (Bank Verification Number) carries centralized NIBSS verification tokens without expiration; and a **Utility Bill** features service providers and billing cycles. In a pure relational database, this requires sparse tables with dozens of `NULL` columns or cumbersome entity-attribute-value (EAV) anti-patterns. MongoDB's document model represents these as an embedded polymorphic array within a single atomic document.

2. **High-Volume Telemetry & Audit Trails (`audit_events`):**  
   Financial compliance requires an append-only log of user behaviors (`LOGIN_SUCCESS`, `LOGIN_FAILED`, `TRANSFER_INITIATED`, `PIN_CHANGED`, `KYC_UPGRADED`, `FRAUD_FLAG`). Each event carries dynamic telemetry payloads (e.g., client IPs, geolocation, failure reasons, transfer amounts, or ML fraud risk scores). MongoDB accommodates variable schema shapes without DDL schema migration locking.

3. **Self-Pruning Ephemeral State (`login_sessions`):**  
   Mobile auth tokens and transient user sessions must expire strictly after 60 minutes. MongoDB natively provides native Background Time-To-Live (TTL) index mechanics that autonomously purge expired tokens without cron jobs or database batch triggers.

---

## 2. Directory Structure

```
portfolio-4-nosql/
├── README.md                                  # Comprehensive portfolio documentation
├── nosql-model-design.md                      # In-depth NoSQL data modeling & architecture report
├── script/                                    # Automated mongosh JavaScript scripts
│   ├── 01_schema_validation.js               # Collection initialization & JSON Schema validation
│   ├── 02_seed_data.js                       # Deterministic LCG synthetic data generator (105k+ docs)
│   ├── 03_crud_and_aggregation.js             # CRUD operations & 4 enterprise aggregation pipelines
│   └── 04_indexes_explain.js                 # Indexing strategy, explain() profiling & TTL demo
├── output/                                    # Raw execution output transcripts
│   ├── 03_crud_and_aggregation.txt            # Console output from CRUD and aggregation suite
│   └── 04_indexes_explain.txt                 # Detailed executionStats (before vs. after indexing)
└── screenshots/                               # MongoDB Atlas & mongosh execution evidence
    ├── Bamishaye_Favour_301915930_MongoDB_setup_with_atlas.png
    ├── Bamishaye_Favour_301915930_schema_validation_01.png
    ├── Bamishaye_Favour_301915930_schema_validation_02.png
    ├── Bamishaye_Favour_301915930_seed_data_kyc_profiles.png
    ├── Bamishaye_Favour_301915930_seed_data_audit_events.png
    ├── Bamishaye_Favour_301915930_seed_data_login_session.png
    ├── Bamishaye_Favour_301915930_login_session.png
    ├── Bamishaye_Favour_301915930_indexes_explain.png
    └── Bamishaye_Favour_301915930_after_indexes_explain.png
```

---

## 3. Scripts Implementation & Execution Flow

Scripts are designed for non-interactive automated execution via `mongosh`:

### `script/01_schema_validation.js` — Schema Validation Rules
- **Purpose:** Enforces structured document governance using MongoDB `$jsonSchema` validators while retaining flexible nested attributes.
- **Rules Configured:**
  - `kyc_profiles`: Mandates `customer_id` (numeric cross-reference to PostgreSQL `customers.customer_id`), `tier` (1–3), `status` (`['PENDING', 'VERIFIED', 'REJECTED']`), `created_at`, and a `documents` array containing at least 1 document with strict sub-object definitions (`type` in `['BVN', 'NIN', 'PASSPORT', 'DRIVERS_LICENCE', 'UTILITY_BILL']`, `number`). Set with `validationAction: 'error'`.
  - `audit_events`: Mandates `customer_id`, `event_type` enum, UTC timestamp `ts`, and dynamic payload object `details`. Set with `validationAction: 'error'`.
  - `login_sessions`: Unconstrained collection ready for TTL index configuration.
- **Constraint Proof:** Intentionally executes an invalid document insertion (`{ customer_id: 1, status: 'MAYBE' }`). The script captures and verifies the rejection:  
  `PASS: invalid KYC document rejected -> DocumentValidationFailure (code 121)`.

### `script/02_seed_data.js` — Deterministic High-Volume Seeding
- **Purpose:** Generates reproducible, realistic fintech customer profiles and audit traffic.
- **Generator Mechanics:** Utilizes a Linear Congruential Generator (LCG) with `seedState = 42` (analogous to `setseed()` in PostgreSQL) ensuring consistent multi-run parity.
- **Generated Entities:**
  - **5,000 KYC Profiles:** Distributed across Tier 1 (55%), Tier 2 (33%), and Tier 3 (12%). Tier 1 contains BVN; Tier 2 appends NIN or Driver’s Licence; Tier 3 appends international Passport and Utility Bills. Statuses realistically seeded as 93% `VERIFIED`, 3.5% `PENDING`, 3.5% `REJECTED`.
  - **100,000 Audit Events:** Distributed across the preceding 90 days in un-ordered 5,000-document batches:
    - `LOGIN_SUCCESS` (~40%): IP addresses, Nigerian cities (Lagos, Abuja, PH, Ibadan, etc.), devices.
    - `LOGIN_FAILED` (~15%): Targeted IPs, failure reasons (`WRONG_PIN`, `DEVICE_NOT_RECOGNISED`, `ACCOUNT_LOCKED`).
    - `TRANSFER_INITIATED` (~30%): Unique transaction references, `NumberDecimal` monetary amounts, channels (`APP`, `USSD`, `WEB`).
    - `PIN_CHANGED` (~5%): Channel telemetry.
    - `KYC_UPGRADED` (~5%): Stage transition metrics (`from_tier`, `to_tier`).
    - `FRAUD_FLAG` (~5%): Risk rules (`VELOCITY`, `NEW_DEVICE_LARGE_AMOUNT`, `MANY_FAILED_LOGINS`) and scores (40–99).

### `script/03_crud_and_aggregation.js` — CRUD Lifecycle & Aggregation Analytics
- **CRUD Suite:**
  - **CREATE:** Onboards customer `999999` with nested verification documents.
  - **READ:** Queries nested arrays using `$elemMatch` (e.g., tier 3 passport holders, passports expiring within 365 days) and filtered sort limits.
  - **UPDATE:** Atomic upgrades using `$set` (status/tier) alongside `$push` to dynamically append utility bills; appends corresponding immutable audit events.
  - **DELETE:** Clean teardown of temporary test customer documents.
- **Enterprise Aggregation Pipelines:**
  1. **Event Velocity:** Aggregates event volumes by `event_type` over the last 30 days (`$match` $\rightarrow$ `$group` $\rightarrow$ `$sort`).
  2. **Daily Financial Volume:** Computes transfer count and sum of `details.amount` grouped by date for the last 5 days using `$dateToString`.
  3. **AML Fraud Correlation ($lookup Join):** Emulates a relational join. Matches `LOGIN_FAILED` events, groups by customer, filters top 5 worst offenders, joins with `kyc_profiles` via `$lookup`, unwinds, and projects the customer ID, failed login count, KYC tier, and status.
  4. **Tier Complexity Metrics:** Computes the average number of verification documents held per tier using `$size` and `$avg`.

### `script/04_indexes_explain.js` — Index Optimization, Profiling & TTL
- **Benchmarked Workloads:**
  - **Q1 (Customer History):** `audit_events.find({ customer_id: 1001 }).sort({ ts: -1 }).limit(20)`
  - **Q2 (AML Fraud Range):** `audit_events.find({ event_type: 'FRAUD_FLAG', ts: { $gte: 7_days_ago } })`
  - **Q3 (Profile Lookup):** `kyc_profiles.find({ customer_id: 2500 })`
- **Engineered Indexes:**
  - `idx_audit_customer_ts`: Compound `{ customer_id: 1, ts: -1 }` on `audit_events`.
  - `idx_audit_type_ts`: Compound `{ event_type: 1, ts: -1 }` on `audit_events`.
  - `uq_kyc_customer`: Unique single-field index `{ customer_id: 1 }` on `kyc_profiles`.
  - `ttl_session_1h`: Background TTL index `{ created_at: 1 }` with `expireAfterSeconds: 3600` on `login_sessions`.
- **Integrity Enforcement Proof:** Tests insertion of duplicate `customer_id` into `kyc_profiles`, demonstrating error code `11000` (DuplicateKey).

---

## 4. Empirical Performance Benchmark (`explain('executionStats')`)

The table below summarizes the quantitative performance improvements measured across the 100,000-document dataset before and after index creation (extracted directly from [output/04_indexes_explain.txt](output/04_indexes_explain.txt)):

| Query | Workload Description | Metric | Before Indexing (Baseline) | After Indexing (Optimized) | Impact / Speedup |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Q1** | Recent 20 events for Customer 1001 | **Winning Plan**<br>**Docs Examined**<br>**Keys Examined**<br>**Execution Time** | `SORT > COLLSCAN`<br>100,000<br>0<br>**434 ms** | `LIMIT > FETCH > IXSCAN`<br>20<br>20<br>**8 ms** | **98.2% latency reduction**<br>(54.25x faster, 0 in-memory sort) |
| **Q2** | `FRAUD_FLAG` events in last 7 days | **Winning Plan**<br>**Docs Examined**<br>**Keys Examined**<br>**Execution Time** | `COLLSCAN`<br>100,000<br>0<br>**38 ms** | `FETCH > IXSCAN`<br>362<br>362<br>**2 ms** | **94.7% latency reduction**<br>(19.0x faster, zero wasted scans) |
| **Q3** | Unique profile lookup (`customer_id: 2500`) | **Winning Plan**<br>**Docs Examined**<br>**Keys Examined**<br>**Execution Time** | `COLLSCAN`<br>5,000<br>0<br>**20 ms** | `EXPRESS_IXSCAN`<br>1<br>1<br>**2 ms** | **90.0% latency reduction**<br>(10.0x faster, exact point-lookup) |

### Key Optimization Takeaways:
1. **Elimination of In-Memory Blocking Sorts (Q1):**  
   Without an index, MongoDB scans all 100,000 documents into RAM and runs an in-memory blocking sort before taking the top 20 (`SORT > COLLSCAN`). The compound index `{ customer_id: 1, ts: -1 }` stores keys in the exact B-tree sort order required, allowing MongoDB to perform an index walk and terminate immediately after examining 20 keys.
2. **Selective Range Filtering (Q2):**  
   The compound index `{ event_type: 1, ts: -1 }` satisfies the equality condition on event type first and traverses only the matching date range, reducing document inspections from 100,000 down to exactly the 362 matching records.
3. **Storage Overhead Trade-off:**  
   Index sizes were measured post-run:
   - `audit_events`: 14.5 MB raw data, 3.3 MB index footprint (~22.7% index overhead).
   - `kyc_profiles`: 1.2 MB raw data, 0.2 MB index footprint (~16.6% index overhead).

---

## 5. Visual Evidence & Screenshots

All supporting screenshots from MongoDB Atlas and terminal runs are archived in [`screenshots/`](screenshots/):

| Screenshot | Description & Visual Proof |
| :--- | :--- |
| [`MongoDB_setup_with_atlas.png`](screenshots/Bamishaye_Favour_301915930_MongoDB_setup_with_atlas.png) | MongoDB Atlas connection verification showing successful cluster connectivity and database selection. |
| [`schema_validation_01.png`](screenshots/Bamishaye_Favour_301915930_schema_validation_01.png) | Initialization of collections with `$jsonSchema` validation scripts. |
| [`schema_validation_02.png`](screenshots/Bamishaye_Favour_301915930_schema_validation_02.png) | Proof of schema validator rejecting malformed documents (`DocumentValidationFailure`). |
| [`seed_data_kyc_profiles.png`](screenshots/Bamishaye_Favour_301915930_seed_data_kyc_profiles.png) | 5,000 KYC profiles seeded with nested polymorphic document structures. |
| [`seed_data_audit_events.png`](screenshots/Bamishaye_Favour_301915930_seed_data_audit_events.png) | 100,000 audit events successfully committed in batches with event distribution output. |
| [`seed_data_login_session.png`](screenshots/Bamishaye_Favour_301915930_seed_data_login_session.png) | Collection inventory confirming all collections populated in `nexora_db`. |
| [`login_session.png`](screenshots/Bamishaye_Favour_301915930_login_session.png) | Deployment of TTL index on `login_sessions` with automated 1-hour expiration. |
| [`indexes_explain.png`](screenshots/Bamishaye_Favour_301915930_indexes_explain.png) | Baseline `explain('executionStats')` displaying `COLLSCAN` operations and high document reads. |
| [`after_indexes_explain.png`](screenshots/Bamishaye_Favour_301915930_after_indexes_explain.png) | Optimized execution plans displaying `IXSCAN`, millisecond response times, and index metrics. |

---

## 6. How to Run & Reproduce

### Prerequisites
- MongoDB Atlas cluster or local MongoDB instance ($\ge$ 7.0).
- `mongosh` (MongoDB Shell) installed locally.
- Set the connection string environment variable:
  ```bash
  export MONGODB_URI="mongodb+srv://<username>:<password>@<cluster-url>/nexora_db"
  ```

### Step-by-Step Execution

1. **Deploy Schema Validation:**
   ```bash
   mongosh "$MONGODB_URI" script/01_schema_validation.js
   ```

2. **Generate Deterministic Seed Data (5k profiles, 100k events):**
   ```bash
   mongosh "$MONGODB_URI" script/02_seed_data.js
   ```

3. **Execute CRUD & Enterprise Aggregation Pipelines:**
   ```bash
   mongosh "$MONGODB_URI" script/03_crud_and_aggregation.js
   ```

4. **Run Profiling, Index Creation & Explain Analysis:**
   ```bash
   mongosh "$MONGODB_URI" script/04_indexes_explain.js
   ```
