{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
in
{
  home.file.".codex/hooks.json" = {
    source = ../../config/codex/hooks.json;
    force = true;
  };

  home.activation.installMutableCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.codex"}

    if [ -L ${lib.escapeShellArg "${homeDirectory}/.codex/config.toml"} ]; then
      run rm ${lib.escapeShellArg "${homeDirectory}/.codex/config.toml"}
    fi

    if [ ! -e ${lib.escapeShellArg "${homeDirectory}/.codex/config.toml"} ]; then
      run install -m 600 ${../../config/codex/config.toml} ${lib.escapeShellArg "${homeDirectory}/.codex/config.toml"}
    fi
  '';

  home.packages = [
    (pkgs.writeShellScriptBin "codex" ''
      set -eu

      pnpm_codex_bin="''${PNPM_HOME:-$HOME/.local/share/pnpm}/codex"
      homebrew_codex_bin="/opt/homebrew/bin/codex"

      if [ -x "$pnpm_codex_bin" ]; then
        codex_bin="$pnpm_codex_bin"
      elif [ -x "$homebrew_codex_bin" ]; then
        codex_bin="$homebrew_codex_bin"
      else
        printf '%s\n' "codex: expected executable not found at $pnpm_codex_bin or $homebrew_codex_bin" >&2
        exit 127
      fi

      exec /usr/bin/caffeinate -dims -t 3600 "$codex_bin" --dangerously-bypass-approvals-and-sandbox --dangerously-bypass-hook-trust "$@"
    '')
  ];
}
