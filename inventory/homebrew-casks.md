# Homebrew Casks Inventory

## Reviewed Baseline

The following GUI applications are installed through nix-darwin Homebrew casks
for the `gamma` Workstation:

- `ghostty`: terminal app. Configuration is managed by Home Manager.
- `zen`: browser app only. Profiles, sessions, extensions, and account state
  remain outside Nix.
- `raycast`: launcher app only. Settings, extensions, and account state remain
  app-owned or manually restored.
- `karabiner-elements`: app and driver provider for keyboard remaps. Desired
  config is managed through Home Manager.
- `orbstack`: v1 Docker runtime and Docker CLI source of truth. Runtime state
  remains outside Nix.

## Sanitization Notes

This file is not raw `brew list --cask` output. Additional local casks should be
reviewed before being added. Browser profiles, exported application settings,
license files, and sync tokens must not be committed as inventory.
