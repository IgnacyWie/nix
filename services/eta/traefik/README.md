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
