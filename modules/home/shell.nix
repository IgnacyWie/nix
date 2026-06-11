{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;

  tmuxGhostty = pkgs.tmux.overrideAttrs (_old: {
    version = "3.3a";
    src = pkgs.fetchurl {
      url = "https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz";
      hash = "sha256-5P00eEO9B3LE9I1t3mJbCxCbejgP8V2yHpfBGk3N+T8=";
    };
  });

  tmuxWrapper = pkgs.writeShellScript "tmux-wrapper" ''
    set -eu

    tmux_bin="${tmuxGhostty}/bin/tmux"

    if [ ! -x "$tmux_bin" ]; then
      printf 'tmux wrapper: expected pinned tmux at %s\n' "$tmux_bin" >&2
      exit 127
    fi

    command="''${1:-}"

    case "$command" in
      "" | a | attach | attach-session | new | new-session)
        if [ ! -t 0 ] || [ ! -t 1 ]; then
          /usr/bin/open -na Ghostty.app --args --term=xterm-256color -e "$tmux_bin" "$@"
          exit 0
        fi
        ;;
    esac

    exec "$tmux_bin" "$@"
  '';

  shellNavigationAliases = {
    b = "brew";
    downloads = "cd ~/Downloads";
    developer = "cd ~/Developer";
    nano = "nvim";
    o = "open .";
    t = "tmux a";
    tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    v = "nvim";
  };

  gitAliases = {
    g = "git";
  };

  nixAliases = {
    nix-apply-gamma = "~/nix/scripts/apply-gamma";
    nix-check = "~/nix/scripts/check";
    nix-fmt = "~/nix/scripts/fmt";
  };

  projectAliases = {
    deploy = "vercel --prod";
    dev = "pnpm run dev";
    revdojo = "./revisiondojo.sh";
    ruflo = "npx ruflo@latest";
    sm = "ssh mini";
    tc = "typst compile";
    tw = "typst watch";
    wallet-compile = "cd ~/Developer/Imported/GymPass/backend && npm run dev";
    ziki = "./ziki.sh";
  };
in
{
  home.file.".local/bin/tmux" = {
    executable = true;
    force = true;
    source = tmuxWrapper;
  };

  home.packages = [
    (pkgs.writeShellScriptBin "notify" ''
      set -eu

      sound="/System/Library/Sounds/Submarine.aiff"
      assertions="$HOME/Library/DoNotDisturb/DB/Assertions.json"
      dnd_active=0

      if [ -r "$assertions" ] && /usr/bin/grep -q '"storeAssertionRecords"' "$assertions"; then
        dnd_active=1
      elif /usr/bin/defaults -currentHost read com.apple.notificationcenterui doNotDisturb 2>/dev/null | /usr/bin/grep -q '^1$'; then
        dnd_active=1
      fi

      if [ "$dnd_active" = 1 ]; then
        /usr/bin/afplay "$sound"
      else
        /usr/bin/afplay "$sound" -v 10
      fi
    '')
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/scripts"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LANGUAGE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    NVM_DIR = "$HOME/.nvm";
  };

  home.activation.createWorkstationDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/Developer"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/typst"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/Pictures/Screenshots"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.nvm"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.local/bin"}
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.local/scripts"}
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };

    shellAliases = shellNavigationAliases // gitAliases // nixAliases // projectAliases;

    initContent = ''
      unset MAILCHECK
      setopt prompt_subst

      path=(
        /etc/profiles/per-user/$USER/bin
        /run/current-system/sw/bin
        $path
        /opt/homebrew/bin
        /opt/homebrew/sbin
      )
      path=(''${path:#/opt/homebrew/opt/node@20/bin})
      path=(''${path:#$HOME/Library/pnpm})
      typeset -U path
      export PATH

      codex() {
        /etc/profiles/per-user/$USER/bin/codex "$@"
      }

      if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
        . "/opt/homebrew/opt/nvm/nvm.sh"
      fi

      if [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
        . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
      fi

      claude() {
        local bin
        bin="$(whence -p claude)" || return
        caffeinate -dims -t 3600 "$bin" --dangerously-skip-permissions "$@"
      }

      autoload -Uz add-zsh-hook vcs_info
      zstyle ':vcs_info:git:*' formats '%b'
      zstyle ':vcs_info:git:*' actionformats '%b|%a'

      gamma_prompt_precmd() {
        vcs_info

        if [ -n "$vcs_info_msg_0_" ]; then
          local gamma_git_dirty=""
          if [ -n "$(git status --porcelain --untracked-files=normal 2>/dev/null)" ]; then
            gamma_git_dirty="*"
          fi

          gamma_git_prompt="%F{green}$vcs_info_msg_0_$gamma_git_dirty%f "
        else
          gamma_git_prompt=""
        fi
      }

      add-zsh-hook precmd gamma_prompt_precmd
      PROMPT='γ %~/ ''${gamma_git_prompt}'

      bindkey -s '^T' 'git-branch-switcher\n'
      bindkey -s '^Y' 'issue-picker\n'
      bindkey -s '^F' 'tmux-sessionizer\n'
      bindkey -s '^G' 'typst-smart-open\n'

      gamma_dev_command_runner_widget() {
        zle -I

        if [[ -n "''${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
          tmux display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "DEV_COMMAND_RUNNER_TARGET_PANE='#{pane_id}' ~/.local/scripts/dev-command-runner"
          zle reset-prompt
        else
          BUFFER="dev-command-runner"
          CURSOR=''${#BUFFER}
          zle accept-line
        fi
      }

      zle -N gamma_dev_command_runner_widget
      bindkey '^O' gamma_dev_command_runner_widget
    '';
  };
}
