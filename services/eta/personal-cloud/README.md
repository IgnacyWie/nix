# Personal Cloud Service Stack

Personal Cloud is the Copyparty-backed Tier 1 Service Stack for personal cloud
storage on the `eta` Home Server.

## Service Definition

```sh
eta-service inspect personal-cloud
eta-service personal-cloud config
eta-service personal-cloud up
eta-service personal-cloud logs --tail=100
```

The Compose project name is `personal-cloud`. It runs one `copyparty` container
and joins Traefik's `proxy-network` at:

```text
https://files.mac.wie.dev
```

Restore Vaultwarden first because Copyparty credentials and sharing notes live
there.

## Durable Service State

```text
~/Services/data/personal-cloud/config
~/Services/data/personal-cloud/storage
```

`config` contains Copyparty configuration and account state. `storage` contains
the personal cloud file tree. This stack has no separate database service; the
service files themselves are the restore contract, so no Logical Database Dump is
required.

## Required Environment

```sh
cd ~/nix/services/eta/personal-cloud
cp .env.example .env
chmod 600 .env
```

Required values are `PERSONAL_CLOUD_HOST` and `COPYPARTY_USER`. Recover
Copyparty account credentials from Vaultwarden. Never commit `.env`, account
passwords, share links, or private file exports.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/data/personal-cloud/config` and
  `~/Services/data/personal-cloud/storage` through the broad `~/Services` scope.
- `~/nix/services/eta/personal-cloud` for the Service Definition and notes.
- Shared recovery material: `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs.

No path under this stack should be excluded unless it is documented as generated
cache or temporary upload scratch space.

## Manual Restore Drill

1. Restore Vaultwarden and recover Copyparty credentials.
2. Restore to a review directory:

   ```sh
   mkdir -p ~/Restores/personal-cloud-drill
   restic restore latest \
     --target ~/Restores/personal-cloud-drill \
     --include /Users/ignacywielogorski/Services/data/personal-cloud
   ```

3. Stop the active stack only during a real restore:
   `eta-service personal-cloud down`.
4. Copy reviewed data to `~/Services/data/personal-cloud` and verify ownership
   for the Primary User.
5. Recreate `.env` from `.env.example` and Vaultwarden values.
6. Start with `eta-service personal-cloud up`.
7. Verify Traefik access, login, directory listing, upload of one test file, and
   download of one representative existing file.

Success means the Personal Cloud can be recovered from file-level durable state
without relying on anonymous volumes or container overlay data.
