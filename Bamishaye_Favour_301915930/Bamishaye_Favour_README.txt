================================================================================
MIT 8103 ADVANCED DATABASE SYSTEMS — CONTINUOUS ASSESSMENT (40 MARKS)
STANDALONE SUBMISSION README & TECHNICAL CATALOG
================================================================================

STUDENT AND SUBMISSION METADATA
--------------------------------------------------------------------------------
Course Title:          MIT 8103 – Advanced Database Systems
Assessment Component:  Individual Practical Database Portfolio (40 Marks)
Academic Session:      2026/2027 Academic Session (September Cohort)
Awarding Institution:  Miva Open University — School of Post Graduate Studies
Student Full Name:     Bamishaye Favour
Student ID:            301915930
Student Email:         f.bamishaye5930@miva.edu.ng
Chosen Case Study:     Nexora – Digital Savings and Financial Management Platform
GitHub Repository:     https://github.com/favour-bam/MIT-8103---Advanced-Database-Portfolio
Submission Archive:    Bamishaye_Favour_301915930.zip
Date of Submission:    November 2026


================================================================================
1. SELECTED DATABASE CASE STUDY & ORGANISATION STATEMENT (SECTION 2 COMPLIANCE)
================================================================================
In compliance with Section 2 of the MIT 8103 course specifications, the platform
case study below is utilized consistently across all five portfolio modules:

1. Organisation Name & Scenario:
   Nexora – Digital Savings and Financial Management Platform (Simulated).
   A modern fintech platform providing disciplined digital savings, goal-based
   wallets, tokenized virtual/debit cards, high-velocity P2P transfers, automated
   interest calculation, and AML compliance audit trails.

2. Nature of the Business and System:
   Nexora operates an immutable, double-entry financial accounting ledger.
   Unlike standard CRUD systems, balances are never mutated in-place; every
   financial movement produces matching, self-balancing debit and credit journal
   entries whose net sum is zero (sum(Debits) - sum(Credits) = 0).

3. Users of the Database:
   - Retail Customers & Small Merchants: Open wallets, execute transfers, lock
     funds in target savings goals, and retrieve historical account statements.
   - Finance & Treasury Officers: Reconcile daily settlement totals, verify
     journal balance invariants, and execute transaction reversals.
   - AML Compliance & Audit Officers: Monitor automated fraud detection scores,
     investigate flagged transactions, and audit immutable KYC verification trails.
   - System Administrators & DevOps: Administer primary-replica streaming slots,
     monitor replication lag, execute failovers, and maintain ledger partitions.

4. Major Data to be Stored:
   - PostgreSQL 16 Relational Core: 5,001 customer profiles, 6,003 currency accounts,
     206,096 transactions, 404,162 double-entry ledger lines, 15,000 saved beneficiaries,
     and 5,100 KYC identity records.
   - MongoDB Atlas Document Store: 5,000 polymorphic KYC identity profiles, 100,000
     append-only security telemetry audit logs, and auto-expiring login sessions.

5. Key Operations Supported:
   - Atomic, deadlock-free P2P wallet transfers via canonical ordered locking.
   - Real-time account statement generation and multi-table join reconciliations.
   - End-of-day mathematical balance conservation audits (constant 1 Trillion NGN).
   - Automated identity verification and document schema validation ($jsonSchema).
   - High-throughput append-only audit event logging and 4 aggregation pipelines.
   - Physical streaming replication, chaos testing (lag simulation), standby failover
     promotion (pg_promote), and 4-shard horizontal hash partitioning.

--------------------------------------------------------------------------------
ASSESSMENT MARK ALLOCATION & RUBRIC MAPPING
--------------------------------------------------------------------------------
Component Activity Breakdown (Section 3):
- Portfolio 1: Database Design and Modelling             --> 7 Marks
- Portfolio 2: Query Processing and Optimisation         --> 7 Marks
- Portfolio 3: Transactions and Concurrency              --> 7 Marks
- Portfolio 4: NoSQL and Advanced Data Models            --> 7 Marks
- Portfolio 5: Distributed and Cloud Database Exercise   --> 6 Marks
- Final Documentation: 2-3 Page Report & Reflection      --> 6 Marks
TOTAL CONTINUOUS ASSESSMENT                              --> 40 MARKS

University Marking Criteria Rubric (Section 9):
- Technical correctness                                  --> 8 Marks
- Database design quality                                --> 6 Marks
- Practical implementation                               --> 8 Marks
- Query and performance analysis                         --> 5 Marks
- Application of advanced database concepts              --> 5 Marks
- Documentation and GitHub organisation                  --> 5 Marks
- Technical reflection/individual understanding          --> 3 Marks
TOTAL CONTINUOUS ASSESSMENT                              --> 40 MARKS


================================================================================
2. COMPLETE FILE MANIFEST AND 40-MARK RUBRIC MAPPING
================================================================================
The submitted archive Bamishaye_Favour_301915930.zip extracts into the root
directory Bamishaye_Favour_301915930/ with all files mapped to the university
rubric as follows:

--------------------------------------------------------------------------------
PORTFOLIO 1: DATABASE DESIGN & MODELLING (Rubric: Design Quality 6M + Technical Correctness 8M)
--------------------------------------------------------------------------------
- Bamishaye_Favour_P1_CaseStudy.md
  Full specification of Nexora business rules, platform users, and data flows.
- Bamishaye_Favour_P1_RelationalSchema.md
  Formal relational schema documentation, entity specifications, and DBML schema.
- Bamishaye_Favour_P1_Normalisation.md
  Rigorous 1NF to 3NF analysis and architectural defense of 4 controlled denormalisations.
- Bamishaye_Favour_P1_CreateSchema.sql
  Complete DDL scripts creating all 8 tables, checks, regexes, and foreign keys.
- Bamishaye_Favour_P1_SeedData.sql
  Deterministic synthetic data seeding routine (5k customers, 206k txns, 412k ledgers).
- Bamishaye_Favour_P1_ConstraintTests.sql
  10 automated PL/pgSQL unit tests validating negative balances, foreign keys, regexes.
- Bamishaye_Favour_P1_VerifySeed.sql
  Diagnostic queries confirming mathematical money conservation and entity counts.
- Bamishaye_Favour_ERD.png
  High-resolution Entity-Relationship Diagram visualising all tables and relations.
- Bamishaye_Favour_ERD.dbml
  Machine-readable Database Markup Language (DBML) definition of the schema.
- Evidence Screenshots (Screenshots/):
  Bamishaye_Favour_301915930_01setup.png
  Bamishaye_Favour_301915930_er_diagram.png
  Bamishaye_Favour_301915930_seed_data.png
  Bamishaye_Favour_301915930_table01.png
  Bamishaye_Favour_301915930_table02.png
  Bamishaye_Favour_301915930_verify_seed_data.png
  Bamishaye_Favour_301915930_verify_table_account_data.png

--------------------------------------------------------------------------------
PORTFOLIO 2: QUERY OPTIMISATION & PERFORMANCE (Rubric: Query Analysis 5M + Implementation 8M)
--------------------------------------------------------------------------------
- Bamishaye_Favour_P2_README.md
  Portfolio overview, query catalog, planner configuration, and indexing guide.
- Bamishaye_Favour_P2_PerformanceResults.md
  Comprehensive benchmarking report with before/after EXPLAIN ANALYZE breakdowns.
- Bamishaye_Favour_P2_Queries.sql
  Complete suite of 9 financial queries (statements, fraud, reconciliation, joins).
- Bamishaye_Favour_P2_CreateIndexes.sql
  Optimized secondary, composite, partial, and covering B-Tree index DDLs.
- Bamishaye_Favour_P2_DropIndexes.sql
  Reset script dropping custom indexes to re-evaluate baseline unindexed state.
- Bamishaye_Favour_P2_CapturePlans.sql
  Automated script capturing execution plans and buffer statistics for Q1-Q9.
- Bamishaye_Favour_P2_PlannerExperiments.sql
  Planner GUC toggle tests, cost constant alterations, and selectivity tipping points.
- Bamishaye_Favour_P2_WriteCost.sql
  Empirical measurement quantifying secondary index storage and write amplification.
- Raw Output Logs (Output/):
  Bamishaye_Favour_P2_Plans_Before.txt
  Bamishaye_Favour_P2_Plans_After.txt
  Bamishaye_Favour_P2_Plans_Results.txt
  Bamishaye_Favour_P2_Plans_Planner.txt
- Evidence Screenshots (Screenshots/):
  21 timestamped pgAdmin/psql screenshots verifying execution plans (Q1-Q9).

--------------------------------------------------------------------------------
PORTFOLIO 3: TRANSACTIONS & CONCURRENCY (Rubric: Advanced Concepts 5M + Correctness 8M)
--------------------------------------------------------------------------------
- Bamishaye_Favour_P3_README.md
  Portfolio index, ACID lifecycle testing, and concurrency architecture overview.
- Bamishaye_Favour_P3_ConcurrencyAnalysis.md
  Mathematical proof of deadlock elimination and pgbench empirical evaluation.
- Bamishaye_Favour_P3_LockTimeoutExperiment.md
  Independent research experiment evaluating lock_timeout under queue contention.
- Bamishaye_Favour_P3_TransactionScripts.sql
  DDL defining transfer_funds() (canonical ordered locking) & demo routines.
- Bamishaye_Favour_P3_CommitRollbackDemo.sql
  Interactive test validating atomicity, commit persistence, and savepoints.
- Bamishaye_Favour_P3_StressTest_Ordered.pgbench
  pgbench benchmark workload simulating 10 concurrent sessions with ordered locking.
- Bamishaye_Favour_P3_StressTest_Unordered.pgbench
  pgbench benchmark workload exposing deadlocks under naive unordered locking.
- Bamishaye_Favour_P3_IntegrityCheck.sql
  5 diagnostic queries proving total money conservation (1 Trillion Naira).
- Raw Output Logs (Output/):
  Bamishaye_Favour_P3_Stress_Ordered.txt (5,977.72 TPS, 0 deadlocks)
  Bamishaye_Favour_P3_Stress_Unordered.txt (39.38 TPS, 62 deadlocks)
  Bamishaye_Favour_P3_Integrity_Before.txt
  Bamishaye_Favour_P3_Integrity_After_Ordered.txt
  Bamishaye_Favour_P3_Integrity_After_Unordered.txt
  Bamishaye_Favour_P3_Commit_Rollback_Output.txt
- Evidence Screenshots (Screenshots/):
  12 pgAdmin/terminal screenshots documenting stress tests and integrity audits.

--------------------------------------------------------------------------------
PORTFOLIO 4: NOSQL & ADVANCED DATA MODELS (Rubric: Advanced Concepts 5M + Design 6M)
--------------------------------------------------------------------------------
- Bamishaye_Favour_P4_README.md
  Polyglot architecture overview, schema design decisions, and execution guide.
- Bamishaye_Favour_P4_NoSQLModelDesign.md
  In-depth document modeling, embedding vs referencing, and schema validation.
- Bamishaye_Favour_P4_SQLvsNoSQLRationale.md
  Rigorous comparative rationale justifying MongoDB for polymorphic/telemetry data.
- Bamishaye_Favour_P4_SchemaValidation.js
  mongosh script enforcing $jsonSchema validation rules (rejects malformed docs).
- Bamishaye_Favour_P4_SeedData.js
  Deterministic LCG script generating 5,000 KYC profiles and 100,000 audit events.
- Bamishaye_Favour_P4_CrudAndAggregation.js
  CRUD operations and 4 enterprise aggregation pipelines (funnel, risk, fraud).
- Bamishaye_Favour_P4_IndexesExplain.js
  Compound index and TTL index creation with executionStats profiling.
- Raw Output Logs (Output/):
  Bamishaye_Favour_P4_Crud_And_Aggregation.txt
  Bamishaye_Favour_P4_Indexes_Explain.txt
- Evidence Screenshots (Screenshots/):
  9 MongoDB Compass and terminal screenshots validating schema, seeding, and queries.

--------------------------------------------------------------------------------
PORTFOLIO 5: DISTRIBUTED & CLOUD ARCHITECTURES (Rubric: Advanced Concepts 5M + Implementation 8M)
--------------------------------------------------------------------------------
- Bamishaye_Favour_P5_README.md
  Distributed architecture guide, multi-container topology, and failover runbook.
- Bamishaye_Favour_P5_ReplicationAndFailover.md
  Detailed analysis of streaming replication, CAP/PACELC trade-offs, and lag.
- Bamishaye_Favour_P5_DockerCompose.yml
  Multi-container Docker Compose definition for Primary and Hot Standby nodes.
- Bamishaye_Favour_P5_ReplicaEntrypoint.sh
  Automated basebackup and hot standby replication bootstrap script.
- Bamishaye_Favour_P5_PrimaryInit.sh
  Primary node initialization script configuring pg_hba.conf and replication slot.
- Bamishaye_Favour_P5_PrimaryChecks.sql
  Healthcheck queries inspecting pg_stat_replication and WAL sequence numbers.
- Bamishaye_Favour_P5_ReplicaChecks.sql
  Standby diagnostic queries checking pg_is_in_recovery() and replay lag.
- Bamishaye_Favour_P5_Partitioning.sql
  Declarative 4-shard hash partitioning of ledger_entries with pruning tests.
- Bamishaye_Favour_P5_AtlasCloudCheck.js
  MongoDB Atlas distributed quorum script verifying majority write/read concerns.
- Raw Output Logs (Output/):
  Bamishaye_Favour_P5_Primary_Checks.txt
  Bamishaye_Favour_P5_Replica_Checks.txt
  Bamishaye_Favour_P5_Partitioning.txt
  Bamishaye_Favour_P5_Atlas_Cloud_Check.txt
- Evidence Screenshots (Screenshots/):
  17 Docker, psql, and Atlas screenshots verifying replication, failover, and quorum.

--------------------------------------------------------------------------------
SYNTHESIS & GOVERNANCE ARTIFACTS (Rubric: Documentation 5M + Reflection 3M)
--------------------------------------------------------------------------------
- Bamishaye_Favour_README.txt
  Master submission catalog, file manifest, and evaluator execution guide.
- Bamishaye_Favour_Final_Report.md
  2-3 page comprehensive Final Synthesis Report covering all five portfolios.
- Bamishaye_Favour_AI_Use_Declaration.md
  Formal institutional declaration of Generative AI usage and HITL verification.
- Bamishaye_Favour_References.md
  Formal academic and industry citations (Codd, Gray, Coffman, Brewer, Kleppmann).


================================================================================
3. SYSTEM REQUIREMENTS & PREREQUISITES
================================================================================
To execute or inspect the complete test harness locally, ensure the following
software packages are installed:

1. PostgreSQL 16.x or 18.x
   - psql client and pgbench benchmarking tool.
   - Standard contrib modules enabled.
2. Docker Engine & Docker Compose (v2.x or higher)
   - Required for spinning up the Portfolio 5 primary/replica streaming cluster.
3. Node.js (v18+) and mongosh (v2.x+)
   - Required for executing MongoDB Atlas scripts in Portfolios 4 and 5.
4. MongoDB Atlas Account / URI
   - A standard free M0 sandbox cluster or local MongoDB instance (v7.0+).


================================================================================
4. STEP-BY-STEP EVALUATOR SCRIPT VERIFICATION GUIDE
================================================================================
Follow the sequential steps below to verify the portfolio implementations:

--------------------------------------------------------------------------------
STEP 1: Verify Portfolio 1 (Database Design, Schema & Constraints)
--------------------------------------------------------------------------------
1. Connect to PostgreSQL and create the clean database:
   createdb nexora_db
2. Deploy the relational 3NF schema:
   psql -d nexora_db -f Portfolio_1_Design_And_Modelling/Bamishaye_Favour_P1_CreateSchema.sql
3. Execute the 10 constraint unit tests (all must pass with RAISE NOTICE):
   psql -d nexora_db -f Portfolio_1_Design_And_Modelling/Bamishaye_Favour_P1_ConstraintTests.sql
4. Seed the database with deterministic synthetic data:
   psql -d nexora_db -f Portfolio_1_Design_And_Modelling/Bamishaye_Favour_P1_SeedData.sql
5. Confirm money conservation and table counts:
   psql -d nexora_db -f Portfolio_1_Design_And_Modelling/Bamishaye_Favour_P1_VerifySeed.sql
   Expected: Total system balance = exactly 1,000,000,000,000.0000 NGN.

--------------------------------------------------------------------------------
STEP 2: Verify Portfolio 2 (Query Optimisation & Index Profiling)
--------------------------------------------------------------------------------
1. Capture baseline unindexed execution plans (Q1 to Q9):
   psql -d nexora_db -f Portfolio_2_Query_Optimisation/Bamishaye_Favour_P2_CapturePlans.sql > plans_baseline.log
2. Deploy optimized composite, partial, and covering B-Tree indexes:
   psql -d nexora_db -f Portfolio_2_Query_Optimisation/Bamishaye_Favour_P2_CreateIndexes.sql
3. Re-run execution plans to verify speedups and buffer reductions:
   psql -d nexora_db -f Portfolio_2_Query_Optimisation/Bamishaye_Favour_P2_CapturePlans.sql > plans_optimized.log
4. Measure write amplification and secondary index storage overhead:
   psql -d nexora_db -f Portfolio_2_Query_Optimisation/Bamishaye_Favour_P2_WriteCost.sql

--------------------------------------------------------------------------------
STEP 3: Verify Portfolio 3 (ACID Transactions & Concurrency Stress Testing)
--------------------------------------------------------------------------------
1. Deploy the transfer_funds() and transfer_funds_unordered() functions:
   psql -d nexora_db -f Portfolio_3_Transactions_And_Concurrency/Bamishaye_Favour_P3_TransactionScripts.sql
2. Run the interactive ACID commit and rollback demonstration:
   psql -d nexora_db -f Portfolio_3_Transactions_And_Concurrency/Bamishaye_Favour_P3_CommitRollbackDemo.sql
3. Perform the pgbench Stress Test with Canonical Ordered Locking:
   pgbench -d nexora_db -c 10 -j 2 -t 200 -f Portfolio_3_Transactions_And_Concurrency/Bamishaye_Favour_P3_StressTest_Ordered.pgbench
   Expected Result: 2,000 txns, 0 deadlocks, >5,000 TPS.
4. Perform the pgbench Stress Test with Naive Unordered Locking:
   pgbench -d nexora_db -c 10 -j 2 -t 200 -f Portfolio_3_Transactions_And_Concurrency/Bamishaye_Favour_P3_StressTest_Unordered.pgbench
   Expected Result: Multiple deadlocks (approx 62), throughput collapses to <50 TPS.
5. Re-audit money conservation across the system:
   psql -d nexora_db -f Portfolio_3_Transactions_And_Concurrency/Bamishaye_Favour_P3_IntegrityCheck.sql
   Expected: Conservation intact at 1,000,000,000,000.0000 NGN; 0 unbalanced journals.

--------------------------------------------------------------------------------
STEP 4: Verify Portfolio 4 (NoSQL Document Store on MongoDB)
--------------------------------------------------------------------------------
1. Connect mongosh to your MongoDB instance:
   mongosh "<YOUR_MONGODB_URI>/nexora_db"
2. Initialize collections with strict $jsonSchema validation:
   load("Portfolio_4_NoSQL_Document_Store/Bamishaye_Favour_P4_SchemaValidation.js")
3. Execute synthetic seeding (creates 5,000 KYC profiles, 100k audit events):
   load("Portfolio_4_NoSQL_Document_Store/Bamishaye_Favour_P4_SeedData.js")
4. Run CRUD operations and 4 aggregation pipelines:
   load("Portfolio_4_NoSQL_Document_Store/Bamishaye_Favour_P4_CrudAndAggregation.js")
5. Profile indexes and evaluate TTL auto-purging on sessions:
   load("Portfolio_4_NoSQL_Document_Store/Bamishaye_Favour_P4_IndexesExplain.js")

--------------------------------------------------------------------------------
STEP 5: Verify Portfolio 5 (Distributed Streaming Replication & Failover)
--------------------------------------------------------------------------------
1. Navigate to the distributed directory and launch the two-node cluster:
   docker compose -f Portfolio_5_Distributed_And_Cloud/Bamishaye_Favour_P5_DockerCompose.yml up -d
2. Verify replication slot status on the Primary (Port 5433):
   psql -h localhost -p 5433 -U postgres -d nexora_db -f Portfolio_5_Distributed_And_Cloud/Bamishaye_Favour_P5_PrimaryChecks.sql
3. Verify standby recovery status on the Hot Standby (Port 5434):
   psql -h localhost -p 5434 -U postgres -d nexora_db -f Portfolio_5_Distributed_And_Cloud/Bamishaye_Favour_P5_ReplicaChecks.sql
4. Test declarative hash partitioning and partition pruning:
   psql -h localhost -p 5433 -U postgres -d nexora_db -f Portfolio_5_Distributed_And_Cloud/Bamishaye_Favour_P5_Partitioning.sql
5. Run MongoDB Atlas distributed cloud quorum verification:
   mongosh "<YOUR_ATLAS_URI>" Portfolio_5_Distributed_And_Cloud/Bamishaye_Favour_P5_AtlasCloudCheck.js
6. Clean up docker containers:
   docker compose -f Portfolio_5_Distributed_And_Cloud/Bamishaye_Favour_P5_DockerCompose.yml down -v


================================================================================
5. ACADEMIC INTEGRITY & AI DECLARATION SUMMARY
================================================================================
Generative AI was utilized in an ethical, assistive capacity strictly to:
1. Formulate deterministic mathematical data seeding algorithms (setseed in
   PostgreSQL and LCG in MongoDB) to create realistic financial datasets.
2. Author automated constraint testing harnesses and replication diagnostic scripts.

All architectural schema designs, 3NF normalisation derivations, deadlock-free
locking proofs, index optimization strategies, distributed failure evaluations,
and technical synthesis reflections represent original intellectual work conducted
by Bamishaye Favour. 

Full declaration: Bamishaye_Favour_AI_Use_Declaration.md
Academic references: Bamishaye_Favour_References.md
Final synthesis report: Bamishaye_Favour_Final_Report.md

================================================================================
END OF FILE: Bamishaye_Favour_README.txt
================================================================================
