#!/bin/bash
set -euo pipefail

BACKUP_SUBDIR="${BACKUP_SUBDIR:-}"
if [ -n "$BACKUP_SUBDIR" ]; then
    BASE_BACKUP_DIR="/backups/$BACKUP_SUBDIR"
else
    BASE_BACKUP_DIR="/backups"
fi

DATE=$(date +%F_%H-%M-%S)
DEST_DIR="$BASE_BACKUP_DIR/full/$DATE"
if ! mkdir -p "$DEST_DIR"; then
    echo "[ERROR] Failed to create directory $DEST_DIR"
    exit 1
fi

export PGPASSWORD=$(cat $PGPASSWORD_FILE)

echo "[INFO] Performing full backup..."
if ! pg_dump -h "${POSTGRES_HOST}" \
        -p "${POSTGRES_PORT}" \
        -U "${POSTGRES_USER}" \
        "${POSTGRES_DB}" | gzip > "$DEST_DIR/$BACKUP_NAME.gz"; then
    echo "[ERROR] $1"
    exit 1
fi

# Apply retention
if ! find "$BASE_BACKUP_DIR/full" -type d -mtime +"${RETENTION_FULL_DAYS}" -exec rm -rf {} +; then
    echo "[WARNING] Retention cleanup failed"
fi

echo "[INFO] Full backup completed."