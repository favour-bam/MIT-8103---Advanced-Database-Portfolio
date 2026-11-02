#!/bin/bash
set -e
export PGDATA=/var/lib/postgresql/data

if [ ! -s /var/lib/postgresql/data/PG_VERSION ]; then
  echo "replica: waiting for the primary..."
  until pg_isready -h primary -p 5432 -U nexora -d nexora_db; do sleep 2; done
  mkdir -p /var/lib/postgresql/data
  chown postgres:postgres /var/lib/postgresql/data
  chmod 700 /var/lib/postgresql/data
  echo "replica: taking a base backup from the primary"
  PGPASSWORD=repl_pass gosu postgres pg_basebackup -h primary -p 5432 -U replicator -D /var/lib/postgresql/data -R -X stream -C -S replica1_slot -c fast -v
fi

chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data
exec gosu postgres postgres -c hot_standby=on