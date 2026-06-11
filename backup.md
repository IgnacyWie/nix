# Backup Contract

This document defines separate v1 Restic backup contracts for the `gamma`
Workstation and the `eta` Home Server.

Nix rebuilds tools, declarative configuration, and selected application or
service definitions. Restic protects data and recovery material that is not
safely represented in Nix. A working restore requires both layers.

## `gamma` Workstation Backup Repository

The `gamma` Workstation backup target is a Restic repository stored in Backblaze
B2. It is distinct from the `eta` Home Server Backup Repository.

Canonical repository shape:

```sh
b2:gamma-backup-restic:gamma
```

The B2 account id, B2 application key, and Restic password must stay outside
Git. Store the recoverable source of truth in Vaultwarden under an item named:

```text
gamma Restic Backblaze B2
```

At runtime, Restic credentials should be read from macOS Keychain. Use this
service-name pattern:

```text
restic-gamma-b2-account-id
restic-gamma-b2-account-key
restic-gamma-password
```

Expected runtime environment:

```sh
export RESTIC_REPOSITORY="b2:gamma-backup-restic:gamma"
export B2_ACCOUNT_ID="$(security find-generic-password -a "$USER" -s restic-gamma-b2-account-id -w)"
export B2_ACCOUNT_KEY="$(security find-generic-password -a "$USER" -s restic-gamma-b2-account-key -w)"
export RESTIC_PASSWORD="$(security find-generic-password -a "$USER" -s restic-gamma-password -w)"
```

Do not commit exported values, generated environment files, Restic passwords,
B2 keys, raw Keychain dumps, or Vaultwarden exports.

## Backup Scope

The v1 backup scope includes:

- `~/Documents`
- `~/Desktop`
- `~/Pictures`
- `~/Projects`
- `~/Developer`
- `~/Downloads`
- `~/typst`
- `~/nix`
- `~/.ssh`

Broad `~/Library` backup is excluded by default. Add specific application state
only after it is inventoried, documented, and checked for secret-bearing files.

Cloud-synced folders such as iCloud Drive, Dropbox, Google Drive, and similar
services are excluded unless they are explicitly inventoried as part of the
restore contract.

## Exclusions

Start with conservative exclusions for generated, cached, or heavyweight
content:

```text
**/.DS_Store
**/.Trash
**/node_modules
**/.next
**/dist
**/build
**/target
/Users/ignacywielogorski/Library
/Users/ignacywielogorski/Movies
/Users/ignacywielogorski/Music
/Users/ignacywielogorski/.config/karabiner/automatic_backups
```

Only exclude a directory from the backup if either it is reproducible from Git,
Nix, or package managers, or it is intentionally not part of the restore target.
Do not exclude project `.git` directories by default; local branches, stashes,
and unpushed work can be part of the recoverable workstation state.

## Schedule And Retention

The intended v1 cadence is one successful automatic backup per day.

The launchd agent starts at login, at 20:00, and every 6 hours as a catch-up
attempt. Scheduled runs skip when a successful backup marker is less than 20
hours old. This makes laptop sleep, temporary network loss, and Nix
configuration reloads less likely to leave the machine unprotected for a full
day.

Each managed run retries the backup up to 3 times with a 5 minute delay between
attempts. Retention is retried up to 2 times after a successful backup. A
process killed by shutdown, sleep, or launchd unload cannot continue retrying
inside that same process, so the catch-up launchd interval is the recovery path.

The intended retention policy is:

```sh
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
```

Retention runs after a successful managed backup.

## `eta` Home Server Backup Repository

The `eta` Home Server Backup Repository is a separate Restic repository stored
in Backblaze B2. It protects the Service Data Root and Home Server recovery
material for v1; it does not replace the `gamma` Workstation backup contract.

Canonical repository shape:

```sh
b2:eta-home-server-restic:eta
```

The B2 account id, B2 application key, and Restic password must stay outside
Git. Because `eta` hosts Vaultwarden, keep the recoverable source of truth in
the Bootstrap Secret Set: iCloud Keychain plus a second offline emergency copy.
Suggested item name:

```text
eta Restic Backblaze B2
```

At runtime, Restic credentials are read from macOS Keychain. Use this
service-name pattern:

```text
restic-eta-b2-account-id
restic-eta-b2-account-key
restic-eta-password
```

Expected runtime environment:

```sh
export RESTIC_REPOSITORY="b2:eta-home-server-restic:eta"
export B2_ACCOUNT_ID="$(security find-generic-password -a "$USER" -s restic-eta-b2-account-id -w)"
export B2_ACCOUNT_KEY="$(security find-generic-password -a "$USER" -s restic-eta-b2-account-key -w)"
export RESTIC_PASSWORD="$(security find-generic-password -a "$USER" -s restic-eta-password -w)"
```

Do not commit exported values, generated environment files, Restic passwords,
B2 keys, raw Keychain dumps, Vaultwarden exports, or Bootstrap Secret Set
exports.

## `eta` Backup Scope

The v1 Home Server backup scope includes:

- `~/Services` — the Service Data Root for durable service state and logical
  database dumps.
- `~/nix/services/eta` — Service Definitions and per-stack restore notes.
- `~/nix/backup.md` — backup and restore contract.
- `~/nix/manual-steps.md` — manual recovery checklist.
- `~/nix/CONTEXT.md` — domain language for recovery decisions.
- `~/nix/docs/adr` — accepted recovery architecture decisions.

Generated caches, temporary directories, transcode scratch space, and runtime
logs under `~/Services` are excluded by `eta-backup-excludes.txt`. Only exclude
service data when it is reproducible, intentionally disposable, or explicitly
not part of the Home Server Recovery Contract.

## `eta` Schedule And Retention

The intended v1 Home Server Backup Cadence is one successful automatic backup
per day.

The launchd agent starts at login, at 03:00 as the primary nightly run, and
every 6 hours as a catch-up attempt. Scheduled runs skip when a successful
backup marker is less than 20 hours old.

Each managed run retries the backup up to 3 times with a 5 minute delay between
attempts. Retention is retried up to 2 times after a successful backup.

The Home Server Retention Policy is:

```sh
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
```

Retention runs after a successful managed backup.

## Manual Backup

After applying the Home Manager configuration, run the relevant host command:

```sh
gamma-restic-backup
eta-restic-backup
```

Check the repository after backup:

```sh
restic snapshots
restic check
```

## Restore Commands

Home Manager provides a safe fuzzy restore helper:

```sh
backup-restore-picker
```

The picker is for inspection, command generation, and restore drills. It uses
the same Restic repository and Keychain services as `gamma-restic-backup`.
Missing credentials produce a clear error before any snapshot or restore action
runs.

The picker has three staged selectors:

1. `backup snapshot> ` selects a Restic snapshot and previews snapshot metadata.
2. `backup file> ` browses files in that snapshot and previews metadata. Text
   files under 1 MiB are previewed with `bat` when available.
3. `backup action> ` selects one safe action.

Supported v1 actions:

- `print-command`: prints an explicit `restic restore` command.
- `copy-command`: copies that command with `pbcopy`.
- `restore-to-review-dir`: restores only after typing `restore`.

Generated restore commands target a timestamped review directory under
`~/Restores`, for example:

```sh
restic restore <snapshot-id> \
  --target "$HOME/Restores/restic-<snapshot-id>-<timestamp>" \
  --include /Users/ignacywielogorski/Documents/<file>
```

The v1 picker does not restore directly to the original path, overwrite an
existing review target, delete files, prune snapshots, or open/move restored
files after completion.

List snapshots:

```sh
restic snapshots
```

Restore one file to a temporary location:

```sh
mkdir -p /tmp/restic-restore-test
restic restore latest \
  --target /tmp/restic-restore-test \
  --include /Users/ignacywielogorski/Documents/<file>
```

Restore a directory to a temporary location:

```sh
mkdir -p /tmp/restic-restore
restic restore latest \
  --target /tmp/restic-restore \
  --include /Users/ignacywielogorski/Projects
```

Restore the workstation data set after reviewing the selected snapshot:

```sh
restic restore <snapshot-id> --target /
```

Before restoring over an active home directory, verify the snapshot id, confirm
the destination path, and prefer restoring into a temporary directory first.

## Restore Drills

Run two separate restore checks.

### Single-File Restic Restore

Frequency: before migrating backup automation into Nix, then periodically after
major backup changes.

Procedure:

1. Load Restic and B2 credentials from Keychain.
2. Run `restic snapshots`.
3. Restore one known file into `/tmp/restic-restore-test`.
4. Open or checksum the restored file.
5. Remove the temporary restore directory.

Success means Restic credentials, repository access, snapshot metadata, and file
restore all work.

### Fuzzy Picker Review Restore

Frequency: after changing `backup-restore-picker` or backup credentials.

Procedure:

1. Run `backup-restore-picker`.
2. Select a recent snapshot.
3. Select a known small text file.
4. Choose `print-command` and verify the target is under `~/Restores`.
5. Rerun the picker, choose `restore-to-review-dir`, and type `restore`.
6. Compare the restored file contents against the expected source.
7. Remove the review directory after the drill.

Success means the fuzzy workflow can inspect backups and restore into a safe
review directory without writing over the active home directory.

### Fresh-User Rebuild Drill

Frequency: before treating the flake as the workstation source of truth, then
after major host or backup changes.

Procedure:

1. Create a fresh macOS user or use a disposable macOS install.
2. Install Nix and enable flakes plus `nix-command`.
3. Clone this repository.
4. Apply the `gamma` configuration when available.
5. Recover Vaultwarden access.
6. Recover Restic credentials into Keychain.
7. Restore a representative subset of personal data to a temporary path.
8. Complete the manual restore checklist in `manual-steps.md`.

Success means the documented process can rebuild tools and recover protected
data without relying on hidden state from the current user account.
