# Immich Service Stack

Immich is a Tier 1 Service Stack for photos and videos on the `eta` Home Server.
This migration is intended as a lift-and-shift into explicit Service Definition
and Service Data Root paths.

## Service Definition

Run this stack on `eta` through the Service Control Command:

```sh
eta-service inspect immich
eta-service immich config
eta-service immich up
eta-service immich logs --tail=100
```

The Compose project name is `immich`. Expected containers are
`immich-server`, `immich-machine-learning`, `redis`, and `database`. The browser
service joins the Traefik Ingress Layer network, `proxy-network`, at:

```text
https://photos.mac.wie.dev
```

The Immich router applies the `immich-upload-limit@docker` Traefik middleware.
The middleware allows request bodies up to 2 GB, while the Traefik stack sets
30-minute read/write/idle timeouts so large mobile video uploads do not hit the
default proxy timeout before Immich receives the full request.

Restore Vaultwarden first because Immich database credentials live there.

## Durable Service State

Immich Durable Service State lives under:

```text
~/Services/photos
~/Services/data/immich/postgres
~/Services/data/immich/model-cache
~/Services/dumps/immich/immich.dump
```

`~/Services/photos` contains uploaded originals, generated thumbnails, encoded
video, profile assets, and Immich marker files from the current service layout.
`postgres` contains the raw Postgres data directory. The primary
Logical Database Dump is `~/Services/dumps/immich/immich.dump`, created by
`eta-restic-backup` with `pg_dump` when the database container is running.
`model-cache` is reproducible machine-learning cache and may be excluded or
recreated if needed.

## Required Environment

```sh
cd ~/nix/services/eta/immich
cp .env.example .env
chmod 600 .env
```

Required values:

- `IMMICH_TRAEFIK_HOST` — Traefik host name; currently `photos.mac.wie.dev`.
  Do not use `IMMICH_HOST` for routing; Immich treats it as an application bind
  address.
- `IMMICH_UPLOAD_LOCATION` — existing Immich upload/library root; currently
  `/Users/ignacywielogorski/Services/photos`.
- `IMMICH_VERSION` — Immich image version track; currently `v3` for the
  latest stable major release.
- `TZ` — time zone.
- `DB_USERNAME`, `DB_DATABASE_NAME`, `DB_PASSWORD` — Postgres credentials from
  Vaultwarden.

Never commit `.env`, database credentials, API keys, or photo exports.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/photos` and `~/Services/data/immich` through the broad
  `~/Services` backup scope.
- `~/Services/dumps/immich/immich.dump` as the online Postgres restore artifact.
- `~/nix/services/eta/immich` for the Service Definition and restore notes.
- `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs as recovery material.

## Manual Restore Drill

1. Restore Vaultwarden and recover Immich secrets.
2. Restore Immich data and dumps to a review directory:

   ```sh
   mkdir -p ~/Restores/immich-drill
   restic restore latest \
     --target ~/Restores/immich-drill \
     --include /Users/ignacywielogorski/Services/photos \
     --include /Users/ignacywielogorski/Services/data/immich \
     --include /Users/ignacywielogorski/Services/dumps/immich
   ```

3. Stop the active stack only during a real restore: `eta-service immich down`.
4. Copy reviewed data to `~/Services/photos` and `~/Services/data/immich`, then
   verify ownership.
5. If the raw Postgres directory is missing or suspect, initialize the database
   service and restore `immich.dump` with `pg_restore` into the Immich database.
6. Recreate `.env` from `.env.example` and Vaultwarden values.
7. Start Immich with `eta-service immich up`.
8. Verify Traefik access, timeline loading, one representative photo, one video,
   one mobile upload larger than 250 MB, and mobile login if used.

Success means Immich can be recovered from the Home Server Backup Repository and
its Logical Database Dump, not merely from a raw Restic snapshot.
