{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
  assistantAppRoot = "${homeDirectory}/nix/apps/personal-assistant";
  assistantDataRoot = "${homeDirectory}/Services/data/personal-assistant";
  assistantLogRoot = "${homeDirectory}/Library/Logs/personal-assistant";
  nodeBin = "${pkgs.nodejs}/bin/node";
in
{
  home.activation.createPersonalAssistantDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg assistantDataRoot}
    run chmod 700 ${lib.escapeShellArg assistantDataRoot}
    run mkdir -p ${lib.escapeShellArg assistantLogRoot}
  '';

  launchd.agents.eta-personal-assistant = {
    enable = true;
    config = {
      ProgramArguments = [
        nodeBin
        "${assistantAppRoot}/src/main.mjs"
      ];
      KeepAlive = true;
      ProcessType = "Background";
      RunAtLoad = true;
      StandardOutPath = "${assistantLogRoot}/launchd-stdout.log";
      StandardErrorPath = "${assistantLogRoot}/launchd-stderr.log";
      WorkingDirectory = assistantAppRoot;
      EnvironmentVariables = {
        NODE_ENV = "production";
      };
    };
  };
}
