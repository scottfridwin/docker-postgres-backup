#!/bin/bash
set -euo pipefail

BACKUP_SUBDIR="${BACKUP_SUBDIR:-}"
if [ -n "$BACKUP_SUBDIR" ]; then
    BASE_BACKUP_DIR="/backups/$BACKUP_SUBDIR"
else
    BASE_BACKUP_DIR="/backups"
fi

DATE=$(date +%F_%H-%M-%S)
DEST_DIR="$BASE_BACKUP_DIR/incremental/$DATE"
mkdir -p "$DEST_DIR"

echo "[$(date)] Performing incremental backup..."

# Backup all WALs since last backup
cp /wal_archive/* "$DEST_DIR/" || true

# Apply retention on the incremental backups themselves
find $BASE_BACKUP_DIR/incremental -type d -mtime +${RETENTION_INC_DAYS} -exec rm -rf {} +

# Clean up WAL files using pg_archivecleanup
# Determine the last WAL file to keep
LAST_WAL=$(ls -1 /wal_archive/* | sort | tail -n 1 || true)
if [ -n "$LAST_WAL" ]; then
    echo "[$(date)] Cleaning up WAL archive up to $LAST_WAL"
    pg_archivecleanup /wal_archive "$LAST_WAL"
fi

echo "[$(date)] Incremental backup completed."