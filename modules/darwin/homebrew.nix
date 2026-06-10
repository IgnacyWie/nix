{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    taps = [
      "koekeishiya/formulae"
    ];

    brews = [
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
      "whatsapp"
      "zen"
      "firefox@developer-edition"
    ];

    extraConfig = ''
      brew "koekeishiya/formulae/yabai", trusted: true
      brew "koekeishiya/formulae/skhd", trusted: true
    '';
  };
}
