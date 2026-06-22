{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
  hostName = config.personal.hostName;
  hostPromptSymbol = config.personal.hostPromptSymbol;
  homebrewBinPathEnabled = config.personal.shell.enableHomebrewBinPath;
  workstationIntegrationsEnabled = config.personal.shell.enableWorkstationIntegrations;

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
    nix-check = "~/nix/scripts/check";
    nix-fmt = "~/nix/scripts/fmt";
  }
  // {
    "nix-apply-${hostName}" = "~/nix/scripts/apply-${hostName}";
    "nix-build-${hostName}" = "~/nix/scripts/build-${hostName}";
    "nix-eval-${hostName}" = "~/nix/scripts/eval-${hostName}";
  };

  projectAliases = {
    deploy = "vercel --prod";
    dev = "pnpm run dev";
    revdojo = "./revisiondojo.sh";
    ruflo = "npx ruflo@latest";
    sm = "ssh eta";
    tc = "typst compile";
    tw = "typst watch";
    wallet-compile = "cd ~/Developer/Imported/GymPass/backend && npm run dev";
    ziki = "./ziki.sh";
  };
in
{
  options.personal = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "gamma";
      description = "Host name used by host-aware managed shell helpers.";
    };

    hostPromptSymbol = lib.mkOption {
      type = lib.types.str;
      default = "γ";
      description = "Short host identity shown in the managed shell prompt.";
    };

    shell.enableHomebrewBinPath = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Add /opt/homebrew/bin to the managed zsh path.";
    };

    shell.enableWorkstationIntegrations = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable workstation-only aliases, paths, and interactive shell workflows.";
    };
  };

  config = lib.mkMerge [
    {
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
      ];

      home.sessionVariables = {
        LANG = "en_US.UTF-8";
        LANGUAGE = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };

      home.activation.createShellDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.local/bin"}
        run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.local/scripts"}
        run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.local/share/pnpm"}
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

        shellAliases =
          gitAliases
          // nixAliases
          // lib.optionalAttrs workstationIntegrationsEnabled (shellNavigationAliases // projectAliases);

        initContent = ''
          unset MAILCHECK
          setopt prompt_subst

          path=(
            /etc/profiles/per-user/$USER/bin
            /run/current-system/sw/bin
            $path
          )
          typeset -U path
          export PATH
        ''
        + lib.optionalString homebrewBinPathEnabled ''

          path=(
            $path
            /opt/homebrew/bin
          )
          typeset -U path
          export PATH
        ''
        + ''

          autoload -Uz add-zsh-hook vcs_info
          zstyle ':vcs_info:git:*' formats '%b'
          zstyle ':vcs_info:git:*' actionformats '%b|%a'

          host_shell_prompt_precmd() {
            vcs_info

            if [ -n "$vcs_info_msg_0_" ]; then
              local host_shell_git_dirty=""
              if [ -n "$(git status --porcelain --untracked-files=normal 2>/dev/null)" ]; then
                host_shell_git_dirty="*"
              fi

              host_shell_git_prompt="%F{green}$vcs_info_msg_0_$host_shell_git_dirty%f "
            else
              host_shell_git_prompt=""
            fi
          }

          add-zsh-hook precmd host_shell_prompt_precmd
          PROMPT='${hostPromptSymbol} %~/ ''${host_shell_git_prompt}'
        ''
        + lib.optionalString workstationIntegrationsEnabled ''

          path=(
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

          export PNPM_HOME="''${PNPM_HOME:-$HOME/.local/share/pnpm}"
          path=(
            $path
            $PNPM_HOME
          )
          typeset -U path
          export PATH

          claude() {
            local bin
            bin="$(whence -p claude)" || return
            caffeinate -dims -t 3600 "$bin" --dangerously-skip-permissions "$@"
          }

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
    (lib.mkIf workstationIntegrationsEnabled {
      home.file.".local/bin/tmux" = {
        executable = true;
        force = true;
        source = tmuxWrapper;
      };

      home.sessionPath = [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
      ];

      home.sessionVariables = {
        NVM_DIR = "$HOME/.nvm";
        PNPM_HOME = "$HOME/.local/share/pnpm";
      };

      home.activation.createWorkstationDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArg "${homeDirectory}/Developer"}
        run mkdir -p ${lib.escapeShellArg "${homeDirectory}/typst"}
        run mkdir -p ${lib.escapeShellArg "${homeDirectory}/Pictures/Screenshots"}
        run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.nvm"}
      '';
    })
  ];
}
