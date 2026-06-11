# 0001. Pin tmux 3.3a on gamma

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

Use a Home Manager-managed wrapper at `~/.local/bin/tmux` that delegates to a
Nix-built, pinned `tmux 3.3a` binary.

Home Manager still manages `~/.config/tmux/tmux.conf`, but `programs.tmux.package` is set to `null` so Home Manager does not install the moving nixpkgs tmux into the user profile.

The host system package list also omits nixpkgs tmux. Homebrew does not declare
`tmux`, because the Homebrew formula now resolves to `3.6b`, which reproduces
the Ghostty attach failure.

## Consequences

`tmux` should resolve to `~/.local/bin/tmux` after applying the configuration
and opening a new shell. The wrapper should report `tmux 3.3a`.

Mouse support remains disabled in tmux because tmux `3.3a` crashes under
Ghostty when tmux handles mouse selection. With `mouse off`, text selection is
handled by Ghostty instead.

If newer tmux is reintroduced later, verify attach behavior in Ghostty before
switching:

```sh
tmux new-session -d -s nix-tmux-check "sleep 30"
tmux attach-session -t nix-tmux-check
```
