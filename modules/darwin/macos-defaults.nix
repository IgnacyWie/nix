{ ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
      expose-group-apps = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };

    screencapture = {
      disable-shadow = true;
      include-date = true;
      type = "png";
    };

    CustomUserPreferences."com.apple.HIToolbox" =
      let
        dvorakQwerty = {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 16301;
          "KeyboardLayout Name" = "DVORAK - QWERTY CMD";
        };
        polishPro = {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 30788;
          "KeyboardLayout Name" = "Polish Pro";
        };
      in
      {
        AppleEnabledInputSources = [
          dvorakQwerty
          polishPro
        ];
        AppleSelectedInputSources = [
          dvorakQwerty
        ];
      };
  };
}
