# Vaultwarden Service Stack

Vaultwarden is the v1 Keystone Service for the `eta` Home Server. Restore it
before services whose credentials are stored inside Vaultwarden.

## Service Definition

Run this stack on `eta` through the Service Control Command:

```sh
eta-service inspect vaultwarden
eta-service vaultwarden config
eta-service vaultwarden up
eta-service vaultwarden logs --tail=100
```

The Compose project name is `vaultwarden`. It joins the existing Traefik
Ingress Layer network, `proxy-network`.

## Durable Service State

Vaultwarden Durable Service State lives under the Service Data Root:

```text
~/Services/data/vaultwarden
```

This directory is the v1 SQLite Keystone Data Store. It contains
`db.sqlite3`, attachments, sends, icon cache, RSA keys, and related
Vaultwarden runtime state. Do not migrate Vaultwarden to Postgres in v1.

## Required Environment

Copy the committed example and fill values on `eta`:

```sh
cd ~/nix/services/eta/vaultwarden
cp .env.example .env
chmod 600 .env
```

Required values:

- `VAULTWARDEN_DOMAIN` — public URL clients use for this service.
- `VAULTWARDEN_HOST` — host name matched by Traefik.
- `ADMIN_TOKEN` — admin interface token from the Bootstrap Secret Set.

Optional values with safe defaults:

- `VAULTWARDEN_SIGNUPS_ALLOWED=false`
- `VAULTWARDEN_WEBSOCKET_ENABLED=true`

Never commit `.env`, admin tokens, SMTP credentials, or Vaultwarden exports.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/data/vaultwarden` through the broad `~/Services` backup scope.
- `~/nix/services/eta/vaultwarden` for the Service Definition and restore notes.
- `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs as recovery material.

## Manual Restore Drill

1. Recover the Bootstrap Secret Set from iCloud Keychain or the offline
   emergency copy.
2. Recover Restic credentials for `eta Restic Backblaze B2` into macOS
   Keychain.
3. Restore Vaultwarden data to a review directory first:

   ```sh
   mkdir -p ~/Restores/vaultwarden-drill
   restic restore latest \
     --target ~/Restores/vaultwarden-drill \
     --include /Users/ignacywielogorski/Services/data/vaultwarden
   ```

4. Stop the active stack only during a real restore, not during a review drill:

   ```sh
   eta-service vaultwarden down
   ```

5. For a real restore, copy the restored directory back to:
   `~/Services/data/vaultwarden` and verify ownership for the primary user.
6. Recreate `~/nix/services/eta/vaultwarden/.env` from `.env.example` and the
   Bootstrap Secret Set.
7. Start Vaultwarden first:

   ```sh
   eta-service vaultwarden up
   ```

8. Verify the service is healthy through Traefik and by checking logs.
9. Log in with a known Vaultwarden account.
10. Verify representative vault contents: one login item, one secure note, and
    one attachment if attachments are in use.
11. Only after Vaultwarden is verified, recover credentials for other service
    stacks.

Success means the Keystone Service can be restored from the Home Server Backup
Repository and Bootstrap Secret Set without relying on an existing `eta` host or
Postgres.

## eta-cloud / Hetzner Notes

This stack is expected to run unchanged on `eta-cloud` after the repository and `~/Services` tree are restored from Backblaze B2 Restic.

Cloud host assumptions:

- Host: `nixosConfigurations.eta-cloud`
- Runtime: Docker Compose via `eta-service`
- Service definition: `/Users/ignacywielogorski/nix/services/eta/vaultwarden`
- Durable state root: `/Users/ignacywielogorski/Services`
- Restic repository: `b2:eta-home-server-restic:eta`
- Initial storage posture: single NVMe filesystem, no disk mirror

Useful commands on the Hetzner server:

```sh
eta-service vaultwarden config
eta-service vaultwarden up -d
eta-service vaultwarden ps
eta-service vaultwarden logs --tail=100
```

For recovery, restore to a review directory first and only replace live paths once the restored files and stack-specific secrets are confirmed.
Vaultwarden should be restored before other stacks because it holds most runtime credentials and `.env` values.
