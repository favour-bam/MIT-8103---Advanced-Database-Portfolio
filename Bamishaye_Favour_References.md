# Academic and Industry References

**Course:** MIT 8103 – Advanced Database Systems  
**Session:** 2026/2027 Academic Session (September Cohort)  
**Institution:** Miva Open University — School of Post Graduate Studies  
**Student Name:** Bamishaye Favour  
**Student ID:** 301915930  
**Project:** Nexora – Digital Savings and Financial Management Platform (Simulated)  

---

## 1. Classical Relational Theory & Normalisation

1. **Codd, E. F. (1970).** "A Relational Model of Data for Large Shared Data Banks." *Communications of the ACM*, 13(6), pp. 377–387.  
   *Relevance:* Foundational principles of relational algebra, functional dependencies, and 1NF through 3NF applied in Portfolio 1 entity decomposition.

2. **Codd, E. F. (1972).** "Further Normalization of the Data Base Relational Model." In *Data Base Systems*, Courant Computer Science Symposia Series 6, Prentice-Hall, pp. 33–64.  
   *Relevance:* Elimination of transitive dependencies and Boyce-Codd Normal Form (BCNF) principles evaluated against production financial ledgers.

3. **Date, C. J. (2004).** *An Introduction to Database Systems* (8th ed.). Addison-Wesley.  
   *Relevance:* Reference framework for relational constraints, domain integrity (`CHECK`, `FOREIGN KEY`), and operational update anomalies.

---

## 2. Query Optimisation & Index Engineering

4. **Graefe, G. (1993).** "Query Evaluation Techniques for Large Databases." *ACM Computing Surveys (CSUR)*, 25(2), pp. 73–169.  
   *Relevance:* Theoretical basis for relational access paths, B-Tree traversal mechanics, sequential scans, and cost-based plan selection evaluated in Portfolio 2.

5. **PostgreSQL Global Development Group. (2024).** *PostgreSQL 16.3 Documentation: Chapter 14 – Using EXPLAIN; Chapter 11 – Indexes.* Available at: [https://www.postgresql.org/docs/16/](https://www.postgresql.org/docs/16/)  
   *Relevance:* Exact cost formula calculations (`seq_page_cost`, `random_page_cost`, `cpu_tuple_cost`), buffer hit counters, composite indexing, partial indexing, and covering indexes with `INCLUDE` clauses.

6. **Chaudhuri, S. (1998).** "An Overview of Query Optimization in Relational Systems." In *Proceedings of the 17th ACM SIGACT-SIGMOD-SIGART Symposium on Principles of Database Systems (PODS)*, pp. 34–43.  
   *Relevance:* Dynamic programming join enumeration and selectivity estimation mechanics applied to multi-table ledger reconciliations.

---

## 3. Transaction Processing, Concurrency & Deadlocks

7. **Gray, J., & Reuter, A. (1993).** *Transaction Processing: Concepts and Techniques.* Morgan Kaufmann Publishers.  
   *Relevance:* Formal definition of ACID transaction lifecycles, write-ahead logging (WAL), two-phase locking (2PL), and isolation phenomena implemented in Portfolio 3.

8. **Coffman, E. G., Elphick, M. J., & Shoshani, A. (1971).** "System Deadlocks." *ACM Computing Surveys (CSUR)*, 3(2), pp. 67–78.  
   *Relevance:* Formalization of Coffman's four deadlock conditions (Mutual Exclusion, Hold and Wait, No Preemption, Circular Wait) and mathematical proof of circular wait elimination via canonical ordered locking (`LEAST/GREATEST`).

9. **Berenson, H., Bernstein, P., Gray, J., Melton, J., O'Neil, E., & O'Neil, P. (1995).** "A Critique of ANSI SQL Isolation Levels." *ACM SIGMOD Record*, 24(2), pp. 1–10.  
   *Relevance:* Analysis of read phenomena (dirty read, non-repeatable read, phantom read, write skew) and MVCC snapshot isolation guarantees in PostgreSQL.

---

## 4. NoSQL Document Stores & Polyglot Persistence

10. **Fowler, M., & Sadalage, P. J. (2012).** *NoSQL Distilled: A Brief Guide to the Emerging World of Polyglot Persistence.* Addison-Wesley.  
    *Relevance:* Architectural rationale for polyglot persistence: dividing transactional financial ledgers (PostgreSQL) from polymorphic, schema-flexible audit telemetry (MongoDB) in Portfolio 4.

11. **MongoDB, Inc. (2024).** *MongoDB Manual v7.0: Schema Validation, Aggregation Pipeline, and Indexing.* Available at: [https://www.mongodb.com/docs/manual/](https://www.mongodb.com/docs/manual/)  
    *Relevance:* Implementation details of `$jsonSchema` document constraint validation, TTL background collection purging, and compound aggregation pipeline optimization.

---

## 5. Distributed Systems, Replication & Consensus

12. **Brewer, E. A. (2000).** "Towards Robust Distributed Systems." *ACM PODC Keynote*, Portland, OR.  
    *Relevance:* Formulation of the CAP theorem (Consistency, Availability, Partition Tolerance) evaluated empirically in Portfolio 5 replication failover.

13. **Brewer, E. A. (2012).** "CAP Twelve Years Later: How the 'Rules' Have Changed." *Computer*, 45(2), pp. 23–29.  
    *Relevance:* Analysis of modern trade-offs between partitions, latency, and consistency windows during network degradation.

14. **Abadi, D. J. (2012).** "Consistency Tradeoffs in Modern Distributed Database System Design: CAP is Only Part of the Story." *Computer*, 45(2), pp. 37–42.  
    *Relevance:* The PACELC theorem model applied to evaluate asynchronous PostgreSQL streaming replication and MongoDB Atlas majority quorums.

15. **Kleppmann, M. (2017).** *Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems.* O'Reilly Media.  
    *Relevance:* Core reference for streaming replication lag, WAL ship-and-replay mechanics, split-brain mitigation, and declarative horizontal hash partitioning.

16. **Ongaro, D., & Ousterhout, J. (2014).** "In Search of an Understandable Consensus Algorithm (Raft)." In *2014 USENIX Annual Technical Conference (USENIX ATC 14)*, pp. 305–319.  
    *Relevance:* Theoretical grounding for MongoDB Atlas 3-node replica set leader election and majority write quorums.
