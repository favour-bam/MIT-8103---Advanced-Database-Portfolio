# Academic Artificial Intelligence (AI) Declaration

**Course:** MIT 8103 – Advanced Database Systems  
**Session:** 2026/2027 Academic Session (September Cohort) – First Semester  
**Awarding Institution:** Miva Open University — School of Post Graduate Studies  
**Degree Program:** Master of Information Technology (M.Sc. / MIT)  
**Student Name:** Bamishaye Favour  
**Student ID:** 301915930  
**Project Platform:** Nexora – Digital Savings and Financial Management Platform (Simulated)  
**Date of Submission:** November 2026  
**Artifact:** `AI_declaration.md`  

---

## 1. Formal Institutional Declaration of Generative AI Usage

In strict accordance with Section 11 (*Academic Integrity and AI Use Declaration*) of the MIT 8103 Continuous Assessment specification and institutional academic integrity regulations, I, **Bamishaye Favour (Student ID: 301915930)**, hereby declare that Generative Artificial Intelligence (AI) tools were utilized in a controlled, assistive, and ethical capacity during the design, implementation, and evaluation of **Portfolios 1 through 5**.

The foundational relational architecture, 3NF schema derivations, controlled denormalisation defenses, transaction concurrency controls, deadlock elimination proofs, performance optimization strategies, and distributed cluster evaluations represent my own original intellectual work and understanding. AI was employed strictly as a technical accelerator under human-in-the-loop oversight.

---

## 2. Mandatory Institutional Three-Part Declaration (Section 11 Compliance)

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                   SECTION 11 INSTITUTIONAL THREE-PART AI DECLARATION                   │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ I. THE SPECIFIC AI TOOLS USED                                                          │
│    • OpenAI ChatGPT-4 / GPT-4o (OpenAI)                                                │
│    • Anthropic Claude 3.5 Sonnet (Anthropic)                                           │
│    • Google Gemini 1.5 Pro (Google DeepMind / Antigravity Assistant)                   │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ II. WHAT THE AI TOOLS WERE USED FOR                                                    │
│    1. Formulating mathematical synthetic seed data generation routines:                │
│       - PostgreSQL: PL/pgSQL loop routines with deterministic `setseed(0.42)` to       │
│         populate 5,000 customers, 6,003 accounts, 206k transactions, and 404k ledgers.│
│       - MongoDB: Deterministic Linear Congruential Generator (LCG) script              │
│         (`02_seed_data.js`) generating 5,000 polymorphic KYC docs & 100k audit events. │
│    2. Scaffolding automated diagnostic checks & constraint test harness:               │
│       - Automated PL/pgSQL unit tests (`03_constraint_tests.sql`) for negative checks, │
│         regexes, and `ON DELETE RESTRICT` foreign key integrity.                       │
│       - MongoDB `$jsonSchema` validation negative tests intentionally triggering       │
│         rejection error code `121` (`DocumentValidationFailure`).                      │
│       - Scaffolding pgbench concurrency stress scripts and Docker health check queries.│
├────────────────────────────────────────────────────────────────────────────────────────┤
│ III. HOW OUTPUTS WERE REVIEWED, CORRECTED, TESTED, AND VERIFIED BY THE STUDENT         │
│    1. Line-by-Line Technical Code Audit: Every generated SQL query and JavaScript      │
│       routine was audited against official PostgreSQL 16 and MongoDB 7.0 documentation.│
│    2. Mathematical Invariant Verification: Formulated diagnostic queries               │
│       (`05_verify_seed.sql` & `06_integrity_check.sql`) proving that total system money│
│       remained constant at exactly ₦1,000,000,000,000.00, and verified zero unbalanced │
│       double-entry journals (sum(Debits) - sum(Credits) = 0).                          │
│    3. Hands-On Empirical Execution: All scripts were physically executed on local      │
│       PostgreSQL 16 instances, Docker Compose multi-container clusters, and live        │
│       MongoDB Atlas cloud clusters.                                                    │
│    4. Authentic Evidence Generation: Every execution transcript in `Output/` and every │
│       screenshot in `Screenshots/` (bearing `Bamishaye_Favour_301915930_...`) reflects │
│       an unmanipulated empirical run conducted directly by the student.                │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Scope of AI Assistance Across the 5 Portfolios

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              AI ASSISTANCE BY MODULE                                   │
├──────────────┬──────────────────────────────┬──────────────────────────────────────────┤
│ Portfolio    │ Area of Application          │ Purpose & Specific Artifacts             │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ Port 1 (7M)  │ • PostgreSQL Synthetic Seed  │ Formulated 04_seed_data.sql with         │
│              │ • Constraint & Health Checks │ setseed(0.42) (5k customers, 6k wallets, │
│              │                              │ 206k transactions, 400k+ ledger entries).│
│              │                              │ Simulated 10 PL/pgSQL constraint tests   │
│              │                              │ (03_constraint_tests.sql) and 7 audits.  │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ Port 2 (7M)  │ • Query Profiling Automation │ Assisted in generating diagnostic scripts│
│              │ • Write Amplification Checks │ for capturing EXPLAIN (ANALYZE, BUFFERS) │
│              │                              │ and quantifying secondary index overhead │
│              │                              │ (01_capture_plans.sql, write_cost).      │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ Port 3 (7M)  │ • Concurrency Stress Tests   │ Generated synthetic concurrency workloads│
│              │ • Invariant Audit Scripts    │ (.pgbench scripts) and simulated money   │
│              │                              │ conservation checks (06_integrity_check  │
│              │                              │ proving constant ₦1,000,000,000,000.00). │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ Port 4 (7M)  │ • MongoDB Synthetic Seed     │ Formulated deterministic LCG script      │
│              │ • Schema Validation Checks   │ (02_seed_data.js, seedState = 42) for    │
│              │ • Aggregation Diagnostics    │ 5k KYC profiles and 100k audit events.   │
│              │                              │ Generated validation error simulations.  │
├──────────────┼──────────────────────────────┼──────────────────────────────────────────┤
│ Port 5 (6M)  │ • Replication Diagnostics    │ Assisted in authoring replication health │
│              │ • Chaos & Lag Simulation     │ checks (01_primary_checks.sql,           │
│              │ • Cloud Quorum Checks        │ 02_replica_checks.sql), replica freeze   │
│              │                              │ routines, and Atlas test script (04).    │
└──────────────┴──────────────────────────────┴──────────────────────────────────────────┘
```

---

## 4. Human-in-the-Loop (HITL) Verification & Authorship Affirmation

Every script, query, configuration file, and diagnostic test assisted by Generative AI was subjected to strict **Human-in-the-Loop (HITL)** engineering oversight:

1. **Independent Verification:** All code and SQL/MQL logic was reviewed line-by-line, debugged, and validated against official PostgreSQL 16 and MongoDB Atlas technical documentation.
2. **Empirical Execution:** All scripts were executed on physical test environments (Apple Silicon macOS running PostgreSQL 16 via pgAdmin/psql, Docker Compose multi-container clusters, and live MongoDB Atlas cloud clusters).
3. **Evidence Authenticity:** Every screenshot in the `Screenshots/` directories and every execution transcript in the `Output/` directories reflects an authentic, un-manipulated empirical run conducted by the student.
4. **Analytical Authorship:** All explanations, architectural justifications, theoretical proofs, and conclusions presented in the `README.md`, `normalisation.md`, `performance-analysis.md`, `analysis.md`, `nosql-model-design.md`, and `sql-vs-nosql-rational.md` documents were authored, synthesized, and defended by the student.

---

## 5. Affirmation & Academic Integrity Pledge

I affirm that the description above accurately and honestly reflects the nature and extent of Generative AI usage in this course project. I accept full personal and academic responsibility for the integrity, correctness, originality, and explanation of all submitted work if selected for individual verification.

**Student Name:** Bamishaye Favour  
**Student ID:** 301915930  
**Signature:** *Bamishaye Favour*  
**Date:** November 2026  
