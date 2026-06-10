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
    aider-chat
    bat
    blueutil
    bun
    chafa
    claude-code
    codex
    corepack
    coreutils
    curl
    eza
    fd
    fzf
    gawk
    gh
    git
    gemini-cli
    glow
    gnused
    htop
    just
    jq
    lazygit
    lazysql
    neovim
    opencode
    posting
    restic
    ripgrep
    terminal-notifier
    tree
    typst
    uv
    wget
    zoxide
  ];
}
