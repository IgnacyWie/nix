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
      # Goku depends on joker, but Homebrew bundle cleanup can try to remove
      # an old tapped joker keg before it has reconciled Goku's dependency.
      # Keep joker explicit so apply-gamma cleanup stays dependency-safe.
      "joker"
      "mas"
      "nvm"
    ];

    casks = [
      "wispr-flow"
      "monitorcontrol" # Tool for controlling external monitor brightness, contrast, and volume. Useful for my 49 Inch LG Ultrawide.
      "displaylink" # Tool for using DisplayLink USB graphics adapters. Required for my 49 Inch LG Ultrawide.
      "jordanbaird-ice" # Tool for hiding unused things from the menu bar
      "ghostty"
      "google-chrome"
      "hammerspoon"
      "karabiner-elements"
      "keka" # Faster and more powerful alternative to the built-in Archive Utility for extracting compressed files.
      "loom"
      "orbstack" # Docker alternative for Apple Silicon, with better performance and native support for Apple Silicon.
      "pearcleaner"
      "raycast"
      "sf-symbols"
      "tailscale-app"
      "zen"
      "firefox@developer-edition"
      "onlyoffice" # Open-source office suite, good for editing documents created in Microsoft Office.
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
      tap "jundot/omlx", "https://github.com/jundot/omlx", trusted: true
      brew "omlx", trusted: true
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
