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
      "ghostty"
      "zen"
      "raycast"
      "karabiner-elements"
      "orbstack"
    ];

    extraConfig = ''
      brew "koekeishiya/formulae/yabai", trusted: true
      brew "koekeishiya/formulae/skhd", trusted: true
    '';
  };
}
