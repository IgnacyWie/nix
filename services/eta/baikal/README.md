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

## One-Time Migration Notes

The legacy `calendar` Compose stack stored Baikal state in two places:

```text
calendar_config Docker volume -> /var/www/baikal/config
~/Services/data/baikal     -> /var/www/baikal/Specific
```

If Baikal shows the initialization wizard after migration, the declared bind
mounts are missing one or both of those legacy locations. Stop Baikal and copy
legacy state into the normalized layout:

```sh
eta-service baikal down
mkdir -p ~/Services/data/baikal/config ~/Services/data/baikal/specific

docker run --rm \
  -v calendar_config:/from \
  -v "$HOME/Services/data/baikal/config:/to" \
  alpine sh -c 'cd /from && tar cf - . | tar xf - -C /to'

rsync -a --exclude config --exclude specific \
  ~/Services/data/baikal/ \
  ~/Services/data/baikal/specific/

eta-service baikal up
```

After the copy, `~/Services/data/baikal/config/baikal.yaml` and
`~/Services/data/baikal/specific/db/db.sqlite` must both exist, and
`https://calendar.mac.wie.dev/admin/` should show the admin login rather than the
initialization wizard.

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

## eta-cloud / Hetzner Notes

This stack is expected to run unchanged on `eta-cloud` after the repository and `~/Services` tree are restored from Backblaze B2 Restic.

Cloud host assumptions:

- Host: `nixosConfigurations.eta-cloud`
- Runtime: Docker Compose via `eta-service`
- Service definition: `/Users/ignacywielogorski/nix/services/eta/baikal`
- Durable state root: `/Users/ignacywielogorski/Services`
- Restic repository: `b2:eta-home-server-restic:eta`
- Initial storage posture: single NVMe filesystem, no disk mirror

Useful commands on the Hetzner server:

```sh
eta-service baikal config
eta-service baikal up -d
eta-service baikal ps
eta-service baikal logs --tail=100
```

For recovery, restore to a review directory first and only replace live paths once the restored files and stack-specific secrets are confirmed.
