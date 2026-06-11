# Codex configuration backup

This directory backs up portable Codex configuration from `~/.codex`.

Tracked:

- `config.toml`: user-level Codex preferences and trusted project metadata.
- `hooks.json`: user-level lifecycle hooks.

Not tracked:

- `auth.json`
- `history.jsonl`
- logs, caches, session files, and SQLite state

After restoring `config.toml` or `hooks.json` into `~/.codex`, review new or
changed hooks with `/hooks` so Codex can trust their current definitions.
