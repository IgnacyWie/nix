{ pkgs, ... }:

{
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

  system.stateVersion = 6;
}
