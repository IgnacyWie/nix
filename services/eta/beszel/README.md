# Beszel Service Stack

Beszel is an `eta` monitoring dashboard.

## Run

```sh
eta-service beszel config
eta-service beszel up
eta-service beszel logs --tail=100
```

## Durable Service State

- `~/Services/data/beszel/data`
- `~/Services/data/beszel/socket`

## Required Environment

Copy `.env.example` to `.env` on `eta` and keep it uncommitted. Required values:

- `BESZEL_HOST`
- `TRAEFIK_TLS_DOMAIN_MAIN`
- `TRAEFIK_TLS_DOMAIN_SANS`

## eta-cloud / Hetzner Notes

This stack is expected to run unchanged on `eta-cloud` after the repository and `~/Services` tree are restored from Backblaze B2 Restic.

Cloud host assumptions:

- Host: `nixosConfigurations.eta-cloud`
- Runtime: Docker Compose via `eta-service`
- Service definition: `/Users/ignacywielogorski/nix/services/eta/beszel`
- Durable state root: `/Users/ignacywielogorski/Services`
- Restic repository: `b2:eta-home-server-restic:eta`
- Initial storage posture: single NVMe filesystem, no disk mirror

Useful commands on the Hetzner server:

```sh
eta-service beszel config
eta-service beszel up -d
eta-service beszel ps
eta-service beszel logs --tail=100
```

For recovery, restore to a review directory first and only replace live paths once the restored files and stack-specific secrets are confirmed.
