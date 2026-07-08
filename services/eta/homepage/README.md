# Homepage Service Stack

Homepage contains the Homepage dashboard and Glance dashboard for `eta`.

Service stacks can add themselves to Homepage with Docker discovery labels such
as `homepage.group`, `homepage.name`, `homepage.icon`, and `homepage.href`.

## Run

```sh
eta-service homepage config
eta-service homepage up
eta-service homepage logs --tail=100
```

## Durable Service State

- `~/Services/data/homepage`
- `~/Services/data/glance/config`

## Required Environment

Copy `.env.example` to `.env` on `eta` and keep it uncommitted. Required values:

- `HOMEPAGE_HOST`
- `GLANCE_HOST`
- `HOMEPAGE_ALLOWED_HOSTS`
- `TRAEFIK_TLS_DOMAIN_MAIN`
- `TRAEFIK_TLS_DOMAIN_SANS`

## eta-cloud / Hetzner Notes

This stack is expected to run unchanged on `eta-cloud` after the repository and `~/Services` tree are restored from Backblaze B2 Restic.

Cloud host assumptions:

- Host: `nixosConfigurations.eta-cloud`
- Runtime: Docker Compose via `eta-service`
- Service definition: `/Users/ignacywielogorski/nix/services/eta/homepage`
- Durable state root: `/Users/ignacywielogorski/Services`
- Restic repository: `b2:eta-home-server-restic:eta`
- Initial storage posture: single NVMe filesystem, no disk mirror

Useful commands on the Hetzner server:

```sh
eta-service homepage config
eta-service homepage up -d
eta-service homepage ps
eta-service homepage logs --tail=100
```

For recovery, restore to a review directory first and only replace live paths once the restored files and stack-specific secrets are confirmed.
