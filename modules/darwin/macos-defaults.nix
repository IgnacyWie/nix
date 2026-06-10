{ ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
      autohide-time-modifier = 0.0;
      launchanim = false;
      magnification = false;
      mru-spaces = false;
      orientation = "left";
      show-recents = false;
      showAppExposeGestureEnabled = true;
      showDesktopGestureEnabled = true;
      showMissionControlGestureEnabled = true;
      tilesize = 67;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";
      NewWindowTarget = "Home";
      NewWindowTargetPath = "file:///Users/ignacywielogorski/";
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop = true;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = true;
      ShowStatusBar = true;
      _FXEnableColumnAutoSizing = true;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
      _FXSortFoldersFirstOnDesktop = true;
    };

    NSGlobalDomain = {
      AppleEnableSwipeNavigateWithScrolls = false;
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 30;
      KeyRepeat = 2;
      NSAutomaticWindowAnimationsEnabled = false;
      NSTableViewDefaultSizeMode = 2;
      NSWindowResizeTime = 0.001;
      NSWindowShouldDragOnGesture = true;
      _HIHideMenuBar = false;
      "com.apple.springing.enabled" = true;
    };

    universalaccess = {
      reduceMotion = true;
    };

    WindowManager = {
      AppWindowGroupingBehavior = true;
      AutoHide = false;
      EnableStandardClickToShowDesktop = false;
      EnableTiledWindowMargins = false;
      GloballyEnabled = false;
      HideDesktop = true;
      StageManagerHideWidgets = true;
      StandardHideDesktopIcons = true;
      StandardHideWidgets = true;
    };

    screencapture = {
      type = "png";
    };

    CustomUserPreferences =
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
        NSGlobalDomain = {
          AppleMiniaturizeOnDoubleClick = false;
          AppleReduceDesktopTinting = true;
          QLPanelAnimationDuration = 0;
        };

        "com.apple.HIToolbox" = {
          AppleEnabledInputSources = [
            dvorakQwerty
            polishPro
          ];
          AppleSelectedInputSources = [
            dvorakQwerty
          ];
        };
      };
  };
}
