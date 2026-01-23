#!/bin/bash

# Configuration
PG_USER="postgres"
PG_HOST="localhost"
PG_PORT="5432"
BACKUP_DIR="/opt/pg_backups"
DATE=$(date +"%Y-%m-%d_%H-%M")
RCLONE_REMOTE="ionos:oddstech-backup/prod-postgres"
LOG_FILE="$BACKUP_DIR/pg_backup.log"

# Backup Each DB
databases=$(psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" | xargs)

for db in $databases; do
  BACKUP_FILE="${BACKUP_DIR}/${db}_${DATE}.sql.gz"
  echo "Backing up $db to $BACKUP_FILE..." | tee -a "$LOG_FILE"
  pg_dump -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" "$db" | gzip > "$BACKUP_FILE"
  
  if [ $? -eq 0 ]; then
    echo "Upload $BACKUP_FILE to S3..." | tee -a "$LOG_FILE"
    rclone copy "$BACKUP_FILE" "$RCLONE_REMOTE/" >> "$LOG_FILE" 2>&1
  else
    echo "Backup failed for $db on $DATE" | tee -a "$LOG_FILE"
  fi
done

# Cleanup local backups older than 7 days
find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +7 -delete
