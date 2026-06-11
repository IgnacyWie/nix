{ lib, ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };

    taps = [
      "homebrew-zathura/zathura"
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
      "onlyoffice"
    ];

    masApps = {
      Bitwarden = 1352778147;
      Flighty = 1358823008;
      Amphetamine = 937984704;
      WhatsApp = 310633997;
    };

    extraConfig = ''
      brew "homebrew-zathura/zathura/girara", trusted: true
      brew "homebrew-zathura/zathura/synctex", trusted: true
      brew "homebrew-zathura/zathura/zathura", trusted: true
      brew "homebrew-zathura/zathura/zathura-pdf-poppler", trusted: true
      brew "koekeishiya/formulae/yabai", trusted: true
      brew "koekeishiya/formulae/skhd", trusted: true
    '';
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    zathura_prefix="/opt/homebrew/opt/zathura"
    zathura_poppler_plugin="/opt/homebrew/opt/zathura-pdf-poppler/libpdf-poppler.dylib"

    if [ -e "$zathura_poppler_plugin" ]; then
      mkdir -p "$zathura_prefix/lib/zathura"
      ln -sfn "$zathura_poppler_plugin" "$zathura_prefix/lib/zathura/libpdf-poppler.dylib"
    fi
  '';
}
