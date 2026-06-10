{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };

    taps = [
      "koekeishiya/formulae"
    ];

    brews = [
      "mas"
      "nvm"
      "tmux"
    ];

    casks = [
      "bitwarden"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "loom"
      "orbstack"
      "raycast"
      "sf-symbols"
      "tailscale"
      "whatsapp"
      "zen"
      "firefox@developer-edition"
    ];

    masApps = {
      Flighty = 1358823008;
    };

    extraConfig = ''
      brew "koekeishiya/formulae/yabai", trusted: true
      brew "koekeishiya/formulae/skhd", trusted: true
    '';
  };
}
