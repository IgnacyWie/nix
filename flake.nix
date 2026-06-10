{
  description = "Personal Infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      gammaConfiguration = nix-darwin.lib.darwinSystem {
        inherit system;

        modules = [
          ./hosts/darwin/gamma
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              backupFileExtension = "before-home-manager";
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ignacywielogorski = import ./modules/home;
            };
          }
        ];
      };
    in
    {
      darwinConfigurations.gamma = gammaConfiguration;

      formatter.${system} = pkgs.writeShellApplication {
        name = "nixfmt";
        runtimeInputs = [
          pkgs.findutils
          pkgs.nixfmt
        ];
        text = ''
          find . -name '*.nix' -not -path './.git/*' -print0 | xargs -0 nixfmt
        '';
      };

      checks.${system} = {
        gamma-pam-config =
          let
            pamConfig = pkgs.writeText "sudo-local-pam" gammaConfiguration.config.security.pam.services.sudo_local.text;
          in
          pkgs.runCommand "gamma-pam-config-check" { } ''
            set -eu

            grep -q 'pam_reattach.so' ${pamConfig}
            grep -q 'pam_tid.so' ${pamConfig}

            touch "$out"
          '';

        gamma-backup-config =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            agent = homeConfig.launchd.agents.gamma-restic-backup;
            interval = builtins.head agent.config.StartCalendarInterval;
            program = builtins.head agent.config.ProgramArguments;
          in
          assert agent.enable;
          assert interval.Hour == 20;
          assert interval.Minute == 0;
          assert agent.config.RunAtLoad == true;
          assert agent.config.StartInterval == 21600;
          pkgs.runCommand "gamma-backup-config-check" { } ''
            set -eu

            test -x ${program}
            test "${builtins.elemAt agent.config.ProgramArguments 1}" = "--scheduled"
            grep -q 'RESTIC_REPOSITORY=b2:gamma-backup-restic:gamma' ${program}
            grep -q 'restic-gamma-b2-account-id' ${program}
            grep -q 'restic-gamma-b2-account-key' ${program}
            grep -q 'restic-gamma-password' ${program}
            grep -q -- '--exclude-file' ${program}
            grep -q -- '--scheduled' ${program}
            grep -q 'retry 3 300 backup' ${program}
            grep -q 'retry 2 300 retention' ${program}
            grep -q 'Last successful backup is less than 20 hours old' ${program}
            grep -q -- '--keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune' ${program}

            touch "$out"
          '';

        gamma-terminal-config =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            ghosttyConfig = pkgs.writeText "ghostty-config" homeConfig.xdg.configFile."ghostty/config".text;
            tmuxConfig = pkgs.writeText "tmux-config" homeConfig.programs.tmux.extraConfig;
            tpmSource = homeConfig.home.file.".tmux/plugins/tpm".source;
          in
          pkgs.runCommand "gamma-terminal-config-check" { } ''
            set -eu

            grep -q 'theme = iTerm2 Tango Dark' ${ghosttyConfig}
            grep -q 'font-family = MesloLGS Nerd Font Mono' ${ghosttyConfig}
            grep -q 'keybind = cmd+j=copy_to_clipboard' ${ghosttyConfig}
            grep -q 'keybind = cmd+k=paste_from_clipboard' ${ghosttyConfig}
            grep -q 'keybind = cmd+,=close_surface' ${ghosttyConfig}
            grep -q 'keybind = cmd+y=new_tab' ${ghosttyConfig}
            grep -q 'keybind = cmd+b=new_window' ${ghosttyConfig}
            grep -q "keybind = cmd+'=quit" ${ghosttyConfig}
            grep -q 'keybind = cmd+w=reload_config' ${ghosttyConfig}

            grep -q 'bind-key -n C-f display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/tmux-sessionizer"' ${tmuxConfig}
            grep -q 'bind-key -r f display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/tmux-sessionizer"' ${tmuxConfig}
            grep -q 'bind-key -n C-g display-popup -E -d "$HOME/typst" -w 90% -h 80% "~/.local/scripts/typst-smart-open"' ${tmuxConfig}
            grep -q "set -g @plugin 'seebi/tmux-colors-solarized'" ${tmuxConfig}
            grep -q "set -g @plugin 'niksingh710/minimal-tmux-status'" ${tmuxConfig}
            grep -q 'set-environment -g TMUX_PLUGIN_MANAGER_PATH ~/.tmux/plugins/' ${tmuxConfig}
            grep -q 'set -g @minimal-tmux-status "top"' ${tmuxConfig}
            grep -q 'set -g @minimal-tmux-bg "#278BD3"' ${tmuxConfig}
            grep -q "set -g @colors-solarized 'dark'" ${tmuxConfig}
            grep -q "if-shell 'test -x ~/.tmux/plugins/tpm/tpm' 'run-shell ~/.tmux/plugins/tpm/tpm'" ${tmuxConfig}
            grep -q 'unbind-key -n C-h' ${tmuxConfig}
            grep -q 'unbind-key -n C-j' ${tmuxConfig}
            grep -q 'unbind-key -n C-k' ${tmuxConfig}
            grep -q 'unbind-key -n C-\\\\' ${tmuxConfig}
            grep -q 'bind-key -n C-h display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/git-branch-switcher"' ${tmuxConfig}
            test -x ${tpmSource}/tpm

            touch "$out"
          '';

        gamma-shell-caffeinate-wrappers =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            zshInit = pkgs.writeText "zsh-init" homeConfig.programs.zsh.initContent;
            zshAliases = homeConfig.programs.zsh.shellAliases;
          in
          assert !(builtins.hasAttr "codex" zshAliases);
          assert !(builtins.hasAttr "claude" zshAliases);
          pkgs.runCommand "gamma-shell-caffeinate-wrappers-check"
            {
              nativeBuildInputs = [
                pkgs.coreutils
                pkgs.gnugrep
                pkgs.zsh
              ];
            }
            ''
              set -eu

              grep -q 'bin="$(whence -p codex)" || return' ${zshInit}
              grep -q 'bin="$(whence -p claude)" || return' ${zshInit}
              grep -q 'caffeinate -dims "$bin" "$@"' ${zshInit}

              bin="$TMPDIR/bin"
              mkdir -p "$bin"

              cat > "$bin/caffeinate" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'caffeinate args:'
              for arg in "$@"; do
                printf ' <%s>' "$arg"
              done
              printf '\n'
              EOF
              chmod +x "$bin/caffeinate"

              cat > "$bin/codex" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'real codex should be wrapped\n'
              EOF
              chmod +x "$bin/codex"

              cat > "$bin/claude" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'real claude should be wrapped\n'
              EOF
              chmod +x "$bin/claude"

              PATH="$bin:${pkgs.coreutils}/bin:${pkgs.zsh}/bin" zsh -f <<EOF > "$TMPDIR/wrapper.log"
              source ${zshInit}
              codex --help 'two words'
              claude --version
              EOF

              grep -q 'caffeinate args: <-dims> <'"$bin"'/codex> <--help> <two words>' "$TMPDIR/wrapper.log"
              grep -q 'caffeinate args: <-dims> <'"$bin"'/claude> <--version>' "$TMPDIR/wrapper.log"

              touch "$out"
            '';

        gamma-neovim-config =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            nvimConfig = homeConfig.xdg.configFile."nvim".source;
            homePackages = homeConfig.home.packages;
            homePackageNames = builtins.map (package: package.name or "") homePackages;
          in
          assert homeConfig.programs.neovim.enable;
          assert homeConfig.programs.neovim.defaultEditor;
          assert homeConfig.programs.neovim.viAlias;
          assert homeConfig.programs.neovim.vimAlias;
          assert builtins.any (name: builtins.match ".*gcc.*" name != null) homePackageNames;
          assert builtins.any (name: builtins.match ".*gnumake.*" name != null) homePackageNames;
          assert builtins.any (name: builtins.match ".*lua-language-server.*" name != null) homePackageNames;
          assert builtins.any (name: builtins.match ".*nil.*" name != null) homePackageNames;
          assert builtins.any (name: builtins.match ".*nodejs.*" name != null) homePackageNames;
          assert builtins.any (name: builtins.match ".*python.*" name != null) homePackageNames;
          assert builtins.any (name: builtins.match ".*stylua.*" name != null) homePackageNames;
          assert builtins.any (name: builtins.match ".*tree-sitter.*" name != null) homePackageNames;
          pkgs.runCommand "gamma-neovim-config-check" { } ''
            set -eu

            test -r ${nvimConfig}/init.lua
            test -r ${nvimConfig}/lazy-lock.json
            test -r ${nvimConfig}/lazyvim.json
            test -r ${nvimConfig}/stylua.toml
            test -r ${nvimConfig}/lua/config/keymaps.lua
            test -r ${nvimConfig}/lua/config/options.lua
            test -r ${nvimConfig}/lua/plugins/avante.lua
            test -r ${nvimConfig}/lua/plugins/copilot.lua
            test -r ${nvimConfig}/lua/plugins/molten.lua
            test -r ${nvimConfig}/lua/plugins/nerdtree.lua
            test -r ${nvimConfig}/lua/plugins/nvim-tmux-configuration.lua
            test -r ${nvimConfig}/lua/plugins/typst-preview.lua
            test -r ${nvimConfig}/snippets/javascript/my_snippets.code-snippets
            test ! -e ${nvimConfig}/lua/plugins/example.lua
            test ! -e ${nvimConfig}/LICENSE

            grep -q 'lazyvim.plugins.extras.ai.copilot' ${nvimConfig}/lazyvim.json
            grep -q 'lazyvim.plugins.extras.lang.typescript' ${nvimConfig}/lazyvim.json
            grep -q 'lazyvim.plugins.extras.lang.rust' ${nvimConfig}/lazyvim.json
            grep -q 'vim.g.snacks_animate = false' ${nvimConfig}/lua/config/options.lua
            grep -q 'vim.opt.clipboard = "unnamedplus"' ${nvimConfig}/lua/config/options.lua
            grep -q 'vim.opt.swapfile = false' ${nvimConfig}/lua/config/options.lua
            grep -q 'Polish ą' ${nvimConfig}/lua/config/keymaps.lua
            grep -q ':TypstPreview<Return>' ${nvimConfig}/lua/config/keymaps.lua
            grep -q 'solarized-osaka' ${nvimConfig}/lua/plugins/colorscheme.lua
            grep -q 'provider = "openai"' ${nvimConfig}/lua/plugins/avante.lua
            grep -q 'zbirenbaum/copilot.lua' ${nvimConfig}/lua/plugins/copilot.lua
            grep -q 'benlubas/molten-nvim' ${nvimConfig}/lua/plugins/molten.lua
            grep -q 'quarto-dev/quarto-nvim' ${nvimConfig}/lua/plugins/molten.lua
            grep -q 'GCBallesteros/jupytext.nvim' ${nvimConfig}/lua/plugins/molten.lua
            grep -q 'position = "right"' ${nvimConfig}/lua/plugins/nerdtree.lua
            grep -q 'christoomey/vim-tmux-navigator' ${nvimConfig}/lua/plugins/nvim-tmux-configuration.lua
            grep -q 'qutebrowser %s' ${nvimConfig}/lua/plugins/typst-preview.lua

            touch "$out"
          '';

        gamma-workflow-scripts =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            tmuxSessionizer = homeConfig.home.file.".local/scripts/tmux-sessionizer".source;
            gitBranchSwitcher = homeConfig.home.file.".local/scripts/git-branch-switcher".source;
            typstSmartOpen = homeConfig.home.file.".local/scripts/typst-smart-open".source;
            typstTemplate = homeConfig.home.file."typst/academic-template.typ".source;
            homebrewBrewfile = pkgs.writeText "Brewfile" gammaConfiguration.config.homebrew.brewfile;
            homebrewBrews = gammaConfiguration.config.homebrew.brews;
            homebrewBrewNames = builtins.map (brew: brew.name) homebrewBrews;
            systemPackages = gammaConfiguration.config.environment.systemPackages;
            packageNames = builtins.map (package: package.name or "") systemPackages;
          in
          assert builtins.elem "tmux" homebrewBrewNames;
          assert builtins.any (name: builtins.match ".*chafa.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*fzf.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*glow.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*git.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*lazygit.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*lazysql.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*neovim.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*posting.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*typst.*" name != null) packageNames;
          pkgs.runCommand "gamma-workflow-scripts-check"
            {
              nativeBuildInputs = [
                pkgs.bash
                pkgs.coreutils
                pkgs.findutils
                pkgs.gawk
                pkgs.git
                pkgs.gnugrep
                pkgs.gnused
                pkgs.zsh
              ];
            }
            ''
              set -eu

              test -x ${tmuxSessionizer}
              test -x ${gitBranchSwitcher}
              test -x ${typstSmartOpen}
              test -r ${typstTemplate}
              grep -q 'tmux session> ' ${tmuxSessionizer}
              grep -q 'README: %s' ${tmuxSessionizer}
              grep -q 'glow -s dark' ${tmuxSessionizer}
              ! grep -q 'chafa' ${tmuxSessionizer}
              grep -q 'Recent commits:' ${tmuxSessionizer}
              grep -q 'typst document> ' ${typstSmartOpen}
              grep -q 'typst compile --pages 1' ${typstSmartOpen}
              grep -q 'Type a new document name' ${typstSmartOpen}
              grep -q 'brew "koekeishiya/formulae/yabai", trusted: true' ${homebrewBrewfile}
              grep -q 'brew "koekeishiya/formulae/skhd", trusted: true' ${homebrewBrewfile}

              home="$TMPDIR/home"
              bin="$TMPDIR/bin"
              mkdir -p "$home/Developer/example-project" "$home/typst" "$bin"
              cp ${typstTemplate} "$home/typst/academic-template.typ"

              cat > "$bin/tmux" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'tmux %s\n' "$*" >> "$TMPDIR/tmux.log"
              case " $* " in
                *" has-session "*) exit 1 ;;
              esac
              exit 0
              EOF
              chmod +x "$bin/tmux"

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              printf '%s/Developer/example-project\n' "$HOME"
              EOF
              chmod +x "$bin/fzf"

              cat > "$bin/pgrep" <<'EOF'
              #!${pkgs.runtimeShell}
              printf '123\n'
              EOF
              chmod +x "$bin/pgrep"

              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.zsh}/bin" \
                HOME="$home" \
                TMUX=1 \
                TMPDIR="$TMPDIR" \
                ${tmuxSessionizer}

              grep -q 'new-session -ds example-project -c' "$TMPDIR/tmux.log"
              grep -q 'new-window -t example-project -n node -c' "$TMPDIR/tmux.log"
              grep -q 'send-keys -t example-project:4 lazysql C-m' "$TMPDIR/tmux.log"
              grep -q 'switch-client -t example-project' "$TMPDIR/tmux.log"

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'feature/git-branch-switcher\n'
              EOF
              chmod +x "$bin/fzf"

              mkdir -p "$home/Developer/git-project"
              cd "$home/Developer/git-project"
              git init
              git config user.email test@example.com
              git config user.name Test
              printf 'main\n' > README.md
              git add README.md
              git commit -m initial
              git branch feature/git-branch-switcher

              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.git}/bin:${pkgs.gnused}/bin" \
                HOME="$home" \
                ${gitBranchSwitcher}

              test "$(git branch --show-current)" = "feature/git-branch-switcher"

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'issue-10-check\n'
              EOF
              chmod +x "$bin/fzf"

              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.zsh}/bin" \
                HOME="$home" \
                TMUX=1 \
                TMPDIR="$TMPDIR" \
                zsh -f ${typstSmartOpen}

              test -f "$home/typst/issue-10-check.typ"
              grep -q '#import "academic-template.typ": project' "$home/typst/issue-10-check.typ"
              grep -q 'title: "issue-10-check"' "$home/typst/issue-10-check.typ"
              grep -q 'new-session -d -s typst_' "$TMPDIR/tmux.log"
              grep -q "nvim 'issue-10-check.typ'" "$TMPDIR/tmux.log"

              touch "$out"
            '';

        gamma-window-management-config =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            homebrewBrewfile = pkgs.writeText "Brewfile" gammaConfiguration.config.homebrew.brewfile;
            homebrewCasks = gammaConfiguration.config.homebrew.casks;
            homebrewCaskNames = builtins.map (cask: cask.name) homebrewCasks;
            karabinerConfig = homeConfig.xdg.configFile."karabiner/karabiner.json".source;
            karabinerGermanLetters =
              homeConfig.xdg.configFile."karabiner/assets/complex_modifications/1709730136.json".source;
            karabinerZathura =
              homeConfig.xdg.configFile."karabiner/assets/complex_modifications/zathura_cmd_q.json".source;
            skhdConfig = homeConfig.xdg.configFile."skhd/skhdrc".source;
            yabaiFile = homeConfig.xdg.configFile."yabai/yabairc";
            yabaiConfig = yabaiFile.source;
          in
          assert builtins.elem "karabiner-elements" homebrewCaskNames;
          assert yabaiFile.executable;
          pkgs.runCommand "gamma-window-management-config-check"
            {
              nativeBuildInputs = [
                pkgs.jq
                pkgs.gnugrep
              ];
            }
            ''
              set -eu

              grep -q 'brew "koekeishiya/formulae/yabai", trusted: true' ${homebrewBrewfile}
              grep -q 'brew "koekeishiya/formulae/skhd", trusted: true' ${homebrewBrewfile}

              test -r ${karabinerConfig}
              test -r ${karabinerGermanLetters}
              test -r ${karabinerZathura}
              test -r ${skhdConfig}
              test -x ${yabaiConfig}
              test ! -e ${./config/karabiner}/automatic_backups

              jq -e '.profiles[] | select(.name == "Default" and .selected == true)' ${karabinerConfig} > /dev/null
              jq -e '.profiles[] | select(.name == "Minecraft")' ${karabinerConfig} > /dev/null
              grep -q '"keyboard_type_v2": "iso"' ${karabinerConfig}
              grep -q "Map Command + ' to Ctrl+Q only in Zathura" ${karabinerConfig}
              grep -q 'Easier Numbers' ${karabinerConfig}
              grep -q 'Easier Pane Switching' ${karabinerConfig}
              grep -q 'Make the' ${karabinerConfig}
              grep -q 'Easier Pane Sending' ${karabinerConfig}
              grep -q 'Display Brightness simlayer' ${karabinerConfig}
              grep -q 'Finder Key ~' ${karabinerConfig}
              grep -q 'App Key ;' ${karabinerConfig}
              grep -q 'German' ${karabinerGermanLetters}
              grep -q 'Zathura Cmd' ${karabinerZathura}

              grep -q 'sudo yabai --load-sa' ${yabaiConfig}
              grep -q 'event=dock_did_restart' ${yabaiConfig}
              grep -q 'focus_follows_mouse autoraise' ${yabaiConfig}
              grep -q 'auto_padding_width 1600' ${yabaiConfig}
              grep -q 'yabai -m rule --add app="\^Karabiner-Elements\$" manage=off' ${yabaiConfig}
              grep -q 'yabai -m rule --add app="\^System Settings\$" manage=off space=5' ${yabaiConfig}
              grep -q 'echo "yabai configuration loaded.."' ${yabaiConfig}

              grep -q 'cmd - return : open -na Ghostty.app' ${skhdConfig}
              grep -q "alt - w: open -a 'Zen Browser'" ${skhdConfig}
              grep -q 'alt - 1 : yabai -m space --focus  1' ${skhdConfig}
              grep -q 'alt + shift - 9 : yabai -m window --space  9' ${skhdConfig}
              grep -q '"VMware Fusion"' ${skhdConfig}

              touch "$out"
            '';

        local-pre-commit-hook =
          pkgs.runCommand "local-pre-commit-hook-check"
            {
              nativeBuildInputs = [
                pkgs.gnugrep
              ];
            }
            ''
              set -eu

              test -x ${./.githooks/pre-commit}
              test -x ${./scripts/install-pre-commit-hook}
              grep -q 'scripts/fmt' ${./.githooks/pre-commit}
              grep -q 'scripts/check' ${./.githooks/pre-commit}
              grep -q 'git config core.hooksPath .githooks' ${./scripts/install-pre-commit-hook}

              touch "$out"
            '';
      };
    };
}
