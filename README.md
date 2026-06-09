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

The repository currently contains planning documentation. The first implementation target is `gamma` using `nix-darwin`, Home Manager, and flakes.
