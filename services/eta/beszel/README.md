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
