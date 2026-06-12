# Paperless Service Stack

Paperless is a Tier 1 Service Stack for household documents on the `eta` Home
Server. This is a corrective path-normalization migration from the old
`~/Services/documents/...` layout into the Service Data Root shape.

## Service Definition

```sh
eta-service inspect paperless
eta-service paperless config
eta-service paperless up
eta-service paperless logs --tail=100
```

The Compose project name is `paperless`. Expected containers are `webserver`,
`broker`, `gotenberg`, and `tika`. The web service joins `proxy-network` at:

```text
https://documents.mac.wie.dev
```

Restore Vaultwarden first because Paperless secrets live there.

## Durable Service State

```text
~/Services/data/paperless/data
~/Services/data/paperless/media
~/Services/data/paperless/export
~/Services/data/paperless/consume
~/Services/data/paperless/redis
~/Services/dumps/paperless/paperless.sqlite3
```

`data` contains Paperless application state including the default SQLite
database. `media` contains document originals and generated archives. `export`
and `consume` are user-visible workflow directories. Redis state is not the
primary restore source. `eta-restic-backup` creates the SQLite Logical Database
Dump at `~/Services/dumps/paperless/paperless.sqlite3` when the database exists.

## Required Environment

```sh
cd ~/nix/services/eta/paperless
cp .env.example .env
chmod 600 .env
```

Required values include `PAPERLESS_HOST`, `PAPERLESS_URL`, `USERMAP_UID`,
`USERMAP_GID`, `PAPERLESS_TIME_ZONE`, OCR language settings, and
`PAPERLESS_SECRET_KEY` from Vaultwarden. Never commit `.env`, secret keys, API
tokens, or document exports.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/data/paperless` through the broad `~/Services` backup scope.
- `~/Services/dumps/paperless/paperless.sqlite3` as the online SQLite artifact.
- `~/nix/services/eta/paperless` for the Service Definition and restore notes.
- Shared recovery material: `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs.

## Manual Restore Drill

1. Restore Vaultwarden and recover Paperless secrets.
2. Restore to a review directory:

   ```sh
   mkdir -p ~/Restores/paperless-drill
   restic restore latest \
     --target ~/Restores/paperless-drill \
     --include /Users/ignacywielogorski/Services/data/paperless \
     --include /Users/ignacywielogorski/Services/dumps/paperless
   ```

3. Stop the active stack only during a real restore: `eta-service paperless down`.
4. Copy reviewed data to `~/Services/data/paperless` and verify ownership.
5. If `data/db.sqlite3` is missing or suspect, copy the SQLite artifact from
   `~/Services/dumps/paperless/paperless.sqlite3` to `data/db.sqlite3`.
6. Recreate `.env` from `.env.example` and Vaultwarden values.
7. Start Paperless with `eta-service paperless up`.
8. Verify Traefik access, login, document search, one document original, and one
   generated archive or metadata view.

Success means Paperless documents and metadata can be restored from declared
Service Data Root paths plus the SQLite dump artifact.
