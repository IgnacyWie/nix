# eta Service Definitions

This directory is the Service Definition Layout for the `eta` Home Server.
Each Service Stack lives under `services/eta/<stack>/` and owns one Docker
Compose project.

Expected stack shape:

```text
services/eta/<stack>/
  compose.yaml
  .env.example
  README.md
```

Compose files in this tree define container topology only. Durable service
state belongs under the `eta` Service Data Root, `~/Services`, and stack
restore notes should document the exact data paths used by that stack. New Tier
1 Service Stack migrations should follow the shared
[Tier 1 migration template](./tier-1-stack-template.md) so Service Definition,
backup coverage, logical dump artifacts, Ingress Layer assumptions, and restore
drills are captured consistently.

Service stacks are intentionally not started by launchd as a group. Start or
inspect a stack explicitly on `eta`:

```sh
eta-service list
eta-service inspect <stack>
eta-service <stack> config
eta-service <stack> up
eta-service <stack> down
```

`eta-service list` and `eta-service inspect <stack>` are no-Docker paths. They
only read this checkout and can be used before OrbStack, Docker, or live
containers are available.


## Current Stacks

- `vaultwarden` — Keystone Service. Durable Service State:
  `~/Services/data/vaultwarden`; v1 Keystone Data Store: SQLite.
- `linkding` — Tier 1 bookmark Service Stack. Durable Service State:
  `~/Services/data/linkding`; online SQLite restore artifact:
  `~/Services/dumps/linkding/linkding.sqlite3`.
- `immich` — Tier 1 photos and videos Service Stack. Durable Service State:
  `~/Services/data/immich`; online Postgres artifact:
  `~/Services/dumps/immich/immich.dump`.
- `paperless` — Tier 1 documents Service Stack. Durable Service State:
  `~/Services/data/paperless`; online SQLite artifact:
  `~/Services/dumps/paperless/paperless.sqlite3`.
- `home-assistant` — Tier 1 home automation Service Stack with Matter Server.
  Durable Service State: `~/Services/data/home-assistant` and
  `~/Services/data/matter-server`; online SQLite artifact:
  `~/Services/dumps/home-assistant/home-assistant_v2.db`.
- `baikal` — Tier 1 CalDAV/CardDAV Service Stack. Durable Service State:
  `~/Services/data/baikal`; online SQLite artifact:
  `~/Services/dumps/baikal/db.sqlite`.
- `personal-cloud` — Tier 1 Copyparty-backed Personal Cloud Service Stack.
  Durable Service State: `~/Services/data/personal-cloud`; no separate logical
  database dump is required.

