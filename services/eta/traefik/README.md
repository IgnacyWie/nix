# Traefik Service Stack

Traefik is the `eta` ingress layer. It owns the external `proxy-network` Docker network and routes service labels.

## Run

```sh
eta-service traefik config
eta-service traefik up
eta-service traefik logs --tail=100
```

## Durable Service State

- `~/Services/data/traefik/letsencrypt`
- `~/Services/data/traefik/config/external_services.yml`

## Required Environment

Copy `.env.example` to `.env` on `eta` and keep it uncommitted. Required values:

- `TRAEFIK_DASHBOARD_HOST`
- `TRAEFIK_ACME_EMAIL`
- `TRAEFIK_TLS_DOMAIN_MAIN`
- `TRAEFIK_TLS_DOMAIN_SANS`
- `TRAEFIK_UPLOAD_READ_TIMEOUT`, `TRAEFIK_UPLOAD_WRITE_TIMEOUT`, and
  `TRAEFIK_UPLOAD_IDLE_TIMEOUT` — long enough for large uploads through the
  Ingress Layer; default examples use `30m`.
- `CF_DNS_API_TOKEN` from the Cloudflare DNS bootstrap secret.

## eta-cloud / Hetzner Notes

This stack is expected to run unchanged on `eta-cloud` after the repository and `~/Services` tree are restored from Backblaze B2 Restic.

Cloud host assumptions:

- Host: `nixosConfigurations.eta-cloud`
- Runtime: Docker Compose via `eta-service`
- Service definition: `/Users/ignacywielogorski/nix/services/eta/traefik`
- Durable state root: `/Users/ignacywielogorski/Services`
- Restic repository: `b2:eta-home-server-restic:eta`
- Initial storage posture: single NVMe filesystem, no disk mirror

Useful commands on the Hetzner server:

```sh
eta-service traefik config
eta-service traefik up -d
eta-service traefik ps
eta-service traefik logs --tail=100
```

For recovery, restore to a review directory first and only replace live paths once the restored files and stack-specific secrets are confirmed.
Start Traefik before public HTTP(S) stacks because it owns the ingress network and routing labels.
