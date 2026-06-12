# Tier 1 Service Stack Migration Template

Use this template when migrating a Tier 1 Service Stack into the `eta` Home
Server Recovery Contract. The goal is not just to run the container; migration
is complete only when the Service Definition, Durable Service State, backup
coverage, and restore drill are all declared.

Create one stack directory under the Service Definition Layout:

```text
services/eta/<stack>/
  compose.yaml
  .env.example
  README.md
```

Replace `<stack>` with the Compose project name. Keep service-specific details
inside that stack directory and avoid changing shared backup or recovery
contracts unless the stack needs new reusable machinery.

## 1. Service Definition

The stack README should define:

- The Service Stack name and why it is Tier 1.
- Whether it is a lift-and-shift migration or a Corrective Migration.
- The Service Control Commands used to inspect, start, stop, and view logs:

  ```sh
  eta-service inspect <stack>
  eta-service <stack> config
  eta-service <stack> up
  eta-service <stack> logs --tail=100
  ```

- The Compose project name, expected containers, and any required external
  networks.
- Any ordering dependency, especially whether Vaultwarden must be restored first
  to recover this stack's secrets.

The stack `compose.yaml` should:

- Declare durable bind mounts explicitly rather than relying on anonymous
  volumes or container overlay state.
- Use paths under the `eta` Service Data Root, `~/Services`.
- Reference environment values from `.env` with a committed `.env.example`.
- Join the Traefik Ingress Layer network, `proxy-network`, when the service is
  browser-facing and compatible with the Ingress Layer.
- Avoid public internet exposure; migrated browser-facing services are expected
  to be reached through the Tailscale-only Home Server Access Model unless a
  future ADR changes that policy.

## 2. Durable Service State

The stack README must list every durable path and what it contains.

Use this default path shape unless the service has a documented reason not to:

```text
~/Services/data/<stack>
~/Services/dumps/<stack>
```

Document each path as one of:

- Durable Service State required for normal restore.
- Logical Database Dump or equivalent pre-backup artifact.
- Disposable cache, scratch, generated media, or logs that may be excluded.

If a container requires more than one durable mount, list each host path and the
exact in-container path. The README should make it possible to audit that no
Tier 1 data is left in anonymous Docker volumes or container overlay state.

## 3. Required Environment

Commit a `.env.example` with every required variable and safe defaults for
non-secret options. The stack README should include:

```sh
cd ~/nix/services/eta/<stack>
cp .env.example .env
chmod 600 .env
```

Then list:

- Required host names and URLs.
- Required secrets and where they are recovered from: Bootstrap Secret Set,
  Vaultwarden, macOS Keychain, or another documented Secret Store.
- Optional variables with safe defaults.
- Values that must never be committed.

Do not commit `.env`, tokens, passwords, private keys, exports containing
private user data, or generated secrets.

## 4. Backup Coverage

The stack README must state that the Home Server Backup Repository includes:

- `~/Services/data/<stack>` through the broad `~/Services` backup scope.
- `~/Services/dumps/<stack>` when the stack has pre-backup artifacts.
- `~/nix/services/eta/<stack>` for the Service Definition, env example, and
  restore notes.
- Shared recovery material: `backup.md`, `manual-steps.md`, `CONTEXT.md`, and
  ADRs.

If any path under the stack is intentionally excluded by
`eta-backup-excludes.txt`, document why it is reproducible or disposable.
Tier 1 data should not be excluded unless there is a documented equivalent
restore artifact.

## 5. Logical Database Dumps Or Equivalent Artifacts

Database-backed stacks must define a database-native restore artifact, not only
raw database directory backup. This is required for online backups.

For each database or state engine, document:

- The database type: SQLite, Postgres, MariaDB, application export, or other.
- The source path or connection details needed by the backup job.
- The artifact path under `~/Services/dumps/<stack>/`.
- The command or automation that creates the artifact before Restic runs.
- How the artifact is used during restore if raw state is missing, corrupt, or
  inconsistent.

If a stack has no database, the README should say so explicitly and explain why
no Logical Database Dump is required. If the application has a built-in export
that is the safer restore contract, document that as the equivalent artifact.

## 6. Ingress And Access Model

For browser-facing services, document:

- The Traefik host name and URL.
- The expected Traefik network, usually `proxy-network`.
- Any Traefik labels required by the Compose file.
- Whether the service must be verified through the Ingress Layer after restore.

Migrated v1 Home Server services should assume Tailscale-only access and should
not add public exposure. If a service cannot use Traefik or needs a non-HTTP
protocol, document the exception and the verification path.

## 7. Restore Drill

Every Tier 1 stack README must include a manual restore drill. The drill should
restore into a review directory first and only overwrite live state during a
real restore.

Use this shape:

1. Restore prerequisite services first, especially Vaultwarden when this stack's
   credentials live there.
2. Recover Restic credentials for `eta Restic Backblaze B2` into macOS Keychain.
3. Restore stack data and dump artifacts into `~/Restores/<stack>-drill`:

   ```sh
   mkdir -p ~/Restores/<stack>-drill
   restic restore latest \
     --target ~/Restores/<stack>-drill \
     --include /Users/ignacywielogorski/Services/data/<stack> \
     --include /Users/ignacywielogorski/Services/dumps/<stack>
   ```

4. Stop the active stack only for a real restore:

   ```sh
   eta-service <stack> down
   ```

5. Copy reviewed data back to the documented Service Data Root paths and verify
   ownership for the Primary User.
6. If needed, recover from the Logical Database Dump or equivalent artifact.
7. Recreate `.env` from `.env.example` and the documented Secret Store.
8. Start the stack:

   ```sh
   eta-service <stack> up
   ```

9. Verify health through Traefik or the documented non-HTTP access path.
10. Verify representative user data, not just container health.
11. Record a success condition that proves the Home Server Recovery Contract for
    this stack.

## 8. Migration Checklist

Use this checklist before closing a Tier 1 stack migration issue:

- [ ] `services/eta/<stack>/compose.yaml` exists and declares durable mounts.
- [ ] `services/eta/<stack>/.env.example` exists and contains no secrets.
- [ ] `services/eta/<stack>/README.md` documents Service Definition and control
      commands.
- [ ] Durable Service State paths under `~/Services` are documented.
- [ ] Backup coverage and any intentional exclusions are documented.
- [ ] Database-backed stacks define Logical Database Dumps or equivalent
      pre-backup artifacts.
- [ ] Traefik Ingress Layer and Tailscale-only access assumptions are documented
      where applicable.
- [ ] A manual restore drill exists and restores to a review directory first.
- [ ] The drill verifies representative user data after startup.
- [ ] Service-specific choices are kept out of this shared template unless they
      are promoted into the shared Home Server Recovery Contract.
