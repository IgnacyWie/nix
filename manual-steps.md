# Manual Restore Steps

This checklist covers the steps that should remain explicit during a `gamma`
Workstation restore. Some items may later become declarative, but they should
not be hidden until they are proven reliable.

## Base System

1. Install macOS and sign in with the primary user:
   `ignacywielogorski`.
2. Install Nix using the official macOS installer.
3. Enable `flakes` and `nix-command`.
4. Clone this repository to `~/nix`.
5. When the flake exists, apply the host configuration:

```sh
cd ~/nix
nix flake check
sudo darwin-rebuild switch --flake .#gamma
```

Review build output before switching system-changing configuration.

## Secret Recovery

1. Sign in to Vaultwarden.
2. Open the Vaultwarden item named `gamma Restic Backblaze B2`.
3. Recover the Restic repository, Restic password, B2 account id, and B2
   application key.
4. Store those values in macOS Keychain using the service names documented in
   `backup.md`.
5. Do not save credentials in shell history, Git-tracked files, screenshots, or
   temporary notes.

Expected Keychain service names:

```text
restic-gamma-b2-account-id
restic-gamma-b2-account-key
restic-gamma-password
```

## Authentication

Recover these before relying on the workstation for daily development:

- GitHub CLI authentication with `gh auth login`.
- SSH keys from the Secret Store or another documented recovery source.
- SSH key permissions and agent behavior.
- Browser login for Zen Browser or the current default browser.
- Zen Browser profiles, settings, extensions, and sessions through browser sync,
  backup restore, or manual login. Nix only installs the app in v1.
- Raycast settings, extensions, and account state through Raycast's own sync,
  backup restore, or manual setup. Nix only installs the app in v1.
- OrbStack runtime state and container data through its own backup or restore
  process. OrbStack remains the v1 Docker runtime and Docker CLI source of
  truth.
- App Store login for applications that cannot be installed through Nix or
  Homebrew.

Never commit private SSH keys, exported browser profiles, GitHub tokens, or raw
application credentials.

## Backup Access

1. Load Restic runtime environment from Keychain.
2. Run `restic snapshots`.
3. Complete the single-file restore drill from `backup.md`.
4. Restore larger data sets only after verifying the snapshot id and destination
   path.

## Keyboard

Verify the `Dvorak-QWERTY` input source after restore.

If it is not managed declaratively yet, configure it in macOS System Settings
and document any required manual action here before closing the restore drill.

## Rosetta 2

Install Rosetta 2 only if an Intel-only app is required:

```sh
softwareupdate --install-rosetta
```

Rosetta is not part of the required baseline until a real dependency needs it.

## macOS Permissions

Review and grant permissions intentionally. macOS privacy prompts are part of the
restore process and should not be treated as silently reproducible.

Expected permission categories:

- Karabiner: Input Monitoring and Accessibility, if used.
- yabai: Accessibility and any scripting automation prompts required by the
  chosen configuration.
- skhd: Accessibility, if used.
- Backup tooling: Full Disk Access or selected folder access so Restic can read
  the protected backup scope.
- Terminal or Ghostty: permissions needed to run backup, restore, development,
  and automation commands.

Record any additional permission prompts that are required during the fresh-user
rebuild drill.

## Fresh-User Rebuild Drill

Run this separately from the single-file Restic restore.

1. Start from a fresh macOS user or disposable macOS install.
2. Install Nix, clone `~/nix`, and apply `~/nix#gamma` when available.
3. Recover Vaultwarden access.
4. Restore Restic credentials into Keychain.
5. Authenticate GitHub CLI and SSH.
6. Verify browser and App Store login.
7. Verify `Dvorak-QWERTY`.
8. Grant required macOS permissions for Karabiner, yabai, skhd, and backup
   access.
9. Restore a representative subset of data into a temporary path.
10. Verify Node and pnpm shell behavior with
    [docs/node-pnpm-shell.md](docs/node-pnpm-shell.md), especially that `nvm`
    wins over stale Homebrew Node and global pnpm shims.
11. Confirm development tools and terminal configuration are usable.

The drill passes only if the workstation can be rebuilt using repository
configuration plus Secret Store recovery, without relying on undocumented state
from the original user account.
