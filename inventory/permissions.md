# macOS Permissions Inventory

## Expected Permission Categories

The `gamma` Workstation restore may require manual approval for:

- Karabiner-Elements: Input Monitoring and Accessibility.
- yabai: Accessibility, Automation prompts, and scripting-addition setup when
  still required by the current macOS version.
- skhd: Accessibility or Input Monitoring.
- Backup tooling: Full Disk Access or selected folder access for Restic.
- Terminal or Ghostty: permissions needed to run backup, restore, development,
  and automation commands.

## Validation

After applying the configuration, follow `manual-steps.md` and record any new
privacy prompts here before treating the restore drill as complete. macOS
permission databases are not committed and are not silently reproducible in v1.
