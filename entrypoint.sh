#!/bin/bash
set -euo pipefail

CRON_DIR=/tmp/cron
mkdir -p "$CRON_DIR"

ENABLE_INCREMENTAL="${ENABLE_INCREMENTAL:-true}"
FULL_INTERVAL="${BACKUP_FULL_INTERVAL:-0 2 * * 0}"

cat > "$CRON_DIR/backup" <<EOF
$FULL_INTERVAL /scripts/backup_full.sh
EOF

if [[ "$ENABLE_INCREMENTAL" == "true" ]]; then
    INC_INTERVAL="${BACKUP_INCREMENTAL_INTERVAL:-0 */6 * * *}"
    echo "$INC_INTERVAL /scripts/backup_incremental.sh" >> "$CRON_DIR/backup"
fi

echo "Starting dcron with schedule:"
cat "$CRON_DIR/backup"

# Use busybox crond (non-root safe)
exec busybox crond -f -l 8 -c "$CRON_DIR"