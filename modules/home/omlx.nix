{ config, lib, ... }:

let
  homeDirectory = config.home.homeDirectory;
  omlxBin = "/opt/homebrew/bin/omlx";
  omlxDataRoot = "${homeDirectory}/Services/data/omlx";
  omlxModelDir = "${omlxDataRoot}/models";
  omlxLogDir = "${omlxDataRoot}/logs";
in
{
  home.activation.createEtaOmlxDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg omlxDataRoot}
    run mkdir -p ${lib.escapeShellArg omlxModelDir}
    run mkdir -p ${lib.escapeShellArg omlxLogDir}
  '';

  launchd.agents.eta-omlx = {
    enable = true;
    config = {
      ProgramArguments = [
        omlxBin
        "serve"
        "--base-path"
        omlxDataRoot
        "--model-dir"
        omlxModelDir
        "--host"
        "127.0.0.1"
        "--port"
        "8000"
        "--log-level"
        "info"
        "--max-concurrent-requests"
        "1"
        "--memory-guard"
        "safe"
        "--no-cache"
      ];
      KeepAlive = true;
      ProcessType = "Background";
      RunAtLoad = true;
      StandardOutPath = "${omlxLogDir}/launchd-stdout.log";
      StandardErrorPath = "${omlxLogDir}/launchd-stderr.log";
      WorkingDirectory = omlxDataRoot;
    };
  };
}
