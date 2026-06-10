{ pkgs, ... }:

{
  imports = [
    ./homebrew.nix
  ];

  fonts.packages = [
    pkgs.nerd-fonts.meslo-lg
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.ssl-cert-file = "/etc/ssl/cert.pem";

  nix.settings.trusted-users = [
    "root"
    "@admin"
    "ignacywielogorski"
  ];

  programs.zsh.enable = true;

  security.pam.services.sudo_local = {
    reattach = true;
    touchIdAuth = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  system.stateVersion = 6;
}
