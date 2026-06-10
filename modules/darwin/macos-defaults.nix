{ ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      launchanim = false;
      magnification = false;
      mru-spaces = false;
      orientation = "left";
      show-recents = false;
      showAppExposeGestureEnabled = true;
      showDesktopGestureEnabled = true;
      showhidden = true;
      showMissionControlGestureEnabled = true;
      slow-motion-allowed = false;
      tilesize = 67;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";
      NewWindowTarget = "Other";
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
      AppleShowScrollBars = "Always";
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 30;
      KeyRepeat = 2;
      NSAutomaticWindowAnimationsEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSTableViewDefaultSizeMode = 2;
      NSWindowResizeTime = 0.001;
      NSWindowShouldDragOnGesture = true;
      _HIHideMenuBar = false;
      "com.apple.springing.enabled" = true;
    };

    universalaccess = {
      reduceMotion = true;
      reduceTransparency = true;
    };

    trackpad = {
      Clicking = true;
      ForceSuppressed = true;
      TrackpadRightClick = true;
      TrackpadFourFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerDrag = false;
      TrackpadThreeFingerHorizSwipeGesture = 2;
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
      disable-shadow = true;
      location = "/Users/ignacywielogorski/Pictures/Screenshots";
      save-selections = true;
      show-thumbnail = false;
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
          NSQuitAlwaysKeepsWindows = false;
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

        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            "64" = {
              enabled = false;
              value = {
                parameters = [
                  32
                  49
                  1048576
                ];
                type = "standard";
              };
            };
          };
        };
      };

    CustomSystemPreferences = {
      "/Library/Preferences/com.apple.loginwindow" = {
        TALLogoutSavesState = false;
      };
    };
  };
}
