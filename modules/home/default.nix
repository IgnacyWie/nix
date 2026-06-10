{ ... }:

{
  imports = [
    ./backup.nix
    ./git.nix
    ./ghostty.nix
    ./scripts.nix
    ./shell.nix
    ./ssh.nix
    ./tmux.nix
  ];

  home = {
    username = "ignacywielogorski";
    homeDirectory = "/Users/ignacywielogorski";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
