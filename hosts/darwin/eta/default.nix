{ pkgs, ... }:

{
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
    tree
    wget
  ];
}
