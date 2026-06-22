{ config, lib, ... }:

{
  options.personal.omlx.initialModel = lib.mkOption {
    type = lib.types.str;
    default = "mlx-community/Qwen2.5-1.5B-Instruct-4bit";
    description = ''
      Initial small instruct model preference for eta's host-managed OMLX
      Local Model Runtime. This is an operational preference, not a recovery
      dependency.
    '';
  };

  config = {
    environment.variables.OMLX_INITIAL_MODEL = lib.mkDefault config.personal.omlx.initialModel;

    homebrew = {
      enable = true;

      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "none";
      };

      extraConfig = ''
        tap "jundot/omlx", "https://github.com/jundot/omlx", trusted: true
        tap "ossianhempel/tap", "https://github.com/ossianhempel/homebrew-tap", trusted: true
        tap "steipete/tap", "https://github.com/steipete/homebrew-tap", trusted: true
        brew "omlx", trusted: true
        brew "ossianhempel/tap/things3-cli", trusted: true
        brew "steipete/tap/imsg", trusted: true
      '';
    };
  };
}
