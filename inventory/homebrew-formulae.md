# Homebrew Formulae Inventory

## Reviewed Baseline

The v1 Workstation keeps Homebrew enabled through nix-darwin. The declared
formulae below are the intended baseline; activation installs them without
auto-updating or upgrading, and the Homebrew cleanup phase removes unlisted
Homebrew packages.

Declared formulae:

- `goku`: GokuRakuJoudo generator for maintaining the editable
  `karabiner.edn` source and producing Karabiner JSON.
- `libpq`: PostgreSQL client tools (`psql`, `pg_dump`, `pg_restore`) kept in
  Homebrew and force-linked because the formula is keg-only.
- `nvm`: kept in Homebrew because the shell workflow depends on Homebrew's
  sourced `nvm.sh`.
- `homebrew-zathura/zathura/zathura`: PDF viewer kept in Homebrew because the
  v1 desktop setup already has Zathura-specific Karabiner handling.
- `homebrew-zathura/zathura/zathura-pdf-poppler`: PDF backend plugin for
  Zathura. Activation keeps the required plugin symlink in Zathura's plugin
  directory.
- `homebrew-zathura/zathura/girara`: Zathura interface library from the same
  tap, declared explicitly so Homebrew cleanup keeps the runtime library
  closure intact.
- `homebrew-zathura/zathura/synctex`: trusted explicitly because the Zathura
  formula references it as an optional dependency from the same tap.
- `koekeishiya/formulae/yabai`: installed through trusted formula syntax.
- `koekeishiya/formulae/skhd`: installed through trusted formula syntax.

Declared tap:

- `homebrew-zathura/zathura`: used only for Zathura, its PDF plugin, and the
  related trusted formulae required by that tap.
- `koekeishiya/formulae`: used only for the required yabai and skhd formulae.
- `yqrashawn/goku`: used only for the GokuRakuJoudo formula.

Reviewed CLI tools such as `age`, `bitwarden-cli`, `gnupg`, `helm`, `httpie`,
`k9s`, `kubectl`, `kustomize`, `openssh`, `pinentry_mac`, and `sops` are
installed through Nix system packages instead of Homebrew formulae. PostgreSQL
client tools are the exception and come from Homebrew `libpq`. `tmux` is
pinned to `3.3a` through Home Manager because current `3.6` builds fail to
attach clients in Ghostty on `gamma`.

## Sanitization Notes

This file is not raw `brew leaves` output. Unlisted Homebrew formulae are not
implicitly desired state. If cleanup reports an unlisted formula that should
survive, add it to `modules/darwin/homebrew.nix` and document why it belongs in
the Personal Infrastructure baseline.
