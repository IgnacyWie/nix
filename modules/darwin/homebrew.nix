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
      "yabai"
      "skhd"
    ];

    casks = [
      "ghostty"
      "zen"
      "raycast"
      "karabiner-elements"
      "orbstack"
    ];
  };
}
