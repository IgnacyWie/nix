# macOS Nix Migration and Backup Plan

## Goal

Keep this machine on macOS, but make the development environment and as much user configuration as practical reproducible with Nix.

Nix should be treated as the recipe for rebuilding tools and configuration. Backups should be treated as the source of truth for personal data, application state, and anything macOS does not expose declaratively.

## Target Setup

- `nix-darwin` for macOS system-level configuration.
- Home Manager for user configuration and dotfiles.
- Nix flakes for pinned, reproducible inputs.
- Homebrew managed through `nix-darwin` for GUI apps and casks.
- Time Machine for local full-machine recovery.
- Backblaze Personal Backup as the simple offsite backup layer.
- Optional later: Restic to Backblaze B2 for declarative, encrypted, versioned backups.

## Phase 0: Back Up Before Changing the System

Do this before making Nix the source of truth for anything important.

1. Set up Time Machine to an external SSD/HDD or NAS.
2. Let the first full backup complete.
3. Verify that files can be browsed and restored from Time Machine.
4. Set up Backblaze Personal Backup for offsite backup.
5. Confirm Backblaze is backing up the important directories.

Important directories to verify:

- `~/Documents`
- `~/Desktop`
- `~/Pictures`
- `~/Projects` or equivalent code directory
- `~/nix`
- Any local-only app data that matters

Avoid relying on Nix as backup. Nix can recreate tools and config, not personal data.

## Phase 1: Inventory the Current Mac

Create a record of the current machine before migrating.

Suggested files:

- `README.md`
- `apps.md`
- `manual-steps.md`
- `backup.md`

Record:

- Mac model and macOS version.
- Installed Homebrew formulae.
- Installed Homebrew casks.
- App Store apps.
- Shell config.
- Editor config.
- SSH/GPG setup.
- Important directories.
- Cloud services in use.
- Apps with manual licenses.
- Apps requiring Full Disk Access, Accessibility, camera, microphone, or other macOS permissions.

Useful commands:

```sh
brew leaves > apps/brew-formulae.txt
brew list --cask > apps/brew-casks.txt
mas list > apps/mas-apps.txt
```

`mas` depends on being signed into the App Store and may not be fully reliable.

## Phase 2: Install Nix

Install Nix on macOS using the official installer.

Enable:

- flakes
- `nix-command`

Expected repository shape:

```text
~/nix
  flake.nix
  flake.lock
  hosts/
    macbook/
      default.nix
  modules/
    darwin/
      system.nix
      homebrew.nix
      macos-defaults.nix
      fonts.nix
    home/
      shell.nix
      git.nix
      ssh.nix
      editor.nix
  backup/
    restic.nix
  README.md
  manual-steps.md
  backup.md
```

## Phase 3: Add nix-darwin

Use `nix-darwin` as the macOS system entrypoint.

Start small:

- hostname
- Nix settings
- trusted users
- system packages
- basic macOS defaults
- optional Touch ID for sudo

Initial package examples:

```nix
environment.systemPackages = with pkgs; [
  git
  vim
  curl
  wget
  ripgrep
  fd
  jq
  htop
];
```

Initial macOS defaults examples:

```nix
system.defaults = {
  dock.autohide = true;
  finder.AppleShowAllExtensions = true;
  NSGlobalDomain.AppleShowAllExtensions = true;
};
```

Do not try to encode every macOS setting on day one. Add settings gradually after verifying they work.

## Phase 4: Add Home Manager

Use Home Manager for user-level configuration:

- shell config
- Git config
- editor config
- terminal tools
- dotfiles
- `direnv`
- `starship`
- `tmux`
- language tooling where appropriate

Good early modules:

```nix
programs.git.enable = true;
programs.zsh.enable = true;
programs.direnv.enable = true;
programs.starship.enable = true;
```

Keep secrets out of Git.

## Phase 5: Manage Applications

Use three layers:

1. Nix packages for CLI tools.
2. Homebrew casks for macOS GUI apps.
3. Manual or App Store installation for apps that do not automate cleanly.

Example `nix-darwin` Homebrew config:

```nix
homebrew = {
  enable = true;

  brews = [
    "mas"
  ];

  casks = [
    "google-chrome"
    "visual-studio-code"
    "1password"
    "raycast"
    "spotify"
  ];

  masApps = {
    "Amphetamine" = 937984704;
  };
};
```

Pitfall: App Store automation depends on Apple login state and is less reliable than Nix or Homebrew.

## Phase 6: Handle Secrets

Do not put secrets directly in Git.

First version:

- SSH keys stay in `~/.ssh`.
- API tokens stay in 1Password or macOS Keychain.
- `.env` files stay out of Git.
- Required secrets are documented in `manual-steps.md`.

Later options:

- `sops-nix`
- `agenix`
- 1Password CLI integration

Do not block the first migration on secret automation.

## Phase 7: Backup Model

Use three layers.

### Layer 1: Git

Store this Nix configuration in a remote Git repository.

Back up:

- `~/nix`
- managed dotfiles
- project repositories

### Layer 2: Time Machine

Use this for local full-machine restore and quick file recovery.

Include:

- home directory
- app data
- photos and documents
- local project files
- browser profiles if important

### Layer 3: Offsite Backup

Start with Backblaze Personal Backup.

Back up:

- internal disk
- selected external disks
- documents
- photos
- code
- app data

Periodically check exclusions. Backup tools often skip caches, package-manager stores, cloud-sync placeholders, and some system directories.

Optional later: Restic to Backblaze B2.

Good Restic candidates:

- `~/Documents`
- `~/Desktop`
- `~/Pictures`
- `~/Projects`
- `~/nix`
- selected app config directories
- `~/.ssh`, only if encrypted and handled carefully

Usually avoid backing up:

- `/nix/store`
- `~/Library/Caches`
- `node_modules`
- `target`
- `dist`
- `.DS_Store`
- large build artifacts

## Phase 8: Restore Drill

Test without wiping the Mac.

1. Create a fresh macOS user account.
2. Clone the `~/nix` repository.
3. Run the bootstrap command.
4. Confirm shell, packages, apps, Git, editor, and macOS defaults apply.
5. Restore a few files from Time Machine.
6. Restore a few files from Backblaze or Restic.
7. Update `manual-steps.md` with anything that remains manual.

The goal is not zero manual work. The goal is known, documented manual work.

## Phase 9: Bootstrap Script

Eventually add a small bootstrap script.

Example:

```sh
#!/usr/bin/env bash
set -euo pipefail

xcode-select --install || true

# Install Nix manually first if needed.
# Then:
sudo darwin-rebuild switch --flake ~/nix#macbook
```

Keep the bootstrap script boring. The flake and modules should be the real source of truth.

## Main Pitfalls

- Thinking Nix replaces backup.
- Trying to declare everything on day one.
- Putting secrets in Git.
- Assuming macOS app permissions are reproducible.
- Expecting App Store apps to behave like Nix packages.
- Backing up `/nix/store` unnecessarily.
- Not testing restore.
- Depending only on Backblaze without Time Machine.
- Depending only on Time Machine without offsite backup.
- Forgetting to document manual Apple/macOS steps.

## Recommended Order

1. Set up Time Machine.
2. Set up Backblaze Personal Backup.
3. Create or initialize the `~/nix` Git repo.
4. Install Nix.
5. Add `nix-darwin`.
6. Add Home Manager.
7. Move CLI tools into Nix.
8. Move shell, Git, and editor config into Home Manager.
9. Move GUI apps into Homebrew casks managed by `nix-darwin`.
10. Add Restic/B2 later if more control is needed.
11. Run a restore drill.
