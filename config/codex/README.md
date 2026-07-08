# Codex configuration backup

This directory backs up portable Codex configuration from `~/.codex`.

Tracked:

- `config.toml`: user-level Codex preferences and trusted project metadata.
- `hooks.json`: user-level lifecycle hooks.

Not tracked:

- `auth.json`
- `history.jsonl`
- logs, caches, session files, and SQLite state

Home Manager installs `config.toml` as a mutable copy rather than a symlink so
Codex can persist local state such as hook trust. The deterministic `codex`
wrapper prefers `$PNPM_HOME/codex`, falls back to `/opt/homebrew/bin/codex`, and
passes `--dangerously-bypass-hook-trust` for these repo-owned hooks.

## eta-cloud Backup Context

This configuration is versioned inside `~/nix`, so it is covered by the Home Server Restic repository when the repo is included in `eta`/`eta-cloud` backups. It is not a required runtime dependency for the Hetzner `eta-cloud` service migration unless a service README explicitly says so.
