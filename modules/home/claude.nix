{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
  claudeSettings = ../../config/claude/settings.json;
  settingsPath = "${homeDirectory}/.claude/settings.json";
in
{
  home.activation.installClaudeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.claude"}

    if [ ! -e ${lib.escapeShellArg settingsPath} ]; then
      run install -m 600 ${claudeSettings} ${lib.escapeShellArg settingsPath}
    else
      tmp_file="$(mktemp)"
      ${pkgs.jq}/bin/jq -s '.[0] * { hooks: .[1].hooks }' ${lib.escapeShellArg settingsPath} ${claudeSettings} > "$tmp_file"
      run install -m 600 "$tmp_file" ${lib.escapeShellArg settingsPath}
      run rm "$tmp_file"
    fi
  '';
}
