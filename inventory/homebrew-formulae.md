# Homebrew Formulae Inventory

## Reviewed Baseline

The v1 Workstation keeps Homebrew enabled through nix-darwin. The declared
formulae below are the intended baseline; activation installs them without
auto-updating or upgrading, and the Homebrew cleanup phase removes unlisted
Homebrew packages.

Declared formulae:

- `goku`: GokuRakuJoudo generator for maintaining the editable
  `karabiner.edn` source and producing Karabiner JSON.
- `nvm`: kept in Homebrew because the shell workflow depends on Homebrew's
  sourced `nvm.sh`.
- `tmux`: kept in Homebrew for v1 because the existing TPM workflow and
  terminal behavior were migrated around that binary. Ghostty is configured to
  advertise `TERM=xterm-256color` to avoid `xterm-ghostty` compatibility issues
  when attaching tmux clients locally or through SSH-to-localhost workflows.
- `koekeishiya/formulae/yabai`: installed through trusted formula syntax.
- `koekeishiya/formulae/skhd`: installed through trusted formula syntax.

Declared tap:

- `koekeishiya/formulae`: used only for the required yabai and skhd formulae.
- `yqrashawn/goku`: used only for the GokuRakuJoudo formula.

Reviewed CLI tools such as `age`, `bitwarden-cli`, `gnupg`, `helm`, `httpie`,
`k9s`, `kubectl`, `kustomize`, `openssh`, `pinentry_mac`, and `sops` are
installed through Nix system packages instead of Homebrew formulae.

## Sanitization Notes

This file is not raw `brew leaves` output. Unlisted Homebrew formulae are not
implicitly desired state. If cleanup reports an unlisted formula that should
survive, add it to `modules/darwin/homebrew.nix` and document why it belongs in
the Personal Infrastructure baseline.
