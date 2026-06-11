{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gcc
    gnumake
    lua-language-server
    nil
    nodejs_24
    python3
    python3Packages.pytest
    stylua
    tree-sitter
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withRuby = true;
  };

  xdg.configFile."nvim" = {
    source = ../../config/nvim;
    recursive = true;
    force = true;
  };
}
