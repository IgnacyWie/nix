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

## Current Status

The repository contains the first runnable flake skeleton for `gamma` using
`nix-darwin`, Home Manager, and flakes.

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

Before nix-darwin is installed globally, use the bootstrap wrapper:

```sh
./scripts/bootstrap-apply-gamma
```

The first activation may stop if unmanaged files already exist in `/etc` or if
`/Applications/Nix Apps` is a stale symlink from an earlier setup. Preserve those
files by moving them aside with a `.before-nix-darwin` suffix, then rerun the
bootstrap wrapper.

## Recovery Contract

- [backup.md](backup.md): Restic to Backblaze B2 scope, credential pattern,
  schedule, retention, and restore drills.
- [manual-steps.md](manual-steps.md): post-restore checklist for Nix, secrets,
  authentication, keyboard layout, Rosetta, and macOS permissions.
