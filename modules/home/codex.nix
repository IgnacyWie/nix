{ pkgs, ... }:

{
  home.file.".codex/config.toml" = {
    source = ../../config/codex/config.toml;
    force = true;
  };

  home.file.".codex/hooks.json" = {
    source = ../../config/codex/hooks.json;
    force = true;
  };

  home.packages = [
    (pkgs.writeShellScriptBin "codex" ''
      set -eu

      codex_bin="/opt/homebrew/bin/codex"

      if [ ! -x "$codex_bin" ]; then
        printf '%s\n' "codex: expected executable not found at $codex_bin" >&2
        exit 127
      fi

      exec /usr/bin/caffeinate -dims -t 3600 "$codex_bin" --dangerously-bypass-approvals-and-sandbox "$@"
    '')
  ];
}
