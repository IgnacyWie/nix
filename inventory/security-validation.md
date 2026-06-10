# Security Validation

Use these checks before treating inventory changes as accepted desired state.

## Required Local Checks

Run the flake checks:

```sh
./scripts/check
```

Run the same secret scan used in CI before pushing changes that touch backup,
authentication, shell, SSH, editor, or restore configuration:

```sh
nix shell nixpkgs#gitleaks -c gitleaks detect --source . --config .gitleaks.toml --redact
```

## Sensitive File Coverage

The repository must not contain:

- private SSH keys, SSH certificates, or private GPG keys.
- API tokens or exported AI/development CLI credentials.
- Restic passwords, Backblaze B2 account ids, or Backblaze B2 application keys.
- raw `.env` files or generated environment files.
- raw secret-bearing shell files, shell history, or command transcripts.
- Vaultwarden, Bitwarden, 1Password, or macOS Keychain exports.
- generated Karabiner backups from
  `~/.config/karabiner/automatic_backups`.
- unreviewed application exports, browser profiles, or license files.

## Manual Review Procedure

1. Inspect the raw local source outside Git.
2. Remove credentials, private hostnames when not needed, volatile IDs, caches,
   generated backups, and obsolete settings.
3. Record only the reviewed behavior or restore requirement in `inventory/`.
4. Move desired configuration into Nix or Home Manager only after the finding is
   intentionally accepted.
5. Run `./scripts/check` and the Gitleaks command above.
6. For backup-related changes, complete the restore drill in `backup.md`.

If a real secret is found in Git, rotate or revoke it before continuing.
