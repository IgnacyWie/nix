# Personal Infrastructure

This repository describes the reproducible setup for personal machines using Nix.

## Hosts

### gamma

- Type: 15-inch MacBook Air
- Color: Midnight
- Role: macOS workstation
- User: `ignacywielogorski`
- Git identity: `Ignacy Wielogorski <ignacywie@icloud.com>`
- Terminal: Ghostty
- Developer font: MesloLGS Nerd Font Mono
- Browser: Zen Browser
- Secret store: Vaultwarden client
- Backup: Restic to Backblaze B2, with secrets in macOS Keychain
- Keyboard layout: Dvorak-QWERTY
- Keyboard remap: Caps Lock to Escape (nix-darwin); right Command and right Option are remapped using Karabiner-Elements

## Current Status

The repository contains the first runnable flake skeleton for `gamma` using
`nix-darwin`, Home Manager, flakes, and non-authoritative Homebrew app
installation.

Homebrew activation installs declared GUI apps and formulae for `gamma`, but it
does not auto-update, upgrade, clean up, or remove unlisted Homebrew-managed
software during the v1 migration. Zen Browser and Raycast are installed only as
apps; their profiles, settings, extensions, sessions, and internal state remain
outside Nix. OrbStack is the Docker runtime and initial Docker CLI source of
truth, so this flake does not add a competing Docker CLI.

## Apply Flow

Validate the flake before applying system changes:

```sh
nix flake check
sudo darwin-rebuild switch --flake .#gamma
```

## Local Verification Helpers

The `scripts/` wrappers use the same Nix invocation needed during the initial
flake bootstrap:

```sh
./scripts/check
./scripts/eval-gamma
./scripts/fmt
./scripts/apply-gamma
```

They fall back to `/nix/var/nix/profiles/default/bin/nix`, enable
`nix-command` and `flakes`, and set `NIX_SSL_CERT_FILE=/etc/ssl/cert.pem` when
that macOS certificate bundle is available.

During the first flake bootstrap, `nix flake check` and evaluating
`.#darwinConfigurations.gamma.system` passed with that environment. `nix fmt`
is wired to `nixfmt-rfc-style`, but may fail before the new Darwin
configuration is applied if the current Nix daemon still reads the broken
`/etc/ssl/certs/ca-certificates.crt` path while downloading formatter
dependencies. The Darwin baseline sets `nix.settings.ssl-cert-file` to
`/etc/ssl/cert.pem` so future rebuilds use the macOS CA bundle.

## Local Pre-Commit Checks

Install or update the local Git hook after cloning:

```sh
./scripts/install-pre-commit-hook
```

The installer sets this clone's `core.hooksPath` to `.githooks`. The
repository-managed `pre-commit` hook runs:

```sh
./scripts/fmt
./scripts/check
```

If formatting changes files, the hook stops so the changes can be reviewed and
staged before committing again. `./scripts/check` runs `nix flake check`, which
mirrors the main local validation path without running system-changing commands
such as `darwin-rebuild switch` or `./scripts/apply-gamma`.

Before nix-darwin is installed globally, use the bootstrap wrapper:

```sh
./scripts/bootstrap-apply-gamma
```

The first activation may stop if unmanaged files already exist in `/etc` or if
`/Applications/Nix Apps` is a stale symlink from an earlier setup. Preserve those
files by moving them aside with a `.before-nix-darwin` suffix, then rerun the
bootstrap wrapper.

## Home Commands

Home Manager provides a `notify` command for audible task completion alerts. It
plays `/System/Library/Sounds/Submarine.aiff` at boosted volume when Focus/Do
Not Disturb is inactive, and avoids the volume boost when Focus/Do Not Disturb
appears active.

Home Manager defines zsh functions for `codex` and `claude` that resolve the
real executable with `whence -p` and run it under `caffeinate -dims`, forwarding
all arguments unchanged. This keeps long-running interactive AI CLI sessions
from sleeping the Mac without relying on recursive aliases or manual shell
edits.

Home Manager manages Neovim as the primary editor and links the reviewed
LazyVim-based configuration from `config/nvim` to `~/.config/nvim`. The
migration keeps the existing LazyVim extras, plugin lock file, Solarized Osaka
theme, Copilot and Avante plugin specs, Typst preview binding, tmux navigation,
Neo-tree-on-right workflow, Molten/Quarto/Jupytext notebook workflow,
JavaScript snippets, and Polish diacritic insert-mode mappings. Local plugin
auth state and provider credentials remain outside the repository.

Home Manager manages Ghostty at `~/.config/ghostty/config`. The migrated
configuration keeps the existing Tango Dark theme, MesloLGS Nerd Font Mono,
window padding, tab-style titlebar, close behavior, and Dvorak-QWERTY
command-key workaround bindings for copy, paste, surface, tab, window, quit,
and reload actions.

Home Manager also manages `~/.local/scripts/tmux-sessionizer`. It selects a
project under `~/Developer` or the `~/nix` configuration repository, creates or
switches to a named tmux session, and opens the first window as `codex` before
adding the usual development, Git, database, and REST client windows. Its `fzf`
selector previews the selected project's README with `glow` when present,
falling back to Git status, recent commits, or a compact file listing. The zsh
`Ctrl-F` binding launches this script outside tmux. Inside tmux, `Ctrl-F` and
tmux prefix `f` both launch it in a popup from the current pane directory.

Home Manager manages `~/.local/scripts/git-branch-switcher`. Inside a Git
repository, it uses `fzf` to select local and remote branches by recent commit
date, shows a short commit-log preview, and switches to the selected branch.
Selecting a remote branch creates a local tracking branch when one does not
already exist. The zsh `Ctrl-H` binding launches this script outside tmux, and
the tmux `Ctrl-H` binding launches it in a popup from the current pane
directory, after tmux plugins have loaded.

Home Manager manages `~/.local/scripts/typst-smart-open` and the reviewed
`~/typst/academic-template.typ` template. The script opens an existing Typst
document from `~/typst` or creates a new one from the template, then starts a
dedicated tmux editor session. Its `fzf` selector renders the first page of
existing Typst documents with `typst` and `chafa`, falling back to source text.
The zsh `Ctrl-G` binding launches this script outside tmux, and the tmux
`Ctrl-G` binding launches it in a popup from `~/typst`. Home Manager creates
`~/Developer` and `~/typst` when missing, but it does not manage project
directories or generated Typst documents.

Home Manager manages tmux configuration while Homebrew remains the tmux binary
provider on `gamma`. The Homebrew Brewfile trusts only the required Koekeishiya
formulae, `koekeishiya/formulae/yabai` and `koekeishiya/formulae/skhd`, rather
than the whole tap. Home Manager also pins the TPM checkout at
`~/.tmux/plugins/tpm`; TPM remains the v1 tmux plugin manager for
`seebi/tmux-colors-solarized` and `niksingh710/minimal-tmux-status`, using the
old `~/.tmux/plugins/` plugin path.
The Darwin PAM configuration enables Touch ID for sudo and reattaches sudo
authentication to the user session so Touch ID also works inside tmux.

Home Manager manages the v1 keyboard and window-management configuration:
Karabiner at `~/.config/karabiner/karabiner.json` plus intentional complex
modifications, skhd at `~/.config/skhd/skhdrc`, and yabai at
`~/.config/yabai/yabairc`. Homebrew remains the v1 app and daemon provider for
Karabiner-Elements, yabai, and skhd. The migrated yabai config keeps the current
scripting-addition load commands and Dock restart signal, but fresh restores
still require the manual macOS approvals and sudoers/SIP review documented in
`manual-steps.md`. Karabiner automatic backups are intentionally not tracked.

## Recovery Contract

- [backup.md](backup.md): Restic to Backblaze B2 scope, credential pattern,
  schedule, retention, and restore drills.
- [manual-steps.md](manual-steps.md): post-restore checklist for Nix, secrets,
  authentication, keyboard layout, Rosetta, and macOS permissions.
- [docs/node-pnpm-shell.md](docs/node-pnpm-shell.md): Node, `nvm`, and
  Corepack/pnpm shell behavior required for JavaScript development repos.
