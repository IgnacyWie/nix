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
https://homeassistant.mac.wie.dev
```

The legacy alias remains accepted during migration:

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

## Automations

The source-controlled automation configuration is
[`automations.yaml`](./automations.yaml). The active Home Assistant instance
loads the deployed copy at `/config/automations.yaml`.

Current automations:

- **Bathroom Fan - Delay** — turns off the bathroom fan 20 minutes after it is
  switched on.
- **Wake up with music - Zeppelin** — at `input_datetime.wake_up_time`, plays
  *Guten Morgen Sonnenschein* on the Zeppelin when
  `input_boolean.wake_up_enabled` is on.
- **Stop wake-up music** — stops the Zeppelin from the dashboard stop button.
- **Bedroom - BILRESA bedside remote** — maps the IKEA `09B9` ZHA remote:
  - A single ON press from 06:00 through 22:59 retains the daytime behavior:
    the first press turns on Bed Lamp and LED Bed, and another press turns on
    Bedroom Accent.
  - A single ON press from 23:00 through 05:59 progressively turns on LED Bed,
    then Bed Lamp, then Bedroom Accent.
  - A single OFF press turns off all three bedroom lights.
  - A double ON press turns on all three bedroom lights.
  - A double OFF press performs the bedtime shutdown for enabled, visible
    household devices: all dashboard lights, the bathroom fan, Zeppelin
    playback, and the living-room TV. Hidden, disabled, diagnostic, and
    infrastructure entities are intentionally excluded.
  - When the configured wake-up alarm is playing, any mapped press stops the
    alarm without running its normal light or bedtime action.

## Home Assistant YAML Change Workflow

After changing an automation or any other Home Assistant YAML:

1. Update the source-controlled YAML and this README in the same change.
2. Back up the live file before deployment.
3. Copy the reviewed YAML to the corresponding path under `/config`.
4. Run `ha core check`; restore the backup if validation fails.
5. Reload the affected configuration or restart Home Assistant.
6. Verify the changed entity or automation is loaded and enabled.
7. Commit only the intended Home Assistant files and push the commit.

## Required Environment

```sh
cd ~/nix/services/eta/home-assistant
cp .env.example .env
chmod 600 .env
```

Required values are `HOME_ASSISTANT_HOST`, `HOME_ASSISTANT_LEGACY_HOST`, and
`TZ`. Secrets, long-lived access
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
8. Verify Traefik access at `https://homeassistant.mac.wie.dev`, login,
   automations, one representative integration,
   and Matter device visibility if Matter is in use.

Success means Home Assistant and Matter Server can recover configuration,
automations, and representative device state from declared durable paths.

## eta-cloud / Hetzner Notes

This stack is expected to run unchanged on `eta-cloud` after the repository and `~/Services` tree are restored from Backblaze B2 Restic.

Cloud host assumptions:

- Host: `nixosConfigurations.eta-cloud`
- Runtime: Docker Compose via `eta-service`
- Service definition: `/Users/ignacywielogorski/nix/services/eta/home-assistant`
- Durable state root: `/Users/ignacywielogorski/Services`
- Restic repository: `b2:eta-home-server-restic:eta`
- Initial storage posture: single NVMe filesystem, no disk mirror

Useful commands on the Hetzner server:

```sh
eta-service home-assistant config
eta-service home-assistant up -d
eta-service home-assistant ps
eta-service home-assistant logs --tail=100
```

For recovery, restore to a review directory first and only replace live paths once the restored files and stack-specific secrets are confirmed.
