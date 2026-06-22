{
  config,
  lib,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
  stateDir = "${homeDirectory}/.local/state/todo-business-sync";
  logDir = "${homeDirectory}/Library/Logs/todo-business-sync";
in
{
  home.activation.createTodoBusinessSyncDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg stateDir}
    run mkdir -p ${lib.escapeShellArg logDir}
  '';

  home.file.".local/bin/todo-business-sync" = {
    executable = true;
    force = true;
    source = ../../scripts/todo-business-sync;
  };

  launchd.agents.todo-business-sync = {
    enable = true;
    config = {
      ProgramArguments = [
        "${homeDirectory}/.local/bin/todo-business-sync"
      ];
      RunAtLoad = true;
      StartInterval = 600;
      ProcessType = "Background";
      EnvironmentVariables = {
        PATH = "/opt/homebrew/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      StandardOutPath = "${logDir}/launchd-stdout.log";
      StandardErrorPath = "${logDir}/launchd-stderr.log";
    };
  };
}
