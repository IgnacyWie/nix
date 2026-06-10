# Primary Editor Inventory

## Reviewed Baseline

Neovim is the Primary Editor for the `gamma` Workstation. Home Manager links the
reviewed LazyVim-based configuration from `config/nvim` to
`~/.config/nvim`.

The migrated editor inventory includes:

- LazyVim bootstrap and plugin lock file.
- Solarized Osaka color theme.
- Copilot and Avante plugin specifications, without credentials.
- Typst preview binding.
- tmux navigation integration.
- Neo-tree-on-right workflow.
- Molten, Quarto, and Jupytext notebook workflow.
- JavaScript snippets.
- Polish diacritic insert-mode mappings.

## Sensitive Findings

Provider credentials, local AI auth state, plugin caches, generated histories,
and project-local secrets remain outside the repository.
