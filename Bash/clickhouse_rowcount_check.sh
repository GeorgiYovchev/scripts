#!/bin/bash

USER="default"
PASS="zPqvldz321"
HOST="localhost"
PORT="9000"

echo "===== ClickHouse Row Count Report ====="
echo "Generated on: $(date)"
echo

# Get all databases except system/default schemas
DBS=$(clickhouse-client --host $HOST --port $PORT -u $USER --password "$PASS" -q "SHOW DATABASES" | grep -v -E '^(system|INFORMATION_SCHEMA|information_schema|default)$')

for DB in $DBS; do
  echo ">>> Database: $DB"
  
  TABLES=$(clickhouse-client --host $HOST --port $PORT -u $USER --password "$PASS" -q "SHOW TABLES FROM $DB")

  if [ -z "$TABLES" ]; then
    echo "    (no tables)"
  else
    for T in $TABLES; do
      COUNT=$(clickhouse-client --host $HOST --port $PORT -u $USER --password "$PASS" -q "SELECT count() FROM $DB.$T")
      echo "    $T : $COUNT rows"
    done
  fi

  echo
done
