# Keyboard And Input Source Inventory

## Input Source Baseline

The `gamma` Workstation uses this native macOS Input Source Baseline:

- Selected input source: `DVORAK - QWERTY CMD`.
- Enabled secondary input source: `Polish Pro`.

The baseline is managed through nix-darwin custom user preferences.

## Keyboard Remaps

- Caps Lock to Escape is managed by nix-darwin.
- Right Command is remapped to right Option by Karabiner-Elements.
- The reviewed Karabiner profile preserves ISO virtual keyboard behavior and
  intentional complex modifications for number entry, pane switching, pane
  sending, display brightness chords, Finder shortcuts, app shortcuts, and
  Zathura `Command+'` behavior.

Generated Karabiner automatic backups are excluded from Git and backup scope.
