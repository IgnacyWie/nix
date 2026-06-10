{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;

  resticRepository = "b2:gamma-backup-restic:gamma";

  keychainServices = {
    b2AccountId = "restic-gamma-b2-account-id";
    b2AccountKey = "restic-gamma-b2-account-key";
    resticPassword = "restic-gamma-password";
  };

  backupPaths = [
    "${homeDirectory}/Documents"
    "${homeDirectory}/Desktop"
    "${homeDirectory}/Pictures"
    "${homeDirectory}/Projects"
    "${homeDirectory}/Developer"
    "${homeDirectory}/Downloads"
    "${homeDirectory}/typst"
    "${homeDirectory}/nix"
    "${homeDirectory}/.ssh"
  ];

  backupPathScript = lib.concatMapStringsSep "\n" (
    path: "add_backup_path ${lib.escapeShellArg path}"
  ) backupPaths;

  backupCommand = pkgs.writeShellApplication {
    name = "gamma-restic-backup";
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

      restic backup "''${backup_args[@]}" --exclude-file ${lib.escapeShellArg ../../backup-excludes.txt}
      restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
    '';
  };
in
{
  home.packages = [
    backupCommand
  ];

  home.activation.createGammaResticBackupLogDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/Library/Logs/gamma-restic-backup"}
  '';

  launchd.agents.gamma-restic-backup = {
    enable = true;
    config = {
      ProgramArguments = [
        (lib.getExe backupCommand)
      ];
      ProcessType = "Background";
      StartCalendarInterval = [
        {
          Hour = 20;
          Minute = 0;
        }
      ];
      StandardOutPath = "${homeDirectory}/Library/Logs/gamma-restic-backup/launchd-stdout.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/gamma-restic-backup/launchd-stderr.log";
    };
  };
}
