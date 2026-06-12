{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;

  resticRepository = "b2:eta-home-server-restic:eta";

  keychainServices = {
    b2AccountId = "restic-eta-b2-account-id";
    b2AccountKey = "restic-eta-b2-account-key";
    resticPassword = "restic-eta-password";
  };

  backupPaths = [
    "${homeDirectory}/Services"
    "${homeDirectory}/nix/services/eta"
    "${homeDirectory}/nix/backup.md"
    "${homeDirectory}/nix/manual-steps.md"
    "${homeDirectory}/nix/CONTEXT.md"
    "${homeDirectory}/nix/docs/adr"
  ];

  backupPathScript = lib.concatMapStringsSep "\n" (
    path: "add_backup_path ${lib.escapeShellArg path}"
  ) backupPaths;

  backupCommand = pkgs.writeShellApplication {
    name = "eta-restic-backup";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.restic
    ];
    text = ''
      set -eu

      export RESTIC_REPOSITORY=${lib.escapeShellArg resticRepository}
      B2_ACCOUNT_ID="$(/usr/bin/security find-generic-password -a "$USER" -s ${lib.escapeShellArg keychainServices.b2AccountId} -w)"
      B2_ACCOUNT_KEY="$(/usr/bin/security find-generic-password -a "$USER" -s ${lib.escapeShellArg keychainServices.b2AccountKey} -w)"
      RESTIC_PASSWORD="$(/usr/bin/security find-generic-password -a "$USER" -s ${lib.escapeShellArg keychainServices.resticPassword} -w)"
      export B2_ACCOUNT_ID
      export B2_ACCOUNT_KEY
      export RESTIC_PASSWORD

      mode="manual"
      if [ "''${1:-}" = "--scheduled" ]; then
        mode="scheduled"
      elif [ "''${1:-}" != "" ]; then
        printf 'Usage: eta-restic-backup [--scheduled]\n' >&2
        exit 2
      fi

      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/eta-restic-backup"
      success_marker="$state_dir/last-success"
      mkdir -p "$state_dir"

      if [ "$mode" = "scheduled" ] && [ -e "$success_marker" ]; then
        if find "$success_marker" -mmin -1200 -print -quit | grep -q .; then
          printf 'Last successful backup is less than 20 hours old; skipping scheduled catch-up.\n'
          exit 0
        fi
      fi

      backup_args=()

      add_backup_path() {
        if [ -e "$1" ]; then
          backup_args+=("$1")
        else
          printf 'Skipping missing backup path: %s\n' "$1" >&2
        fi
      }

      ${backupPathScript}

      if [ "''${#backup_args[@]}" -eq 0 ]; then
        printf 'No backup paths exist; refusing to run restic with an empty scope.\n' >&2
        exit 1
      fi

      retry() {
        attempts="$1"
        delay_seconds="$2"
        description="$3"
        shift 3

        attempt=1
        while true; do
          printf 'Starting %s attempt %s/%s.\n' "$description" "$attempt" "$attempts"
          "$@" && return 0

          status="$?"
          if [ "$attempt" -ge "$attempts" ]; then
            printf '%s failed after %s attempts; last exit code: %s.\n' "$description" "$attempts" "$status" >&2
            return "$status"
          fi

          printf '%s failed with exit code %s; retrying in %s seconds.\n' "$description" "$status" "$delay_seconds" >&2
          sleep "$delay_seconds"
          attempt="$((attempt + 1))"
        done
      }

      retry 3 300 backup restic backup "''${backup_args[@]}" --exclude-file ${lib.escapeShellArg ../../eta-backup-excludes.txt}
      touch "$success_marker"
      retry 2 300 retention restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
    '';
  };
in
{
  home.packages = [
    backupCommand
  ];

  home.activation.createEtaResticBackupLogDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/Library/Logs/eta-restic-backup"}
  '';

  launchd.agents.eta-restic-backup = {
    enable = true;
    config = {
      ProgramArguments = [
        (lib.getExe backupCommand)
        "--scheduled"
      ];
      ProcessType = "Background";
      RunAtLoad = true;
      StartInterval = 21600;
      StartCalendarInterval = [
        {
          Hour = 3;
          Minute = 0;
        }
      ];
      StandardOutPath = "${homeDirectory}/Library/Logs/eta-restic-backup/launchd-stdout.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/eta-restic-backup/launchd-stderr.log";
    };
  };
}
