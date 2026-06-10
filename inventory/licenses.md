# Licenses And Account-Backed Apps Inventory

## Reviewed Baseline

The v1 Workstation has no committed license files or serial numbers.

Manual login or app-owned sync may be required for:

- Zen Browser.
- Raycast.
- OrbStack.
- App Store applications added later.
- AI and development CLIs that use account auth or API tokens.

## Handling Rule

License keys, subscription tokens, account exports, and screenshots containing
credentials belong in the Secret Store or the app account, not Git. Add only the
application name, recovery location, and manual restore step here.
