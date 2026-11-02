# Nexora: NoSQL Document Data Modeling & Architecture Design

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Bamishaye Favour (ID: 301915930)  
**Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**Target DBMS:** MongoDB (Atlas Cloud Cluster / `mongosh` 2.x)  
**Database:** `nexora_db`  
**Artifact:** `nosql-model-design.md`  

---

## 1. Executive Summary & Problem Formulation

In high-concurrency digital banking and financial management applications, database architecture directly dictates system scalability, fault tolerance, and developer velocity. **Nexora** operates a dual-wallet digital savings platform processing millions of mobile transactions, customer onboarding submissions, and security audits.

In Portfolios 1 through 3, Nexora's relational core was designed and optimized in PostgreSQL 16 to guarantee strict double-entry ledger invariants, ACID transactional safety, and sub-millisecond query execution. However, as Nexora scales, several mission-critical operational workloads place conflicting demands on a pure relational engine:

1. **Polymorphic Identity Verification (KYC):** Customers submit divergent combinations of identity documents (BVN, NIN, National Passport, Driver’s Licence, Utility Bills), each possessing unique verification attributes, expiration lifecycles, and regulatory issuer metadata.
2. **High-Velocity Append-Only Audit Telemetry:** Compliance mandates recording all user actions (logins, authentication failures, credential mutations, transfer initiations, AML alerts) with unstructured, event-specific contextual payloads.
3. **High-Churn Ephemeral State:** Mobile authentication tokens and session states experience rapid creation and expiration cycles, risking table bloat and high autovacuum overhead in relational systems.

To resolve these challenges without compromising financial integrity, Nexora employs a **Polyglot Persistence Architecture**. This document details the architectural rationale, schema modeling choices, embedding versus referencing trade-offs, index engineering, and aggregation pipeline design for Nexora's document store implemented in **MongoDB**.

---

## 2. Polyglot Persistence Architecture & Domain Boundaries

### 2.1. Domain Allocation Matrix

Nexora explicitly segregates domain responsibilities between PostgreSQL and MongoDB based on transactional requirements, schema mutability, and access patterns:

| Architectural Domain | Primary DBMS | Model Type | Core Invariants & Access Characteristics |
| :--- | :--- | :--- | :--- |
| **Double-Entry Ledgers** | PostgreSQL 16 | Relational | Strict mathematical balance ($\sum \text{Debits} = \sum \text{Credits}$), foreign keys, immutable audit trails. |
| **Wallets & Balances** | PostgreSQL 16 | Relational | Atomicity, row-level pessimistic locking (`FOR UPDATE`), non-negative balance checks (`CHECK balance >= 0`). |
| **Fund Transfers (P2P)** | PostgreSQL 16 | Relational | ACID transactions, canonical ordered locking to prevent deadlocks, strict serializability. |
| **KYC Profiles & Verification** | **MongoDB** | Document | Polymorphic nested arrays, diverse document types, evolving regulatory attributes, point-in-time schema validation. |
| **Audit & Security Telemetry** | **MongoDB** | Document | Append-only, high ingestion rate, heterogeneous JSON payloads, time-series querying, rapid range scans. |
| **Authentication Sessions** | **MongoDB** | Document | High write/delete churn, self-pruning lifecycle via native TTL B-tree indexes, no transactional locks. |

```
                                  ┌─────────────────────────────┐
                                  │   Nexora API / Microservices│
                                  └──────────────┬──────────────┘
                                                 │
                      ┌──────────────────────────┴──────────────────────────┐
                      ▼                                                     ▼
       ┌──────────────────────────────┐                      ┌──────────────────────────────┐
       │   PostgreSQL 16 (Relational) │                      │   MongoDB Atlas (Document)   │
       ├──────────────────────────────┤                      ├──────────────────────────────┤
       │ • customers                  │                      │ • kyc_profiles               │
       │ • accounts                   │                      │   (polymorphic identity docs)│
       │ • transactions               │                      │ • audit_events               │
       │ • ledger_entries             │                      │   (append-only event stream) │
       │ • beneficiaries / cards      │                      │ • login_sessions             │
       │ • ACID Stored Procedures     │                      │   (ephemeral TTL state)      │
       └──────────────────────────────┘                      └──────────────────────────────┘
                      ▲                                                     ▲
                      └───────────────── Distributed Key ───────────────────┘
                                         (customer_id)
```

### 2.2. Distributed Correlation Key (`customer_id`)

The relational `customers.customer_id` integer acts as the deterministic distributed correlation key linking PostgreSQL customer entities to their corresponding MongoDB documents. This maintains loose coupling:
- Operational microservices query PostgreSQL for customer account standing and ledger balances.
- Onboarding, KYC review, and AML fraud microservices query MongoDB using `{ customer_id: <id> }` to inspect document collections and security event logs.
- Eventual consistency is managed asynchronously via idempotent domain events.

---

## 3. Data Modeling Principles: Embedding vs. Referencing

A core architectural challenge in NoSQL document database design is determining whether related data should be **embedded** within a parent document or **referenced** across separate collections.

```
                           ┌──────────────────────────────┐
                           │ Embedding vs. Referencing    │
                           │ Decision Matrix for Nexora   │
                           └──────────────┬───────────────┘
                                          │
            ┌─────────────────────────────┴─────────────────────────────┐
            ▼                                                           ▼
┌───────────────────────────────────────┐   ┌───────────────────────────────────────┐
│              EMBEDDING                │   │              REFERENCING              │
├───────────────────────────────────────┤   ├───────────────────────────────────────┤
│ • 1:1 or Bounded 1:N Relationships    │   │ • Unbounded 1:N Relationships         │
│ • Retrieved together in 1 atomic read │   │ • Independent access lifecycles       │
│ • Low cardinality (< 10 items)        │   │ • Exceeds 16 MB BSON document limit   │
│ • Atomic updates without 2PC          │   │ • High write-rate event streams       │
│ Example: kyc_profiles.documents       │   │ Example: audit_events (by customer_id)│
└───────────────────────────────────────┘   └───────────────────────────────────────┘
```

### 3.1. Embedded Model: `kyc_profiles.documents`
- **Relationship:** 1 to Bounded N (a customer holds between 1 and 4 identity verification documents across Tiers 1, 2, and 3).
- **Access Pattern:** The mobile application and compliance officers always retrieve a customer's KYC profile alongside all associated identity documents in a single atomic read operation.
- **Decision:** **Embed**. Embedding eliminates expensive multi-table joins, guarantees document-level ACID atomicity during KYC status updates, and prevents the risk of orphaned document records.

### 3.2. Referenced Model: `audit_events`
- **Relationship:** 1 to Unbounded N (an active customer generates hundreds or thousands of security and operational events over their platform lifetime).
- **The 16 MB Document Limit Trap:** Embedding unbounded audit logs inside the customer profile document would eventually violate MongoDB's 16 MB BSON document size limit, cause massive document memory fragmentation, and drastically inflate read latency for simple profile queries.
- **Decision:** **Reference**. Audit events are stored in a dedicated, append-only `audit_events` collection with `customer_id` as a reference index.

---

## 4. Collection Schemas & JSON Schema Validation

While MongoDB is fundamentally flexible, production financial systems require strict schema governance at the persistence tier. We enforce this using MongoDB `$jsonSchema` validators with `validationAction: 'error'`.

### 4.1. Collection: `kyc_profiles`

#### Structural Rationale
In relational systems, accommodating BVN (11 digits, NIBSS verified), NIN (11 digits, NIMC verified), Passports (international country code, expiry date), Driver’s Licenses (state of issue, expiry date), and Utility Bills (disco provider, billing dates) requires either:
1. Multiple sparsely populated tables with foreign keys.
2. A single bloated table with 20+ nullable columns (`NULL` values for 80% of rows).
3. An Anti-pattern Entity-Attribute-Value (EAV) design that destroys index selectivity.

MongoDB resolves this cleanly: each document contains a polymorphic `documents` array where each element contains common identification fields (`type`, `number`) alongside type-specific fields.

#### JSON Schema Validator Definition
```javascript
nosql.createCollection('kyc_profiles', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['customer_id', 'tier', 'status', 'documents', 'created_at'],
            properties: {
                customer_id: {
                    bsonType: 'number',
                    minimum: 1,
                    description: 'References customers.customer_id in PostgreSQL'
                },
                tier: {
                    bsonType: 'number',
                    minimum: 1,
                    maximum: 3,
                    description: 'KYC Tier (1 = Basic, 2 = Medium, 3 = Enhanced)'
                },
                status: {
                    enum: ['PENDING', 'VERIFIED', 'REJECTED'],
                    description: 'Current verification lifecycle state'
                },
                documents: {
                    bsonType: 'array',
                    minItems: 1,
                    items: {
                        bsonType: 'object',
                        required: ['type', 'number'],
                        properties: {
                            type: {
                                enum: ['BVN', 'NIN', 'PASSPORT', 'DRIVERS_LICENCE', 'UTILITY_BILL']
                            },
                            number: { bsonType: 'string' }
                        }
                    }
                },
                created_at: { bsonType: 'date' }
            }
        }
    },
    validationAction: 'error'
});
```

#### Sample Polymorphic Tier 3 Document
```json
{
  "_id": ObjectId("671e62bc1234567890abcdef"),
  "customer_id": 4821,
  "tier": 3,
  "status": "VERIFIED",
  "documents": [
    {
      "type": "BVN",
      "number": "22194857201",
      "verified_with": "NIBSS"
    },
    {
      "type": "NIN",
      "number": "58201948201",
      "verified_with": "NIMC"
    },
    {
      "type": "PASSPORT",
      "number": "A09283741",
      "country": "NG",
      "expiry": ISODate("2032-11-14T00:00:00.000Z")
    },
    {
      "type": "UTILITY_BILL",
      "number": "UB84920194",
      "provider": "Ikeja Electric",
      "issued_on": ISODate("2026-09-12T00:00:00.000Z")
    }
  ],
  "risk_notes": "Enhanced due diligence completed",
  "devices": [
    {
      "platform": "iPhone",
      "first_seen": ISODate("2026-01-15T08:30:00.000Z")
    }
  ],
  "created_at": ISODate("2025-08-10T14:22:10.000Z")
}
```

---

### 4.2. Collection: `audit_events`

#### Structural Rationale
Audit events represent an immutable, append-only time-series stream. Because security events carry varying diagnostic data (an authentication failure tracks IP and failure reason; a fund transfer tracks payment references, channels, and monetary sums; a fraud flag tracks risk detection rules and scores), the `details` field is modeled as a polymorphic sub-document.

#### JSON Schema Validator Definition
```javascript
nosql.createCollection('audit_events', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['customer_id', 'event_type', 'ts', 'details'],
            properties: {
                customer_id: { bsonType: 'number', minimum: 1 },
                event_type: {
                    enum: [
                        'LOGIN_SUCCESS',
                        'LOGIN_FAILED',
                        'PIN_CHANGED',
                        'TRANSFER_INITIATED',
                        'KYC_UPGRADED',
                        'FRAUD_FLAG'
                    ]
                },
                ts: { bsonType: 'date' },
                details: { bsonType: 'object' }
            }
        }
    },
    validationAction: 'error'
});
```

#### Sample Audit Event Documents
```json
// Example 1: Security Telemetry (Failed Login)
{
  "_id": ObjectId("671e62bc1234567890abcde1"),
  "customer_id": 1001,
  "event_type": "LOGIN_FAILED",
  "ts": ISODate("2026-10-23T19:21:02.276Z"),
  "details": {
    "ip": "41.58.112.45",
    "reason": "DEVICE_NOT_RECOGNISED"
  }
}

// Example 2: Financial Telemetry (Transfer Initiated)
{
  "_id": ObjectId("671e62bc1234567890abcde2"),
  "customer_id": 1001,
  "event_type": "TRANSFER_INITIATED",
  "ts": ISODate("2026-10-24T10:14:05.120Z"),
  "details": {
    "reference": "ref-8492019482",
    "amount": NumberDecimal("125000.00"),
    "channel": "APP"
  }
}
```

---

### 4.3. Collection: `login_sessions` (Ephemeral State & TTL Lifecycle)

#### Structural Rationale
User authentication tokens (JWTs, mobile session handles) must be valid for exactly 1 hour following issuance. Rather than running scheduled cleanup scripts (e.g., cron jobs executing `DELETE FROM sessions WHERE expires_at < NOW()`, which causes relational table locks and deadlocks), MongoDB natively supports **Time-To-Live (TTL)** B-tree indexes.

#### TTL Index Configuration
```javascript
nosql.login_sessions.createIndex(
    { created_at: 1 },
    { expireAfterSeconds: 3600, name: 'ttl_session_1h' }
);
```

#### Lifecycle Mechanics
1. On login, the authentication gateway inserts a document with `created_at: new Date()`.
2. A background thread within MongoDB's storage engine runs every 60 seconds, reads the `ttl_session_1h` index, and automatically purges documents whose `created_at` timestamp is older than 3600 seconds.
3. This guarantees zero maintenance overhead, zero deadlocks, and bounded storage usage.

---

## 5. Indexing Strategy & Execution Plan Profiling

### 5.1. The Equality-Sort-Range (ESR) Indexing Rule
To maximize index efficiency and eliminate in-memory sorting, indexes in Nexora are constructed following the canonical **Equality, Sort, Range (ESR)** design principle:

1. **Equality (`E`):** Fields queried with exact matching (`customer_id: 1001`, `event_type: 'FRAUD_FLAG'`) appear first.
2. **Sort (`S`):** Fields dictating query order (`ts: -1`) appear next to enable the query planner to walk the B-tree directly without allocating an in-memory buffer.
3. **Range (`R`):** Fields queried via inequalities (`ts: { $gte: ... }`) appear last.

```
                              Compound Index: { customer_id: 1, ts: -1 }
                                     ▲                   ▲
                                     │                   │
                               [ Equality ]           [ Sort ]
```

### 5.2. Engineered Production Indexes

```javascript
// 1. Customer Audit History: satisfies equality on customer_id, sort on ts
nosql.audit_events.createIndex(
    { customer_id: 1, ts: -1 },
    { name: 'idx_audit_customer_ts' }
);

// 2. Event Type Range Audit: satisfies equality on event_type, range scan on ts
nosql.audit_events.createIndex(
    { event_type: 1, ts: -1 },
    { name: 'idx_audit_type_ts' }
);

// 3. Unique KYC Enforcement: guarantees 1:1 mapping between customer and profile
nosql.kyc_profiles.createIndex(
    { customer_id: 1 },
    { unique: true, name: 'uq_kyc_customer' }
);
```

---

### 5.3. Empirical Execution Plan Analysis (`explain('executionStats')`)

The empirical effectiveness of this indexing strategy was benchmarked against the full dataset (5,000 KYC profiles and 100,000 audit events). Detailed execution results from [`output/04_indexes_explain.txt`](output/04_indexes_explain.txt) are summarized below:

```
────────────────────────────────────────────────────────────────────────────────────────
Query 1: Latest 20 Audit Events for Customer 1001
Filter: { customer_id: 1001 }.sort({ ts: -1 }).limit(20)
────────────────────────────────────────────────────────────────────────────────────────
Baseline (Unindexed):
  • Winning Plan Stages : SORT > COLLSCAN
  • Docs Examined       : 100,000 (100% of collection scanned)
  • Keys Examined       : 0
  • Execution Time      : 434 ms

Optimized (Compound Index: idx_audit_customer_ts):
  • Winning Plan Stages : LIMIT > FETCH > IXSCAN
  • Docs Examined       : 20
  • Keys Examined       : 20
  • Execution Time      : 8 ms
  • Latency Improvement : 98.16% reduction (54.25x faster, zero memory sort)
────────────────────────────────────────────────────────────────────────────────────────

────────────────────────────────────────────────────────────────────────────────────────
Query 2: High-Priority Fraud Flags in Last 7 Days
Filter: { event_type: 'FRAUD_FLAG', ts: { $gte: 7_days_ago } }
────────────────────────────────────────────────────────────────────────────────────────
Baseline (Unindexed):
  • Winning Plan Stages : COLLSCAN
  • Docs Examined       : 100,000
  • Keys Examined       : 0
  • Execution Time      : 38 ms

Optimized (Compound Index: idx_audit_type_ts):
  • Winning Plan Stages : FETCH > IXSCAN
  • Docs Examined       : 362
  • Keys Examined       : 362
  • Execution Time      : 2 ms
  • Latency Improvement : 94.74% reduction (19.0x faster)
────────────────────────────────────────────────────────────────────────────────────────

────────────────────────────────────────────────────────────────────────────────────────
Query 3: KYC Profile Point Lookup
Filter: { customer_id: 2500 }
────────────────────────────────────────────────────────────────────────────────────────
Baseline (Unindexed):
  • Winning Plan Stages : COLLSCAN
  • Docs Examined       : 5,000
  • Keys Examined       : 0
  • Execution Time      : 20 ms

Optimized (Unique Index: uq_kyc_customer):
  • Winning Plan Stages : EXPRESS_IXSCAN
  • Docs Examined       : 1
  • Keys Examined       : 1
  • Execution Time      : 2 ms
  • Latency Improvement : 90.00% reduction (10.0x faster)
────────────────────────────────────────────────────────────────────────────────────────
```

---

## 6. Analytical Aggregation Pipelines

To support real-time dashboards, compliance reporting, and AML detection without offloading processing to application servers, Nexora executes native MongoDB aggregation pipelines.

### 6.1. Pipeline 1: 30-Day Event Type Distribution
- **Objective:** Quantifies activity across all security event types over the last 30 days.
- **Stages:** `$match` (date filter) $\rightarrow$ `$group` (aggregate counts by `event_type`) $\rightarrow$ `$sort` (descending volume).
```javascript
nosql.audit_events.aggregate([
    { $match: { ts: { $gte: new Date(Date.now() - 30 * 86400000) } } },
    { $group: { _id: '$event_type', events: { $sum: 1 } } },
    { $sort: { events: -1 } }
]);
```

### 6.2. Pipeline 2: Financial Telemetry & Daily Liquidity Velocity
- **Objective:** Aggregates initiated transfer counts and gross transaction value per day for the latest 5 active days.
- **Stages:** `$match` (`TRANSFER_INITIATED`) $\rightarrow$ `$group` (date formatted string via `$dateToString`, count, and `$sum` on `details.amount`) $\rightarrow$ `$sort` $\rightarrow$ `$limit` (5).
```javascript
nosql.audit_events.aggregate([
    { $match: { event_type: 'TRANSFER_INITIATED' } },
    {
        $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$ts' } },
            transfers: { $sum: 1 },
            total_amount: { $sum: '$details.amount' }
        }
    },
    { $sort: { _id: -1 } },
    { $limit: 5 }
]);
```

### 6.3. Pipeline 3: AML Correlation via Multi-Collection `$lookup`
- **Objective:** Identifies the top 5 customers with repeated authentication failures (`LOGIN_FAILED`) and joins with their KYC profile to evaluate their current verification tier and onboarding status.
- **Stages:** `$match` $\rightarrow$ `$group` (count failed logins by customer) $\rightarrow$ `$sort` $\rightarrow$ `$limit` (5) $\rightarrow$ `$lookup` (emulating a SQL join on `kyc_profiles.customer_id`) $\rightarrow$ `$unwind` $\rightarrow$ `$project`.
```javascript
nosql.audit_events.aggregate([
    { $match: { event_type: 'LOGIN_FAILED' } },
    { $group: { _id: '$customer_id', failed_logins: { $sum: 1 } } },
    { $sort: { failed_logins: -1, _id: 1 } },
    { $limit: 5 },
    {
        $lookup: {
            from: 'kyc_profiles',
            localField: '_id',
            foreignField: 'customer_id',
            as: 'kyc'
        }
    },
    { $unwind: '$kyc' },
    {
        $project: {
            _id: 0,
            customer_id: '$_id',
            failed_logins: 1,
            tier: '$kyc.tier',
            status: '$kyc.status'
        }
    }
]);
```

### 6.4. Pipeline 4: Schema Complexity & Tier Cardinality Analysis
- **Objective:** Audits the average number of verification documents held per customer tier to measure compliance burden and data footprint.
- **Stages:** `$group` (grouped by `tier`, counting profiles and computing `$avg` on `$size` of `documents` array) $\rightarrow$ `$sort`.
```javascript
nosql.kyc_profiles.aggregate([
    {
        $group: {
            _id: '$tier',
            customers: { $sum: 1 },
            avg_documents: { $avg: { $size: '$documents' } }
        }
    },
    { $sort: { _id: 1 } }
]);
```

---

## 7. Storage Engine & Concurrency Guarantees

### 7.1. Document-Level Concurrency in WiredTiger
MongoDB’s storage engine, **WiredTiger**, utilizes optimistic multi-version concurrency control (MVCC) and document-level locking. For Nexora’s workload:
- High-frequency appends to `audit_events` execute concurrently with zero reader lock contention.
- Upgrades to a customer's KYC profile acquire a document-level exclusive write lock only on that individual customer document, leaving all other customer profiles unlocked.

### 7.2. Write Concern & Read Concern Settings
In fintech environments, write durability must be explicitly tuned according to data criticality:

1. **KYC Documents (`kyc_profiles`):**
   - Configured with `w: 'majority'`, `j: true` (journaled).
   - Guarantees that document modifications are committed to disk and acknowledged by a majority of replica set nodes before confirmation.
2. **Audit Telemetry (`audit_events`):**
   - Configured with `w: 1`, `j: false` for maximum ingestion throughput during burst payment traffic, backed by memory journal flushing.

---

## 8. Summary of Architectural Trade-offs

| Design Decision | Primary Benefit | Trade-off / Cost | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **Polyglot Persistence (Postgres + MongoDB)** | Specialized engines for relational ledger vs. flexible polymorphic document storage. | Dual database management, no native cross-engine distributed foreign keys. | Synchronized application events, distributed correlation key (`customer_id`). |
| **Embedded `documents` in `kyc_profiles`** | Atomic single-document reads/writes; zero joins for profile verification. | Array update syntax (`$push`, `$elemMatch`), slight document size increase. | Strict limit on maximum documents per tier (max 4 items). |
| **Referenced `audit_events`** | Prevents exceeding 16 MB BSON document limit; append-only write throughput. | Requires index lookup or `$lookup` aggregation to correlate with profile. | ESR compound indexes (`customer_id: 1, ts: -1`) reducing reads to 20 documents. |
| **TTL Index on `login_sessions`** | Fully automated session expiration with zero scheduled cron maintenance. | Background thread runs once every 60 seconds (slight expiration latency). | Application treats tokens expired past TTL as invalid immediately. |
| **JSON Schema Validation** | Enforces data integrity at the database layer while preserving nested flexibility. | Invalidation on unexpected payload attributes. | Clear document evolution versioning and `validationAction: 'error'`. |

---

## 9. Conclusion

The NoSQL document model implemented for **Nexora** in Portfolio 4 exemplifies how a high-concurrency fintech platform leverages **Polyglot Persistence** to scale beyond the constraints of pure relational storage. By isolating polymorphic KYC records, append-only security logs, and volatile authentication sessions into MongoDB, Nexora achieves:
1. **Schema Flexibility:** Full support for diverse Nigerian and international identity documents without sparse relational tables or EAV anti-patterns.
2. **Optimized Query Performance:** Up to **98.2% latency reduction** across operational endpoints via ESR-aligned compound indexes.
3. **Operational Simplicity:** Automated ephemeral data expiration via background TTL indexes.
4. **Architectural Separation:** Offloading high-velocity telemetry from the core PostgreSQL double-entry ledger, preserving relational resources for critical financial transfers.
