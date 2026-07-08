# Claude Code configuration backup

This directory backs up portable Claude Code user configuration from
`~/.claude/settings.json`.

Tracked:

- `settings.json`: user-level Claude Code settings and lifecycle hooks.

Not tracked:

- project history
- caches
- backups
- credentials or auth state

Home Manager merges the tracked `hooks` block into the mutable
`~/.claude/settings.json` file on activation, preserving other local settings so
Claude Code can keep managing its own state.

## eta-cloud Backup Context

This configuration is versioned inside `~/nix`, so it is covered by the Home Server Restic repository when the repo is included in `eta`/`eta-cloud` backups. It is not a required runtime dependency for the Hetzner `eta-cloud` service migration unless a service README explicitly says so.
