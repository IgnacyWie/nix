# Probo Service Stack

Probo is a self-hosted GRC and compliance application for the `eta` Home Server.
This stack follows the official single-host Docker Compose model: Probo,
PostgreSQL, SeaweedFS object storage, and headless Chrome.

## Service Definition

Run this stack on `eta` through the Service Control Command:

```sh
eta-service inspect probo
eta-service probo config
eta-service probo up
eta-service probo logs --tail=100
```

The Compose project name is `probo`. Expected containers are `probo`,
`probo_postgres`, `probo_seaweedfs`, and `probo_chrome`. Only the Probo web
service joins the Traefik Ingress Layer network, `proxy-network`, at:

```text
https://probo.mac.wie.dev
```

Restore Vaultwarden first if Probo secrets are stored there. If Vaultwarden is
unavailable, recover the first-start secrets from the Bootstrap Secret Set or
another documented secret store before starting this stack.

## Durable Service State

Probo Durable Service State lives under:

```text
~/Services/data/probo/probo
~/Services/data/probo/postgres
~/Services/data/probo/seaweedfs
~/Services/dumps/probo/probod.dump
```

`probo/probo` contains local Probo application data. `postgres` contains the raw
PostgreSQL data directory. `seaweedfs` contains object storage data for uploaded
files and generated artifacts. The primary Logical Database Dump is
`~/Services/dumps/probo/probod.dump`, created by `eta-restic-backup` with
`pg_dump` when the Postgres container is running.

PostgreSQL and SeaweedFS must be backed up as one recovery point. A database
dump without matching objects can restore records whose files are missing.

## Required Environment

```sh
cd ~/nix/services/eta/probo
cp .env.example .env
chmod 600 .env
```

Required values:

- `PROBO_TRAEFIK_HOST` and `PROBOD_BASE_URL` — Traefik hostname and canonical
  Probo URL.
- `PROBOD_ENCRYPTION_KEY`, `PROBOD_AUTH_COOKIE_SECRET`,
  `PROBOD_AUTH_PASSWORD_PEPPER`, and `PROBOD_TRUST_AUTH_TOKEN_SECRET` — stable
  random secrets generated before first start.
- `PROBOD_OAUTH2_SERVER_SIGNING_KEY` — RSA private key used for OAuth token
  signing. Store it in `.env` as a quoted value with escaped newlines.
- `PROBOD_PG_ROOT_PASSWORD` and `PROBOD_PG_PASSWORD` — PostgreSQL credentials.
- `PROBOD_OPENAI_API_KEY` or `PROBOD_ANTHROPIC_API_KEY` — LLM provider
  credentials. Current Probo images default the Probo agent provider to
  `openai`; without a matching provider key, startup can fail with
  `unknown LLM provider "openai" for probo agent`.
- `PROBOD_SMTP_*` and `PROBOD_MAILER_SENDER_EMAIL` — SMTP relay settings for
  outbound mail.

Generate first-start secrets with:

```sh
openssl rand -base64 32
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048
```

Preserve the generated values. Replacing encryption, signing, or authentication
secrets after users and data exist can invalidate sessions or make stored data
inaccessible.

Never commit `.env`, database credentials, SMTP credentials, generated secrets,
OAuth private keys, or Probo data exports.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/data/probo` through the broad `~/Services` backup scope.
- `~/Services/dumps/probo/probod.dump` as the online Postgres restore artifact.
- `~/nix/services/eta/probo` for the Service Definition, env example, and
  restore notes.
- `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs as recovery material.

No Probo Tier 1 data path is intentionally excluded by
`eta-backup-excludes.txt`. Runtime logs, temporary directories, and generic
caches under `~/Services` remain excluded by the shared backup rules.

## Manual Restore Drill

1. Restore Vaultwarden or the Bootstrap Secret Set and recover Probo secrets.
2. Restore Probo data and dumps to a review directory:

   ```sh
   mkdir -p ~/Restores/probo-drill
   restic restore latest \
     --target ~/Restores/probo-drill \
     --include /Users/ignacywielogorski/Services/data/probo \
     --include /Users/ignacywielogorski/Services/dumps/probo
   ```

3. Stop the active stack only during a real restore: `eta-service probo down`.
4. Copy reviewed data to `~/Services/data/probo` and
   `~/Services/dumps/probo`, then verify ownership.
5. If the raw Postgres directory is missing or suspect, initialize the database
   service and restore `probod.dump` with `pg_restore` into the Probo database.
6. Recreate `.env` from `.env.example` and recovered secret values.
7. Start Traefik first if needed, then start Probo with `eta-service probo up`.
8. Verify Traefik access, sign-in, one compliance record, one file upload, PDF
   generation, and outbound email delivery.

Success means Probo can be recovered from the Home Server Backup Repository,
its Logical Database Dump, and its matching SeaweedFS object data.

## eta-cloud / Hetzner Notes

This stack is expected to run unchanged on `eta-cloud` after the repository and
`~/Services` tree are restored from Backblaze B2 Restic.

Cloud host assumptions:

- Host: `nixosConfigurations.eta-cloud`
- Runtime: Docker Compose via `eta-service`
- Service definition: `/Users/ignacywielogorski/nix/services/eta/probo`
- Durable state root: `/Users/ignacywielogorski/Services`
- Restic repository: `b2:eta-home-server-restic:eta`
- Initial storage posture: single NVMe filesystem, no disk mirror

Useful commands on the Hetzner server:

```sh
eta-service probo config
eta-service probo up -d
eta-service probo ps
eta-service probo logs --tail=100
```

For recovery, restore to a review directory first and only replace live paths
once the restored files and stack-specific secrets are confirmed.
