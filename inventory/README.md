# Sanitized Inventory

This directory records the reviewed inventory for the `gamma` Workstation in
the Personal Infrastructure migration.

The inventory is intentionally sanitized. Raw local command output, app exports,
shell profiles, SSH private keys, GPG key material, token-bearing config files,
Vaultwarden exports, Keychain exports, and generated Karabiner backups do not
belong in this directory. A finding should become desired state only after it is
reviewed, documented, and moved into the appropriate Nix, Home Manager, backup,
or manual restore configuration.

## Host Context

- Host Family: Darwin Workstation
- Host Name: `gamma`
- Primary User: `ignacywielogorski`
- Primary Editor: Neovim
- Secret Store: Vaultwarden client, with runtime backup secrets in macOS
  Keychain

## Inventory Files

- [homebrew-formulae.md](homebrew-formulae.md): reviewed Homebrew formulae and
  taps that remain outside Nix or are intentionally installed through
  nix-darwin Homebrew integration.
- [homebrew-casks.md](homebrew-casks.md): reviewed GUI applications installed
  through Homebrew casks.
- [mas-apps.md](mas-apps.md): App Store application inventory and validation
  notes.
- [shell.md](shell.md): sanitized shell configuration findings.
- [editor.md](editor.md): sanitized Primary Editor findings.
- [ssh-gpg.md](ssh-gpg.md): sanitized SSH and GPG findings.
- [directories.md](directories.md): important local directories and restore
  ownership.
- [cloud-services.md](cloud-services.md): cloud and sync services relevant to
  restore decisions.
- [licenses.md](licenses.md): manually licensed or account-backed applications.
- [permissions.md](permissions.md): macOS privacy and system permission
  inventory.
- [intel-only-apps.md](intel-only-apps.md): Rosetta 2 and Intel-only application
  findings.
- [keyboard-input.md](keyboard-input.md): Input Source Baseline and keyboard
  remap findings.
- [security-validation.md](security-validation.md): validation steps for secret
  and sensitive-file handling.
- [eta-docker-orbstack.md](eta-docker-orbstack.md): sanitized Docker and
  OrbStack findings for the `eta` Home Server migration.
- [future-v2.md](future-v2.md): explicitly deferred v2 work.

## eta-cloud Inventory Context

`eta-cloud` is the NixOS/Hetzner target host for the Home Server migration. It intentionally reuses `/Users/ignacywielogorski` on Linux so sanitized inventory paths, Restic snapshots, and Compose stack references stay comparable across the Mac Mini and cloud host.

Inventory files remain sanitized: do not add B2 keys, Restic passwords, Vaultwarden exports, Tailscale auth keys, API tokens, or copied `.env` contents. Runtime secrets belong in Vaultwarden and, on `eta-cloud`, in `/Users/ignacywielogorski/.config/eta-restic-backup/env` with `0600` permissions.
