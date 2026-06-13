# Homepage Service Stack

Homepage contains the Homepage dashboard and Glance dashboard for `eta`.

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
