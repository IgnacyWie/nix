{
  config,
  lib,
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
