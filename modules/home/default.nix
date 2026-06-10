{ ... }:

{
  imports = [
    ./backup.nix
  ];

  home = {
    username = "ignacywielogorski";
    homeDirectory = "/Users/ignacywielogorski";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
