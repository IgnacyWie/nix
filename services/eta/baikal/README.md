# Baikal Service Stack

Baikal is a Tier 1 Service Stack for CalDAV/CardDAV calendar and contacts data
on the `eta` Home Server. This migration replaces the previous named `config`
volume with explicit bind mounts under the Service Data Root.

## Service Definition

```sh
eta-service inspect baikal
eta-service baikal config
eta-service baikal up
eta-service baikal logs --tail=100
```

The Compose project name is `baikal`. It runs one `baikal` container and joins
Traefik's `proxy-network` at:

```text
https://calendar.mac.wie.dev
```

Restore Vaultwarden first because Baikal admin and client credentials live there.

## Durable Service State

```text
~/Services/data/baikal/config
~/Services/data/baikal/specific
~/Services/dumps/baikal/db.sqlite
```

`config` contains Baikal configuration that was previously in a Docker named
volume. `specific` contains Baikal runtime data including the SQLite database.
`eta-restic-backup` creates an online SQLite artifact at
`~/Services/dumps/baikal/db.sqlite` when the database exists.

## Required Environment

```sh
cd ~/nix/services/eta/baikal
cp .env.example .env
chmod 600 .env
```

`BAIKAL_HOST` is required. Recover admin credentials and CalDAV/CardDAV client
passwords from Vaultwarden. Never commit `.env`, credentials, or calendar/contact
exports containing private data.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/data/baikal` through the broad `~/Services` backup scope.
- `~/Services/dumps/baikal/db.sqlite` as the online SQLite artifact.
- `~/nix/services/eta/baikal` for the Service Definition and restore notes.
- Shared recovery material: `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs.

## Manual Restore Drill

1. Restore Vaultwarden and recover Baikal credentials.
2. Restore to a review directory:

   ```sh
   mkdir -p ~/Restores/baikal-drill
   restic restore latest \
     --target ~/Restores/baikal-drill \
     --include /Users/ignacywielogorski/Services/data/baikal \
     --include /Users/ignacywielogorski/Services/dumps/baikal
   ```

3. Stop the active stack only during a real restore: `eta-service baikal down`.
4. Copy reviewed data to `~/Services/data/baikal` and verify ownership.
5. If the live SQLite database is missing or suspect, copy
   `~/Services/dumps/baikal/db.sqlite` back to the Baikal database path under
   `specific`.
6. Recreate `.env` from `.env.example` and Vaultwarden values.
7. Start Baikal with `eta-service baikal up`.
8. Verify Traefik access, admin login, one calendar event, and one contact from a
   CalDAV/CardDAV client.

Success means Baikal no longer depends on an unnamed Docker volume and can be
restored from declared Service Data Root paths plus the SQLite artifact.
