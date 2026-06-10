{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      branch.sort = "-committerdate";
      commit.gpgSign = false;
      core.editor = "nvim";
      fetch.prune = true;
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rerere.enabled = true;
      user = {
        email = "ignacywie@icloud.com";
        name = "Ignacy Wielogorski";
      };
    };
  };
}
