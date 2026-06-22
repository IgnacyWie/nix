# Homebrew Casks Inventory

## Reviewed Baseline

The following GUI applications are installed through nix-darwin Homebrew casks
for the `gamma` Workstation:

- `firefox@developer-edition`: secondary development browser. Profiles,
  extensions, sessions, and account state remain outside Nix.
- `ghostty`: terminal app. Configuration is managed by Home Manager.
- `google-chrome`: Chromium-family browser for compatibility testing. Profiles,
  extensions, sessions, and account state remain outside Nix.
- `hammerspoon`: menu bar automation host for the Gamma Restic Backup status
  item. Configuration is managed by Home Manager.
- `karabiner-elements`: app and driver provider for keyboard remaps. Desired
  config is managed through Home Manager.
- `keka`: archive utility. Keka is configured as the default opener for common
  archive formats during nix-darwin activation.
- `loom`: screen recording app. Account state and recordings remain outside
  Nix.
- `orbstack`: v1 Docker runtime and Docker CLI source of truth. Runtime state
  remains outside Nix.
- `raycast`: launcher app only. Settings, extensions, and account state remain
  app-owned or manually restored.
- `sf-symbols`: Apple symbol browser for design and development work.
- `telegram`: messaging app. Account state remains outside Nix.
- `tailscale`: macOS menu bar UI from the standalone/Homebrew distribution.
  Login, network state, and VPN permissions remain outside Nix.
- `whatsapp`: messaging app. Account state remains outside Nix.
- `zen`: browser app only. Profiles, sessions, extensions, and account state
  remain outside Nix.

## Sanitization Notes

This file is not raw `brew list --cask` output. Additional local casks should be
reviewed before being added. Unlisted casks are zapped by the Homebrew cleanup
phase after any required manual trust decisions for old taps. Browser profiles,
exported application settings, license files, and sync tokens must not be
committed as inventory.
