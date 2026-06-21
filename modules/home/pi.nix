{ pkgs, ... }:

let
  pi-coding-agent = pkgs.callPackage ../../packages/pi-coding-agent.nix { };
in
{
  home.packages = [
    pi-coding-agent
  ];
}
