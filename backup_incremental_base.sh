#!/bin/bash
set -euo pipefail

BACKUP_SUBDIR="${BACKUP_SUBDIR:-}"
if [ -n "$BACKUP_SUBDIR" ]; then
    BASE_BACKUP_DIR="/backups/$BACKUP_SUBDIR"
else
    BASE_BACKUP_DIR="/backups"
fi

DATE=$(date +%F_%H-%M-%S)
DEST_DIR="$BASE_BACKUP_DIR/incremental_base/$DATE"

echo "[INFO] Performing incremental base backup into $DEST_DIR"
mkdir -p "$DEST_DIR"

export PGPASSWORD=$(cat "$PGPASSWORD_FILE")

if ! pg_basebackup \
        -h "${POSTGRES_HOST}" \
        -p "${POSTGRES_PORT}" \
        -U "${POSTGRES_USER}" \
        -D "$DEST_DIR" \
        -F tar \
        -z \
        -X none; then
    echo "[ERROR] Base backup failed"
    exit 1
fi

echo "[INFO] Base backup completed."

# Cleanup old incremental base backups
echo "[INFO] Applying incremental base backup retention policy..."
if ! find "$BASE_BACKUP_DIR/incremental_base" -mindepth 1 -maxdepth 1 -type d -mtime +"${RETENTION_INC_DAYS}" -print -exec rm -rf {} + 2>&1; then
    echo "[WARNING] Retention cleanup for incremental base backups may have failed" >&2
fi

# Cleanup old incrementals relative to the oldest base
OLDEST_BASE=$(ls -1 "$BASE_BACKUP_DIR/incremental_base" | sort | head -n 1 || true)

if [ -n "$OLDEST_BASE" ]; then
    echo "[INFO] Retaining incrementals since base $OLDEST_BASE"
    if ! find "$BASE_BACKUP_DIR/incremental" -mindepth 1 -maxdepth 1 -type d \
        ! -newer "$BASE_BACKUP_DIR/incremental_base/$OLDEST_BASE" \
        -print -exec rm -rf {} + 2>&1; then
        echo "[WARNING] Retention cleanup for incrementals may have failed" >&2
    fi
else
    echo "[INFO] No incremental base backups found, skipping incremental cleanup"
fi
