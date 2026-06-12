# Home Assistant Service Stack

Home Assistant with Matter Server is a Tier 1 Service Stack for household
automation on the `eta` Home Server.

## Service Definition

```sh
eta-service inspect home-assistant
eta-service home-assistant config
eta-service home-assistant up
eta-service home-assistant logs --tail=100
```

The Compose project name is `home-assistant`. Expected containers are
`homeassistant`, `hass-proxy`, and `matter-server`. Home Assistant and Matter use
host networking for discovery, mDNS, IPv6, and device access. `hass-proxy` joins
`proxy-network` so Traefik can route:

```text
https://hass.mac.wie.dev
```

Restore Vaultwarden first for Home Assistant credentials and tokens.

## Durable Service State

```text
~/Services/data/home-assistant/config
~/Services/data/matter-server
~/Services/dumps/home-assistant/home-assistant_v2.db
```

The Home Assistant config directory contains YAML configuration, `.storage`,
integrations, automations, and the default SQLite state database. Matter Server
state lives in `~/Services/data/matter-server`. `eta-restic-backup` creates an
online SQLite backup artifact for `home-assistant_v2.db` when it exists.

## Required Environment

```sh
cd ~/nix/services/eta/home-assistant
cp .env.example .env
chmod 600 .env
```

Required values are `HOME_ASSISTANT_HOST` and `TZ`. Secrets, long-lived access
tokens, integration credentials, and recovery codes are recovered from
Vaultwarden or the Home Assistant config backup. Never commit `.env`, tokens, or
Home Assistant exports containing private household data.

## Backup Scope

The Home Server Backup Repository includes:

- `~/Services/data/home-assistant` and `~/Services/data/matter-server`.
- `~/Services/dumps/home-assistant/home-assistant_v2.db` as the SQLite artifact.
- `~/nix/services/eta/home-assistant` for the Service Definition and notes.
- Shared recovery material: `backup.md`, `manual-steps.md`, `CONTEXT.md`, and ADRs.

## Manual Restore Drill

1. Restore Vaultwarden and recover Home Assistant credentials.
2. Restore data and dumps to a review directory:

   ```sh
   mkdir -p ~/Restores/home-assistant-drill
   restic restore latest \
     --target ~/Restores/home-assistant-drill \
     --include /Users/ignacywielogorski/Services/data/home-assistant \
     --include /Users/ignacywielogorski/Services/data/matter-server \
     --include /Users/ignacywielogorski/Services/dumps/home-assistant
   ```

3. Stop the active stack only during a real restore:
   `eta-service home-assistant down`.
4. Copy reviewed data to `~/Services/data/home-assistant` and
   `~/Services/data/matter-server`; verify ownership.
5. If the live SQLite database is missing or suspect, copy the dump artifact to
   `config/home-assistant_v2.db` before startup.
6. Recreate `.env` from `.env.example` and Vaultwarden values.
7. Start with `eta-service home-assistant up`.
8. Verify Traefik access, login, automations, one representative integration,
   and Matter device visibility if Matter is in use.

Success means Home Assistant and Matter Server can recover configuration,
automations, and representative device state from declared durable paths.
