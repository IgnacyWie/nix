{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
  dataDir = "${homeDirectory}/.local/share/spolszcz";
  python = "${pkgs.python3}/bin/python3";

  workflowSource = ../../config/spolszcz/Spolszcz.workflow;
  servicesDir = "${homeDirectory}/Library/Services";
  workflowTarget = "${servicesDir}/Spolszcz.workflow";
in
{
  # Offline restorer + its frequency-built dictionary, kept side by side so the
  # script finds the dictionary relative to itself.
  home.file."${dataDir}/restore.py".source = ../../config/spolszcz/restore.py;
  home.file."${dataDir}/words.tsv".source = ../../config/spolszcz/words.tsv;

  # CLI wrapper, also invoked by the macOS Quick Action and the Hammerspoon
  # hotkey. Reads text on stdin, writes the diacritised text to stdout.
  home.file.".local/scripts/spolszcz" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      export SPOLSZCZ_DICT=${lib.escapeShellArg "${dataDir}/words.tsv"}
      exec ${lib.escapeShellArg python} ${lib.escapeShellArg "${dataDir}/restore.py"} "$@"
    '';
  };

  # Install the right-click Quick Action into ~/Library/Services. It is copied
  # (not symlinked) because Launch Services ignores read-only /nix/store bundles,
  # then the Services cache is refreshed so it appears without a re-login.
  home.activation.installSpolszczService = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg servicesDir}
    run rm -rf ${lib.escapeShellArg workflowTarget}
    run cp -R ${workflowSource} ${lib.escapeShellArg workflowTarget}
    run chmod -R u+w ${lib.escapeShellArg workflowTarget}
    if [ -x /System/Library/CoreServices/pbs ]; then
      run /System/Library/CoreServices/pbs -update || true
    fi
  '';
}
