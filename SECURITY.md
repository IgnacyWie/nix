# Security

## Secret Scanning

Pull requests run Gitleaks with the default rule set plus repository-specific
rules in `.gitleaks.toml`. The custom rules focus on the Personal
Infrastructure threat model: Restic and Backblaze B2 credentials, local
environment files, password-manager exports, macOS Keychain exports, backup
secret files, and SSH private keys.

Run the same scan locally before pushing changes that touch backup,
authentication, or workstation restore configuration:

```sh
nix shell nixpkgs#gitleaks -c gitleaks detect --source . --config .gitleaks.toml --redact
```

If the scan reports a real secret, revoke or rotate the credential first, then
remove it from the branch before merging. Do not add real tokens, private SSH
keys, Restic passwords, B2 keys, Vaultwarden exports, or raw Keychain dumps to
this repository.

## False Positives

Treat ignores as reviewed security exceptions:

1. Prefer changing the example value so it is obviously fake and no longer
   matches.
2. For a one-off false positive, add the finding fingerprint to
   `.gitleaksignore` in the same change that introduces the flagged content.
3. For a durable fake pattern or intentionally committed fixture, add the
   narrowest possible allowlist entry to `.gitleaks.toml`.
4. Document why the value is safe in the pull request.

Never ignore a finding that contains a live credential. Rotate it and remove it
from Git history instead.
