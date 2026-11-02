#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username nexora --dbname nexora_db <<EOSQL
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'repl_pass';
EOSQL
echo "host replication replicator all scram-sha-256" >> /var/lib/postgresql/data/pg_hba.conf