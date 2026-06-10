# 0001. Use Homebrew tmux on gamma

## Status

Accepted.

## Context

`gamma` uses Ghostty as the terminal emulator. After moving workstation tools into the Nix configuration, `tmux` resolved to the Nix package at version `3.6a`.

In Ghostty, that binary could create detached sessions but failed when attaching a client:

```sh
tmux attach-session -t exponata-form
```

The failure was:

```text
open terminal failed: not a terminal
```

The same terminal, session, and `TERM=xterm-ghostty` combination worked with the existing Homebrew tmux `3.3a_3` binary at `/opt/homebrew/bin/tmux`.

## Decision

Use Homebrew as the tmux binary provider on `gamma`.

Home Manager still manages `~/.config/tmux/tmux.conf`, but `programs.tmux.package` is set to `null` so Home Manager does not install Nix tmux into the user profile.

The host system package list also omits Nix tmux. Homebrew declares `tmux` explicitly so the working binary is managed.

## Consequences

`tmux` should resolve to `/opt/homebrew/bin/tmux` after applying the configuration and opening a new shell.

If Nix tmux is reintroduced later, verify attach behavior in Ghostty before switching:

```sh
tmux new-session -d -s nix-tmux-check "sleep 30"
tmux attach-session -t nix-tmux-check
```
