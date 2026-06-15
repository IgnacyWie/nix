{ config, ... }:

let
  homeDirectory = config.home.homeDirectory;
in
{
  home.file.".hammerspoon/init.lua" = {
    source = ../../config/hammerspoon/init.lua;
    force = true;
  };

  home.file.".hammerspoon/gamma-backup.lua" = {
    source = ../../config/hammerspoon/gamma-backup.lua;
    force = true;
  };

  home.file.".hammerspoon/wifi.lua" = {
    source = ../../config/hammerspoon/wifi.lua;
    force = true;
  };

  launchd.agents.hammerspoon = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-ga"
        "Hammerspoon"
      ];
      RunAtLoad = true;
      StartInterval = 3600;
      StandardOutPath = "${homeDirectory}/Library/Logs/hammerspoon-launchd.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/hammerspoon-launchd.log";
    };
  };
}
