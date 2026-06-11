{ pkgs, ... }:

{
  imports = [
    ./base.nix
    ./default-apps.nix
    ./homebrew.nix
    ./macos-defaults.nix
  ];

  security.pam.services.sudo_local = {
    reattach = true;
    touchIdAuth = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
