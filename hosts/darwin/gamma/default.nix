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
    age
    bat
    bun
    bitwarden-cli
    chafa
    claude-code
    codex
    corepack
    coreutils
    curl
    eza
    fd
    ffmpeg
    fzf
    gawk
    gh
    git
    gemini-cli
    glow
    gnupg
    gnused
    google-cloud-sdk
    kubernetes-helm
    htop
    httpie
    imagemagick
    just
    jq
    k9s
    kubectl
    kustomize
    lazygit
    lazysql
    neovim
    opencode
    openssh
    pandoc
    pinentry_mac
    posting
    restic
    ripgrep
    sops
    tailscale
    terminal-notifier
    tree
    typst
    uv
    wget
    zoxide
  ];
}
