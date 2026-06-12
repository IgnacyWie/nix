# eta Docker and OrbStack Inventory Workflow

Use this workflow to mechanically inventory current Docker and OrbStack state on
`eta` before writing or finalizing Service Definitions. The inventory informs the
migration, but current live state is not automatically desired state.

Raw output can contain secrets, internal URLs, private paths, labels, and broken
or obsolete settings. Keep raw output local and commit only reviewed, sanitized
findings.

## 1. Collect raw local inventory

From this repository on a trusted machine that can reach the current Home Server
with `ssh eta`:

```sh
./scripts/collect-eta-docker-orbstack-inventory
```

The script writes to:

```text
.local/inventory/eta/docker-orbstack-<timestamp>/
```

Override the SSH alias or output directory when needed:

```sh
ETA_INVENTORY_HOST=eta \
ETA_INVENTORY_DIR=.local/inventory/eta/docker-orbstack-manual \
  ./scripts/collect-eta-docker-orbstack-inventory
```

The raw directory includes Docker/OrbStack host context, containers, mounts,
networks, volumes, Compose projects, labels, and environment-variable keys. Some
raw files may include full environment values or labels from `docker inspect`; do
not copy or commit them directly.

## 2. Review raw files locally

Use the raw inventory to answer migration questions:

- Which containers belong to each Service Stack?
- Which mounts map to durable state under the Service Data Root, `~/Services`?
- Which named volumes or anonymous volumes must be replaced with explicit paths?
- Which networks and labels are still needed once the stack uses the Ingress
  Layer and Tailscale access model?
- Which environment variables are required, and which must come from the Secret
  Store or Bootstrap Secret Set?
- Which settings are accidental runtime history and should be dropped?

Do not treat the current container list as the Migration Scope. The v1 Tier 1
Service Stacks are Vaultwarden, Immich, Paperless, Home Assistant with Matter
Server, Baikal, Linkding, and Personal Cloud. FreshRSS remains Tier 2 for v1.
Matrix, Synapse, Mautrix bridges, and the Arr media stack remain outside v1
unless a later issue changes scope.

## 3. Sanitize before commit

Copy only reviewed findings into `inventory/eta-docker-orbstack.md` or into a
specific `services/eta/<stack>/README.md` / `compose.yaml`.

Before committing, explicitly check for:

- secrets, tokens, passwords, API keys, auth headers, cookies, session IDs, and
  DSNs;
- internal URLs, hostnames, IP addresses, tailnet details, and private email
  addresses that do not need to be versioned;
- Docker labels, Traefik labels, and Compose labels that reveal private routing
  or obsolete topology;
- private absolute paths outside documented Service Data Root paths;
- environment values rather than environment-variable names;
- obsolete settings copied from broken or experimental containers;
- raw JSON, command output, or unreviewed exports.

If a setting is secret-bearing, document only the variable name and where it must
be recovered from. If a path is private but important, document its role and use a
sanitized path such as `~/Services/<stack>/...`.

## 4. Record migration decisions

Sanitized inventory should be written in migration language, not as a Docker dump.
For each in-scope stack, prefer:

- intended Service Stack name;
- current containers that appear related;
- desired durable data paths under `~/Services`;
- required logical database dumps or pre-backup artifacts;
- required networks, ingress, and ports after migration;
- required environment-variable names and secret source;
- review notes and open questions.

The final Service Definition is the source of truth. Inventory is supporting
evidence only.

## Linkding corrective migration

Linkding is a Corrective Migration. Its current broken volume layout does not
preserve bookmarks across restarts, so the migration must not preserve the live
layout just because it appears in Docker or OrbStack inventory.

When reviewing Linkding inventory, identify the failure mode, discard the broken
mount/volume shape, and design the Service Definition around durable service
state under `~/Services/linkding/...` plus a restore drill that proves bookmarks
survive container recreation.
