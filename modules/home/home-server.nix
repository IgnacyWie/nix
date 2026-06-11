{
  config,
  lib,
  pkgs,
  ...
}:

let
  serviceDataRoot = "${config.home.homeDirectory}/Services";

  etaService = pkgs.writeShellScript "eta-service" ''
    set -euo pipefail

    service_root="''${ETA_SERVICE_ROOT:-$HOME/Services}"

    usage() {
      cat <<'USAGE'
    eta-service: Service Control Commands run authoritatively on eta.

    Usage:
      eta-service list
      eta-service <stack> config
      eta-service <stack> ps
      eta-service <stack> logs [args...]
      eta-service <stack> pull [args...]
      eta-service <stack> restart [args...]
      eta-service <stack> start [args...]
      eta-service <stack> stop [args...]
      eta-service <stack> up [args...]
      eta-service <stack> down [args...]

    Service stacks are directories under ~/Services that contain compose.yaml,
    compose.yml, docker-compose.yaml, or docker-compose.yml.
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
      if [[ ! -d "$service_root" ]]; then
        return 0
      fi

      find "$service_root" -mindepth 1 -maxdepth 1 -type d | sort | while read -r stack_dir; do
        if find_compose_file "$stack_dir" >/dev/null; then
          basename "$stack_dir"
        fi
      done
    }

    run_compose() {
      local stack=$1
      local command=$2
      shift 2

      local stack_dir="$service_root/$stack"
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
          exec docker-compose --project-directory "$stack_dir" --file "$compose_file" config "$@"
          ;;
        ps)
          exec docker-compose --project-directory "$stack_dir" --file "$compose_file" ps "$@"
          ;;
        logs)
          exec docker-compose --project-directory "$stack_dir" --file "$compose_file" logs "$@"
          ;;
        pull)
          exec docker-compose --project-directory "$stack_dir" --file "$compose_file" pull "$@"
          ;;
        restart)
          exec docker-compose --project-directory "$stack_dir" --file "$compose_file" restart "$@"
          ;;
        start | up)
          exec docker-compose --project-directory "$stack_dir" --file "$compose_file" up -d "$@"
          ;;
        stop)
          exec docker-compose --project-directory "$stack_dir" --file "$compose_file" stop "$@"
          ;;
        down)
          exec docker-compose --project-directory "$stack_dir" --file "$compose_file" down "$@"
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
      *)
        if [[ $# -lt 2 ]]; then
          usage >&2
          exit 64
        fi

        run_compose "$@"
        ;;
    esac
  '';
in
{
  home.activation.createHomeServerDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg serviceDataRoot}
  '';

  home.file.".local/bin/eta-service" = {
    executable = true;
    force = true;
    source = etaService;
  };
}
