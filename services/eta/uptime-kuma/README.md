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
