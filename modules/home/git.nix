{ config, ... }:

{
  home.file.".ssh/allowed_signers".text = ''
    ignacywie@icloud.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfJhSA0QU8AkhkNOCrO1EavY+D3tfcANzA90apm5LOd Github Access Developer Key
  '';

  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      branch.sort = "-committerdate";
      commit.gpgSign = true;
      core.editor = "nvim";
      fetch.prune = true;
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rerere.enabled = true;
      user = {
        email = "ignacywie@icloud.com";
        name = "IgnacyWie";
        signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfJhSA0QU8AkhkNOCrO1EavY+D3tfcANzA90apm5LOd Github Access Developer Key";
      };
    };
  };
}
