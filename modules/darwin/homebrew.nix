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
      "yqrashawn/goku"
    ];

    brews = [
      "goku"
      "mas"
      "nvm"
      "tmux"
    ];

    casks = [
      "wispr-flow"
      "bitwarden"
      "displaylink"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "loom"
      "orbstack"
      "raycast"
      "sf-symbols"
      "tailscale-app"
      "zen"
      "firefox@developer-edition"
    ];

    masApps = {
      Flighty = 1358823008;
      WhatsApp = 310633997;
    };

    extraConfig = ''
      brew "koekeishiya/formulae/yabai", trusted: true
      brew "koekeishiya/formulae/skhd", trusted: true
    '';
  };
}
