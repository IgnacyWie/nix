# Stirling PDF Service Stack

Stirling PDF provides browser-based PDF tools for `eta`.

## Run

```sh
eta-service stirling-pdf config
eta-service stirling-pdf up
eta-service stirling-pdf logs --tail=100
```

## Route

- `https://pdf.mac.wie.dev`

The service is exposed through Traefik and is added to Homepage through Docker
labels. Homepage must have Docker discovery enabled in its runtime config.

## Durable Service State

- `~/Services/data/stirling-pdf/configs`
- `~/Services/data/stirling-pdf/custom-files`
- `~/Services/data/stirling-pdf/logs`
- `~/Services/data/stirling-pdf/pipeline`
- `~/Services/data/stirling-pdf/tessdata`

## Required Environment

Copy `.env.example` to `.env` on `eta` and keep it uncommitted. Required values:

- `STIRLING_PDF_HOST`
- `TRAEFIK_TLS_DOMAIN_MAIN`
- `TRAEFIK_TLS_DOMAIN_SANS`

Keep `STIRLING_PDF_SECURITY_ENABLE_LOGIN=true` unless access is otherwise
restricted by the Home Server Access Model.
