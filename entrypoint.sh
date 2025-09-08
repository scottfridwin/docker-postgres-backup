#!/bin/bash
set -euo pipefail

CRON_DIR=/tmp/cron
mkdir -p "$CRON_DIR"

ENABLE_INCREMENTAL="${ENABLE_INCREMENTAL:-true}"
FULL_INTERVAL="${BACKUP_FULL_INTERVAL:-0 2 1 * *}" # Default to 2:00 AM on the first day of each month

cat > "$CRON_DIR/backup" <<EOF
$FULL_INTERVAL /scripts/backup_full.sh
EOF

if [[ "$ENABLE_INCREMENTAL" == "true" ]]; then
    INC_BASE_INTERVAL="${BACKUP_INCREMENTAL_BASE_INTERVAL:-0 3 * * 0}" # Default to 3:00 AM every Sunday
    echo "$INC_BASE_INTERVAL /scripts/backup_incremental_base.sh" >> "$CRON_DIR/backup"
    INC_INTERVAL="${BACKUP_INCREMENTAL_INTERVAL:-0 */6 * * *}" # Default to every 6 hours
    echo "$INC_INTERVAL /scripts/backup_incremental.sh" >> "$CRON_DIR/backup"
fi

echo "Starting dcron with schedule:"
cat "$CRON_DIR/backup"

# Use busybox crond (non-root safe)
exec busybox crond -f -l 8 -c "$CRON_DIR"