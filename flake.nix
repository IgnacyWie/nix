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
          pkgs.runCommand "gamma-backup-config-check" { } ''
            set -eu

            test -x ${program}
            grep -q 'RESTIC_REPOSITORY=b2:gamma-backup-restic:gamma' ${program}
            grep -q 'restic-gamma-b2-account-id' ${program}
            grep -q 'restic-gamma-b2-account-key' ${program}
            grep -q 'restic-gamma-password' ${program}
            grep -q -- '--exclude-file' ${program}
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

            grep -q "set -g @plugin 'christoomey/vim-tmux-navigator'" ${tmuxConfig}
            grep -q "set -g @plugin 'seebi/tmux-colors-solarized'" ${tmuxConfig}
            grep -q "set -g @plugin 'niksingh710/minimal-tmux-status'" ${tmuxConfig}
            grep -q 'set-environment -g TMUX_PLUGIN_MANAGER_PATH ~/.tmux/plugins/' ${tmuxConfig}
            grep -q 'set -g @minimal-tmux-status "top"' ${tmuxConfig}
            grep -q 'set -g @minimal-tmux-bg "#278BD3"' ${tmuxConfig}
            grep -q "set -g @colors-solarized 'dark'" ${tmuxConfig}
            grep -q "if-shell 'test -x ~/.tmux/plugins/tpm/tpm' 'run-shell ~/.tmux/plugins/tpm/tpm'" ${tmuxConfig}
            test -x ${tpmSource}/tpm

            touch "$out"
          '';

        gamma-workflow-scripts =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            tmuxSessionizer = homeConfig.home.file.".local/scripts/tmux-sessionizer".source;
            typstSmartOpen = homeConfig.home.file.".local/scripts/typst-smart-open".source;
            typstTemplate = homeConfig.home.file."typst/academic-template.typ".source;
            homebrewBrews = gammaConfiguration.config.homebrew.brews;
            homebrewBrewNames = builtins.map (brew: brew.name) homebrewBrews;
            systemPackages = gammaConfiguration.config.environment.systemPackages;
            packageNames = builtins.map (package: package.name or "") systemPackages;
          in
          assert builtins.elem "tmux" homebrewBrewNames;
          assert builtins.any (name: builtins.match ".*fzf.*" name != null) packageNames;
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
                pkgs.gnugrep
                pkgs.gnused
                pkgs.zsh
              ];
            }
            ''
              set -eu

              test -x ${tmuxSessionizer}
              test -x ${typstSmartOpen}
              test -r ${typstTemplate}

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
              printf 'issue-10-check\n'
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
                ${tmuxSessionizer} "$home/Developer/example-project"

              grep -q 'new-session -ds example-project -c' "$TMPDIR/tmux.log"
              grep -q 'new-window -t example-project -n node -c' "$TMPDIR/tmux.log"
              grep -q 'send-keys -t example-project:4 lazysql C-m' "$TMPDIR/tmux.log"
              grep -q 'switch-client -t example-project' "$TMPDIR/tmux.log"

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
      };
    };
}
