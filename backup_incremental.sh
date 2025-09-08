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
if ! mkdir -p "$DEST_DIR"; then
    echo "[ERROR] Failed to create directory $DEST_DIR"
    exit 1
fi

echo "[INFO] Performing incremental backup..."

# Backup all WALs since last backup
if ! cp /wal_archive/* "$DEST_DIR/" 2>/dev/null; then
    echo "[WARNING] No WAL files found to copy from /wal_archive"
fi

# Clean up WAL files using pg_archivecleanup
LAST_WAL=$(ls -1 /wal_archive/* 2>/dev/null | sort | tail -n 1 || true)
if [ -n "$LAST_WAL" ]; then
    echo "[INFO] Cleaning up WAL archive up to $LAST_WAL"
    if ! pg_archivecleanup /wal_archive "$LAST_WAL"; then
        echo "[WARNING] pg_archivecleanup failed"
    fi
else
    echo "[INFO] No WAL files found for cleanup."
fi

echo "[INFO] Incremental backup completed."