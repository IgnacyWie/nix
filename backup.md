# Backup Contract

This document defines the v1 backup and restore contract for the `gamma`
Workstation.

Nix rebuilds tools, declarative configuration, and selected application
settings. Restic protects personal data, local project state, and recoverable
application state that is not safely represented in Nix. A working restore
requires both layers.

## Repository Target

The backup target is a Restic repository stored in Backblaze B2.

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

The intended v1 schedule is one automatic backup per day.

The intended retention policy is:

```sh
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
```

Retention runs after a successful managed backup.

## Manual Backup

After applying the Home Manager configuration, run:

```sh
gamma-restic-backup
```

Check the repository after backup:

```sh
restic snapshots
restic check
```

## Restore Commands

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
