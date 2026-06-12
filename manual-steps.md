# Manual Restore Steps

This checklist covers the steps that should remain explicit during a `gamma`
Workstation restore. Some items may later become declarative, but they should
not be hidden until they are proven reliable.

## Base System

1. Install macOS and sign in with the primary user:
   `ignacywielogorski`.
2. Install Nix using the official macOS installer.
3. Enable `flakes` and `nix-command`.
4. Install Homebrew for Apple Silicon if `/opt/homebrew/bin/brew` does not
   already exist. The v1 configuration manages Homebrew packages, but does not
   bootstrap Homebrew itself.
5. Clone this repository to `~/nix`.
6. When the flake exists, apply the host configuration:

```sh
cd ~/nix
nix flake check
sudo darwin-rebuild switch --flake .#gamma
```

Review build output before switching system-changing configuration.

## Homebrew Cleanup

The `gamma` Homebrew baseline is authoritative: nix-darwin activation installs
declared entries and zaps unlisted Homebrew casks during cleanup.

Before applying a change that removes Homebrew entries, preview the cleanup:

```sh
cd ~/nix
make homebrew-cleanup-preview
```

The preview helper answers `n` to Homebrew's cleanup prompt automatically. It
should show `Would uninstall`, `Would untap`, and `Would remove` output only; it
must not uninstall anything.

Manual action is expected when Homebrew cannot inspect or remove old local
state safely:

- If Homebrew prints `Refusing to load ... from untrusted tap`, review the tap
  and trust only the exact cask or formula that Homebrew names, then rerun the
  preview. If Homebrew prints `tap formula is not trusted`, use the same narrow
  formula trust command. For example:

  ```sh
  brew trust --cask nikitabobko/tap/aerospace
  brew trust --formula michaelroosz/ssh/libsk-libfido2
  brew trust --formula ignacywie/tap/agent-loop-workflow
  ```

- If Homebrew prints `Refusing to untap ... because it contains the following
  installed formulae or casks`, decide whether each listed package belongs in
  the workstation baseline. If it does, add it to
  `modules/darwin/homebrew.nix`. If it does not, uninstall it manually and rerun
  the preview. For example:

  ```sh
  brew uninstall --formula heroku
  ```

- If Homebrew asks whether to proceed with cleanup, answer only after reviewing
  the `Would uninstall` and `Would untap` lists. `make apply-gamma` runs the
  same cleanup through nix-darwin with cask zapping enabled.

The trust commands above do not add those packages to the desired baseline;
they only let Homebrew load old tap metadata so cleanup can remove unlisted
packages.

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
- Tailscale Enrollment for `eta`. Tailscale may be installed by Nix, but joining
  the trusted tailnet remains a manual recovery step. Do not expect `ssh eta` or
  `eta-service` from `gamma` to work until `eta` is enrolled and visible at
  `eta.sparrow-pomano.ts.net`.
- Browser login for Zen Browser or the current default browser.
- Zen Browser profiles, settings, extensions, and sessions through browser sync,
  backup restore, or manual login. Nix only installs the app in v1.
- Raycast settings, extensions, and account state through Raycast's own sync,
  backup restore, or manual setup. Nix only installs the app in v1.
- OrbStack runtime state and container data through its own backup or restore
  process. OrbStack remains the v1 Docker runtime and Docker CLI source of
  truth.
- DisplayLink Manager may need to be launched once after installation, granted
  Screen Recording permission, and restarted before external DisplayLink
  displays are available.
- App Store login for applications that cannot be installed through Nix or
  Homebrew.

Never commit private SSH keys, exported browser profiles, GitHub tokens, or raw
application credentials.

## User-Installed CLI Tools

Some CLI tools are installed into `~/.local/bin` as user-level tools until they
are promoted into the declarative workstation baseline.

Install or update `mlx-vlm` with `uv`:

```sh
uv tool install mlx-vlm
```

Verify the installed entrypoints:

```sh
uv tool list | rg -A8 '^mlx-vlm'
command -v mlx_vlm.generate
mlx_vlm.generate --help
```

## Backup Access

### `gamma` Workstation

1. Load Restic runtime environment from Keychain.
2. Run `restic snapshots`.
3. Complete the single-file restore drill from `backup.md`.
4. Restore larger data sets only after verifying the snapshot id and destination
   path.

### `eta` Home Server

1. Create or recover the Backblaze B2 bucket for the Home Server Backup
   Repository: `eta-home-server-restic`.
2. Create a B2 application key with least-privilege access to that bucket.
3. Store the B2 account id, B2 application key, Restic repository, and Restic
   password in the Bootstrap Secret Set under `eta Restic Backblaze B2`.
4. Add the runtime credentials to macOS Keychain using the service names from
   `backup.md`:
   `restic-eta-b2-account-id`, `restic-eta-b2-account-key`, and
   `restic-eta-password`.
5. Apply the `eta` configuration and initialize the Restic repository once if it
   does not exist: `RESTIC_REPOSITORY=b2:eta-home-server-restic:eta restic init`
   after loading credentials from Keychain.
6. Run `eta-restic-backup` once manually and verify `restic snapshots` and
   `restic check`.
7. Confirm the launchd agent is loaded and writing logs under
   `~/Library/Logs/eta-restic-backup`.
8. Complete a restore drill for one file from `~/Services` and one recovery
   document from `~/nix/services/eta` or `~/nix/backup.md`.


## `eta` Home Server Keystone Recovery

Vaultwarden is the v1 Keystone Service and must be restored before relying on
self-hosted secrets for other Home Server services. Vaultwarden does not replace
the Bootstrap Secret Set; keep iCloud Keychain plus the offline emergency copy
current enough to recover Restic and Vaultwarden admin access.

1. Recover the Bootstrap Secret Set.
2. Restore `eta` Restic credentials into macOS Keychain using the service names
   in `backup.md`.
3. Restore Vaultwarden service data from the Home Server Backup Repository to a
   review directory first, then to `~/Services/data/vaultwarden` during a real
   recovery.
4. Recreate `~/nix/services/eta/vaultwarden/.env` from
   `~/nix/services/eta/vaultwarden/.env.example` and Bootstrap Secret Set
   values.
5. Start Vaultwarden first: `eta-service vaultwarden up`.
6. Verify login and representative vault contents before restoring dependent
   services.
7. Keep Vaultwarden SQLite-backed in v1; do not add Postgres as part of this
   recovery path.

## Keyboard

Verify the declarative input-source baseline and the keyboard remaps after
restore:

- `DVORAK - QWERTY CMD` is the selected input source.
- `Polish Pro` is enabled as the secondary input source.
- Caps Lock to Escape.
- Right Command and right Option mapping in Karabiner-Elements.
- ISO virtual keyboard behavior in Karabiner-Elements.
- Karabiner complex modifications for easier numbers, pane switching, pane
  sending, display brightness chords, Finder shortcuts, app shortcuts, and
  Zathura `Command+'` behavior.

The input-source baseline and Caps Lock remap are managed by nix-darwin. Right
Command/right Option mapping is managed in Karabiner-Elements at
`~/.config/karabiner/karabiner.json`, generated from the tracked
`config/karabiner.edn` Goku source during Home Manager activation. Use
`make check-karabiner-edn` to compare the current Goku output with the tracked
JSON. If the Karabiner mappings are not configured on first boot, open
Karabiner-Elements and apply the configured `Default` profile before closing the
restore drill.

## Workstation Defaults

Verify the nix-darwin Workstation Defaults after activation:

- Dock is on the left and uses quick autohide.
- Finder shows the expected path/status bars, desktop volumes, and home-folder
  new-window target.
- Dark mode and key-repeat behavior are active.
- Reduce Motion and Reduce Transparency are enabled.
- Trackpad tap-to-click, secondary click, three-finger drag, and disabled Force
  Click are active.
- Scroll bars are always visible, and new documents are not saved to iCloud by
  default.
- Stage Manager remains disabled, desktop icons/widgets stay hidden, click
  wallpaper to show Desktop is disabled, and tiled window margins stay disabled.
- Screenshots use PNG format, skip the floating thumbnail, omit window shadows,
  remember the last selection, and save to `~/Pictures/Screenshots`.

Some macOS defaults, especially appearance and input-source changes, may require
logging out and back in or restarting affected apps before they are visible.

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
- yabai: Accessibility, Automation prompts, and scripting-addition setup. Review
  whether SIP changes are still required for the macOS version in use before
  enabling the scripting addition.
- yabai sudoers: the migrated config runs `sudo yabai --load-sa` on startup and
  after Dock restarts. If scripting additions remain required, configure the
  narrow yabai sudoers rule recommended by the installed Koekeishiya formula
  rather than granting broad passwordless sudo.
- skhd: Accessibility/Input Monitoring, if prompted.
- DisplayLink Manager: Screen Recording. Reboot after the Homebrew cask
  installation, then grant the permission if prompted and restart the app.
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
7. Verify `DVORAK - QWERTY CMD`, `Polish Pro`, Caps Lock to Escape
   (nix-darwin), and right Command/right Option mapping in Karabiner-Elements.
8. Verify the migrated skhd bindings for Ghostty launch, space focus/move,
   window focus/swap/warp, fullscreen, sticky, and padding/gap toggle.
9. Verify the migrated yabai layout, padding, gap, app rules, and
   scripting-addition behavior. If `sudo yabai --load-sa` fails, complete the
   documented sudoers/SIP steps before treating the restore as complete.
10. Grant required macOS permissions for Karabiner, yabai, skhd, and backup
    access.
11. Restore a representative subset of data into a temporary path.
12. Verify Node and pnpm shell behavior with
    [docs/node-pnpm-shell.md](docs/node-pnpm-shell.md), especially that `nvm`
    wins over stale Homebrew Node and global pnpm shims.
13. Verify local workflow scripts after applying Home Manager:
    `command -v tmux-sessionizer`, `command -v git-branch-switcher`,
    `command -v typst-smart-open`, and one interactive smoke test for each
    script. The scripts expect `~/Developer` and `~/typst`, which Home Manager
    creates without managing their contents.
14. Confirm development tools and terminal configuration are usable.

The drill passes only if the workstation can be rebuilt using repository
configuration plus Secret Store recovery, without relying on undocumented state
from the original user account.
