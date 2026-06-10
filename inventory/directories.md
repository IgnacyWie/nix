# Important Directories Inventory

## Restic-Protected Directories

The v1 backup contract protects these Primary User paths:

- `~/Documents`
- `~/Desktop`
- `~/Pictures`
- `~/Projects`
- `~/Developer`
- `~/Downloads`
- `~/typst`
- `~/nix`
- `~/.ssh`

## Home Manager-Created Directories

Home Manager creates these directories when missing:

- `~/Developer`
- `~/typst`
- `~/Pictures/Screenshots`
- `~/.nvm`
- `~/.local/bin`
- `~/.local/scripts`
- `~/.ssh/sockets`

## Excluded Or Manual State

Broad `~/Library`, `~/Movies`, and `~/Music` are outside the v1 restore
contract. Add specific application state only after it is reviewed and checked
for secret-bearing files. Generated Karabiner automatic backups are excluded and
must not become desired state.
