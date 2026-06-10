# Homebrew Casks Inventory

## Reviewed Baseline

The following GUI applications are installed through nix-darwin Homebrew casks
for the `gamma` Workstation:

- `bitwarden`: desktop password manager client, including use with Vaultwarden
  servers. Vault contents and server configuration remain outside Nix.
- `ghostty`: terminal app. Configuration is managed by Home Manager.
- `karabiner-elements`: app and driver provider for keyboard remaps. Desired
  config is managed through Home Manager.
- `loom`: screen recording app. Account state and recordings remain outside
  Nix.
- `orbstack`: v1 Docker runtime and Docker CLI source of truth. Runtime state
  remains outside Nix.
- `raycast`: launcher app only. Settings, extensions, and account state remain
  app-owned or manually restored.
- `sf-symbols`: Apple symbol browser for design and development work.
- `whatsapp`: messaging app. Account state remains outside Nix.
- `zen`: browser app only. Profiles, sessions, extensions, and account state
  remain outside Nix.

## Sanitization Notes

This file is not raw `brew list --cask` output. Additional local casks should be
reviewed before being added. Browser profiles, exported application settings,
license files, and sync tokens must not be committed as inventory.
