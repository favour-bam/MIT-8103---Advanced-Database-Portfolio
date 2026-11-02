#!/usr/bin/env bash
# Runner for Portfolio 3 Concurrency Stress Testing
DB="${1:-nexora_db}"
echo "[*] Running Ordered Locking Stress Test on $DB..."
pgbench -d "$DB" -c 10 -j 2 -t 200 -f Bamishaye_Favour_P3_StressTest_Ordered.pgbench
echo "[*] Running Naive Unordered Locking Stress Test on $DB..."
pgbench -d "$DB" -c 10 -j 2 -t 200 -f Bamishaye_Favour_P3_StressTest_Unordered.pgbench
