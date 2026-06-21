{ pkgs, ... }:

{
  imports = [
    ./homebrew.nix
  ];

  networking.hostName = "eta";
  networking.computerName = "eta";
  system.primaryUser = "ignacywielogorski";

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  users.users.ignacywielogorski = {
    name = "ignacywielogorski";
    home = "/Users/ignacywielogorski";
  };

  security.pam.services.sudo_local.enable = false;

  environment.systemPackages = with pkgs; [
    curl
    docker-compose
    fd
    fzf
    gh
    git
    jq
    restic
    ripgrep
    tailscale
    tmux
    tree
    wget
  ];
}
