# macOS Nix Migration and Backup Plan

## Goal

Keep this machine on macOS, but make the development environment and as much user configuration as practical reproducible with Nix.

Nix should be treated as the recipe for rebuilding tools and configuration. Backups should be treated as the source of truth for personal data, application state, and anything macOS does not expose declaratively.

## Target Setup

- `nix-darwin` for macOS system-level configuration.
- Home Manager for user configuration and dotfiles.
- Nix flakes for pinned, reproducible inputs.
- Homebrew managed through `nix-darwin` for GUI apps and casks.
- Restic as the current backup layer, migrated from the manually configured first backup as soon as possible.
- Optional later: Time Machine for local full-machine recovery.
- Optional later: Backblaze Personal Backup as a simple offsite backup layer.

## Phase 0: Stabilize Backup Before Changing the System

Do this before making Nix the source of truth for anything important.

1. Inventory the current manually configured Restic backup to Backblaze B2.
2. Record the repository location, included paths, excluded paths, schedule, retention policy, and restore command.
3. Verify that at least one file can be restored from the Restic repository.
4. Migrate the Restic configuration into this repository without committing credentials.
5. Optional later: add Time Machine for local full-machine recovery.
6. Optional later: add Backblaze Personal Backup for broad offsite coverage.

Important directories to verify:

- `~/Documents`
- `~/Desktop`
- `~/Pictures`
- `~/Projects` or equivalent code directory
- `~/Developer`
- `~/Downloads`
- `~/typst`
- `~/nix`
- Any local-only app data that matters

Avoid relying on Nix as backup. Nix can recreate tools and config, not personal data. Restic configuration may live in Nix, but the Restic repository and credentials remain outside Git. For the first migration, Restic should read secrets from macOS Keychain, with the values recoverable from Vaultwarden.

## Phase 1: Inventory the Current Mac

Create a record of the current machine before migrating.

Treat the current Mac as inventory, not automatically as the desired final state. A setting should move into Nix only after it is intentionally kept. This policy can be tightened later once the repository has proven it can rebuild the workstation reliably.

Suggested files:

- `README.md`
- `inventory/`
- `manual-steps.md`
- `backup.md`

Create `backup.md` and `manual-steps.md` before writing substantial Nix code, but do not put secrets in either file. Structure `manual-steps.md` as a post-restore checklist, especially for Vaultwarden login, Restic credentials, GitHub authentication, SSH key recovery, browser login, App Store login, and macOS permission prompts.
Document Rosetta 2 as an install-if-needed manual step rather than a required baseline.
Commit sanitized inventory files. Do not commit raw local config files until they have been reviewed for secrets, tokens, private hostnames, and obsolete settings.
Document and verify the Dvorak-QWERTY keyboard layout during restore. Only make it declarative if `nix-darwin` can manage it cleanly.

Record:

- Mac model and macOS version.
- Installed Homebrew formulae.
- Installed Homebrew casks.
- App Store apps.
- Shell config.
- Neovim config.
- SSH/GPG setup.
- Important directories.
- Cloud services in use.
- Apps with manual licenses.
- Apps requiring Full Disk Access, Accessibility, camera, microphone, or other macOS permissions.
- Intel-only apps that may require Rosetta 2.
- Keyboard layout and input source, currently Dvorak-QWERTY.

Current assumption: no cloud-synced folders are in use for backup purposes. Revisit this if iCloud Drive, Dropbox, Google Drive, or similar services become part of the workflow.
The first flake only needs to support `aarch64-darwin` for `gamma`. Add other systems only when real hosts require them.
Use `nixpkgs-unstable` for the first flake, pinned by `flake.lock`. Update inputs manually with `nix flake update`; do not auto-update pinned inputs.
Have `nix-darwin` and Home Manager follow the same pinned `nixpkgs` input unless a concrete incompatibility forces a split later.
Enable unfree packages globally for the personal workstation configuration with `nixpkgs.config.allowUnfree = true`.

Useful commands:

```sh
brew leaves > inventory/brew-formulae.txt
brew list --cask > inventory/brew-casks.txt
mas list > inventory/mas-apps.txt
```

`mas` depends on being signed into the App Store and may not be fully reliable.

## Phase 2: Install Nix

Install Nix on macOS using the official installer.

Enable:

- flakes
- `nix-command`

Use `nixfmt-rfc-style` as the flake formatter so `nix fmt` formats Nix files consistently.

Canonical apply command:

```sh
nix flake check
sudo darwin-rebuild switch --flake ~/nix#gamma
```

Expected repository shape:

```text
~/nix
  flake.nix
  flake.lock
  hosts/
    darwin/
      gamma/
        default.nix
    nixos/
      <future-server>/
        default.nix
  modules/
    darwin/
      system.nix
      homebrew.nix
      macos-defaults.nix
      fonts.nix
    nixos/
    home/
      shell.nix
      git.nix
      ssh.nix
      neovim.nix
      ghostty.nix
      karabiner.nix
      tmux.nix
      yabai.nix
      skhd.nix
      scripts.nix
  assets/
    typst/
      academic-template.typ
  backup/
    restic.nix
  inventory/
  README.md
  manual-steps.md
  backup.md
```

## Phase 3: Add nix-darwin

Use `nix-darwin` as the macOS system entrypoint.

Start small:

- hostname
- Nix settings
- trusted users: `root`, `@admin`, and `ignacywielogorski`
- system packages
- macOS defaults, added comprehensively but in reviewed batches
- Touch ID for sudo
- developer fonts, starting with MesloLGS Nerd Font Mono

Initial package examples:

```nix
environment.systemPackages = with pkgs; [
  bat
  bun
  git
  curl
  eza
  fd
  fzf
  gh
  htop
  jq
  lazygit
  neovim
  posting
  restic
  ripgrep
  tmux
  tree
  typst
  wget
  zoxide
];
```

Start with the curated CLI baseline above, then review `brew leaves` and migrate only tools that should be part of the workstation baseline.
Include dependencies for migrated workflow scripts, including `fzf`, `tmux`, `neovim`, `typst`, `lazygit`, `posting`, and Corepack-managed `pnpm`. Verify whether `lazysql` is available cleanly through Nix; otherwise keep it in Homebrew or make that script window optional.
Do not migrate unused automation apps such as Hammerspoon just because they appear in the current Homebrew inventory.
Use yabai and skhd as the v1 window-management source of truth. Do not migrate AeroSpace unless it becomes active again later.

Initial macOS defaults examples:

```nix
system.defaults = {
  dock.autohide = true;
  finder.AppleShowAllExtensions = true;
  NSGlobalDomain.AppleShowAllExtensions = true;
};
```

Aim to make macOS system settings as complete as practical, but add them in reviewed batches. Prefer settings that are supported by `nix-darwin`, easy to verify, and unlikely to fight macOS privacy prompts or app-managed preferences.

## Phase 4: Add Home Manager

Use Home Manager for user-level configuration:

- shell config
- Git config
- Neovim config
- terminal tools
- Ghostty terminal config
- Karabiner-Elements keyboard customization
- yabai and skhd window-management config
- dotfiles
- `direnv`
- `starship`
- `tmux`
- language tooling where appropriate

Adopt dotfiles gradually. Start with low-risk generated configuration, then move existing files such as shell, Git, Neovim, and ignore files into Home Manager only after reviewing their current contents.
Use a clean `zsh` baseline rather than copying the existing shell setup wholesale. Existing `.zshrc` aliases should be inventoried and migrated intentionally into the Home Manager shell module. Split aliases into simple categories such as shell/navigation, Git, Nix, and project-specific aliases.
Migrate existing zsh keybindings intentionally. Current important bindings include Ctrl-F for `tmux-sessionizer` and Ctrl-G for `typst-smart-open`.
Do not carry Oh My Zsh into the Nix-managed shell baseline unless a later review finds a specific plugin or behavior that must be preserved.
Manage Neovim configuration in this repository rather than pointing to a separate Neovim config repository. Migrate the current Neovim setup after inspecting it, preserving intentional options, keymaps, plugins, and language tooling rather than starting from a blank config.
Manage Ghostty configuration through Home Manager after inspecting the existing config. Migrate the whole current Ghostty config unless inspection shows machine-specific or obsolete settings.
Preserve Ghostty's Dvorak-QWERTY command-key workarounds as intentional keybindings.
Migrate `~/.local/scripts` into this repository after review. Preserve script behavior first, then refactor later only after the managed versions work. Current workflow scripts include `tmux-sessionizer` for project tmux sessions under `~/Developer` and `typst-smart-open` for creating/opening Typst documents under `~/typst`.
Manage the Typst template required by `typst-smart-open`, currently `~/typst/academic-template.typ`, as a repository asset if it contains no sensitive material.
Have Home Manager create `~/Developer` and `~/typst` if missing, but do not manage project contents or generated Typst documents inside those directories.
Migrate tmux configuration through Home Manager, but keep TPM as the tmux plugin manager for v1.
Migrate Karabiner-Elements, yabai, and skhd configuration. These are first-class workstation behavior, not optional app preferences. Preserve yabai scripting addition behavior for v1 and document any required macOS permissions, sudoers setup, or SIP-related manual steps.
For Karabiner, migrate `karabiner.json` and intentional `assets/complex_modifications/*.json`; do not migrate `automatic_backups/`.
Install Karabiner-Elements through Homebrew cask and manage its desired configuration through Home Manager. Document required macOS approvals as manual restore steps.
Install yabai and skhd through Homebrew for v1, using the upstream tap if needed, while managing their configuration through Home Manager.
Preserve the full current skhd config for v1, including app-specific and device-specific bindings. Review potentially stale bindings only after the migrated config works.
Preserve the full current yabai config for v1, including app rules that may later prove stale. Review and clean up rules only after the migrated config works.
Prefer centralized default language tooling for the workstation, while allowing project-specific escape hatches where version pinning or ecosystem tooling makes that more practical.
Node.js is an explicit exception: use `nvm` initially for Node versions, especially for projects with `.nvmrc`. Individual projects can later opt into `direnv` and Nix dev shells when they need stronger reproducibility.
Use Corepack for package managers such as `pnpm` when projects declare them. Install Bun through Nix as part of the workstation tool baseline.

Good early modules:

```nix
programs.git.enable = true;
programs.zsh.enable = true;
programs.direnv.enable = true;
programs.starship.enable = true;
```

The first Git module should manage identity and safe defaults only. Defer commit signing until key management is intentionally designed.

Keep secrets out of Git.

## Phase 5: Manage Applications

Use three layers:

1. Nix packages for CLI tools.
2. Homebrew casks for macOS GUI apps.
3. Manual or App Store installation for apps that do not automate cleanly.

Start with Homebrew in a non-authoritative mode. The Nix configuration should install declared formulae and casks, but it should not remove unlisted Homebrew apps until the application inventory has been reviewed and accepted as complete.
During activation, do not automatically update Homebrew, upgrade packages, or clean up unlisted packages. Use `autoUpdate = false`, `upgrade = false`, and `cleanup = "none"` initially.
Install the current browser app declaratively where practical, starting with Zen Browser, but do not manage browser profiles, extensions, sessions, or settings through Nix. Browser profile recovery belongs to backup, sync, or manual restore steps.
Install Raycast as a first-class required app in v1, but do not manage Raycast internal config or extensions.
The initial required GUI app set is Ghostty, Zen Browser, Raycast, Karabiner-Elements, and OrbStack. Add other casks only after inventory review. Install OrbStack for daily container workflows, but do not manage its runtime state through Nix in v1.
Use OrbStack as the v1 Docker runtime and initial Docker CLI source of truth. Do not add a competing Nix-managed Docker CLI unless verification shows it is needed.
Keep Python tooling minimal in v1. Do not migrate global Python versions, Miniconda, Pipenv, Spyder, or PyCharm unless a concrete workflow requires them later.
Install AI/dev-agent CLIs used daily, including Claude Code, Codex, OpenCode, and Gemini. Keep their credentials in Vaultwarden, Keychain, or manual auth flows; do not export API keys from managed shell config.
Preserve existing AI/dev-agent bypass aliases as intentional workflow shortcuts, including Claude Code and Codex aliases that disable approval/sandbox prompts.

Example `nix-darwin` Homebrew config:

```nix
homebrew = {
  enable = true;

  brews = [
    "mas"
    "yabai"
    "skhd"
  ];

  casks = [
    "ghostty"
    "zen-browser"
    "raycast"
    "karabiner-elements"
    "orbstack"
  ];

  masApps = {
    "Amphetamine" = 937984704;
  };
};
```

Pitfall: App Store automation depends on Apple login state and is less reliable than Nix or Homebrew.
Inventory App Store apps during migration, but keep App Store automation non-authoritative at first. Add `masApps` only for apps known to reinstall cleanly, and document Apple ID login or unreliable installs in `manual-steps.md`.

## Phase 6: Handle Secrets

Do not put secrets directly in Git.

First version:

- SSH keys stay in `~/.ssh`.
- API tokens stay in Vaultwarden or macOS Keychain.
- `.env` files stay out of Git.
- Non-secret SSH client config can be managed with Home Manager after review.
- Required secrets are documented in `manual-steps.md`.
- Vaultwarden is the recovery source for secrets, not the automatic provisioning source.

Later options:

- `sops-nix`
- `agenix`
- Vaultwarden-compatible workflows for secret storage and SSH key recovery
- v2: automate selected secret provisioning from Vaultwarden after the baseline rebuild and restore process is stable.

Do not block the first migration on secret automation.

## Phase 7: Backup Model

Use Restic as the active backup layer, with optional additional layers later.

### Layer 1: Git

Store this Nix configuration in a remote Git repository.

Back up:

- `~/nix`
- managed dotfiles
- project repositories

### Layer 2: Restic

Use this for encrypted, versioned backups of selected personal data and configuration.

The current Restic backend is Backblaze B2. Restic secrets should be stored locally outside Git. Use macOS Keychain as the v1 runtime secret provider, with recovery details documented from Vaultwarden. A future version may automate selected Restic secret provisioning from Vaultwarden.
Declare the Restic repository location in Nix; only credentials and passwords stay in Keychain.
Keep the existing Restic Keychain service names: `restic-gamma-b2-account-id`, `restic-gamma-b2-account-key`, and `restic-gamma-password`.
Run Restic both ways: provide a manual backup command for explicit runs and a `launchd` schedule for regular automatic backups.
Schedule the automatic Restic backup daily at 20:00 as the initial laptop-friendly cadence.
Use an initial Restic retention policy of 7 daily snapshots, 4 weekly snapshots, and 12 monthly snapshots. Do not keep yearly snapshots initially.

Include:

- documents
- photos
- local project files
- downloads, because important files may temporarily live there
- `~/nix`
- `~/Developer`
- `~/typst`
- `~/.ssh`
- selected app configuration
- browser profiles if important and safe to back up

Do not include all of `~/Library` initially. Back up only selected app state from `~/Library` after inventory, and only when the data cannot be recreated reliably.

Usually avoid backing up:

- `/nix/store`
- `~/Library/Caches`
- `node_modules`
- `target`
- `dist`
- `.DS_Store`
- large build artifacts

### Layer 3: Optional Local Full-Machine Backup

Add Time Machine later for local full-machine restore and quick file recovery.

### Layer 4: Optional Broad Offsite Backup

Add Backblaze Personal Backup later if broad offsite coverage is still useful alongside Restic.

Periodically check exclusions. Backup tools often skip caches, package-manager stores, cloud-sync placeholders, and some system directories.

Good Restic candidates:

- `~/Documents`
- `~/Desktop`
- `~/Pictures`
- `~/Projects`
- `~/Developer`
- `~/Downloads`
- `~/nix`
- `~/typst`
- selected app config directories
- `~/.ssh`, only if encrypted and handled carefully

## Phase 8: Restore Drill

Test without wiping the Mac. Include both a single-file Restic restore and a fresh-user rebuild drill.

1. Create a fresh macOS user account.
2. Clone the `~/nix` repository.
3. Run the bootstrap command.
4. Confirm shell, packages, apps, Git, Neovim, and macOS defaults apply.
5. Restore a few files from Restic.
6. Optional later: restore a few files from Time Machine or Backblaze if those layers are added.
7. Update `manual-steps.md` with anything that remains manual.

The goal is not zero manual work. The goal is known, documented manual work.

## Phase 9: Bootstrap Script

Eventually add a small bootstrap script.
For v1, install Nix manually first using the current official installer. The bootstrap script should assume Nix already exists and should not hand-roll or wrap the Nix installer.

Example:

```sh
#!/usr/bin/env bash
set -euo pipefail

xcode-select --install || true

# Install Nix manually first.
# Then:
sudo darwin-rebuild switch --flake ~/nix#gamma
```

Keep the bootstrap script boring. The flake and modules should be the real source of truth.

## v2 Roadmap

Consider these only after the baseline rebuild and restore drill work reliably:

- Automate selected secret provisioning from Vaultwarden.
- Automate SSH key recovery from Vaultwarden where appropriate.
- Optionally wrap the official Nix installer in the bootstrap script.
- Add pre-commit hooks for formatting and validation.
- Tighten Homebrew cleanup once the app inventory is trusted.
- Move mature projects to `direnv` and Nix dev shells.

## Main Pitfalls

- Thinking Nix replaces backup.
- Trying to declare everything on day one.
- Putting secrets in Git.
- Assuming macOS app permissions are reproducible.
- Expecting App Store apps to behave like Nix packages.
- Backing up `/nix/store` unnecessarily.
- Not testing restore.
- Having only one untested backup path.
- Migrating Restic config without documenting restore commands.
- Forgetting to document manual Apple/macOS steps.

## Recommended Order

1. Inventory and verify the current Restic backup.
2. Create or initialize the `~/nix` Git repo.
3. Install Nix.
4. Add `nix-darwin`.
5. Add Home Manager.
6. Migrate Restic configuration without committing credentials.
7. Move CLI tools into Nix.
8. Move shell, zsh keybindings, local scripts, Git, Neovim, Ghostty, and tmux config into Home Manager.
9. Move Karabiner, yabai, and skhd config into Home Manager while installing their apps/tools through Homebrew.
10. Move required GUI apps into Homebrew casks managed by `nix-darwin`.
11. Optional later: add Time Machine and Backblaze Personal Backup if needed.
12. Run a restore drill.
