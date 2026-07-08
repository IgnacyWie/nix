# Uptime Kuma Service Stack

Uptime Kuma provides service uptime monitoring for `eta`.

## Run

```sh
eta-service uptime-kuma config
eta-service uptime-kuma up
eta-service uptime-kuma logs --tail=100
```

## Durable Service State

- `~/Services/data/uptime-kuma`

## Required Environment

Copy `.env.example` to `.env` on `eta` and keep it uncommitted. Required values:

- `UPTIME_KUMA_HOST`
- `TRAEFIK_TLS_DOMAIN_MAIN`
- `TRAEFIK_TLS_DOMAIN_SANS`

## eta-cloud / Hetzner Notes

This stack is expected to run unchanged on `eta-cloud` after the repository and `~/Services` tree are restored from Backblaze B2 Restic.

Cloud host assumptions:

- Host: `nixosConfigurations.eta-cloud`
- Runtime: Docker Compose via `eta-service`
- Service definition: `/Users/ignacywielogorski/nix/services/eta/uptime-kuma`
- Durable state root: `/Users/ignacywielogorski/Services`
- Restic repository: `b2:eta-home-server-restic:eta`
- Initial storage posture: single NVMe filesystem, no disk mirror

Useful commands on the Hetzner server:

```sh
eta-service uptime-kuma config
eta-service uptime-kuma up -d
eta-service uptime-kuma ps
eta-service uptime-kuma logs --tail=100
```

For recovery, restore to a review directory first and only replace live paths once the restored files and stack-specific secrets are confirmed.
