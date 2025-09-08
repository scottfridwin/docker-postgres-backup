#!/bin/bash
set -euo pipefail

DATE=$(date +%F_%H-%M-%S)
DEST_DIR="/backups/full/$DATE"
mkdir -p "$DEST_DIR"

export PGPASSWORD=$(cat $PGPASSWORD_FILE)

echo "[$(date)] Performing full backup..."
pg_dump -h "${POSTGRES_HOST}" \
        -p "${POSTGRES_PORT}" \
        -U "${POSTGRES_USER}" \
        "${POSTGRES_DB}" | gzip > "$DEST_DIR/$BACKUP_NAME.gz"

# Apply retention
find /backups/full -type d -mtime +${RETENTION_FULL_DAYS} -exec rm -rf {} +

echo "[$(date)] Full backup completed."