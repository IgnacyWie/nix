# Linkding Service Stack

Linkding is a Tier 1 Service Stack for bookmarks on the `eta` Home Server. This
is a Corrective Migration: the old `bookmarks` Compose stack mounted
`~/Services/data/linkding` to the wrong container path, so bookmarks were stored
inside container overlay state and did not satisfy the Home Server Recovery
Contract.

## Service Definition

Run this stack on `eta` through the Service Control Command:

```sh
eta-service inspect linkding
eta-service linkding config
eta-service linkding up
eta-service linkding logs --tail=100
```

The Compose project name is `linkding`. It joins the existing Traefik Ingress
Layer network, `proxy-network`, and preserves the existing bookmark domain:

```text
https://bookmarks.mac.wie.dev
```

## Durable Service State

Linkding Durable Service State lives under the Service Data Root:

```text
~/Services/data/linkding
```

The service data bind mount must target `/etc/linkding/data` exactly. Do not
recreate the old mount path with the trailing quote.

Linkding uses SQLite in this directory. `eta-restic-backup` also creates an
online SQLite backup artifact when the database exists:

```text
~/Services/dumps/linkding/linkding.sqlite3
```

## Required Environment

Copy the committed example and fill secret values on `eta` after Vaultwarden is
restored:

```sh
cd ~/nix/services/eta/linkding
cp .env.example .env
chmod 600 .env
```

Required values:

- `LINKDING_HOST` — Traefik host name; currently `bookmarks.mac.wie.dev`.
- `LINKDING_CSRF_TRUSTED_ORIGINS` — trusted HTTPS origin for the same domain.
- `LINKDING_SUPERUSER_NAME` — bootstrap admin username.
- `LINKDING_SUPERUSER_PASSWORD` — bootstrap admin password from Vaultwarden.

Optional values with safe defaults:

- `LINKDING_DISABLE_BACKGROUND_TASKS=False`

Never commit `.env`, Linkding credentials, API tokens, or exported bookmark
data that may contain private URLs.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/data/linkding` through the broad `~/Services` backup scope.
- `~/Services/dumps/linkding/linkding.sqlite3` as the online SQLite restore
  artifact created by `eta-restic-backup`.
- `~/nix/services/eta/linkding` for the Service Definition and restore notes.
- `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs as recovery material.

## Manual Persistence Drill

1. Ensure `.env` exists from `.env.example` and Vaultwarden values.
2. Start Linkding:

   ```sh
   eta-service linkding up
   ```

3. Open `https://bookmarks.mac.wie.dev` through the Ingress Layer.
4. Create or import one test bookmark.
5. Restart the Service Stack:

   ```sh
   eta-service linkding restart
   ```

6. Reopen Linkding and verify the bookmark still exists.
7. Confirm the database exists under the Service Data Root:

   ```sh
   ls -lh ~/Services/data/linkding/db.sqlite3
   ```

Success means Linkding no longer depends on container overlay state for
bookmarks.

## Manual Restore Drill

Run this after Vaultwarden has been restored, because Linkding credentials live
there rather than in the Bootstrap Secret Set.

1. Restore Linkding data to a review directory first:

   ```sh
   mkdir -p ~/Restores/linkding-drill
   restic restore latest \
     --target ~/Restores/linkding-drill \
     --include /Users/ignacywielogorski/Services/data/linkding \
     --include /Users/ignacywielogorski/Services/dumps/linkding/linkding.sqlite3
   ```

2. Stop the active stack only during a real restore, not during a review drill:

   ```sh
   eta-service linkding down
   ```

3. For a real restore, copy the reviewed data directory back to:
   `~/Services/data/linkding` and verify ownership for the primary user.
4. If the raw SQLite file is missing or suspect, recover from the dump artifact:

   ```sh
   mkdir -p ~/Services/data/linkding
   cp ~/Restores/linkding-drill/Users/ignacywielogorski/Services/dumps/linkding/linkding.sqlite3 \
     ~/Services/data/linkding/db.sqlite3
   ```

5. Recreate `~/nix/services/eta/linkding/.env` from `.env.example` and
   Vaultwarden values.
6. Start Linkding:

   ```sh
   eta-service linkding up
   ```

7. Verify health through Traefik and confirm representative bookmarks are
   present.

Success means Linkding can be recovered from the Home Server Backup Repository
after the Keystone Service has restored service secrets.
