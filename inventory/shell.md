# Shell Inventory

## Reviewed Baseline

Home Manager manages the Primary User's zsh configuration for the `gamma`
Workstation:

- zsh completion, autosuggestions, syntax highlighting, history, prompt, and
  key bindings.
- `LANG`, `LANGUAGE`, `LC_ALL`, and `NVM_DIR` session variables.
- local script path entries for `~/.local/bin` and `~/.local/scripts`.
- aliases for navigation, Git, Nix helper scripts, and reviewed project
  workflows.
- `codex` and `claude` wrapper functions that run the real executable under
  `caffeinate` for up to one hour with their permission-bypass flags enabled.
- removal of stale Homebrew Node and pnpm shim paths before shell startup.

## User-Installed Tools

These tools are intentionally installed under `~/.local/bin` instead of being
managed by Nix in the v1 baseline:

- `mlx-vlm` is installed with `uv tool install mlx-vlm`. It provides
  `mlx_vlm.generate`, `mlx_vlm.chat`, `mlx_vlm.chat_ui`, `mlx_vlm.convert`, and
  `mlx_vlm.server` for local MLX vision-language workflows.

## Sensitive Findings

Do not commit raw shell profiles, exported `.env` files, shell history, API
tokens, AI CLI credentials, or backup credentials. If a shell finding contains
credentials or private hostnames, rewrite it as a sanitized behavior note before
adding it to this inventory.
