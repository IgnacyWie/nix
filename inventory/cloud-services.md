# Cloud Services Inventory

## Reviewed Baseline

- Backblaze B2 stores the Restic repository for the `gamma` Workstation.
- Vaultwarden is the Secret Store recovery source. The Workstation is only a
  client and does not host Vaultwarden.
- GitHub hosts this Personal Infrastructure repository and is authenticated
  manually through `gh auth login`.
- Zen Browser sync, Raycast sync, OrbStack state, and App Store account state
  remain app-owned or manually restored in v1.

## Not Part Of The Backup Contract

iCloud Drive, Dropbox, Google Drive, and similar cloud-synced folders are not
currently part of the v1 restore contract. If one becomes required, document
whether it is the source of truth, a cache, or a recoverable copy before adding
it to backup scope.
