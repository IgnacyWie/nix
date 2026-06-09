{
  pkgs,
  ...
}:

{
  networking.hostName = "gamma";
  networking.computerName = "gamma";
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
    git
    vim
  ];
}
