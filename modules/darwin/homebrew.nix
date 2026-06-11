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
    ];

    casks = [
      "wispr-flow"
      "bitwarden"
      "displaylink"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "keka"
      "loom"
      "orbstack"
      "pearcleaner"
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
