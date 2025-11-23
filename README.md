# Volume Backupper

A small Docker image that reads data from a mounted volume and periodically stores compressed backups.
Originally created after losing a Minecraft server; it is suitable for any directory you want to snapshot.

---
### Volumes
- `/backups:rw` where backups are stored. Files are saved with the following format: `backup_$(date +"%Y%m%d_%H%M%S")`
- `/data:ro` directory from which to read the data

Notes:
- The container writes backup files into `/backups` and reads the source data from `/data`.
- Ensure the host directory mounted as `/backups` is writable by the container process.

---
### Environment
- `PERIOD_CRON_SYNTAX`: specify the period. Example: `"*/1 * * * *"` to run it every minute (default). NOTE: it's not possible to go below one minute.
- `SKIP_ZIP_PATHS`: list-string of relative paths to ignore. Example: `[ignore_this, ignore_this2]`
- `RETENTION`: how many old backups to keep (default `3`)

### Environment variables
- `PERIOD_CRON_SYNTAX` (string): Cron syntax (5 fields). Example: `"*/1 * * * *"` runs every minute. The scheduler does not support intervals below one minute.
- `SKIP_ZIP_PATHS` (JSON array string): List of relative paths (to `/data`) to exclude from the zip. Example: `
  - `[ignore_this, ignore_this2]`
  Paths are interpreted relative to the root of the mounted `/data` volume.
- `RETENTION` (integer): Number of most recent backups to keep (default `3`). Older backups are deleted by count (keeps N newest files). Setting `0` will keep no backups (not recommended).

---
### Example docker-compose
```yml
services:
  volume_backupper:
    image: dosisido/volume_backupper:latest
    container_name: volume_backupper
    restart: unless-stopped
    volumes:
      - ./backups:/backups:rw
      - ./data:/data:ro
    environment:
      - PERIOD_CRON_SYNTAX=*/1 * * * *
      - SKIP_ZIP_PATHS="[ignore_this, ignore_this2]"
      - RETENTION=3
```

### Quick start

Using `docker compose` (recommended):
```
docker compose up -d --build
```

Using `docker run`:
```
docker run -d --name volume_backupper \
  -v $(pwd)/backups:/backups:rw \
  -v $(pwd)/data:/data:ro \
  -e PERIOD_CRON_SYNTAX="*/1 * * * *" \
  -e SKIP_ZIP_PATHS='["ignore_this","ignore_this2"]' \
  -e RETENTION=3 \
  dosisido/volume_backupper:latest
```

### Backup format
- Filenames follow the pattern `backup_YYYYMMDD_HHMMSS.zip` (for example `backup_20251123_143012.zip`).
- Each backup is a compressed archive of the `/data` tree, excluding paths listed in `SKIP_ZIP_PATHS`.


### Important notes
- Backups are not encrypted by default. If you store sensitive data, add encryption or push backups to a secure remote.
- `RETENTION` deletes old backups by keeping only the newest N files (count-based), not by age.


### Contributing
Issues and pull requests are welcome. If you want a feature (e.g., S3 upload, encryption), open an issue describing the desired behavior.

