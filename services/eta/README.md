# eta Service Definitions

This directory is the Service Definition Layout for the `eta` Home Server.
Each Service Stack lives under `services/eta/<stack>/` and owns one Docker
Compose project.

Expected stack shape:

```text
services/eta/<stack>/
  compose.yaml
  README.md
```

Compose files in this tree define container topology only. Durable service
state belongs under the `eta` Service Data Root, `~/Services`, and stack
restore notes should document the exact data paths used by that stack.

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

