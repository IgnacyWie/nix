# App Store Apps Inventory

## Reviewed Baseline

The following App Store applications are installed through nix-darwin
Homebrew `masApps` for the `gamma` Workstation:

- `Flighty` (`1358823008`): flight tracker app. Account, subscription, iCloud,
  trip, and notification state remain outside Nix.
- `WhatsApp` (`310633997`): messaging app installed as WhatsApp Messenger from
  the App Store. Account pairing, message history, and notification state remain
  outside Nix.

## Restore Validation

During a fresh-user rebuild drill, sign in to the App Store and record any
required App Store-only applications here before automating them with `mas`.
Treat `mas list` output as raw inventory until reviewed, because it may include
apps that are no longer required for the Personal Infrastructure baseline.
