# Managed Neovim Configuration

This directory contains the migrated LazyVim-based primary editor
configuration. Home Manager installs it to `~/.config/nvim` through
`modules/home/neovim.nix`. That link is authoritative: activation replaces
pre-existing files in that tree with the repository-managed version.

## Migration Notes

- `lazyvim.json`, `lazy-lock.json`, `init.lua`, `lua/config`, active
  `lua/plugins`, snippets, and Stylua settings were copied from the previous
  user configuration.
- The stock LazyVim `lua/plugins/example.lua` file was intentionally excluded
  because it returned an empty spec and only contained commented examples.
- The stock LazyVim starter README and license were intentionally replaced with
  repository-local documentation.
- Plugin authentication and API credentials are not stored here. Copilot,
  Avante, and similar plugins must continue to use their normal local auth or
  environment-based credential flows.
