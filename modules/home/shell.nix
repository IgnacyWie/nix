{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;

  shellNavigationAliases = {
    b = "brew";
    downloads = "cd ~/Downloads";
    developer = "cd ~/Developer";
    nano = "nvim";
    o = "open .";
    t = "tmux a";
    tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    v = "nvim";
  };

  gitAliases = {
    g = "git";
  };

  nixAliases = {
    nix-apply-gamma = "~/nix/scripts/apply-gamma";
    nix-check = "~/nix/scripts/check";
    nix-fmt = "~/nix/scripts/fmt";
  };

  projectAliases = {
    claude = "claude --permission-mode bypassPermissions";
    codex = "codex --dangerously-bypass-approvals-and-sandbox";
    deploy = "vercel --prod";
    dev = "pnpm run dev";
    revdojo = "./revisiondojo.sh";
    ruflo = "npx ruflo@latest";
    sm = "ssh mini";
    tc = "typst compile";
    tw = "typst watch";
    wallet-compile = "cd ~/Developer/Imported/GymPass/backend && npm run dev";
    ziki = "./ziki.sh";
  };
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "notify" ''
      set -eu

      sound="/System/Library/Sounds/Submarine.aiff"
      assertions="$HOME/Library/DoNotDisturb/DB/Assertions.json"
      dnd_active=0

      if [ -r "$assertions" ] && /usr/bin/grep -q '"storeAssertionRecords"' "$assertions"; then
        dnd_active=1
      elif /usr/bin/defaults -currentHost read com.apple.notificationcenterui doNotDisturb 2>/dev/null | /usr/bin/grep -q '^1$'; then
        dnd_active=1
      fi

      if [ "$dnd_active" = 1 ]; then
        /usr/bin/afplay "$sound"
      else
        /usr/bin/afplay "$sound" -v 10
      fi
    '')
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/scripts"
  ];

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LANGUAGE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    NVM_DIR = "$HOME/.nvm";
  };

  home.activation.createWorkstationDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/Developer"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/typst"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.nvm"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.local/bin"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.local/scripts"}
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };

    shellAliases = shellNavigationAliases // gitAliases // nixAliases // projectAliases;

    initContent = ''
      unset MAILCHECK

      path=(''${path:#/opt/homebrew/opt/node@20/bin})
      path=(''${path:#$HOME/Library/pnpm})
      export PATH

      if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
        . "/opt/homebrew/opt/nvm/nvm.sh"
      fi

      if [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
        . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
      fi

      bindkey -s '^F' 'tmux-sessionizer\n'
      bindkey -s '^G' 'typst-smart-open\n'
    '';
  };
}
