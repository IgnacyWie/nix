{ ... }:

{
  xdg.configFile = {
    "karabiner.edn".source = ../../config/karabiner.edn;
    "karabiner/karabiner.json".source = ../../config/karabiner/karabiner.json;
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
