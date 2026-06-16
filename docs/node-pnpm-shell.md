# Node and pnpm Shell Setup

This note records the shell fix needed for JavaScript development repos that
use `nvm` plus Corepack-managed package managers.

## Problem

The previous shell environment could prepend these paths ahead of `nvm`:

```sh
/opt/homebrew/opt/node@20/bin
$HOME/Library/pnpm
```

That made `nvm use 22` appear to work while `node` and `pnpm` still resolved to
older global shims. In `~/Developer/inspecto-lsp`, the symptom was `pnpm`
running `pnpm@11.5.2` under Node 20 and failing with:

```text
Error [ERR_UNKNOWN_BUILTIN_MODULE]: No such built-in module: node:sqlite
```

The second failure mode is global installs:

```text
ERR_PNPM_NO_GLOBAL_BIN_DIR Unable to find the global bin directory
```

`pnpm install -g <package>` needs a writable global bin directory configured in
`PNPM_HOME` and visible in `PATH`.

## Required zsh Behavior

Every interactive zsh session should remove stale inherited Node and pnpm paths
before loading `nvm`, then append the managed pnpm global bin directory behind
the `nvm` paths:

```sh
path=(${path:#/opt/homebrew/opt/node@20/bin})
path=(${path:#$HOME/Library/pnpm})
export PATH

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] &&
  . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
path=($path $PNPM_HOME)
typeset -U path
export PATH
```

Do not prepend `PNPM_HOME` for this setup. Keep it after the active `nvm` Node
bin directory so Corepack exposes the package manager pinned by each
repository's `packageManager` field, while global pnpm binaries remain
available as fallbacks.

## Verification

For a repo that pins `pnpm@10.11.0`, such as `~/Developer/inspecto-lsp`, a fresh
shell should pass:

```sh
nvm use 22
hash -r

node -v
which node
pnpm --version
which pnpm
echo "$PNPM_HOME"
```

Expected shape:

```text
node: v22.x
node path: $HOME/.nvm/versions/node/v22.x/bin/node
pnpm: 10.11.0
pnpm path: $HOME/.nvm/versions/node/v22.x/bin/pnpm
PNPM_HOME: $HOME/.local/share/pnpm
```

If `pnpm` still resolves to `$HOME/Library/pnpm/pnpm`, the stale global pnpm
shim is taking precedence and should be removed from `PATH` before `nvm` loads.

For global installs, a fresh shell should pass:

```sh
pnpm install -g @openai/codex
command -v codex
```

## Development Smoke Test

After shell setup and dependency installation:

```sh
cd ~/Developer/inspecto-lsp
nvm use 22
pnpm install
pnpm dev
```

The app should start Next.js on `http://localhost:3000`. The root route may
redirect to `/qr-code-login`; that is expected for a signed-out development
session.
