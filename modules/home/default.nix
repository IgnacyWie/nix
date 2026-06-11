{ ... }:

{
  imports = [
    ./claude.nix
    ./codex.nix
    ./git.nix
    ./ghostty.nix
    ./neovim.nix
    ./scripts.nix
    ./shell.nix
    ./ssh.nix
    ./tmux.nix
    ./window-management.nix
  ];

  home = {
    username = "ignacywielogorski";
    homeDirectory = "/Users/ignacywielogorski";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
