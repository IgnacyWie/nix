# Repository Guidelines

## Project Structure & Module Organization

This repository is intended to become the source of truth for a reproducible macOS setup using Nix. It currently contains planning documentation in `PLAN.md`.

As the configuration is added, prefer this structure:

- `flake.nix` and `flake.lock`: top-level Nix entrypoint and pinned inputs.
- `hosts/<hostname>/default.nix`: machine-specific `nix-darwin` configuration.
- `modules/darwin/`: macOS system modules, Homebrew integration, fonts, and defaults.
- `modules/home/`: Home Manager modules for shell, Git, editor, and user tools.
- `backup/`: backup-related configuration, for example Restic modules.
- `manual-steps.md`: steps that cannot be reliably automated.

Keep modules focused by responsibility. Avoid mixing machine-specific values into shared modules.

## Build, Test, and Development Commands

No runnable Nix configuration exists yet. Once `flake.nix` is present, use:

```sh
nix flake check
```

Validates flake outputs and catches evaluation errors.

```sh
darwin-rebuild switch --flake .#<hostname>
```

Applies the macOS configuration for the selected host.

```sh
nix fmt
```

Formats Nix files if a formatter is configured.

Do not run system-changing commands unless the target host and expected changes are clear.

## Coding Style & Naming Conventions

Use two-space indentation for Nix files. Prefer small modules with descriptive names, for example `modules/home/git.nix` or `modules/darwin/homebrew.nix`.

Use lowercase kebab-case for file and directory names. Keep option names idiomatic to Nix and avoid custom abstractions until duplication is real.

Markdown files should use concise headings and actionable lists.

## Testing Guidelines

For Nix changes, run `nix flake check` before applying. For host changes, review the diff or build output from `darwin-rebuild` before switching.

When adding backup configuration, test both backup and restore. Document restore commands and manual verification steps in `backup.md` or `manual-steps.md`.

## Commit & Pull Request Guidelines

Current history uses Conventional Commits, for example:

```text
chore(docs): created PLAN.md
```

Continue using `type(scope): summary`, such as `feat(nix): add darwin host` or `docs(backup): document restore drill`.

Pull requests should describe the intent, list important commands run, mention any manual macOS steps, and call out changes that affect secrets, backups, or system defaults.

## Security & Configuration Tips

Never commit secrets, private SSH keys, API tokens, or unencrypted backup credentials. Prefer 1Password, macOS Keychain, `sops-nix`, or `agenix` once secret management is introduced.
