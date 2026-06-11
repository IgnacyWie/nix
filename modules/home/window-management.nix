{
  config,
  lib,
  ...
}:

let
  karabinerJsonSeed = ../../config/karabiner/karabiner.json;
  karabinerJsonPath = "${config.xdg.configHome}/karabiner/karabiner.json";
in

{
  home.activation.generateKarabinerJson = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    goku_bin="/opt/homebrew/bin/goku"
    if [ ! -x "$goku_bin" ]; then
      if command -v goku >/dev/null 2>&1; then
        goku_bin="$(command -v goku)"
      else
        printf 'error: goku is required to generate karabiner.json from karabiner.edn\n' >&2
        exit 1
      fi
    fi

    run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/karabiner"}
    if [ -L ${lib.escapeShellArg karabinerJsonPath} ]; then
      run rm ${lib.escapeShellArg karabinerJsonPath}
    fi

    run install -m 0644 ${karabinerJsonSeed} ${lib.escapeShellArg karabinerJsonPath}
    run env HOME=${lib.escapeShellArg config.home.homeDirectory} \
      GOKU_EDN_CONFIG_FILE=${lib.escapeShellArg "${config.xdg.configHome}/karabiner.edn"} \
      "$goku_bin"
  '';

  xdg.configFile = {
    "karabiner.edn".source = ../../config/karabiner.edn;
    "karabiner/assets/complex_modifications/1709730136.json".source =
      ../../config/karabiner/assets/complex_modifications/1709730136.json;
    "karabiner/assets/complex_modifications/zathura_cmd_q.json".source =
      ../../config/karabiner/assets/complex_modifications/zathura_cmd_q.json;

    "skhd/skhdrc".source = ../../config/skhd/skhdrc;

    "yabai/yabairc" = {
      executable = true;
      source = ../../config/yabai/yabairc;
    };
  };
}
