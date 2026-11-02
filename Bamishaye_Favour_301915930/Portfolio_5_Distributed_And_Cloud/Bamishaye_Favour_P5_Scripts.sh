#!/usr/bin/env bash
# Runner for Portfolio 5 Distributed Topology Verification
echo "[*] Launching PostgreSQL Primary and Standby containers..."
docker compose -f Bamishaye_Favour_P5_DockerCompose.yml up -d
echo "[*] Checking Primary replication status..."
sleep 3
psql -h localhost -p 5433 -U postgres -d nexora_db -f Bamishaye_Favour_P5_PrimaryChecks.sql
echo "[*] Checking Hot Standby recovery status..."
psql -h localhost -p 5434 -U postgres -d nexora_db -f Bamishaye_Favour_P5_ReplicaChecks.sql
