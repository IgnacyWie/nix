# Dawarich Service Stack

Dawarich is a Tier 1 Service Stack for location history on the `eta` Home Server.
This migration replaces Docker named volumes with explicit Service Data Root bind
mounts and adds a Postgres Logical Database Dump.

## Service Definition

```sh
eta-service inspect dawarich
eta-service dawarich config
eta-service dawarich up
eta-service dawarich logs --tail=100
```

The Compose project name is `dawarich`. Expected containers are `redis`,
`database`, `app`, and `sidekiq`. The web app joins Traefik's `proxy-network` at:

```text
https://map.mac.wie.dev
```

Restore Vaultwarden first because Dawarich database and Rails secrets live there.

## Durable Service State

```text
~/Services/data/dawarich/postgres
~/Services/data/dawarich/shared
~/Services/data/dawarich/public
~/Services/data/dawarich/watched
~/Services/data/dawarich/storage
~/Services/data/dawarich/redis
~/Services/dumps/dawarich/dawarich.dump
```

`postgres` is the raw Postgres data directory. `storage`, `public`, `watched`,
and `shared` contain application uploads/imports and generated user data. Redis
state is not the primary restore source. `eta-restic-backup` creates the
Postgres Logical Database Dump at `~/Services/dumps/dawarich/dawarich.dump` when
the database container is running.

## Required Environment

```sh
cd ~/nix/services/eta/dawarich
cp .env.example .env
chmod 600 .env
```

Required secret values include `POSTGRES_PASSWORD` and `SECRET_KEY_BASE` from
Vaultwarden. Other required values define `DAWARICH_HOST`, database name/user,
Rails environment, application hosts, protocol, time zone, and background worker
settings. Never commit `.env`, database credentials, Rails secrets, exports, or
raw location data.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/data/dawarich` through the broad `~/Services` backup scope.
- `~/Services/dumps/dawarich/dawarich.dump` as the online Postgres artifact.
- `~/nix/services/eta/dawarich` for the Service Definition and restore notes.
- Shared recovery material: `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs.

## Manual Restore Drill

1. Restore Vaultwarden and recover Dawarich secrets.
2. Restore to a review directory:

   ```sh
   mkdir -p ~/Restores/dawarich-drill
   restic restore latest \
     --target ~/Restores/dawarich-drill \
     --include /Users/ignacywielogorski/Services/data/dawarich \
     --include /Users/ignacywielogorski/Services/dumps/dawarich
   ```

3. Stop the active stack only during a real restore: `eta-service dawarich down`.
4. Copy reviewed data to `~/Services/data/dawarich` and verify ownership.
5. If the raw Postgres directory is missing or suspect, initialize the database
   service and restore `dawarich.dump` with `pg_restore` into the Dawarich
   database.
6. Recreate `.env` from `.env.example` and Vaultwarden values.
7. Start Dawarich with `eta-service dawarich up`.
8. Verify Traefik access, login, map rendering, and representative location
   points/trips.

Success means Dawarich can restore location history from declared data paths and
its database-native dump artifact.
