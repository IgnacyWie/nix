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
  `caffeinate`.
- removal of stale Homebrew Node and pnpm shim paths before shell startup.

## Sensitive Findings

Do not commit raw shell profiles, exported `.env` files, shell history, API
tokens, AI CLI credentials, or backup credentials. If a shell finding contains
credentials or private hostnames, rewrite it as a sanitized behavior note before
adding it to this inventory.
