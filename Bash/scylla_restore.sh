#!/bin/bash
set -euo pipefail

# Config 
S3_BUCKET="oddstech-backup"
CLUSTER_ID="06c66eb5-7a77-44a2-8678-365e192910d8"
LOCAL_DATA_DIR="/var/lib/scylla/data"

# Node IDs from backup
NODE_IDS=(
  "03920d28-5ef9-4d20-a726-0826e71d4d60"
  "3136b04e-c77c-4955-8fb7-ce8f9961e3f5"
  "d17169f9-b5e6-4ae4-8c44-21e5be795583"
)

# Keyspaces to restore
KEYSPACES=(
  "payments"
  "accounting"
  "manualpay"
  "casino_aggregator"
)

# 1. Loop over nodes and keyspaces
for NODE_ID in "${NODE_IDS[@]}"; do
  for KEYSPACE in "${KEYSPACES[@]}"; do
    echo "=== Restoring $KEYSPACE from node $NODE_ID ==="

    # 2. Download SSTables into staging directory
    STAGE_DIR="/tmp/scylla_restore/$NODE_ID/$KEYSPACE"
    mkdir -p "$STAGE_DIR"

    aws s3 sync \
      s3://$S3_BUCKET/backup/sst/cluster/$CLUSTER_ID/dc/datacenter1/node/$NODE_ID/keyspace/$KEYSPACE/ \
      "$STAGE_DIR/" || {
        echo "⚠️ No SSTables found for $KEYSPACE on $NODE_ID, skipping"
        continue
      }

    # 3. Copy into Scylla data dir
    for TABLE_DIR in "$STAGE_DIR"/*; do
      TABLE_NAME=$(basename "$TABLE_DIR")
      TARGET_DIR=$(ls -d $LOCAL_DATA_DIR/$KEYSPACE/${TABLE_NAME}-*/ 2>/dev/null || true)

      if [ -n "$TARGET_DIR" ]; then
        echo "Copying $TABLE_NAME → $TARGET_DIR"
        cp -r "$TABLE_DIR"/* "$TARGET_DIR"/
      else
        echo "⚠️ Target dir for $TABLE_NAME not found, skipping"
      fi
    done
  done
done

# 4. Run refresh per keyspace
for KS in "${KEYSPACES[@]}"; do
  echo "Running nodetool refresh on keyspace: $KS"
  for TABLE in $(cqlsh -e "USE $KS; DESC TABLES;" | tr -d '[:space:]'); do
    nodetool refresh $KS $TABLE || true
  done
done

echo "✅ ScyllaDB restore completed for all nodes/keyspaces"
