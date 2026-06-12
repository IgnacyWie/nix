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

## v1 Migration Scope

Migration Scope is the intentionally migrated subset of Home Server services; it
is not the same thing as the current running Docker or OrbStack container list.
Current runtime inventory is supporting evidence only, and existing containers
must not be copied into this tree just because they are running on `eta`.

The v1 Tier 1 Service Stacks are:

- `vaultwarden` — Keystone Service.
- `immich` — photos and videos.
- `paperless` — documents.
- `home-assistant` — home automation, including Matter Server.
- `baikal` — CalDAV/CardDAV.
- `linkding` — bookmarks.
- `personal-cloud` — Copyparty-backed Personal Cloud.

FreshRSS is Tier 2 for v1. It may be inventoried and discussed, but it is not a
v1 Tier 1 migration blocker and should not receive Tier 1 restore-drill or
backup-gating requirements unless a later issue changes the scope.

Explicitly out of scope for v1 migration work:

- Matrix.
- Synapse.
- Mautrix bridges.
- The Arr media stack, including Radarr, Sonarr, Lidarr, Readarr, Bazarr,
  Prowlarr, and related media automation services.

Do not add Service Definitions for those out-of-scope stacks under
`services/eta/` during v1. If a future issue changes this decision, update this
scope section and the repository checks in the same change.

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

