FROM alpine:3.22

RUN apk add --no-cache \
          postgresql15 \
          rclone \
          redis \
          bash \
          tzdata \
          coreutils \
          busybox-suid \
          curl \
          su-exec \
          dcron \
          gzip \
    && mkdir -p /scripts /backups

COPY backup_full.sh /scripts/backup_full.sh
COPY backup_incremental.sh /scripts/backup_incremental.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /scripts/*.sh /entrypoint.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=1m --retries=3 CMD pgrep crond >/dev/null && [ -d /backups ] && [ -w /backups ]

ENTRYPOINT ["/entrypoint.sh"]