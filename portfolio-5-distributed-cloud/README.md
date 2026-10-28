# Portfolio 5: Distributed and Cloud Database Architectures

**Course:** MIT 8103 – Advanced Database Systems  
**Student:** Bamishaye Favour (ID: 301915930)  
**Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**Technologies:** Docker, Docker Compose, PostgreSQL 16 (Primary & Hot Standby), MongoDB Atlas (Cloud 3-Node Replica Set)  
**Scale:** ~5,000 customers, 6,003 accounts, 412,046 ledger entries, 100,000 audit events  
**Artifacts:** `README.md`, `analysis.md`  

---

## 1. Architectural Overview

As fintech platforms scale to millions of concurrent active users, single-node database instances encounter hard physical bottlenecks in CPU, I/O bandwidth, memory capacity, and connection limits. More critically, single-node topologies present an unacceptable **Single Point of Failure (SPOF)**, violating regulatory and operational availability mandates.

**Portfolio 5** extends **Nexora** into modern distributed and cloud data architectures. It implements, evaluates, and stress-tests:
1. **High-Availability (HA) Physical Streaming Replication:** A multi-container PostgreSQL 16 cluster featuring an active read-write **Primary** node and a streaming read-only **Hot Standby Replica** with dedicated replication slots.
2. **Replication Mechanics & Consistency Trade-offs:** Controlled empirical evaluations of asynchronous replication lag, stale read windows, replica freezing, WAL buffering, synchronous commit guarantees, and cluster failover promotion.
3. **Horizontal Scaling via Declarative Hash Partitioning:** Sharding the core double-entry ledger (`ledger_entries`) into 4 discrete partitions by `account_id` (412,046 rows), evaluating partition pruning efficiency and cross-partition scatter-gather costs.
4. **Cloud Managed DBaaS (MongoDB Atlas 3-Node Replica Set):** Verification of distributed cloud quorum protocols, distributed write concerns (`w: 'majority'`), secondary read preferences (`readPref('secondary')`), and linearizable read concerns (`readConcern('majority')`).

For exhaustive theoretical derivations, mathematical models, CAP/PACELC proofs, and failover mechanics, see the companion research artifact:  
👉 **[analysis.md](analysis.md)**

```
                                Nexora Distributed Architecture
                                
                  ┌────────────────────────────────────────────────────────┐
                  │              Application / API Gateway                 │
                  └───────────────┬────────────────────────┬───────────────┘
                                  │                        │
                      Writes      │                        │  Read-Only Traffic
                      (Port 5433) │                        │  (Port 5434)
                                  ▼                        ▼
                   ┌────────────────────────┐    WAL   ┌────────────────────────┐
                   │  nexora-pg-primary     ├─────────►│  nexora-pg-replica     │
                   │  (Port 5433)           │ Streaming│  (Port 5434)           │
                   │  Read-Write Master     │  Slot    │  Hot Standby Read-Only │
                   ├────────────────────────┤          ├────────────────────────┤
                   │ • Double-Entry Ledgers │          │ • Balance Inquiries    │
                   │ • ACID P2P Transfers   │          │ • Statement Generation │
                   │ • 4-Shard Partitioning │          │ • Analytical Audits    │
                   └────────────────────────┘          └────────────────────────┘
                                               │
                                               ▼
                              ┌──────────────────────────────────┐
                              │     MongoDB Atlas (Cloud HA)     │
                              │     3-Node Global Replica Set    │
                              ├──────────────────────────────────┤
                              │ • Primary (Leader Election)      │
                              │ • 2 Standby Secondary Replicas   │
                              │ • Majority Write/Read Quorums    │
                              └──────────────────────────────────┘
```

---

## 2. Directory Structure

```
portfolio-5-distributed-cloud/
├── README.md                                  # Comprehensive portfolio overview & execution guide
├── analysis.md                                # In-depth technical & theoretical research report
├── docker-compose.yml                         # Dual-node PostgreSQL primary & replica infrastructure
├── replica-entrypoint.sh                      # Standby provisioning: pg_basebackup & streaming boot
├── primary-init/                              # Automated primary initialization hooks
│   └── 01_replication.sh                     # Role creation (replicator) & pg_hba.conf rules
├── 01_primary_checks.sql                      # Primary health, replication slots, WAL LSN diagnostics
├── 02_replica_checks.sql                      # Replica receiver health, lag, read test, write rejection
├── 03_partitioning.sql                        # Hash partitioning of ledger_entries (412k rows)
├── 04_atlas_cloud_check.js                    # MongoDB Atlas 3-node replica set verification script
├── nexora_dump.sql                            # Relational production snapshot (61.9 MB, 412k entries)
├── output/                                    # Raw execution output transcripts
│   ├── 01_primary_checks.txt                  # Output from primary diagnostics
│   ├── 02_replica_checks.txt                  # Output from replica diagnostics & write rejection
│   ├── 03_partitioning.txt                    # Output from hash sharding & partition pruning EXPLAIN
│   └── 04_atlas_cloud_check.txt               # Output from MongoDB Atlas distributed quorum checks
└── screenshots/                               # 17 photographic proofs from live test runs
    ├── Bamishaye_Favour_301915930_docker_compose_setup.png
    ├── Bamishaye_Favour_301915930_docker_ps.png
    ├── Bamishaye_Favour_301915930_primary_checks.png
    ├── Bamishaye_Favour_301915930_replica_checks.png
    ├── Bamishaye_Favour_301915930_compare_the_two_servers.png
    ├── Bamishaye_Favour_301915930_row_counts_01.png
    ├── Bamishaye_Favour_301915930_row_counts_02.png
    ├── Bamishaye_Favour_301915930_replication_marker.png
    ├── Bamishaye_Favour_301915930_freeze_the_replica.png
    ├── Bamishaye_Favour_301915930_replication_lag_and_a_stale_read.png
    ├── Bamishaye_Favour_301915930_caught_up.png
    ├── Bamishaye_Favour_301915930_synchronous_replication.png
    ├── Bamishaye_Favour_301915930_sync_hang.png
    ├── Bamishaye_Favour_301915930_failover.png
    ├── Bamishaye_Favour_301915930_partitioning.png
    ├── Bamishaye_Favour_301915930_atlas_clusters.png
    └── Bamishaye_Favour_301915930_atlas_check_output.png
```

---

## 3. Environment & Configuration Manifest

### 3.1. Docker Topology & Port Allocation

To ensure completely isolated execution without conflicting with standard local PostgreSQL installations (running on port `5432`), the cluster maps unique host ports:

| Container Name | Role | Internal Port | Host Port | Database / User | Volume Name |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `nexora-pg-primary` | Read-Write Master | 5432 | **5433** | `nexora_db` / `nexora` | `primary_data` |
| `nexora-pg-replica` | Read-Only Hot Standby | 5432 | **5434** | `nexora_db` / `nexora` | `replica_data` |

### 3.2. Critical PostgreSQL Engine Configurations

The Primary container is started with specialized engine flags optimized for high-volume streaming:
- `wal_level = replica`: Emits necessary WAL records to support physical streaming replication and standby read queries.
- `max_wal_senders = 10`: Allocates sufficient worker processes to stream WAL records concurrently.
- `max_replication_slots = 10`: Permits persistent replication slots, preventing WAL recycling until the replica has acknowledged receipt.
- `wal_keep_size = 256MB`: Preserves minimum retained WAL volume on disk to prevent replica disconnection during burst writes.

### 3.3. Autonomous Replica Provisioning Pipeline

The standby container relies on [`replica-entrypoint.sh`](replica-entrypoint.sh) to bootstrap dynamically from zero state:
1. Waits for the Primary healthcheck to turn green using `pg_isready -h primary -p 5432`.
2. Connects using the dedicated `replicator` role.
3. Executes `pg_basebackup -h primary -p 5432 -U replicator -D /var/lib/postgresql/data -R -X stream -C -S replica1_slot -c fast -v`.
   - `-R`: Automatically writes connection credentials into `standby.signal` and `postgresql.auto.conf`.
   - `-X stream`: Streams WAL logs while backup is in flight.
   - `-C -S replica1_slot`: Automatically creates the persistent physical replication slot `replica1_slot` on the primary.
4. Starts the PostgreSQL engine with `hot_standby = on`.

---

## 4. Laboratory Experiments & Empirical Verification

### Experiment 1: Baseline Asynchronous Streaming Verification
- **Execution:** Ran [`01_primary_checks.sql`](01_primary_checks.sql) against port 5433 and [`02_replica_checks.sql`](02_replica_checks.sql) against port 5434.
- **Empirical Findings ([output/01_primary_checks.txt](output/01_primary_checks.txt), [output/02_replica_checks.txt](output/02_replica_checks.txt)):**
  - Primary confirms `pg_is_in_recovery() = false`.
  - Primary `pg_stat_replication` shows active `walreceiver` in state `streaming`, sync state `async`, with identical `sent_lsn = 0/8515098` and `replay_lsn = 0/8515098` (0 bytes lag).
  - Replica confirms `pg_is_in_recovery() = true`.
  - Replica `pg_stat_wal_receiver` confirms live upstream connection to `sender_host: primary:5432` bound to `slot_name: replica1_slot`.
  - Read query on replica executes successfully (`SELECT count(*) FROM accounts` $\rightarrow$ 6,003 rows).
  - Write query on replica is strictly rejected by the storage engine:
    ```sql
    UPDATE accounts SET balance = balance WHERE account_id = 1;
    -- Result: ERROR: cannot execute UPDATE in a read-only transaction
    ```

### Experiment 2: Replication Lag, Stale Reads & Catch-up Dynamics
- **Scenario:** Simulating a network partition or heavy I/O freeze on the standby node.
- **Procedure:**
  1. The replica container was frozen via `docker pause nexora-pg-replica`.
  2. Write operations and test markers were committed to the primary on port 5433.
  3. Inspected the primary: WAL LSN advanced while the replication slot restart LSN remained pinned at the pre-freeze position, safely accumulating WAL on the primary without data loss.
  4. Attempted reads on the replica: Queries experienced a **Stale Read Window**, seeing data only up to the frozen LSN.
  5. The replica was unpaused via `docker unpause nexora-pg-replica`.
  6. The `walreceiver` process re-established streaming, drained the buffered WAL backlog, and replayed commits until `replay_lsn` matched `primary_wal_position`.

### Experiment 3: Synchronous Replication & The Availability Hang
- **Scenario:** Evaluating CAP theorem trade-offs by shifting from asynchronous to synchronous replication.
- **Procedure:**
  1. Set `synchronous_standby_names = 'ANY 1 (*)'` and reloaded configuration on the primary.
  2. While the standby was healthy, writes committed with slight round-trip latency overhead.
  3. Simulated standby failure by pausing/stopping the replica.
  4. Executed an `INSERT`/`UPDATE` on the primary: **The primary blocked indefinitely**, unable to return commit acknowledgment to the client because quorum could not be achieved.
  5. **Theoretical Insight:** Proves that synchronous replication converts a partition ($P$) event into an availability loss (choosing $CP$ over $AP$).

### Experiment 4: Controlled Standby Promotion (Failover)
- **Scenario:** Primary hardware failure necessitating promotion of the read replica into an autonomous write master.
- **Procedure:**
  1. Primary container halted.
  2. Executed promotion on the standby node: `SELECT pg_promote();` (or `pg_ctl promote`).
  3. Standby processed remaining WAL, removed `standby.signal`, and transitioned `pg_is_in_recovery()` from `true` to `false`.
  4. The former replica successfully accepted write transactions (`UPDATE accounts ...`).

### Experiment 5: Horizontal Partitioning (Sharding Emulation)
- **Execution:** Executed [`03_partitioning.sql`](03_partitioning.sql) on the primary, migrating 412,046 ledger records into a 4-partition hash-sharded table `ledger_entries_sharded` partitioned by `account_id`:
  - `ledger_shard_0` (MODULUS 4, REMAINDER 0): 105,481 rows (25.6%)
  - `ledger_shard_1` (MODULUS 4, REMAINDER 1): 103,322 rows (25.1%)
  - `ledger_shard_2` (MODULUS 4, REMAINDER 2): 103,279 rows (25.1%)
  - `ledger_shard_3` (MODULUS 4, REMAINDER 3): 99,964 rows (24.2%)
- **Partition Pruning Verification ([output/03_partitioning.txt](output/03_partitioning.txt)):**
  - **Query WITH Partition Key (`WHERE account_id = 1001`):**  
    PostgreSQL optimizer applies **Partition Pruning**, eliminating 3 shards immediately and targeting *only* `ledger_shard_0` via index scan.
  - **Query WITHOUT Partition Key (`WHERE transaction_id = 12345`):**  
    PostgreSQL cannot prune partitions; it initiates a **Parallel Append** across all 4 shards with 2 parallel workers, demonstrating the scatter-gather cost of non-partitioned lookups.

### Experiment 6: Cloud DBaaS Validation (MongoDB Atlas 3-Node Replica Set)
- **Execution:** Executed [`04_atlas_cloud_check.js`](04_atlas_cloud_check.js) against MongoDB Atlas cluster.
- **Verified Distributed Capabilities ([output/04_atlas_cloud_check.txt](output/04_atlas_cloud_check.txt)):**
  - Cluster topology inspected: verified active Primary and Secondary nodes.
  - Write Concern Quorum: Inserted document with `{ writeConcern: { w: 'majority', wtimeout: 5000 } }`. Acknowledged in 937 ms after majority cross-region persistence.
  - Read Preference Offloading: Successfully queried `kyc_profiles` (5,000 documents) directly from a Secondary node via `.readPref('secondary')`.
  - Read Concern Isolation: Queried committed marker via `.readConcern('majority')`, guaranteeing protection against dirty reads or rollbacks during re-elections.

---

## 5. Visual Evidence Index

All 17 high-resolution screenshots supporting this portfolio are archived in [`screenshots/`](screenshots/):

| Screenshot File | Phase / Topic | Verified Laboratory Evidence |
| :--- | :--- | :--- |
| [`docker_compose_setup.png`](screenshots/Bamishaye_Favour_301915930_docker_compose_setup.png) | Environment | Docker Compose startup initializing `primary` and `replica` containers. |
| [`docker_ps.png`](screenshots/Bamishaye_Favour_301915930_docker_ps.png) | Environment | `docker ps` confirming `nexora-pg-primary` on 5433 and `nexora-pg-replica` on 5434. |
| [`primary_checks.png`](screenshots/Bamishaye_Favour_301915930_primary_checks.png) | Replication | Running `01_primary_checks.sql`: verifying `is_replica = f` and active replication slot. |
| [`replica_checks.png`](screenshots/Bamishaye_Favour_301915930_replica_checks.png) | Replication | Running `02_replica_checks.sql`: verifying `is_replica = t` and write rejection. |
| [`compare_the_two_servers.png`](screenshots/Bamishaye_Favour_301915930_compare_the_two_servers.png) | Verification | Side-by-side terminal session comparing primary (5433) and replica (5434). |
| [`row_counts_01.png`](screenshots/Bamishaye_Favour_301915930_row_counts_01.png) | Consistency | Row count audit across customer, account, and card tables matching on both nodes. |
| [`row_counts_02.png`](screenshots/Bamishaye_Favour_301915930_row_counts_02.png) | Consistency | Transaction and ledger entry count verification across nodes (412,046 rows). |
| [`replication_marker.png`](screenshots/Bamishaye_Favour_301915930_replication_marker.png) | Replication | Inserting marker record on primary and instantaneous replication on standby. |
| [`freeze_the_replica.png`](screenshots/Bamishaye_Favour_301915930_freeze_the_replica.png) | Chaos Testing | Freezing replica container via `docker pause` to induce simulated network lag. |
| [`replication_lag_and_a_stale_read.png`](screenshots/Bamishaye_Favour_301915930_replication_lag_and_a_stale_read.png) | Chaos Testing | Demonstrating stale read on frozen replica while primary advances. |
| [`caught_up.png`](screenshots/Bamishaye_Favour_301915930_caught_up.png) | Recovery | Unfreezing replica; streaming catch-up until `replay_lsn` equals primary WAL position. |
| [`synchronous_replication.png`](screenshots/Bamishaye_Favour_301915930_synchronous_replication.png) | Consistency | Configuring `synchronous_standby_names` on primary node. |
| [`sync_hang.png`](screenshots/Bamishaye_Favour_301915930_sync_hang.png) | CAP Theorem | Demonstrating write hang when synchronous replica is paused (Availability loss). |
| [`failover.png`](screenshots/Bamishaye_Favour_301915930_failover.png) | Failover | Promotion of standby via `pg_promote()` into independent writable master. |
| [`partitioning.png`](screenshots/Bamishaye_Favour_301915930_partitioning.png) | Partitioning | Hash partitioning execution: 4 shards populated and partition pruning plan verified. |
| [`atlas_clusters.png`](screenshots/Bamishaye_Favour_301915930_atlas_clusters.png) | Cloud DBaaS | MongoDB Atlas UI showing 3-node replica set cluster, metrics, and global deployment. |
| [`atlas_check_output.png`](screenshots/Bamishaye_Favour_301915930_atlas_check_output.png) | Cloud DBaaS | Execution output of `04_atlas_cloud_check.js`: majority write/read concerns and secondary read. |

---

## 6. How to Run & Reproduce

### 6.1. Start the Distributed PostgreSQL Cluster
```bash
# Navigate to the portfolio folder
cd portfolio-5-distributed-cloud

# Spin up primary and replica in detached mode
docker compose up -d

# Verify healthy status
docker compose ps
```

### 6.2. Load Seed Data & Execute Replication Healthchecks
```bash
# Restore production dump to primary (port 5433)
PGPASSWORD=nexora_pass psql -h localhost -p 5433 -U nexora -d nexora_db -f nexora_dump.sql

# Run primary replication diagnostics
PGPASSWORD=nexora_pass psql -h localhost -p 5433 -U nexora -d nexora_db -f 01_primary_checks.sql

# Run replica replication diagnostics
PGPASSWORD=nexora_pass psql -h localhost -p 5434 -U nexora -d nexora_db -f 02_replica_checks.sql
```

### 6.3. Execute Hash Partitioning Benchmark
```bash
PGPASSWORD=nexora_pass psql -h localhost -p 5433 -U nexora -d nexora_db -f 03_partitioning.sql
```

### 6.4. Run MongoDB Atlas Cloud Verification
```bash
# Set your Atlas URI and execute
export ATLAS_URI="mongodb+srv://<user>:<password>@<cluster>.mongodb.net/nexora_db"
mongosh "$ATLAS_URI" --file 04_atlas_cloud_check.js
```

### 6.5. Teardown
```bash
# Stop containers (preserves volumes)
docker compose down

# Full wipe (removes all volumes)
docker compose down -v
```
