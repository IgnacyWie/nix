{
  config,
  lib,
  pkgs,
  ...
}:

let
  userName = "ignacywielogorski";
  homeDirectory = "/Users/${userName}";
  serviceDefinitionRoot = "${homeDirectory}/nix/services/eta";
  resticRepository = "b2:eta-home-server-restic:eta";
  resticEnvironmentFile = "${homeDirectory}/.config/eta-restic-backup/env";
  backupExcludes = ../../.. + "/eta-backup-excludes.txt";

  authorizedSshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuZfw+lgWssLrdPbEO9rJOa4L5CiLkoELiiSjTyw6J7cicPNgnEZy9WW/UO1Vr5lOzACnMQwQHHktCKiS3fBG7dPjP6KdqPJOrhgM56Lk4eovN3SsTY+Zr+8mcQQZXrVkv023PaKMFeGtedvzVfOOpimf3jRHhjOntz9MyHqZWkvd0E9E6VnvIpNbw9+KG2/oUjjRHA9hyH+JzcY31EwWnjHV1qEMOSk/3f/NyMg6JuQxCixzd8FkS+bI8BWX/JaafjNTJib2YseS8kWSmy6bafg5YqQ4wJpAKK8ZG6zxoXYrTcL3VgPqYvQJcbRbH+Zfxg7UiWYExomImq0lAALwcWRfMq8gKCyTtb1zhc+qR6kcdKs+dOVp5v0+MWpJdJwvRqnk7TIrHS2ME7r8qFYrVF5ooXKXT9nB2rTIdS4XvOvouQBhE3p/FypCR5wFXyHy7voBU5oAVC4VjX3wDnF/FW+xsFFVmmvdtvx2XVFTUCjyhisUT/HqOZ0KrPnmLEIE= ignacywielogorski@Ignacys-MacBook-Air.local";

  etaService = pkgs.writeShellApplication {
    name = "eta-service";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.docker-compose
      pkgs.findutils
    ];
    text = ''
      set -euo pipefail

      service_definition_root="''${ETA_SERVICE_DEFINITION_ROOT:-$HOME/nix/services/eta}"

      usage() {
        cat <<'USAGE'
      eta-service: Service Control Commands run authoritatively on eta-cloud.

      Usage:
        eta-service list
        eta-service inspect <stack>
        eta-service <stack> config
        eta-service <stack> ps
        eta-service <stack> logs [args...]
        eta-service <stack> pull [args...]
        eta-service <stack> restart [args...]
        eta-service <stack> start [args...]
        eta-service <stack> stop [args...]
        eta-service <stack> up [args...]
        eta-service <stack> down [args...]

      Service stacks are directories under ~/nix/services/eta that contain
      compose.yaml, compose.yml, docker-compose.yaml, or docker-compose.yml.
      USAGE
      }

      find_compose_file() {
        local stack_dir=$1

        for file in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
          if [[ -f "$stack_dir/$file" ]]; then
            printf '%s\n' "$stack_dir/$file"
            return 0
          fi
        done

        return 1
      }

      list_stacks() {
        if [[ ! -d "$service_definition_root" ]]; then
          return 0
        fi

        find "$service_definition_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r stack_dir; do
          if find_compose_file "$stack_dir" >/dev/null; then
            basename "$stack_dir"
          fi
        done
      }

      inspect_stack() {
        local stack=$1
        local stack_dir="$service_definition_root/$stack"
        if [[ ! -d "$stack_dir" ]]; then
          printf 'eta-service: unknown stack: %s\n' "$stack" >&2
          printf 'Known stacks:\n' >&2
          list_stacks >&2
          exit 1
        fi

        local compose_file
        if ! compose_file=$(find_compose_file "$stack_dir"); then
          printf 'eta-service: %s has no Compose file\n' "$stack_dir" >&2
          exit 1
        fi

        printf 'stack=%s\n' "$stack"
        printf 'project=%s\n' "$stack"
        printf 'directory=%s\n' "$stack_dir"
        printf 'compose_file=%s\n' "$compose_file"
      }

      run_compose() {
        local stack=$1
        local command=$2
        shift 2

        local stack_dir="$service_definition_root/$stack"
        if [[ ! -d "$stack_dir" ]]; then
          printf 'eta-service: unknown stack: %s\n' "$stack" >&2
          printf 'Known stacks:\n' >&2
          list_stacks >&2
          exit 1
        fi

        local compose_file
        if ! compose_file=$(find_compose_file "$stack_dir"); then
          printf 'eta-service: %s has no Compose file\n' "$stack_dir" >&2
          exit 1
        fi

        case "$command" in
          config)
            exec docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" config "$@"
            ;;
          ps)
            exec docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" ps "$@"
            ;;
          logs)
            exec docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" logs "$@"
            ;;
          pull)
            exec docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" pull "$@"
            ;;
          restart)
            exec docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" restart "$@"
            ;;
          start | up)
            exec docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" up -d "$@"
            ;;
          stop)
            exec docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" stop "$@"
            ;;
          down)
            exec docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" down "$@"
            ;;
          *)
            usage >&2
            exit 64
            ;;
        esac
      }

      case "''${1:-}" in
        "" | -h | --help)
          usage
          ;;
        list)
          list_stacks
          ;;
        inspect)
          if [[ $# -ne 2 ]]; then
            usage >&2
            exit 64
          fi

          inspect_stack "$2"
          ;;
        *)
          if [[ $# -lt 2 ]]; then
            usage >&2
            exit 64
          fi

          run_compose "$@"
          ;;
      esac
    '';
  };

  etaResticBackup = pkgs.writeShellApplication {
    name = "eta-restic-backup";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.docker
      pkgs.gnugrep
      pkgs.restic
      pkgs.sqlite
    ];
    text = ''
      set -euo pipefail

      export RESTIC_REPOSITORY=${lib.escapeShellArg resticRepository}

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

      add_backup_path "$HOME/Services"
      add_backup_path "$HOME/nix/services/eta"
      add_backup_path "$HOME/nix/backup.md"
      add_backup_path "$HOME/nix/manual-steps.md"
      add_backup_path "$HOME/nix/CONTEXT.md"
      add_backup_path "$HOME/nix/docs/adr"

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

      retry 3 300 backup restic backup "''${backup_args[@]}" --exclude-file ${lib.escapeShellArg backupExcludes}
      touch "$success_marker"
      retry 2 300 retention restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
    '';
  };

  etaResticRestoreLatest = pkgs.writeShellApplication {
    name = "eta-restic-restore-latest";
    runtimeInputs = [ pkgs.restic ];
    text = ''
      set -euo pipefail

      target="''${1:-/}"
      export RESTIC_REPOSITORY=${lib.escapeShellArg resticRepository}

      printf 'This restores the latest eta Home Server snapshot into: %s\n' "$target" >&2
      printf 'Type restore to continue: ' >&2
      read -r confirmation
      if [ "$confirmation" != "restore" ]; then
        printf 'Aborted.\n' >&2
        exit 1
      fi

      exec restic restore latest --target "$target"
    '';
  };
in
{
  imports = [ ];

  networking.hostName = "eta-cloud";
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.grub.enable = lib.mkDefault true;
  boot.loader.grub.devices = lib.mkDefault [ "/dev/nvme0n1" ];

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # No RAID/ZFS mirror is declared for eta-cloud. The first Hetzner version is
  # intentionally single-disk/simple because Backblaze B2 Restic is the recovery
  # source of truth for service data. Replace this with generated hardware and
  # filesystem configuration after provisioning the exact auction server.

  users.users.${userName} = {
    isNormalUser = true;
    home = homeDirectory;
    createHome = true;
    extraGroups = [
      "docker"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [ authorizedSshKey ];
  };

  security.sudo.wheelNeedsPassword = true;

  environment.systemPackages = [
    etaResticBackup
    etaResticRestoreLatest
    etaService
    pkgs.curl
    pkgs.docker-compose
    pkgs.fd
    pkgs.fzf
    pkgs.git
    pkgs.jq
    pkgs.restic
    pkgs.ripgrep
    pkgs.tailscale
    pkgs.tmux
    pkgs.tree
    pkgs.wget
  ];

  environment.shellAliases = {
    eta-backup = "eta-restic-backup";
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${homeDirectory}/Services 0755 ${userName} users -"
    "d ${serviceDefinitionRoot} 0755 ${userName} users -"
    "d ${homeDirectory}/.config/eta-restic-backup 0700 ${userName} users -"
    "d ${homeDirectory}/.local/state/eta-restic-backup 0755 ${userName} users -"
  ];

  systemd.services.eta-restic-backup = {
    description = "eta-cloud Home Server Restic backup to Backblaze B2";
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = userName;
      Group = "users";
      WorkingDirectory = homeDirectory;
      EnvironmentFile = resticEnvironmentFile;
      ExecStart = "${lib.getExe etaResticBackup} --scheduled";
    };
  };

  systemd.timers.eta-restic-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15m";
      OnCalendar = "03:00";
      OnUnitActiveSec = "6h";
      Persistent = true;
      Unit = "eta-restic-backup.service";
    };
  };

  system.stateVersion = "25.11";
}
