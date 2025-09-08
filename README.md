# docker-postgres-backup

A simple, containerized solution for automated full and incremental backups of a PostgreSQL database, with retention policies and optional incremental backup scheduling.

## Features

- **Full Backups:** Scheduled `pg_dump` backups of your PostgreSQL database, compressed and stored in `/backups/full` or `/backups/$BACKUP_SUBDIR/full`.
- **Incremental Backups:** Optionally perform a physical base backup (`pg_basebackup`) and archive PostgreSQL WAL files for point-in-time recovery. Base backups are stored in `/backups/base` or `/backups/$BACKUP_SUBDIR/base`, and WAL incrementals in `/backups/incremental` or `/backups/$BACKUP_SUBDIR/incremental`. Incrementals are retained only as long as their corresponding base backup exists.
- **Retention Policies:** Automatically remove old backups based on configurable retention periods.
- **Configurable Scheduling:** Use environment variables to control backup intervals via cron.
- **Easy Integration:** Designed to run as a Docker container, with minimal configuration.
- **Customizable:** Enable or disable incremental backups with a single environment variable.

## Usage

### Environment Variables

| Variable                          | Description                                              | Default                |
|-----------------------------------|----------------------------------------------------------|------------------------|
| `POSTGRES_HOST`                   | PostgreSQL host                                          | (required)             |
| `POSTGRES_PORT`                   | PostgreSQL port                                          | (required)             |
| `POSTGRES_USER`                   | PostgreSQL user                                          | (required)             |
| `POSTGRES_DB`                     | PostgreSQL database name                                 | (required)             |
| `PGPASSWORD_FILE`                 | Path to file containing the PostgreSQL password          | (required)             |
| `ENABLE_INCREMENTAL`              | Enable incremental (WAL) backups (`true`/`false`)        | `true`                 |
| `BACKUP_NAME`                     | Name for the backup file                                 | `backup`               |
| `RETENTION_FULL_DAYS`             | Days to keep full backups                                | `7`                    |
| `RETENTION_INC_DAYS`              | Days to keep incremental backups                         | `3`                    |
| `BACKUP_FULL_INTERVAL`            | Cron schedule for full backups                           | `0 2 1 * *`            |
| `BACKUP_INCREMENTAL_BASE_INTERVAL`| Cron schedule for incremental base backups               | `0 3 * * 0`            |
| `BACKUP_INCREMENTAL_INTERVAL`     | Cron schedule for incremental backups                    | `0 */6 * * *`          |
| `BACKUP_SUBDIR`                   | Subdirectory for backups to be stored                    | (undefined)            |

### Volumes

- `/backups` — Where backups are stored (mount this to persist backups)
- `/wal_archive` — Directory where PostgreSQL archives WAL files (mount this for incremental backups)

### Docker Run Example

```sh
docker run -d \
  -e POSTGRES_HOST=db \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=mydb \
  -e PGPASSWORD_FILE=/run/secrets/pgpassword \
  -e RETENTION_FULL_DAYS=30 \
  -e RETENTION_INC_DAYS=10 \
  -e ENABLE_INCREMENTAL=true \
  -v /host/backups:/backups \
  -v /host/wal_archive:/wal_archive \
  --name pg-backup \
  fridwin/postgres-backup
```

### Docker Compose Example

```yaml
services:
  postgres-backup:
    image: fridwin/postgres-backup
    container_name: postgres-backup
    user: "my_uid:my_gid" # Suggested, not required
    environment:
      - TZ=${TIME_ZONE}
      - POSTGRES_HOST=db
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_DB=mydb
      - PGPASSWORD_FILE=/run/secrets/pgpassword
      - RETENTION_FULL_DAYS=30
      - RETENTION_INC_DAYS=10
      - ENABLE_INCREMENTAL=true
    volumes:
      - /host/backups:/backups
      - /host/wal_archive:/wal_archive
    restart: unless-stopped
```

### PostgreSQL WAL Archiving

To use incremental backups, configure your PostgreSQL server to archive WAL files to the `/wal_archive` directory (mounted into the container). Example `postgresql.conf` settings:

```
archive_mode = on
archive_command = 'cp %p /wal_archive/%f'
```

### Restore

__TODO: Better examples for restore process. Possible commands that can be run with container as one-time execution for restore.__
- **Full backup:** Unzip and restore with `pg_restore` or `psql`.
- **Incremental backup:** Use full backup plus WAL files for point-in-time recovery.


### Healthcheck

The container includes a healthcheck that verifies:

1. Cron is running
2. The last backup completed successfully
3. Optionally, the last backup is recent (if `MAX_AGE` is set)

```yaml
HEALTHCHECK --interval=5m --timeout=10s --start-period=1m CMD /healthcheck.sh
```

---
## License

MIT License © 2025 Scott Fridlund