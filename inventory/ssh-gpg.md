# SSH And GPG Inventory

## SSH Reviewed Baseline

Home Manager manages non-secret SSH client configuration for the Primary User.
The configuration includes reviewed host aliases, forwarding behavior, socket
paths, default identity-file reference, and the OrbStack SSH include.

Private SSH keys, SSH certificates, passphrases, agent state, and raw exported
known-host inventories are not committed. Recover required SSH keys from the
Secret Store or another documented recovery source during restore.

## GPG Reviewed Baseline

No GPG private key material is committed or managed in v1. Git commit signing is
currently disabled in the managed Git configuration.

If GPG signing is reintroduced, document the public configuration separately
from key recovery. Private keys and revocation certificates belong in the Secret
Store, not Git.
