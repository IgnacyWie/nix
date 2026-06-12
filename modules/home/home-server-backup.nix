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
      pkgs.sqlite
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

      create_sqlite_dump() {
        description="$1"
        source_db="$2"
        dump_db="$3"

        if [ ! -f "$source_db" ]; then
          printf 'Skipping %s SQLite dump; missing database: %s\n' "$description" "$source_db" >&2
          return 0
        fi

        dump_dir="$(dirname "$dump_db")"
        mkdir -p "$dump_dir"
        tmp_db="$dump_db.tmp"
        rm -f "$tmp_db"
        sqlite3 "$source_db" ".backup '$tmp_db'"
        mv "$tmp_db" "$dump_db"
        printf 'Created %s SQLite dump: %s\n' "$description" "$dump_db"
      }

      create_postgres_dump() {
        description="$1"
        container="$2"
        dump_path="$3"

        if ! command -v docker >/dev/null 2>&1; then
          printf 'Skipping %s Postgres dump; docker command is unavailable.\n' "$description" >&2
          return 0
        fi

        if ! docker container inspect "$container" >/dev/null 2>&1; then
          printf 'Skipping %s Postgres dump; missing container: %s\n' "$description" "$container" >&2
          return 0
        fi

        dump_dir="$(dirname "$dump_path")"
        mkdir -p "$dump_dir"
        tmp_dump="$dump_path.tmp"
        rm -f "$tmp_dump"
        if docker exec "$container" sh -lc 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$tmp_dump"; then
          mv "$tmp_dump" "$dump_path"
          printf 'Created %s Postgres dump: %s\n' "$description" "$dump_path"
        else
          rm -f "$tmp_dump"
          printf 'Skipping %s Postgres dump; pg_dump failed.\n' "$description" >&2
          return 0
        fi
      }

      create_logical_dumps() {
        create_sqlite_dump Linkding \
          "$HOME/Services/data/linkding/db.sqlite3" \
          "$HOME/Services/dumps/linkding/linkding.sqlite3"
        create_sqlite_dump Paperless \
          "$HOME/Services/data/paperless/data/db.sqlite3" \
          "$HOME/Services/dumps/paperless/paperless.sqlite3"
        create_sqlite_dump HomeAssistant \
          "$HOME/Services/data/home-assistant/config/home-assistant_v2.db" \
          "$HOME/Services/dumps/home-assistant/home-assistant_v2.db"
        create_sqlite_dump Baikal \
          "$HOME/Services/data/baikal/specific/db/db.sqlite" \
          "$HOME/Services/dumps/baikal/db.sqlite"
        create_postgres_dump Immich immich_postgres \
          "$HOME/Services/dumps/immich/immich.dump"
      }

      create_logical_dumps
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
