# Homebrew Formulae Inventory

## Reviewed Baseline

The v1 Workstation keeps Homebrew enabled through nix-darwin, but Homebrew is
non-authoritative. Activation installs declared formulae and trusted tap
formulae without auto-updating, upgrading, cleaning up, or removing unlisted
packages.

Declared formulae:

- `nvm`: kept in Homebrew because the shell workflow depends on Homebrew's
  sourced `nvm.sh`.
- `tmux`: kept in Homebrew for v1 because the existing TPM workflow and terminal
  behavior were migrated around that binary.
- `koekeishiya/formulae/yabai`: installed through trusted formula syntax.
- `koekeishiya/formulae/skhd`: installed through trusted formula syntax.

Declared tap:

- `koekeishiya/formulae`: used only for the required yabai and skhd formulae.

## Sanitization Notes

This file is not raw `brew leaves` output. Unlisted Homebrew formulae are not
implicitly desired state. Before tightening cleanup, compare current local
formulae against this file and migrate only tools that belong in the Personal
Infrastructure baseline.
