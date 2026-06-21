{ modulesPath, ... }:

let
  ignacyPublicSshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuZfw+lgWssLrdPbEO9rJOa4L5CiLkoELiiSjTyw6J7cicPNgnEZy9WW/UO1Vr5lOzACnMQwQHHktCKiS3fBG7dPjP6KdqPJOrhgM56Lk4eovN3SsTY+Zr+8mcQQZXrVkv023PaKMFeGtedvzVfOOpimf3jRHhjOntz9MyHqZWkvd0E9E6VnvIpNbw9+KG2/oUjjRHA9hyH+JzcY31EwWnjHV1qEMOSk/3f/NyMg6JuQxCixzd8FkS+bI8BWX/JaafjNTJib2YseS8kWSmy6bafg5YqQ4wJpAKK8ZG6zxoXYrTcL3VgPqYvQJcbRbH+Zfxg7UiWYExomImq0lAALwcWRfMq8gKCyTtb1zhc+qR6kcdKs+dOVp5v0+MWpJdJwvRqnk7TIrHS2ME7r8qFYrVF5ooXKXT9nB2rTIdS4XvOvouQBhE3p/FypCR5wFXyHy7voBU5oAVC4VjX3wDnF/FW+xsFFVmmvdtvx2XVFTUCjyhisUT/HqOZ0KrPnmLEIE= ignacywielogorski@Ignacys-MacBook-Air.local";
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Force the live ISO to copy itself entirely into RAM on boot
  boot.kernelParams = [ "copytoram" ];

  boot.zfs.forceImportRoot = false;

  networking.hostName = "omega";
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  users.users.nixos.openssh.authorizedKeys.keys = [
    ignacyPublicSshKey
  ];

  image.fileName = "nixos-omega-installer.iso";
  system.stateVersion = "25.11";
}
