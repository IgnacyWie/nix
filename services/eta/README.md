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

