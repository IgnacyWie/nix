# Personal Infrastructure

This repository describes the reproducible setup for personal machines using Nix.

## Contents

- [Purpose](#purpose)
- [Current Status](#current-status)
- [Workstation](#workstation)
- [Repository Workflow](#repository-workflow)
- [Managed Configuration](#managed-configuration)
- [Managed Keybindings](#managed-keybindings)
- [Recovery Contract](#recovery-contract)

## Purpose

Nix is the source of truth for tools, system configuration, user configuration,
and repeatable workstation setup. Backups remain the source of truth for
personal data, application state, and macOS-managed settings that are not
reliably declarative.

## Current Status

The repository contains the first runnable flake skeleton for `gamma` using
`nix-darwin`, Home Manager, flakes, and non-authoritative Homebrew app
installation.

Homebrew activation installs declared GUI apps and formulae for `gamma`, but it
does not auto-update, upgrade, clean up, or remove unlisted Homebrew-managed
software during the v1 migration. Zen Browser and Raycast are installed only as
apps; their profiles, settings, extensions, sessions, and internal state remain
outside Nix. Home Manager adds `/opt/homebrew/bin` and `/opt/homebrew/sbin` to
the shell path because `tmux`, `nvm`, `yabai`, and `skhd` are intentionally
provided by Homebrew. OrbStack is the Docker runtime and initial Docker CLI
source of truth, so this flake does not add a competing Docker CLI.

## Workstation

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
- Keyboard layout: `DVORAK - QWERTY CMD`, with `Polish Pro` enabled as the
  secondary input source
- Keyboard remap: Caps Lock to Escape (nix-darwin); right Command and right
  Option are remapped using Karabiner-Elements

## Home Server

### eta

- Role: macOS Home Server
- User: `ignacywielogorski`
- Platform: `aarch64-darwin`
- Service data root: `~/Services`
- Service Definition Layout: `~/nix/services/eta/<stack>/`
- Container runtime: OrbStack

The current `eta` slice is a buildable host skeleton. It sets the Host Name,
Primary User, shared Home Manager Host Shell Baseline with the `η` Host Prompt
Symbol, and baseline Home Server tools such as Git, jq, Restic, Tailscale, and
Docker Compose. The same Host Shell Baseline preserves the `γ` Host Prompt
Symbol for the `gamma` Workstation, while workstation-only aliases, Homebrew
paths, and interactive UI workflows are enabled explicitly for `gamma` rather
than inherited by `eta`. The `eta` slice intentionally does not define launchd
jobs for service stacks or start live containers.

Home Server Service Definitions live in this repository under
`services/eta/<stack>/`. Each stack is a separate Compose project named after
the stack directory, so stacks can be inspected, started, stopped, and restored
independently. Durable service state remains outside the checkout under
`~/Services`; Compose definitions should mount explicit per-stack paths there
and stack documentation should describe restore expectations.

The v1 Migration Scope is narrower than the current running Docker or OrbStack
state on `eta`. The v1 Tier 1 Service Stacks are Vaultwarden, Immich, Paperless,
Home Assistant with Matter Server, Baikal, Linkding, and Personal Cloud.
FreshRSS is Tier 2 for v1. Matrix, Synapse, Mautrix bridges, and the Arr media
stack are explicitly out of scope for v1 migration work and must not be added to
`services/eta/` unless a later issue changes the scope and updates the checks.

The canonical SSH Host Alias for the Home Server is `eta`, pointing at the
Tailscale identity `eta.sparrow-pomano.ts.net` as user `ignacywielogorski`.
`gamma` provides managed convenience wrappers for remote Home Server operations:

```sh
eta-shell
eta-service list
eta-service inspect <stack>
eta-service <stack> <command> [args...]
```

`eta-service` on `gamma` delegates over SSH to the managed `eta-service` command
on `eta`. Service Control Commands run authoritatively on `eta`; `gamma` only
provides shortcuts and does not own Home Server service state.

On `eta`, `eta-service list` and `eta-service inspect <stack>` only read
`~/nix/services/eta` and do not require Docker, OrbStack, or live containers.
Startup remains explicit through commands such as `eta-service <stack> up`; the
flake does not configure launchd autostart for all stacks.

OMLX is installed on `eta` through host-specific Homebrew configuration as the
host-managed Local Model Runtime for Local AI Service Stacks. This Homebrew
scope is separate from the `gamma` Workstation Homebrew scope. The initial model
preference is configurable with `personal.omlx.initialModel` and defaults to
`mlx-community/Qwen2.5-1.5B-Instruct-4bit`, a small instruct model preference
for constrained Apple Silicon memory. It is not a recovery dependency; restored
service state must not require that exact model to exist.

Home Manager manages OMLX as a user launchd agent on `eta`. The agent starts at
login, restarts on failure, and runs:

```sh
/opt/homebrew/bin/omlx serve \
  --base-path ~/Services/data/omlx \
  --model-dir ~/Services/data/omlx/models \
  --host 127.0.0.1 \
  --port 8000 \
  --log-level info \
  --max-concurrent-requests 1 \
  --memory-guard safe \
  --no-cache
```

The raw OMLX model API is intentionally bound only to `127.0.0.1:8000` and is
not exposed directly to the LAN or tailnet. v1 does not configure an OMLX API
key because the raw API is localhost-only; later service-facing access should go
through an explicit local proxy or integration boundary. Durable model storage
lives at `~/Services/data/omlx/models`; OMLX runtime logs and launchd stdout and
stderr live under `~/Services/data/omlx/logs`.

### omega

- Role: NAS, initially bootstrapped through a NixOS installer ISO
- Platform: `x86_64-linux`
- Live ISO host name: `omega`
- Live ISO SSH user: `nixos`
- Discovery target: `omega.local` when the LAN supports mDNS

The `omega` installer ISO enables OpenSSH, disables password SSH login, injects
Ignacy's public SSH key for the default live `nixos` user, and publishes the
`omega` host name with Avahi/mDNS. Build it with:

```sh
make build-omega-installer-iso
```

The ISO is written under `result/iso/nixos-omega-installer.iso`. Building this
Linux ISO requires an `x86_64-linux` Nix builder; on macOS that usually means a
configured remote Linux builder, running the command on a Linux Nix machine, or
manually running the `Build omega installer ISO` GitHub Actions workflow and
downloading its `omega-installer-iso` artifact.

After flashing and booting it, connect with:

```sh
ssh nixos@omega.local
```

## Repository Workflow

### Apply Flow

Validate the flake before applying system changes:

```sh
make check
make apply-gamma
```

### Verification Helpers

Common repository commands are exposed through `make`:

```sh
make
make check
make eval-gamma
make build-gamma
make eval-eta
make build-eta
make apply-eta
make fmt
make apply-gamma
```

The `make` targets are thin wrappers around `scripts/`. The scripts use the
same Nix invocation needed during the initial flake bootstrap:

```sh
./scripts/check
./scripts/eval-gamma
./scripts/build-gamma
./scripts/eval-eta
./scripts/build-eta
./scripts/apply-eta
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

Validate the `eta` Home Server skeleton without applying system-changing
changes:

```sh
make check
make eval-eta
make build-eta
```

`make build-eta` evaluates and builds `.#darwinConfigurations.eta.system` with
`nix build --no-link`; it does not run `darwin-rebuild switch`. Once the build
output is reviewed on `eta`, apply the host with:

```sh
make apply-eta
```

### Pre-Commit Checks

Install or update the local Git hook after cloning:

```sh
make install-pre-commit-hook
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

CI also runs secret scanning on pull requests. See [SECURITY.md](SECURITY.md)
for the Gitleaks configuration, local scan command, and false-positive process.

## Managed Configuration

### Workstation Defaults

nix-darwin manages the first reviewed Workstation Defaults batch for `gamma`:
stable Dock behavior including left-side quick autohide, Finder
visibility/search defaults, global key-repeat and appearance defaults,
screenshot format and destination behavior, reduced-motion and
reduced-transparency accessibility behavior, trackpad defaults including
three-finger Space switching without three-finger drag, selected WindowManager
preferences, visible scroll bars, local-first document saves, disabled
window/session restoration after app quit or login, and the native macOS
input-source baseline. The
selected input source is `DVORAK - QWERTY CMD`, with `Polish Pro` enabled as the
secondary layout. Privacy permissions, Rosetta 2, app-managed settings, volatile
Dock contents, and Spaces UUID/window placement state remain manual or app-owned.

Before nix-darwin is installed globally, use the bootstrap wrapper:

```sh
./scripts/bootstrap-apply-gamma
```

The first activation may stop if unmanaged files already exist in `/etc` or if
`/Applications/Nix Apps` is a stale symlink from an earlier setup. Preserve those
files by moving them aside with a `.before-nix-darwin` suffix, then rerun the
bootstrap wrapper.

### Home Commands

Home Manager provides a `notify` command for audible task completion alerts. It
plays `/System/Library/Sounds/Submarine.aiff` at boosted volume when Focus/Do
Not Disturb is inactive, and avoids the volume boost when Focus/Do Not Disturb
appears active.

Codex user configuration is backed up under `config/codex`. Home Manager links
the managed `hooks.json` into `~/.codex` and installs a mutable
`~/.codex/config.toml` copy when one is missing, so Codex can persist local
state such as hook trust. The managed `hooks.json` uses the Home Manager
`notify` command for Codex `Stop` and `PermissionRequest` lifecycle events, so
completed turns and approval requests produce the same audible alert.

Home Manager provides a deterministic `codex` wrapper that prefers
`$PNPM_HOME/codex`, falls back to `/opt/homebrew/bin/codex`, and runs the
selected binary under `caffeinate -dims -t 3600` with
`--dangerously-bypass-approvals-and-sandbox` and
`--dangerously-bypass-hook-trust`. It also defines a zsh function for `claude`
that resolves the real executable with `whence -p` and runs it under
`caffeinate -dims -t 3600` with `--dangerously-skip-permissions`. This keeps
long-running interactive AI CLI sessions from sleeping the Mac for up to one
hour and intentionally starts Codex without approval or hook-trust prompts.

Claude Code user settings are backed up under `config/claude`. Home Manager
merges the tracked hook block into the mutable `~/.claude/settings.json` file on
activation, preserving local MCP, plugin, theme, and other Claude-managed
settings. The managed Claude hooks call `notify` on `Stop`, `PermissionRequest`,
and selected `Notification` events.

Home Manager installs the current Pi coding agent CLI (`pi-coding-agent` 0.79.9)
through a shared module imported by both `gamma` and `eta`, so the same `pi`
executable is available on the workstation and home server.

### Primary Editor

Home Manager manages Neovim as the primary editor and links the reviewed
LazyVim-based configuration from `config/nvim` to `~/.config/nvim`. The
migration keeps the existing LazyVim extras, plugin lock file, Solarized Osaka
theme, Copilot and Avante plugin specs, Typst preview binding, tmux navigation,
Neo-tree-on-right workflow, Molten/Quarto/Jupytext notebook workflow,
JavaScript snippets, Python and pytest tooling, and Polish diacritic
insert-mode mappings. Local plugin auth state and provider credentials remain
outside the repository.

### Terminal

Home Manager manages Ghostty at `~/.config/ghostty/config`. The migrated
configuration keeps the existing Tango Dark theme, MesloLGS Nerd Font Mono,
window padding, tab-style titlebar, close behavior, and Dvorak-QWERTY
command-key workaround bindings for copy, paste, surface, tab, window, quit,
and reload actions. Ghostty advertises `TERM=xterm-256color` for compatibility
with tmux and SSH-to-localhost workflows instead of the newer
`TERM=xterm-ghostty` default.

### Workflow Scripts

Home Manager also manages `~/.local/scripts/tmux-sessionizer`. It selects a
project under `~/Developer`, `~/nix`, or `~/typst`, creates or
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
already exist. The zsh `Ctrl-T` binding launches this script, and tmux prefix
`T` launches it in a popup from the current pane directory.

Home Manager manages `~/.local/scripts/dev-command-runner`. From inside a
project, it starts at the Git repository root when available, discovers useful
development commands from `package.json`, `justfile`/`Justfile`, `Makefile`,
`flake.nix`, and executable files in `scripts/`, then runs the selected command
from the project root. Its `fzf` selector uses the `dev command> ` prompt and
previews script bodies, Just recipes, Make targets, repo scripts, and Nix check
context. JavaScript package scripts infer the package manager from lock files,
preferring pnpm, then Yarn, Bun, npm lock files, and finally npm. The zsh and
tmux binding is `Ctrl-O`; raw `Ctrl-D` is intentionally left to zsh for
delete-char/EOF behavior. Inside tmux, `Ctrl-O` and prefix `D` launch the same
runner in a 90% by 80% popup from the current pane directory, then send the
selected command back to the original pane so it runs in the main window.

Home Manager manages `~/.local/scripts/issue-picker`. Inside a GitHub-backed
Git repository, it detects the current `owner/repo` from the local Git remote,
lists open issues with `gh issue list`, and opens an `fzf` picker with the
`issue> ` prompt. The preview uses `gh issue view` to show issue title, state,
labels, assignees, URL, body, and comments when available. After selecting an
issue, a second `fzf` action menu supports opening the issue in the browser,
copying its URL with `pbcopy`, creating or switching to an
`issue-<number>-<slugified-title>` branch, or starting a `codex` session with
the issue URL as context. The zsh `Ctrl-Y` binding launches this script outside
tmux, and tmux prefix `Y` launches it in a popup from the current pane
directory. `Ctrl-I` is intentionally left unbound for this workflow because
terminals encode Tab as `Ctrl-I`.

Home Manager manages `~/.local/scripts/typst-smart-open` and the reviewed
`~/typst/academic-template.typ` template. The script opens an existing Typst
document from `~/typst` or creates a new one from the template, then starts a
dedicated tmux editor session. Its `fzf` selector renders the first page of
existing Typst documents with `typst` and `chafa`, falling back to source text.
The zsh `Ctrl-G` binding launches this script outside tmux, and the tmux
`Ctrl-G` binding launches it in a popup from `~/typst`. Home Manager creates
`~/Developer` and `~/typst` when missing, but it does not manage project
directories or generated Typst documents.

Home Manager manages `~/.local/scripts/backup-restore-picker` as the safe
Restic restore helper. It uses staged `fzf` selectors for snapshots, files, and
actions, defaults to printing or copying an explicit restore command, and only
runs a restore into a timestamped `~/Restores` review directory after typed
confirmation. It does not restore directly over original paths in v1; see
[backup.md](backup.md) for the restore safety model and drill.

### tmux Configuration

Home Manager manages tmux configuration and a pinned `tmux 3.3a` wrapper at
`~/.local/bin/tmux` because newer `tmux 3.6` builds fail to attach clients in
Ghostty on `gamma`. The Homebrew Brewfile trusts only the required Koekeishiya
formulae, `koekeishiya/formulae/yabai` and `koekeishiya/formulae/skhd`, rather
than the whole tap. Home Manager also pins the TPM checkout at
`~/.tmux/plugins/tpm`; TPM remains the v1 tmux plugin manager for
`seebi/tmux-colors-solarized` and `niksingh710/minimal-tmux-status`, using the
old `~/.tmux/plugins/` plugin path. Since tmux mouse mode remains disabled,
`Shift-Up` and `Shift-Down` enter tmux copy mode and scroll the tmux viewport by
line while `Shift-PageUp` and `Shift-PageDown` scroll by page. These bindings
keep scroll intent in tmux when a full-screen CLI such as Codex is active in the
pane.

The Darwin PAM configuration enables Touch ID for sudo and reattaches sudo
authentication to the user session so Touch ID also works inside tmux.

### Keyboard and Window Management

Home Manager manages the v1 keyboard and window-management configuration:
Karabiner's Goku source at `~/.config/karabiner.edn`, generated Karabiner JSON
at `~/.config/karabiner/karabiner.json` plus intentional complex modifications,
skhd at `~/.config/skhd/skhdrc`, and yabai at `~/.config/yabai/yabairc`.
Homebrew remains the v1 app and daemon provider for Goku, Karabiner-Elements,
yabai, and skhd. During Home Manager activation, the checked-in Karabiner JSON is
used as a bootstrap seed and Goku regenerates `~/.config/karabiner/karabiner.json`
from `~/.config/karabiner.edn`. `make check-karabiner-edn` runs the same
generation path in an isolated temporary home and compares its output with the
tracked generated JSON. The migrated yabai config keeps the current
scripting-addition load commands and Dock restart signal, but fresh restores
still require the manual macOS approvals and sudoers/SIP review documented in
`manual-steps.md`. Karabiner automatic backups are intentionally not tracked.

## Managed Keybindings

This section documents the keybindings and remaps managed by this repository.
It lists custom bindings from zsh, tmux, Neovim config files, Ghostty, skhd, and
Karabiner. LazyVim's built-in defaults are inherited but not duplicated here.

### Shell Workflow Keybindings

| Key | Scope | Action |
| --- | --- | --- |
| `Ctrl-F` | zsh, tmux | Launch `tmux-sessionizer`; tmux opens it in a popup. |
| `Ctrl-G` | zsh, tmux | Launch `typst-smart-open`; tmux opens it from `~/typst`. |
| `Ctrl-O` | zsh, tmux | Launch `dev-command-runner`; tmux opens it in a popup. |
| `Ctrl-T` | zsh | Launch `git-branch-switcher`. |
| `Ctrl-Y` | zsh | Launch `issue-picker`; avoids the `Ctrl-I`/Tab terminal collision. |
| tmux prefix `D` | tmux | Launch `dev-command-runner` in a popup. |
| tmux prefix `f` | tmux | Launch `tmux-sessionizer` in a popup. |
| tmux prefix `Y` | tmux | Launch `issue-picker` in a popup. |
| tmux prefix `T` | tmux | Launch `git-branch-switcher` in a popup. |

### tmux Keybindings

| Key | Action |
| --- | --- |
| `Ctrl-H/J/K/L` | Move left/down/up/right across Neovim splits and tmux panes through `vim-tmux-navigator`; `Ctrl-L` no longer clears the shell in tmux. |
| `Ctrl-\` | Move to the previously active tmux pane through `vim-tmux-navigator`. |
| tmux prefix `h/j/k/l` | Select the left/down/up/right tmux pane. |
| `Alt-Left/Right/Up/Down` | Select the neighboring tmux pane. |
| tmux prefix `\|` | Split the current pane horizontally. |
| tmux prefix `-` | Split the current pane vertically. |
| tmux prefix `r` | Reload `~/.config/tmux/tmux.conf`. |
| copy mode `v` | Begin selection. |
| copy mode `y` | Copy selection to the macOS clipboard with `pbcopy`. |
| `Shift-Up/Down` | Enter or stay in copy mode and scroll by line. |
| `Shift-PageUp/PageDown` | Enter or stay in copy mode and scroll by page. |

### Neovim Keybindings

| Key | Action |
| --- | --- |
| `Ctrl-H/J/K/L` | Move left/down/up/right across Neovim splits and tmux panes. |
| `Ctrl-\` | Move to the previously active tmux pane. |
| `+` / `-` | Increment or decrement the number under the cursor. |
| `dw` | Delete backward from the cursor to the start of the word. |
| `Ctrl-A` | Select the whole file. |
| `Ctrl-M` | Jump forward in the jumplist. |
| `<leader>t` | Start Typst preview. |
| `Tab` | Jump forward in a LuaSnip snippet placeholder while selecting snippets. |
| `Shift-Tab` | Jump backward in a LuaSnip snippet placeholder in insert/select mode. |
| `Alt-]`, `Alt-[` | Cycle to the next or previous Copilot suggestion. |
| `<leader>fe`, `<leader>e` | Toggle Neo-tree at the project root. |
| `<leader>fE`, `<leader>E` | Toggle Neo-tree at the current working directory. |
| `<leader>ge` | Toggle Neo-tree Git status view. |
| `<leader>be` | Toggle Neo-tree buffer view. |
| Neo-tree `l`, `h` | Open the selected node or close the selected node. |
| Neo-tree `Y` | Copy the selected path to the clipboard. |
| Neo-tree `O` | Open the selected path with the system application. |
| Neo-tree `P` | Toggle preview. |
| Neo-tree `Space` | Disabled. |
| `<leader>xx`, `<leader>xX` | Toggle workspace or buffer diagnostics in Trouble. |
| `<leader>cs`, `<leader>cl` | Toggle Trouble symbols or LSP view. |
| `<leader>xL`, `<leader>xQ` | Toggle Trouble location list or quickfix list. |
| `<localleader>me`, `<localleader>r` | Evaluate Molten operator or visual selection. |
| `<localleader>rr`, `<localleader>rc` | Re-evaluate a Molten cell or run a Quarto cell. |
| `<localleader>ra`, `<localleader>rA`, `<localleader>RA` | Run cells above, all cells, or all languages. |
| `<localleader>rl` | Run the current Quarto line. |
| `<localleader>os`, `<localleader>oh` | Open or hide Molten output. |
| `<localleader>md`, `<localleader>mx` | Delete a Molten cell or open output in the browser. |
| `` `a``/`` `c``/`` `e``/`` `l``/`` `n``/`` `o``/`` `s``/`` `z``/`` `x`` | Insert Polish lowercase diacritics in insert mode. |
| Uppercase variants such as `` `A`` and `` `Z`` | Insert Polish uppercase diacritics in insert mode. |

### Ghostty Keybindings

These bindings preserve QWERTY-style Command shortcuts on the Dvorak-QWERTY
Command layout.

| Key | Action |
| --- | --- |
| `Cmd-J` | Copy to clipboard. |
| `Cmd-K` | Paste from clipboard. |
| `Cmd-,` | Close surface. |
| `Cmd-Y` | New tab. |
| `Cmd-B` | New window. |
| `Cmd-'` | Quit Ghostty. |
| `Cmd-W` | Reload Ghostty config. |

### Karabiner Remaps

| Key | Action |
| --- | --- |
| `Caps Lock` | Send `Escape` through nix-darwin. |
| `Cmd-'` in Zathura | Send `Ctrl-Q`. |
| hold `A` for 500 ms | Type `ä`; tap still types `a`. |
| hold `Shift-A` for 500 ms | Type `Ä`; tap still types `A`. |
| `Right-Cmd-Q/W/E/R/T/Y/U/I/O/P` | Type `1/2/3/4/5/6/7/8/9/0`. |
| `Right-Opt-Q/W/E/R/T/Y/U/I` | Send `Right-Opt-1/2/3/4/5/6/7/8`. |
| `Right-Opt-Shift-Q/W/E/R/T/Y/U/I/O/P` | Send `Right-Opt-Shift-1/2/3/4/5/6/7/8/9/0`. |
| `non-US backslash` | Send `Fn`. |
| `Eject` | Open `~/Downloads`. |
| `F4`, `F5`, `F8` | Preserve these keys as function keys in Karabiner. |
| simultaneous `Q+W`, `Q+E` | Decrease or increase display brightness. |
| simultaneous `` `+I/J/H/R/N/A`` | Open `~/Developer`, home, Downloads, Pictures, Desktop, or Applications. |
| simultaneous `Z+;` | Open Safari and enter app-launcher mode. |
| app-launcher `;` | Open Safari. |
| simultaneous `Z+L` / app-launcher `L` | Opens Netflix in one rule and Notes in a later duplicate rule; this conflict is preserved from the current Karabiner config. |
| simultaneous `Z+T` / app-launcher `T` | Open YouTube. |
| simultaneous `Z+G` / app-launcher `G` | Open `https://s19.idu.edu.pl`. |
| simultaneous `Z+I` / app-launcher `I` | Open Zed. |
| simultaneous `Z+K` / app-launcher `K` | Open iTerm. |
| simultaneous `Z+R` / app-launcher `R` | Open System Preferences. |
| simultaneous `Z+M` / app-launcher `M` | Open Messages. |
| simultaneous `Z+P` / app-launcher `P` | Open Things3. |

### Window Management Keybindings

| Key | Action |
| --- | --- |
| `Cmd-Return` | Open a new Ghostty instance. |
| `Alt-Return` | Open Ghostty and start `ssh dev`. |
| `Alt-W` | Open Zen Browser. |
| `Alt-F`, `Alt-U` | Toggle yabai fullscreen zoom for the focused window. |
| `Alt-S` | Toggle sticky window. |
| `Alt-H/T` | Focus previous or next window. |
| `Alt-Shift-D/H/T/N` | Swap the focused window west/south/north/east. |
| `Shift-Cmd-D/H/T/N` | Stack the focused window west/south/north/east. |
| `Alt-Cmd-D/H/T/N` | Warp the focused window west/south/north/east. |
| `Alt-Tab`, `Alt-Shift-Tab` | Focus next or previous stacked window. |
| `Alt-Shift-0` | Balance windows in the current space. |
| `Alt-R` | Rotate the current space by 90 degrees. |
| `Alt-J` | Toggle yabai padding and gaps. |
| `Alt-1` through `Alt-9` | Focus space 1 through 9. |
| `Alt-0`, `Alt-L` | Focus the recent space. |
| `Alt-Shift-1` through `Alt-Shift-9` | Move the focused window to space 1 through 9. |
| `Alt-Shift-Space` | Toggle floating mode and place the focused window on a grid. |
| `F18` | Run the local Tailscale trigger script. |
| `F17` | Open `/Volumes`. |
| `F16` | Open iTerm2 at `~/Developer/backend`. |
| `F8` | Focus space 6. |
| `F4` | Open Firefox Developer Edition. |

## Recovery Contract

- [backup.md](backup.md): Restic to Backblaze B2 scope, credential pattern,
  schedule, retention, and restore drills.
- [inventory/](inventory/): sanitized migration inventory for apps, shell,
  editor, SSH/GPG, directories, cloud services, licenses, permissions,
  Intel-only app findings, keyboard/input state, and security validation.
- [manual-steps.md](manual-steps.md): post-restore checklist for Nix, secrets,
  authentication, keyboard layout, Rosetta, and macOS permissions.
- [docs/node-pnpm-shell.md](docs/node-pnpm-shell.md): Node, `nvm`, and
  Corepack/pnpm shell behavior required for JavaScript development repos.
