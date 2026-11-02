# Nexora: SQL vs. NoSQL Architectural Rationale

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Bamishaye Favour (ID: 301915930)  
**Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**RDBMS:** PostgreSQL 16 (Relational Core Engine)  
**NoSQL DBMS:** MongoDB (Document Store Engine)  
**Artifact:** `sql-vs-nosql-rational.md`  

---

## 1. Executive Summary

Enterprise fintech architectures cannot rely on a naive "one-size-fits-all" database paradigm. Digital banking engines like **Nexora** execute workloads with fundamentally incompatible performance, consistency, and structural characteristics:

1. **Transactional Core (Relational):** Multi-party peer-to-peer (P2P) fund transfers, non-negative wallet balances, and strict double-entry ledger bookkeeping require absolute atomicity, immediate linearizable consistency, and mathematical conservation of money.
2. **Auxiliary & Telemetry Domains (Document):** Multi-tiered identity verification (KYC), immutable audit trails, and high-turnover authentication sessions require schema polymorphism, horizontal write-ingestion scalability, and self-pruning lifecycles.

Rather than forcing relational constructs onto semi-structured event streams (which degrades performance through schema bloat and lock contention) or running financial ledgers on document stores (which introduces complex multi-document coordination risks), Nexora employs a principled **Polyglot Persistence Architecture**.

This report articulates the theoretical, operational, and empirical rationale comparing **PostgreSQL 16 (SQL)** and **MongoDB (NoSQL)** within Nexora, providing an architectural decision framework for modern financial systems.

---

## 2. Theoretical Foundations: SQL vs. NoSQL

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               THEORETICAL COMPARISON                                  │
├──────────────────────────────┬────────────────────────────┬────────────────────────────┤
│ Architectural Dimension      │ PostgreSQL 16 (SQL)        │ MongoDB (NoSQL Document)   │
├──────────────────────────────┼────────────────────────────┼────────────────────────────┤
│ **Data Model**               │ Relational Tables (1NF–3NF)│ Hierarchical BSON Documents│
│ **Schema Paradigm**          │ Strict Schema-on-Write     │ Governed Schema-on-Read    │
│ **Consistency Model**        │ ACID (Linearizable)        │ PACELC (PC/EC configurable)│
│ **Transaction Scope**        │ Cross-table Multi-row ACID │ Single-document Atomic     │
│ **Concurrency Control**      │ Multi-Version (MVCC) + 2PL │ WiredTiger MVCC + Ticket   │
│ **Relationship Strategy**    │ Foreign Keys & Joins       │ Embedding or Referencing   │
│ **Scaling Paradigm**         │ Scale-Up / Partitioning    │ Horizontal Sharding        │
│ **Query Language**           │ Declarative SQL (ANSI)     │ MQL / Aggregation Pipeline │
└──────────────────────────────┴────────────────────────────┴────────────────────────────┘
```

### 2.1. Relational Algebra vs. Document Hierarchy
- **Relational Model (Codd's Relational Algebra):** Founded on set theory and first-order predicate logic. Relations are normalized into discrete two-dimensional tables where each attribute is atomic. Integrity is guaranteed via primary keys, candidate keys, and foreign keys. This eliminates data redundancy at the cost of join overhead during data retrieval.
- **Document Model (Hierarchical Aggregates):** Data that is accessed together is stored together as self-describing BSON (Binary JSON) documents. This provides natural mapping to application-layer domain objects (Domain-Driven Design Aggregates), eliminating the object-relational impedance mismatch for nested data structures.

### 2.2. ACID vs. BASE & The CAP/PACELC Theorems

```
                               CAP & PACELC Trade-off Boundary
                               
             PostgreSQL                                      MongoDB
          (ACID / CA / PC/EC)                         (BASE / CP / PA/EC)
                   │                                           │
         ┌─────────┴─────────┐                       ┌─────────┴─────────┐
         │ Immediate         │                       │ Configurable      │
         │ Consistency       │                       │ Write Concern     │
         │ (Linearizable)    │                       │ (w:1 to majority) │
         └───────────────────┘                       └───────────────────┘
```

1. **PostgreSQL (ACID / CA under Single-Node / PC/EC):**
   - **Atomicity:** All-or-nothing ledger execution using write-ahead logging (WAL).
   - **Consistency:** Transactions transition the database from one valid state to another, strictly enforcing relational constraints (`CHECK`, `FOREIGN KEY`, `NOT NULL`).
   - **Isolation:** Configurable up to `SERIALIZABLE`; Nexora leverages `READ COMMITTED` paired with explicit canonical row-level locks (`SELECT ... FOR UPDATE`).
   - **Durability:** Committed transactions persist across system crashes via synchronous WAL flushing.

2. **MongoDB (PACELC Analysis):**
   - Under network partition ($P$), MongoDB chooses **Consistency** ($C$) over Availability ($A$) for a given shard: if a primary node loses quorum, writes are refused until a new primary is elected.
   - Else ($E$), when functioning normally, MongoDB trades latency ($L$) for consistency ($C$) depending on write concern (`w: 'majority'` vs. `w: 1`).
   - While MongoDB 4.0+ supports multi-document distributed transactions, their performance overhead makes them sub-optimal for high-throughput financial ledgers compared to native RDBMS engines.

---

## 3. Detailed Workload & Domain Evaluation in Nexora

### 3.1. Why SQL (PostgreSQL 16) is Mandatory for Core Ledger Domains

#### Domain 1: Double-Entry Ledger Bookkeeping (`ledger_entries`)
- **Requirement:** Every financial transaction must create balanced credit and debit entries ($\sum \text{Debits} - \sum \text{Credits} = 0$).
- **Why NoSQL Fails Here:** In a document database, updating balances across two distinct account documents requires either multi-document distributed transactions (which incur severe two-phase commit overhead) or compensating transactions (which leave the system temporarily unbalanced).
- **PostgreSQL Implementation:** Implements strict relational constraints, immediate foreign key validation, and relational checks. Double-entry arithmetic validation runs deterministically within a single ACID transaction block.

#### Domain 2: Concurrency-Safe Fund Transfers (`transfer_funds`)
- **Requirement:** Concurrent fund transfers between identical accounts must never cause race conditions, lost updates, or deadlocks.
- **PostgreSQL Implementation:** Utilizes canonical ordered locking (`LEAST(from_id, to_id)` followed by `GREATEST(from_id, to_id)`). This mathematically eliminates Dijkstra's circular wait condition, allowing Nexora to achieve **5,977.72 TPS with 0% deadlock failure** in `pgbench` benchmarks.
- **Relational Invariant:** Non-negative account balances are guaranteed at the database engine level via `CHECK (balance >= 0)`.

---

### 3.2. Why NoSQL (MongoDB) is Superior for Auxiliary & Telemetry Domains

```
                                 Nexora Polyglot Workloads
                                 
       RELATIONAL (PostgreSQL)                              DOCUMENT (MongoDB)
  ┌───────────────────────────────────┐               ┌───────────────────────────────────┐
  │ • Double-entry ledger entries     │               │ • Polymorphic KYC Profiles        │
  │ • Customer account balances       │               │ • High-volume Audit Event logs    │
  │ • P2P fund transfer functions     │               │ • Ephemeral login sessions        │
  │ • Immutable audit trail           │               │ • Regulatory AML queries          │
  └───────────────────────────────────┘               └───────────────────────────────────┘
```

#### Domain 3: Polymorphic Identity Verification (`kyc_profiles`)
- **The Relational Pitfall:**
  Identity verification documents across regulatory tiers in Nigeria exhibit divergent attributes:
  - **BVN:** 11-digit numeric string, verified against NIBSS, no expiration.
  - **NIN:** 11-digit numeric string, verified against NIMC, no expiration.
  - **Passport:** Alphanumeric identifier, country code, issue date, mandatory future expiration date.
  - **Driver's Licence:** Alphanumeric identifier, state of issue, expiration date.
  - **Utility Bill:** Service provider name, disco region, meter number, past billing date.
  
  In PostgreSQL, modeling this polymorphism requires:
  - **Sparse Columns:** A single table with 25+ nullable columns, where 70–80% of fields contain `NULL`.
  - **Entity-Attribute-Value (EAV):** A key-value table (`profile_id, attribute_key, attribute_value`) that destroys relational typing, breaks indexing efficiency, and requires complex multi-join queries.
  - **Multiple Concrete Tables:** Separate tables for `bvn_records`, `passport_records`, etc., requiring complex outer joins to reconstruct a single profile.

- **The MongoDB Solution:**
  Documents naturally embed an array of polymorphic sub-objects within `kyc_profiles.documents`. Each document type carries only its relevant fields:
  ```json
  {
    "customer_id": 1001,
    "tier": 3,
    "status": "VERIFIED",
    "documents": [
      { "type": "BVN", "number": "22212345678", "verified_with": "NIBSS" },
      { "type": "PASSPORT", "number": "A12345678", "country": "NG", "expiry": "2031-05-01" },
      { "type": "UTILITY_BILL", "number": "UB99999999", "provider": "Eko Disco", "issued_on": "2026-10-27" }
    ]
  }
  ```
  Schema validity is strictly enforced via `$jsonSchema` validators while retaining structural elasticity.

#### Domain 4: High-Velocity Security Telemetry (`audit_events`)
- **The Relational Pitfall:**
  Audit logging requires recording every user action (`LOGIN_SUCCESS`, `LOGIN_FAILED`, `PIN_CHANGED`, `TRANSFER_INITIATED`, `KYC_UPGRADED`, `FRAUD_FLAG`). Each event carries dynamic telemetry:
  - Logins carry client IP, geolocation, device family.
  - Authentication failures carry failure reasons (`WRONG_PIN`, `DEVICE_NOT_RECOGNISED`).
  - Transfers carry payment references, amounts, and channel codes.
  - Fraud flags carry risk detection rules and anomaly scores.
  
  In PostgreSQL, high-throughput ingestion of heterogeneous event streams leads to high table and index lock contention, frequent table bloat, and write amplification.

- **The MongoDB Solution:**
  MongoDB provides an append-only collection with a dynamic `details` payload. Coupled with compound indexes (`{ customer_id: 1, ts: -1 }` and `{ event_type: 1, ts: -1 }`), queries scanning 100,000 events execute in **8 ms** and **2 ms** respectively, eliminating memory-intensive sorting.

#### Domain 5: Ephemeral Authentication Sessions (`login_sessions`)
- **The Relational Pitfall:**
  Mobile user sessions and JWT handles expire after 60 minutes. In relational databases, expired sessions must be deleted using batch jobs:
  ```sql
  DELETE FROM login_sessions WHERE created_at < NOW() - INTERVAL '1 hour';
  ```
  Running this query continuously under high load results in table lock escalation, transaction log bloat, deadlocks with incoming logins, and heavy autovacuum overhead.

- **The MongoDB Solution:**
  MongoDB natively supports background **Time-To-Live (TTL)** B-tree indexes:
  ```javascript
  nosql.login_sessions.createIndex(
      { created_at: 1 },
      { expireAfterSeconds: 3600, name: 'ttl_session_1h' }
  );
  ```
  A dedicated background storage thread autonomously reclaims expired documents once per minute with zero manual cron jobs, zero transaction lock contention, and bounded storage footprint.

---

## 4. Architectural & Empirical Comparison Matrix

The table below contrasts the technical implementation details and empirical performance observed in Nexora's testing environments:

| Feature / Metric | PostgreSQL 16 Implementation | MongoDB Atlas Implementation | Architectural Winner & Rationale |
| :--- | :--- | :--- | :--- |
| **Primary Workload** | Double-entry financial ledgers, accounts, fund transfers. | Polymorphic KYC verification, security telemetry, session tokens. | **Polyglot:** Specialized engines for specialized domains. |
| **Integrity Enforcement** | Hard engine-level constraints: `FOREIGN KEY`, `CHECK (balance >= 0)`, `UNIQUE`. | Configurable `$jsonSchema` validators with `validationAction: 'error'`. | **PostgreSQL:** For strict multi-table relational invariants. |
| **Concurrency Mechanism** | Row-level locking (`SELECT ... FOR UPDATE`), canonical ordering (`LEAST/GREATEST`). | Document-level locking via WiredTiger tickets, optimistic MVCC. | **PostgreSQL:** Deterministic deadlock elimination in financial transfers. |
| **Write Optimization** | Write-Ahead Log (WAL), checkpointer, autovacuum maintenance. | Memory-mapped WiredTiger cache, background checkpointing, append-only logs. | **MongoDB:** Superior ingestion velocity for un-normalized event streams. |
| **Index Profiling** | `EXPLAIN (ANALYZE, BUFFERS)` | `cursor.explain('executionStats')` | **Both:** Exceptional profiling tools; ESR rules in MongoDB mirror composite index ordering in SQL. |
| **Query Latency (Indexed)** | < 1 ms on primary key lookups, 1.67 ms average transfer latency. | 2 ms on point lookups (`EXPRESS_IXSCAN`), 8 ms on customer audit timeline. | **Parity:** Both engines achieve single-digit millisecond latency when properly indexed. |
| **Unindexed Penalty** | Heavy Seq Scans, disk spills on external merge sorts. | Full `COLLSCAN` scanning 100,000 documents; in-memory blocking `SORT` (434 ms). | **Both:** Unindexed scans severely degrade throughput under production volumes. |
| **Schema Evolution** | Requires explicit DDL (`ALTER TABLE`), transactional DDL supported. | Dynamic field additions without DDL downtime; validator updates via `collMod`. | **MongoDB:** Agile evolution for auxiliary and compliance telemetry fields. |

---

## 5. Cross-System Data Synchronization Patterns

Operating a polyglot persistence architecture requires a robust strategy for maintaining data coherence across PostgreSQL and MongoDB without introducing brittle two-phase commit (2PC) distributed transactions.

```
                          Event-Driven Asynchronous Synchronization
                          
   ┌───────────────────────┐
   │  Client / Mobile App  │
   └───────────┬───────────┘
               │ 1. Initiate Transfer
               ▼
   ┌─────────────────────────────────────────────────────────┐
   │               Nexora Core Transaction Engine            │
   │  BEGIN;                                                 │
   │    UPDATE accounts SET balance = balance - 500 ...      │
   │    INSERT INTO ledger_entries (...)                     │
   │    INSERT INTO outbox_events (event_type, payload, ...) │
   │  COMMIT;                                                │
   └───────────┬─────────────────────────────────────────────┘
               │ 2. Outbox CDC / Event Relay
               ▼
   ┌───────────────────────┐
   │  Message Broker / Bus │ (Kafka / RabbitMQ)
   └───────────┬───────────┘
               │ 3. Asynchronous Consumer
               ▼
   ┌─────────────────────────────────────────────────────────┐
   │               MongoDB Telemetry Service                 │
   │  nosql.audit_events.insertOne({                         │
   │    customer_id: event.customer_id,                      │
   │    event_type: 'TRANSFER_INITIATED',                    │
   │    ts: event.timestamp,                                 │
   │    details: event.details                               │
   │  });                                                    │
   └─────────────────────────────────────────────────────────┘
```

### The Transactional Outbox Pattern
1. **The Dual-Write Anti-Pattern:** Attempting to synchronously write to both PostgreSQL and MongoDB within an application service is fragile: if the MongoDB write fails after PostgreSQL commits, the systems become permanently desynchronized.
2. **The Solution (Transactional Outbox):**
   - The PostgreSQL transaction writes to both the relational tables and an internal `outbox_events` table within the same atomic relational transaction block.
   - A Change Data Capture (CDC) process (e.g., Debezium) or message relay reads the outbox table and publishes events to an event bus (e.g., Apache Kafka).
   - A lightweight ingestion microservice consumes the event and inserts the audit record into MongoDB's `audit_events` collection.
   - This guarantees **at-least-once delivery** and eventual consistency between the financial ledger and the NoSQL audit log.

---

## 6. Conclusion & Architectural Verdict

The architectural comparison between SQL and NoSQL in Nexora demonstrates that the debate is not about which paradigm is universally superior, but about **matching workload characteristics to storage engine capabilities**:

1. **PostgreSQL 16** remains the indispensable foundation for Nexora's core banking ledger, wallet balances, and fund transfers, where ACID guarantees, relational invariants, and deterministic deadlock prevention are non-negotiable.
2. **MongoDB** is the ideal solution for Nexora's secondary domains, offering superior ergonomics and performance for polymorphic KYC documents, append-only security telemetry, and self-purging session state.
3. By harmonizing both technologies through a **Polyglot Persistence Architecture** connected via the distributed correlation key `customer_id` and the Transactional Outbox pattern, Nexora achieves both **uncompromising financial correctness** and **horizontal scalability**.
