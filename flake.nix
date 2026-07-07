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
      nixosSystem = "x86_64-linux";
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
              users.ignacywielogorski = {
                imports = [
                  ./modules/home
                  ./modules/home/backup.nix
                ];
                personal = {
                  hostName = "gamma";
                  hostPromptSymbol = "γ";
                  shell.enableWorkstationIntegrations = true;
                };
              };
            };
          }
        ];
      };
      etaConfiguration = nix-darwin.lib.darwinSystem {
        inherit system;

        modules = [
          ./hosts/darwin/eta
          ./modules/darwin/base.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              backupFileExtension = "before-home-manager";
              useGlobalPkgs = true;
              useUserPackages = true;
              users.ignacywielogorski = {
                imports = [
                  ./modules/home/base.nix
                  ./modules/home/codex.nix
                  ./modules/home/git.nix
                  ./modules/home/home-server.nix
                  ./modules/home/home-server-backup.nix
                  ./modules/home/omlx.nix
                  ./modules/home/pi.nix
                  ./modules/home/shell.nix
                  ./modules/home/todo-business-sync.nix
                ];
                personal = {
                  hostName = "eta";
                  hostPromptSymbol = "η";
                  shell.enableHomebrewBinPath = true;
                  shell.enableWorkstationIntegrations = false;
                };
              };
            };
          }
        ];
      };
      omegaInstallerConfiguration = nixpkgs.lib.nixosSystem {
        system = nixosSystem;

        modules = [
          ./hosts/nixos/omega/installer.nix
        ];
      };
    in
    {
      darwinConfigurations.eta = etaConfiguration;
      darwinConfigurations.gamma = gammaConfiguration;
      nixosConfigurations.omega-installer = omegaInstallerConfiguration;

      packages.${nixosSystem}.omega-installer-iso =
        omegaInstallerConfiguration.config.system.build.isoImage;

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
        eta-host-skeleton =
          let
            etaConfig = etaConfiguration.config;
          in
          assert etaConfig.networking.hostName == "eta";
          assert etaConfig.networking.computerName == "eta";
          assert etaConfig.system.primaryUser == "ignacywielogorski";
          assert etaConfig.nixpkgs.hostPlatform.system == "aarch64-darwin";
          assert etaConfig.home-manager.users.ignacywielogorski.home.username == "ignacywielogorski";
          assert
            etaConfig.home-manager.users.ignacywielogorski.home.homeDirectory == "/Users/ignacywielogorski";
          pkgs.runCommand "eta-host-skeleton-check" { } ''
            set -eu
            touch "$out"
          '';

        omega-installer-iso =
          let
            omegaConfig = omegaInstallerConfiguration.config;
            omegaAuthorizedKeys = omegaConfig.users.users.nixos.openssh.authorizedKeys.keys;
          in
          assert omegaConfig.networking.hostName == "omega";
          assert nixosSystem == "x86_64-linux";
          assert omegaConfig.boot.zfs.forceImportRoot == false;
          assert omegaConfig.services.openssh.enable;
          assert omegaConfig.services.openssh.openFirewall;
          assert omegaConfig.services.openssh.settings.PasswordAuthentication == false;
          assert omegaConfig.services.openssh.settings.PermitRootLogin == "no";
          assert omegaConfig.services.avahi.enable;
          assert omegaConfig.services.avahi.openFirewall;
          assert builtins.elem 22 omegaConfig.networking.firewall.allowedTCPPorts;
          assert builtins.elem
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuZfw+lgWssLrdPbEO9rJOa4L5CiLkoELiiSjTyw6J7cicPNgnEZy9WW/UO1Vr5lOzACnMQwQHHktCKiS3fBG7dPjP6KdqPJOrhgM56Lk4eovN3SsTY+Zr+8mcQQZXrVkv023PaKMFeGtedvzVfOOpimf3jRHhjOntz9MyHqZWkvd0E9E6VnvIpNbw9+KG2/oUjjRHA9hyH+JzcY31EwWnjHV1qEMOSk/3f/NyMg6JuQxCixzd8FkS+bI8BWX/JaafjNTJib2YseS8kWSmy6bafg5YqQ4wJpAKK8ZG6zxoXYrTcL3VgPqYvQJcbRbH+Zfxg7UiWYExomImq0lAALwcWRfMq8gKCyTtb1zhc+qR6kcdKs+dOVp5v0+MWpJdJwvRqnk7TIrHS2ME7r8qFYrVF5ooXKXT9nB2rTIdS4XvOvouQBhE3p/FypCR5wFXyHy7voBU5oAVC4VjX3wDnF/FW+xsFFVmmvdtvx2XVFTUCjyhisUT/HqOZ0KrPnmLEIE= ignacywielogorski@Ignacys-MacBook-Air.local"
            omegaAuthorizedKeys;
          pkgs.runCommand "omega-installer-iso-check" { } ''
            set -eu

            test -x ${./scripts/build-omega-installer-iso}
            grep -q 'build-omega-installer-iso:' ${./Makefile}
            grep -q 'nixosConfigurations.omega-installer.config.system.build.isoImage' ${./scripts/build-omega-installer-iso}
            grep -q 'omega.local' ${./README.md}

            touch "$out"
          '';

        eta-home-server-baseline =
          let
            etaConfig = etaConfiguration.config;
            homeConfig = etaConfig.home-manager.users.ignacywielogorski;
            packageNames = builtins.map (package: package.name or "") etaConfig.environment.systemPackages;
            zshInit = pkgs.writeText "eta-zsh-init" homeConfig.programs.zsh.initContent;
            zshAliases = homeConfig.programs.zsh.shellAliases;
            sessionPath = homeConfig.home.sessionPath;
            sessionVariables = homeConfig.home.sessionVariables;
            homePackages = homeConfig.home.packages;
            piPackage = builtins.head (
              builtins.filter (package: package.name or "" == "pi-coding-agent-0.79.9") homePackages
            );
            codexPackage = builtins.head (
              builtins.filter (package: package.name or "" == "codex") homePackages
            );
            homeLaunchAgentNames = builtins.attrNames homeConfig.launchd.agents;
            systemLaunchDaemonNames = builtins.attrNames etaConfig.launchd.daemons;
            systemLaunchAgentNames = builtins.attrNames etaConfig.launchd.agents;
            liveContainerJobNames = builtins.filter (
              name: builtins.match ".*(docker|compose|orbstack|service-stack).*" name != null
            ) (homeLaunchAgentNames ++ systemLaunchDaemonNames ++ systemLaunchAgentNames);
          in
          assert builtins.any (name: builtins.match ".*curl.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*docker-compose.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*git.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*jq.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*khal.*" name != null) packageNames;
          assert !(builtins.any (name: builtins.match ".*openclaw.*" name != null) packageNames);
          assert builtins.any (name: builtins.match ".*restic.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*tailscale.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*tmux.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*vdirsyncer.*" name != null) packageNames;
          assert !(builtins.hasAttr "gamma-restic-backup" homeConfig.launchd.agents);
          assert homeConfig.personal.hostName == "eta";
          assert homeConfig.personal.hostPromptSymbol == "η";
          assert homeConfig.personal.shell.enableHomebrewBinPath;
          assert !homeConfig.personal.shell.enableWorkstationIntegrations;
          assert builtins.hasAttr "nix-apply-eta" zshAliases;
          assert builtins.hasAttr "nix-build-eta" zshAliases;
          assert builtins.hasAttr "nix-eval-eta" zshAliases;
          assert !(builtins.hasAttr "nix-apply-gamma" zshAliases);
          assert !(builtins.hasAttr "developer" zshAliases);
          assert !(builtins.hasAttr "deploy" zshAliases);
          assert !(builtins.hasAttr "tailscale" zshAliases);
          assert builtins.elem "/opt/homebrew/bin" sessionPath;
          assert !(builtins.elem "/opt/homebrew/sbin" sessionPath);
          assert !(builtins.hasAttr "NVM_DIR" sessionVariables);
          assert !(builtins.hasAttr ".local/bin/tmux" homeConfig.home.file);
          assert liveContainerJobNames == [ ];
          pkgs.runCommand "eta-home-server-baseline-check" { } ''
            set -eu

            grep -Fq "PROMPT='η %~/ " ${zshInit}
            grep -Fq 'host_shell_prompt_precmd()' ${zshInit}
            grep -Fq 'add-zsh-hook precmd host_shell_prompt_precmd' ${zshInit}
            grep -Fq '/opt/homebrew/bin' ${zshInit}
            ! grep -Fq '/opt/homebrew/sbin' ${zshInit}
            ! grep -Fq '.local/share/pi-node' ${zshInit}
            test -x ${piPackage}/bin/pi
            test "$(${piPackage}/bin/pi --version)" = "0.79.9"
            test -x ${codexPackage}/bin/codex
            grep -Fq 'pnpm_codex_bin="''${PNPM_HOME:-$HOME/.local/share/pnpm}/codex"' ${codexPackage}/bin/codex
            grep -Fq 'exec /usr/bin/caffeinate -dims -t 3600 "$codex_bin" --dangerously-bypass-approvals-and-sandbox --dangerously-bypass-hook-trust "$@"' ${codexPackage}/bin/codex
            ! grep -Fq "PROMPT='γ %~/ " ${zshInit}
            ! grep -q 'gamma-restic-backup' ${zshInit}
            ! grep -Fq 'codex() {' ${zshInit}
            ! grep -Fq 'claude() {' ${zshInit}
            ! grep -q "bindkey -s '\^T' 'git-branch-switcher" ${zshInit}
            ! grep -q "bindkey -s '\^Y' 'issue-picker" ${zshInit}
            ! grep -q 'gamma_dev_command_runner_widget()' ${zshInit}

            touch "$out"
          '';

        eta-repo-workflow = pkgs.runCommand "eta-repo-workflow-check" { } ''
          set -eu

          test -x ${./scripts/eval-eta}
          test -x ${./scripts/build-eta}
          test -x ${./scripts/apply-eta}
          grep -q 'eval-eta:' ${./Makefile}
          grep -q 'build-eta:' ${./Makefile}
          grep -q 'apply-eta:' ${./Makefile}
          grep -q '.#darwinConfigurations.eta.system' ${./scripts/eval-eta}
          grep -q '.#darwinConfigurations.eta.system' ${./scripts/build-eta}
          grep -q '.#eta' ${./scripts/apply-eta}
          ! grep -q 'darwin-rebuild switch' ${./scripts/build-eta}
          grep -q 'darwin-rebuild switch --flake .#eta' ${./scripts/apply-eta}
          grep -q 'make eval-eta' ${./README.md}
          grep -q 'make build-eta' ${./README.md}
          grep -q 'make apply-eta' ${./README.md}
          grep -q 'without applying' ${./README.md}

          touch "$out"
        '';

        eta-omlx-homebrew =
          let
            etaConfig = etaConfiguration.config;
            gammaConfig = gammaConfiguration.config;
            etaHomebrewBrewfile = pkgs.writeText "eta-homebrew-brewfile" etaConfig.homebrew.brewfile;
            etaHomebrewExtraConfig = pkgs.writeText "eta-homebrew-extra-config" etaConfig.homebrew.extraConfig;
            etaHomebrewBrewNames = builtins.map (brew: brew.name) etaConfig.homebrew.brews;
            gammaHomebrewExtraConfig = pkgs.writeText "gamma-homebrew-extra-config" gammaConfig.homebrew.extraConfig;
          in
          assert etaConfig.homebrew.enable;
          assert etaConfig.homebrew.onActivation.autoUpdate == false;
          assert etaConfig.homebrew.onActivation.upgrade == false;
          assert etaConfig.homebrew.onActivation.cleanup == "none";
          assert builtins.elem "himalaya" etaHomebrewBrewNames;
          assert etaConfig.personal.omlx.initialModel == "mlx-community/Qwen2.5-1.5B-Instruct-4bit";
          assert etaConfig.environment.variables.OMLX_INITIAL_MODEL == etaConfig.personal.omlx.initialModel;
          pkgs.runCommand "eta-omlx-homebrew-check" { } ''
            set -eu

            grep -Fq 'brew "himalaya"' ${etaHomebrewBrewfile}
            grep -Fq 'tap "jundot/omlx", "https://github.com/jundot/omlx", trusted: true' ${etaHomebrewExtraConfig}
            grep -Fq 'tap "steipete/tap", "https://github.com/steipete/homebrew-tap", trusted: true' ${etaHomebrewExtraConfig}
            grep -Fq 'brew "omlx", trusted: true' ${etaHomebrewExtraConfig}
            grep -Fq 'brew "steipete/tap/imsg", trusted: true' ${etaHomebrewExtraConfig}
            ! grep -Fq 'ossianhempel/tap' ${etaHomebrewExtraConfig}
            ! grep -Fq 'things3-cli' ${etaHomebrewExtraConfig}
            ! grep -Fq 'jundot/omlx' ${gammaHomebrewExtraConfig}
            ! grep -Fq 'steipete/tap' ${gammaHomebrewExtraConfig}
            ! grep -Fq 'brew "omlx"' ${gammaHomebrewExtraConfig}
            ! grep -Fq 'imsg' ${gammaHomebrewExtraConfig}

            touch "$out"
          '';

        eta-omlx-launchd =
          let
            etaConfig = etaConfiguration.config;
            homeConfig = etaConfig.home-manager.users.ignacywielogorski;
            agent = homeConfig.launchd.agents.eta-omlx;
            expectedProgramArguments = [
              "/opt/homebrew/bin/omlx"
              "serve"
              "--base-path"
              "/Users/ignacywielogorski/Services/data/omlx"
              "--model-dir"
              "/Users/ignacywielogorski/Services/data/omlx/models"
              "--host"
              "127.0.0.1"
              "--port"
              "8000"
              "--log-level"
              "info"
              "--max-concurrent-requests"
              "1"
              "--memory-guard"
              "safe"
              "--no-cache"
            ];
          in
          assert agent.enable;
          assert agent.config.ProgramArguments == expectedProgramArguments;
          assert agent.config.KeepAlive == true;
          assert agent.config.ProcessType == "Background";
          assert agent.config.RunAtLoad == true;
          assert
            agent.config.StandardOutPath
            == "/Users/ignacywielogorski/Services/data/omlx/logs/launchd-stdout.log";
          assert
            agent.config.StandardErrorPath
            == "/Users/ignacywielogorski/Services/data/omlx/logs/launchd-stderr.log";
          assert agent.config.WorkingDirectory == "/Users/ignacywielogorski/Services/data/omlx";
          assert !(builtins.elem "--api-key" agent.config.ProgramArguments);
          pkgs.runCommand "eta-omlx-launchd-check" { } ''
            set -eu

            grep -Fq 'Services/data/omlx' ${./modules/home/omlx.nix}
            grep -Fq '/models' ${./modules/home/omlx.nix}
            grep -Fq '/logs' ${./modules/home/omlx.nix}
            grep -Fq 'curl -fsS http://127.0.0.1:8000/health' ${./manual-steps.md}
            grep -Fq 'curl -fsS http://127.0.0.1:8000/v1/models' ${./manual-steps.md}
            grep -Fq 'launchctl print gui/$(id -u)/org.nix-community.home.eta-omlx' ${./manual-steps.md}
            grep -Fq 'not exposed directly to the LAN or tailnet' ${./README.md}
            grep -Fq '~/Services/data/omlx/models' ${./README.md}
            grep -Fq '~/Services/data/omlx/logs' ${./README.md}

            touch "$out"
          '';

        eta-todo-business-sync =
          let
            etaConfig = etaConfiguration.config;
            homeConfig = etaConfig.home-manager.users.ignacywielogorski;
            agent = homeConfig.launchd.agents.todo-business-sync;
            program = homeConfig.home.file.".local/bin/todo-business-sync".source;
            expectedProgramArguments = [
              "/Users/ignacywielogorski/.local/bin/todo-business-sync"
            ];
          in
          assert agent.enable;
          assert agent.config.ProgramArguments == expectedProgramArguments;
          assert agent.config.RunAtLoad == true;
          assert agent.config.StartInterval == 600;
          assert agent.config.ProcessType == "Background";
          assert
            agent.config.StandardOutPath
            == "/Users/ignacywielogorski/Library/Logs/todo-business-sync/launchd-stdout.log";
          assert
            agent.config.StandardErrorPath
            == "/Users/ignacywielogorski/Library/Logs/todo-business-sync/launchd-stderr.log";
          assert builtins.hasAttr "PATH" agent.config.EnvironmentVariables;
          pkgs.runCommand "eta-todo-business-sync-check" { } ''
            set -eu

            test -x ${program}
            grep -Fq 'TODO_BUSINESS_GITHUB_REPO:-IgnacyWie/todo-business' ${program}
            grep -Fq 'TODO_BUSINESS_THINGS_AREA:-Business' ${program}
            grep -Fq '<!-- todo-business-sync:things-uuid=%s -->' ${program}
            grep -Fq '<!-- todo-business-sync:github-issue=%s -->' ${program}
            grep -Fq 'gh issue list' ${program}
            grep -Fq 'gh issue create' ${program}
            grep -Fq 'gh issue edit' ${program}
            grep -Fq 'gh issue close' ${program}
            grep -Fq '"$things_bin" areas --json' ${program}
            grep -Fq '"$things_bin" tasks --json --area "$area" --all --limit=0' ${program}
            grep -Fq '"$things_bin" add --list "$area" --notes "$notes" -- "$title"' ${program}
            grep -Fq '"$things_bin" update --id="$uuid"' ${program}
            grep -Fq '"$things_bin" update --id="$things_uuid" --completed' ${program}
            grep -Fq 'StartInterval = 600;' ${./modules/home/todo-business-sync.nix}
            grep -Fq 'Library/Logs/todo-business-sync' ${./modules/home/todo-business-sync.nix}
            grep -Fq '.local/state/todo-business-sync' ${./modules/home/todo-business-sync.nix}

            touch "$out"
          '';

        eta-v1-migration-scope = pkgs.runCommand "eta-v1-migration-scope-check" { } ''
          set -eu

          grep -Fq 'The v1 Tier 1 Service Stacks are:' ${./services/eta/README.md}
          grep -Fq '`vaultwarden` — Keystone Service.' ${./services/eta/README.md}
          grep -Fq '`immich` — photos and videos.' ${./services/eta/README.md}
          grep -Fq '`paperless` — documents.' ${./services/eta/README.md}
          grep -Fq '`home-assistant` — home automation, including Matter Server.' ${./services/eta/README.md}
          grep -Fq '`baikal` — CalDAV/CardDAV.' ${./services/eta/README.md}
          grep -Fq '`linkding` — bookmarks.' ${./services/eta/README.md}
          grep -Fq '`personal-cloud` — Copyparty-backed Personal Cloud.' ${./services/eta/README.md}
          grep -Fq 'FreshRSS is Tier 2 for v1.' ${./services/eta/README.md}
          grep -Fq 'Explicitly out of scope for v1 migration work:' ${./services/eta/README.md}
          grep -Fq 'Matrix.' ${./services/eta/README.md}
          grep -Fq 'Synapse.' ${./services/eta/README.md}
          grep -Fq 'Mautrix bridges.' ${./services/eta/README.md}
          grep -Fq 'The Arr media stack' ${./services/eta/README.md}
          grep -Fq 'must not be copied into this tree just because they are running on `eta`' ${./services/eta/README.md}
          grep -Fq 'current running Docker' ${./README.md}
          grep -Fq 'Matrix, Synapse, Mautrix bridges, and the Arr media' ${./README.md}
          grep -Fq 'FreshRSS remains Tier 2 for v1.' ${./docs/eta-docker-orbstack-inventory.md}
          grep -Fq 'Migration Scope is not the same thing as current running Docker or OrbStack state.' ${./CONTEXT.md}

          find ${./services/eta} -mindepth 1 -maxdepth 1 -type d | while IFS= read -r dir; do
            stack="$(basename "$dir")"
            case "$stack" in
              matrix|synapse|mautrix|mautrix-*|arr|radarr|sonarr|lidarr|readarr|bazarr|prowlarr)
                echo "out-of-scope v1 service stack added under services/eta: $stack" >&2
                exit 1
                ;;
            esac
          done

          touch "$out"
        '';

        eta-service-control-command =
          let
            etaConfig = etaConfiguration.config;
            homeConfig = etaConfig.home-manager.users.ignacywielogorski;
            etaService = homeConfig.home.file.".local/bin/eta-service".source;
          in
          pkgs.runCommand "eta-service-control-command-check" { } ''
            set -eu

            test -x ${etaService}
            test -d ${./services/eta}
            grep -Fq 'Service Definition Layout' ${./services/eta/README.md}
            grep -Fq 'eta-service: Service Control Commands run authoritatively on eta.' ${etaService}
            grep -Fq 'service_definition_root="''${ETA_SERVICE_DEFINITION_ROOT:-$HOME/nix/services/eta}"' ${etaService}
            grep -Fq 'find "$service_definition_root" -mindepth 1 -maxdepth 1 -type d' ${etaService}
            grep -Fq 'inspect_stack()' ${etaService}
            grep -Fq 'docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" up -d "$@"' ${etaService}
            grep -Fq 'docker-compose --project-name "$stack" --project-directory "$stack_dir" --file "$compose_file" down "$@"' ${etaService}

            home="$TMPDIR/home"
            service_definitions="$TMPDIR/services/eta"
            mkdir -p "$home" "$service_definitions"
            HOME="$home" ${etaService} --help > "$TMPDIR/help.txt"
            grep -Fq 'Service Control Commands run authoritatively on eta.' "$TMPDIR/help.txt"
            grep -Fq 'directories under ~/nix/services/eta' "$TMPDIR/help.txt"

            HOME="$home" ETA_SERVICE_DEFINITION_ROOT="$service_definitions" ${etaService} list > "$TMPDIR/list.txt"
            test ! -s "$TMPDIR/list.txt"

            mkdir -p "$service_definitions/example"
            touch "$service_definitions/example/compose.yaml"
            HOME="$home" ETA_SERVICE_DEFINITION_ROOT="$service_definitions" ${etaService} list > "$TMPDIR/list-with-stack.txt"
            grep -Fxq 'example' "$TMPDIR/list-with-stack.txt"

            HOME="$home" ETA_SERVICE_DEFINITION_ROOT="$service_definitions" ${etaService} inspect example > "$TMPDIR/inspect.txt"
            grep -Fxq 'stack=example' "$TMPDIR/inspect.txt"
            grep -Fxq 'project=example' "$TMPDIR/inspect.txt"
            grep -Fxq "directory=$service_definitions/example" "$TMPDIR/inspect.txt"
            grep -Fxq "compose_file=$service_definitions/example/compose.yaml" "$TMPDIR/inspect.txt"

            touch "$out"
          '';

        eta-backup-config =
          let
            etaConfig = etaConfiguration.config;
            homeConfig = etaConfig.home-manager.users.ignacywielogorski;
            agent = homeConfig.launchd.agents.eta-restic-backup;
            expectedCalendarInterval = [
              {
                Day = null;
                Hour = 3;
                Minute = 0;
                Month = null;
                Weekday = null;
              }
            ];
            expectedProgramArguments = [
              program
              "--scheduled"
            ];
            program = builtins.head agent.config.ProgramArguments;
            backupExcludes = pkgs.writeText "expected-eta-backup-excludes" (
              builtins.readFile ./eta-backup-excludes.txt
            );
          in
          assert agent.enable;
          assert agent.config.ProcessType == "Background";
          assert agent.config.RunAtLoad == true;
          assert agent.config.StartInterval == 21600;
          assert agent.config.StartCalendarInterval == expectedCalendarInterval;
          assert agent.config.ProgramArguments == expectedProgramArguments;
          assert
            agent.config.StandardOutPath
            == "/Users/ignacywielogorski/Library/Logs/eta-restic-backup/launchd-stdout.log";
          assert
            agent.config.StandardErrorPath
            == "/Users/ignacywielogorski/Library/Logs/eta-restic-backup/launchd-stderr.log";
          assert !(builtins.hasAttr "gamma-restic-backup" homeConfig.launchd.agents);
          pkgs.runCommand "eta-backup-config-check" { } ''
            set -eu

            test -x ${program}
            test "$(basename ${program})" = "eta-restic-backup"
            cmp ${backupExcludes} ${./eta-backup-excludes.txt}

            grep -Fqx "export RESTIC_REPOSITORY=b2:eta-home-server-restic:eta" ${program}
            grep -Fqx "B2_ACCOUNT_ID=\"\$(/usr/bin/security find-generic-password -a \"\$USER\" -s restic-eta-b2-account-id -w)\"" ${program}
            grep -Fqx "B2_ACCOUNT_KEY=\"\$(/usr/bin/security find-generic-password -a \"\$USER\" -s restic-eta-b2-account-key -w)\"" ${program}
            grep -Fqx "RESTIC_PASSWORD=\"\$(/usr/bin/security find-generic-password -a \"\$USER\" -s restic-eta-password -w)\"" ${program}
            grep -Fqx "export B2_ACCOUNT_ID" ${program}
            grep -Fqx "export B2_ACCOUNT_KEY" ${program}
            grep -Fqx "export RESTIC_PASSWORD" ${program}

            grep -Fqx 'create_sqlite_dump() {' ${program}
            grep -Fqx 'create_postgres_dump() {' ${program}
            grep -Fq 'sqlite3 "$source_db" ".backup' ${program}
            grep -Fq 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' ${program}
            grep -Fqx 'create_logical_dumps' ${program}
            grep -Fq '"$HOME/Services/dumps/linkding/linkding.sqlite3"' ${program}
            grep -Fq '"$HOME/Services/dumps/paperless/paperless.sqlite3"' ${program}
            grep -Fq '"$HOME/Services/dumps/home-assistant/home-assistant_v2.db"' ${program}
            grep -Fq '"$HOME/Services/dumps/baikal/db.sqlite"' ${program}
            grep -Fq '"$HOME/Services/dumps/immich/immich.dump"' ${program}
            grep -Eq '^retry 3 300 backup restic backup "\$\{backup_args\[@\]\}" --exclude-file /nix/store/[a-z0-9]+-source/eta-backup-excludes\.txt$' ${program}
            grep -Fqx "retry 2 300 retention restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune" ${program}
            grep -Fqx '    "$@" && return 0' ${program}
            grep -Fqx "    printf 'Last successful backup is less than 20 hours old; skipping scheduled catch-up.\n'" ${program}

            grep -Fqx "add_backup_path /Users/ignacywielogorski/Services" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/nix/services/eta" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/nix/backup.md" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/nix/manual-steps.md" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/nix/CONTEXT.md" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/nix/docs/adr" ${program}
            grep -Fq "/Users/ignacywielogorski/Services/**/cache" ${./eta-backup-excludes.txt}
            grep -Fq "/Users/ignacywielogorski/Services/**/tmp" ${./eta-backup-excludes.txt}
            grep -Fq "/Users/ignacywielogorski/Services/**/logs" ${./eta-backup-excludes.txt}

            ! grep -Eq "^(export )?(B2_ACCOUNT_ID|B2_ACCOUNT_KEY|RESTIC_PASSWORD)='[^$]" ${program}
            ! grep -Eq "^(export )?(B2_ACCOUNT_ID|B2_ACCOUNT_KEY|RESTIC_PASSWORD)=\"[^$]" ${program}

            touch "$out"
          '';

        eta-vaultwarden-service-stack = pkgs.runCommand "eta-vaultwarden-service-stack-check" { } ''
          set -eu

          test -f ${./services/eta/vaultwarden/compose.yaml}
          test -f ${./services/eta/vaultwarden/.env.example}
          test -f ${./services/eta/vaultwarden/README.md}

          grep -Fq 'image: vaultwarden/server:1.36.0' ${./services/eta/vaultwarden/compose.yaml}
          grep -Fq 'container_name: vaultwarden' ${./services/eta/vaultwarden/compose.yaml}
          grep -Fq -- '- ''${HOME}/Services/data/vaultwarden:/data' ${./services/eta/vaultwarden/compose.yaml}
          grep -Fq 'name: proxy-network' ${./services/eta/vaultwarden/compose.yaml}
          grep -Fq 'external: true' ${./services/eta/vaultwarden/compose.yaml}
          grep -Fq 'env_file:' ${./services/eta/vaultwarden/compose.yaml}
          grep -Fq -- '- ./.env' ${./services/eta/vaultwarden/compose.yaml}
          grep -Fq 'ADMIN_TOKEN=set-me' ${./services/eta/vaultwarden/.env.example}
          grep -Fq 'VAULTWARDEN_DOMAIN=https://vaultwarden.example.ts.net' ${./services/eta/vaultwarden/.env.example}
          grep -Fq 'Do not commit .env or real secret values.' ${./services/eta/vaultwarden/.env.example}

          grep -Fq 'Keystone Service' ${./services/eta/vaultwarden/README.md}
          grep -Fq '~/Services/data/vaultwarden' ${./services/eta/vaultwarden/README.md}
          grep -Fq 'v1 SQLite Keystone Data Store' ${./services/eta/vaultwarden/README.md}
          grep -Fq 'Do not migrate Vaultwarden to Postgres in v1.' ${./services/eta/vaultwarden/README.md}
          grep -Fq 'eta-service vaultwarden up' ${./services/eta/vaultwarden/README.md}
          grep -Fq 'Verify representative vault contents' ${./services/eta/vaultwarden/README.md}

          grep -Fq 'including Vaultwarden SQLite Keystone Data Store material' ${./backup.md}
          grep -Fq 'services/eta/vaultwarden' ${./backup.md}
          grep -Fq 'Vaultwarden Keystone Restore Drill' ${./backup.md}
          grep -Fq 'without Postgres' ${./backup.md}
          grep -Fq 'Vaultwarden the only recovery source for `eta`' ${./backup.md}

          grep -Fq '`eta` Home Server Keystone Recovery' ${./manual-steps.md}
          grep -Fq 'Vaultwarden does not replace' ${./manual-steps.md}
          grep -Fq 'eta-service vaultwarden up' ${./manual-steps.md}
          grep -Fq 'do not add Postgres' ${./manual-steps.md}

          ! grep -R 'sDuTLX' ${./services/eta/vaultwarden}

          touch "$out"
        '';

        eta-linkding-service-stack = pkgs.runCommand "eta-linkding-service-stack-check" { } ''
          set -eu

          test -f ${./services/eta/linkding/compose.yaml}
          test -f ${./services/eta/linkding/.env.example}
          test -f ${./services/eta/linkding/README.md}

          grep -Fq 'image: sissbruecker/linkding:1.45.0' ${./services/eta/linkding/compose.yaml}
          grep -Fq 'container_name: linkding' ${./services/eta/linkding/compose.yaml}
          grep -Fq -- '- ''${HOME}/Services/data/linkding:/etc/linkding/data' ${./services/eta/linkding/compose.yaml}
          ! grep -Fq '/etc/linkding/data"' ${./services/eta/linkding/compose.yaml}
          grep -Fq 'name: proxy-network' ${./services/eta/linkding/compose.yaml}
          grep -Fq 'external: true' ${./services/eta/linkding/compose.yaml}
          grep -Fq 'traefik.http.routers.linkding.rule: Host(`''${LINKDING_HOST}`)' ${./services/eta/linkding/compose.yaml}
          grep -Fq 'traefik.http.routers.linkding.tls.certresolver: myresolver' ${./services/eta/linkding/compose.yaml}
          grep -Fq 'traefik.http.routers.linkding.tls.domains[0].main: mac.wie.dev' ${./services/eta/linkding/compose.yaml}
          grep -Fq 'traefik.http.routers.linkding.tls.domains[0].sans: "*.mac.wie.dev"' ${./services/eta/linkding/compose.yaml}
          grep -Fq 'LINKDING_HOST=bookmarks.mac.wie.dev' ${./services/eta/linkding/.env.example}
          grep -Fq 'LINKDING_CSRF_TRUSTED_ORIGINS=https://bookmarks.mac.wie.dev' ${./services/eta/linkding/.env.example}
          grep -Fq 'LINKDING_SUPERUSER_PASSWORD=set-me' ${./services/eta/linkding/.env.example}
          grep -Fq 'Do not commit .env or real secrets.' ${./services/eta/linkding/.env.example}

          grep -Fq 'Corrective Migration' ${./services/eta/linkding/README.md}
          grep -Fq '~/Services/data/linkding' ${./services/eta/linkding/README.md}
          grep -Fq '~/Services/dumps/linkding/linkding.sqlite3' ${./services/eta/linkding/README.md}
          grep -Fq 'bookmarks.mac.wie.dev' ${./services/eta/linkding/README.md}
          grep -Fq 'eta-service linkding up' ${./services/eta/linkding/README.md}
          grep -Fq 'verify the bookmark still exists' ${./services/eta/linkding/README.md}

          grep -Fq 'Linkding Durable Service State' ${./backup.md}
          grep -Fq 'Linkding Corrective Migration Restore Drill' ${./backup.md}
          grep -Fq 'services/eta/linkding' ${./backup.md}
          grep -Fq '`eta` Home Server Linkding Recovery' ${./manual-steps.md}

          ! grep -R 'freemason' ${./services/eta/linkding}

          touch "$out"
        '';

        eta-immich-large-upload-proxy = pkgs.runCommand "eta-immich-large-upload-proxy-check" { } ''
          set -eu

          test -f ${./services/eta/immich/compose.yaml}
          test -f ${./services/eta/immich/README.md}
          test -f ${./services/eta/traefik/compose.yaml}
          test -f ${./services/eta/traefik/.env.example}
          test -f ${./services/eta/traefik/README.md}

          grep -Fq 'traefik.http.middlewares.immich-upload-limit.buffering.maxRequestBodyBytes: "2000000000"' ${./services/eta/immich/compose.yaml}
          grep -Fq 'traefik.http.middlewares.immich-upload-limit.buffering.memRequestBodyBytes: "10485760"' ${./services/eta/immich/compose.yaml}
          grep -Fq 'traefik.http.routers.immich.middlewares: immich-upload-limit@docker' ${./services/eta/immich/compose.yaml}
          grep -Fq 'traefik.http.services.immich.loadbalancer.passhostheader: "true"' ${./services/eta/immich/compose.yaml}

          grep -Fq -- '--entrypoints.web.transport.respondingTimeouts.readTimeout=''${TRAEFIK_UPLOAD_READ_TIMEOUT:-30m}' ${./services/eta/traefik/compose.yaml}
          grep -Fq -- '--entrypoints.web.transport.respondingTimeouts.writeTimeout=''${TRAEFIK_UPLOAD_WRITE_TIMEOUT:-30m}' ${./services/eta/traefik/compose.yaml}
          grep -Fq -- '--entrypoints.web.transport.respondingTimeouts.idleTimeout=''${TRAEFIK_UPLOAD_IDLE_TIMEOUT:-30m}' ${./services/eta/traefik/compose.yaml}
          grep -Fq -- '--entrypoints.websecure.transport.respondingTimeouts.readTimeout=''${TRAEFIK_UPLOAD_READ_TIMEOUT:-30m}' ${./services/eta/traefik/compose.yaml}
          grep -Fq -- '--entrypoints.websecure.transport.respondingTimeouts.writeTimeout=''${TRAEFIK_UPLOAD_WRITE_TIMEOUT:-30m}' ${./services/eta/traefik/compose.yaml}
          grep -Fq -- '--entrypoints.websecure.transport.respondingTimeouts.idleTimeout=''${TRAEFIK_UPLOAD_IDLE_TIMEOUT:-30m}' ${./services/eta/traefik/compose.yaml}

          grep -Fq 'TRAEFIK_UPLOAD_READ_TIMEOUT=30m' ${./services/eta/traefik/.env.example}
          grep -Fq 'TRAEFIK_UPLOAD_WRITE_TIMEOUT=30m' ${./services/eta/traefik/.env.example}
          grep -Fq 'TRAEFIK_UPLOAD_IDLE_TIMEOUT=30m' ${./services/eta/traefik/.env.example}
          grep -Fq 'one mobile upload larger than 250 MB' ${./services/eta/immich/README.md}
          grep -Fq 'large uploads through the' ${./services/eta/traefik/README.md}

          touch "$out"
        '';

        eta-local-ai-service-stack = pkgs.runCommand "eta-local-ai-service-stack-check" { } ''
          set -eu

          test -f ${./services/eta/local-ai/compose.yaml}
          test -f ${./services/eta/local-ai/.env.example}
          test -f ${./services/eta/local-ai/README.md}

          grep -Fq 'image: ghcr.io/open-webui/open-webui:main' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'container_name: open-webui' ${./services/eta/local-ai/compose.yaml}
          grep -Fq -- '- ''${HOME}/Services/data/local-ai/open-webui:/app/backend/data' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'name: proxy-network' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'external: true' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'traefik.http.routers.open-webui.rule: Host(`''${OPEN_WEBUI_HOST}`)' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'traefik.http.routers.open-webui.tls.certresolver: myresolver' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'traefik.http.routers.open-webui.tls.domains[0].main: mac.wie.dev' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'traefik.http.routers.open-webui.tls.domains[0].sans: "*.mac.wie.dev"' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'traefik.http.services.open-webui.loadbalancer.server.port: "8080"' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'OPENAI_API_BASE_URLS: ''${OMLX_OPENAI_API_BASE_URL:-http://host.docker.internal:8000/v1}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'OPENAI_API_KEYS: ''${OMLX_OPENAI_API_KEY:-omlx-local-no-key}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'extra_hosts:' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'host.docker.internal:host-gateway' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'healthcheck:' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'disable: true' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'WEBUI_AUTH: ''${OPEN_WEBUI_AUTH:-true}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'image: clusterzx/paperless-ai:latest' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'container_name: paperless-ai' ${./services/eta/local-ai/compose.yaml}
          grep -Fq -- '- ''${HOME}/Services/data/local-ai/paperless-ai:/app/data' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'PAPERLESS_API_URL: ''${PAPERLESS_AI_PAPERLESS_API_URL:-http://paperless-webserver-1:8000/api}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'PAPERLESS_API_TOKEN: ''${PAPERLESS_AI_PAPERLESS_API_TOKEN:-set-me}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'PAPERLESS_USERNAME: ''${PAPERLESS_AI_PAPERLESS_USERNAME:-set-me}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'CUSTOM_BASE_URL: ''${OMLX_OPENAI_API_BASE_URL:-http://host.docker.internal:8000/v1}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'CUSTOM_API_KEY: ''${OMLX_OPENAI_API_KEY:-omlx-local-no-key}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'CUSTOM_MODEL: ''${PAPERLESS_AI_OMLX_MODEL:-set-me}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'API_KEY: ''${PAPERLESS_AI_API_KEY:-set-me}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'JWT_SECRET: ''${PAPERLESS_AI_JWT_SECRET:-set-me}' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'traefik.http.routers.paperless-ai.rule: Host(`''${PAPERLESS_AI_HOST}`)' ${./services/eta/local-ai/compose.yaml}
          grep -Fq 'traefik.http.services.paperless-ai.loadbalancer.server.port: "3000"' ${./services/eta/local-ai/compose.yaml}

          grep -Fq 'OPEN_WEBUI_HOST=ai.mac.wie.dev' ${./services/eta/local-ai/.env.example}
          grep -Fq 'OPEN_WEBUI_AUTH=true' ${./services/eta/local-ai/.env.example}
          grep -Fq 'OPEN_WEBUI_ENABLE_SIGNUP=false' ${./services/eta/local-ai/.env.example}
          grep -Fq 'OMLX_OPENAI_API_BASE_URL=http://host.docker.internal:8000/v1' ${./services/eta/local-ai/.env.example}
          grep -Fq 'OMLX_OPENAI_API_KEY=omlx-local-no-key' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_HOST=paperless-ai.mac.wie.dev' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_PAPERLESS_API_URL=http://paperless-webserver-1:8000/api' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_PAPERLESS_USERNAME=set-me-paperless-ai-user' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_PAPERLESS_API_TOKEN=set-me-paperless-api-token' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_PROVIDER=custom' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_OMLX_MODEL=set-me-omlx-model' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_API_KEY=set-me-random-api-key' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_JWT_SECRET=set-me-random-jwt-secret' ${./services/eta/local-ai/.env.example}
          grep -Fq 'PAPERLESS_AI_PROCESSED_TAG_NAME=ai-written-metadata' ${./services/eta/local-ai/.env.example}
          grep -Fq 'Do not commit .env or real secrets.' ${./services/eta/local-ai/.env.example}

          grep -Fq 'Local AI Service Stack' ${./services/eta/local-ai/README.md}
          grep -Fq 'https://ai.mac.wie.dev' ${./services/eta/local-ai/README.md}
          grep -Fq 'https://paperless-ai.mac.wie.dev' ${./services/eta/local-ai/README.md}
          grep -Fq '~/Services/data/local-ai/open-webui' ${./services/eta/local-ai/README.md}
          grep -Fq '~/Services/data/local-ai/paperless-ai' ${./services/eta/local-ai/README.md}
          grep -Fq 'host-managed OMLX' ${./services/eta/local-ai/README.md}
          grep -Fq 'http://host.docker.internal:8000/v1' ${./services/eta/local-ai/README.md}
          grep -Fq 'Open WebUI application authentication' ${./services/eta/local-ai/README.md}
          grep -Fq 'Tier 1 Paperless Service Stack' ${./services/eta/local-ai/README.md}
          grep -Fq 'dedicated Paperless user/token' ${./services/eta/local-ai/README.md}
          grep -Fq 'AI-written document metadata' ${./services/eta/local-ai/README.md}
          grep -Fq 'Paperless-AI supports login/JWT sessions' ${./services/eta/local-ai/README.md}
          grep -Fq 'eta-service local-ai up' ${./services/eta/local-ai/README.md}

          grep -Fq '`local-ai` — Tier 2 Local AI Service Stack.' ${./services/eta/README.md}
          grep -Fq 'ai.mac.wie.dev' ${./services/eta/README.md}
          grep -Fq 'paperless-ai.mac.wie.dev' ${./services/eta/README.md}

          ! grep -R 'sk-' ${./services/eta/local-ai}

          touch "$out"
        '';

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

        gamma-macos-defaults =
          let
            defaults = gammaConfiguration.config.system.defaults;
            dvorakQwerty = {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 16301;
              "KeyboardLayout Name" = "DVORAK - QWERTY CMD";
            };
            polishPro = {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 30788;
              "KeyboardLayout Name" = "Polish Pro";
            };
            customGlobal = defaults.CustomUserPreferences.NSGlobalDomain;
            customLoginwindow = defaults.CustomSystemPreferences."/Library/Preferences/com.apple.loginwindow";
            hitoolbox = defaults.CustomUserPreferences."com.apple.HIToolbox";
            spotlightHotkey =
              defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys."64";
          in
          assert defaults.dock.autohide == true;
          assert defaults.dock.autohide-delay == 0.0;
          assert defaults.dock.autohide-time-modifier == 0.0;
          assert defaults.dock.launchanim == false;
          assert defaults.dock.magnification == false;
          assert defaults.dock.mru-spaces == false;
          assert defaults.dock.orientation == "left";
          assert defaults.dock.show-recents == false;
          assert defaults.dock.showAppExposeGestureEnabled == true;
          assert defaults.dock.showDesktopGestureEnabled == true;
          assert defaults.dock.showhidden == true;
          assert defaults.dock.showMissionControlGestureEnabled == true;
          assert defaults.dock.slow-motion-allowed == false;
          assert defaults.dock.tilesize == 67;
          assert defaults.finder.AppleShowAllExtensions == true;
          assert defaults.finder.AppleShowAllFiles == false;
          assert defaults.finder.FXDefaultSearchScope == "SCcf";
          assert defaults.finder.FXEnableExtensionChangeWarning == false;
          assert defaults.finder.FXPreferredViewStyle == "clmv";
          assert defaults.finder.NewWindowTarget == "PfLo";
          assert defaults.finder.NewWindowTargetPath == "file:///Users/ignacywielogorski/";
          assert defaults.finder.ShowExternalHardDrivesOnDesktop == true;
          assert defaults.finder.ShowHardDrivesOnDesktop == true;
          assert defaults.finder.ShowMountedServersOnDesktop == true;
          assert defaults.finder.ShowPathbar == true;
          assert defaults.finder.ShowRemovableMediaOnDesktop == true;
          assert defaults.finder.ShowStatusBar == true;
          assert defaults.finder._FXEnableColumnAutoSizing == true;
          assert defaults.finder._FXShowPosixPathInTitle == true;
          assert defaults.finder._FXSortFoldersFirst == true;
          assert defaults.finder._FXSortFoldersFirstOnDesktop == true;
          assert defaults.NSGlobalDomain.AppleEnableSwipeNavigateWithScrolls == false;
          assert defaults.NSGlobalDomain.AppleInterfaceStyle == "Dark";
          assert defaults.NSGlobalDomain.AppleShowAllExtensions == true;
          assert defaults.NSGlobalDomain.AppleShowScrollBars == "Always";
          assert defaults.NSGlobalDomain.ApplePressAndHoldEnabled == false;
          assert defaults.NSGlobalDomain.InitialKeyRepeat == 30;
          assert defaults.NSGlobalDomain.KeyRepeat == 2;
          assert defaults.NSGlobalDomain.NSAutomaticWindowAnimationsEnabled == false;
          assert defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud == false;
          assert defaults.NSGlobalDomain.NSTableViewDefaultSizeMode == 2;
          assert defaults.NSGlobalDomain.NSWindowResizeTime == 0.001;
          assert defaults.NSGlobalDomain.NSWindowShouldDragOnGesture == true;
          assert defaults.NSGlobalDomain._HIHideMenuBar == false;
          assert defaults.NSGlobalDomain."com.apple.springing.enabled" == true;
          assert defaults.universalaccess.reduceMotion == true;
          assert defaults.universalaccess.reduceTransparency == false;
          assert defaults.trackpad.Clicking == false;
          assert defaults.trackpad.ForceSuppressed == true;
          assert defaults.trackpad.TrackpadRightClick == true;
          assert defaults.trackpad.TrackpadFourFingerHorizSwipeGesture == 0;
          assert defaults.trackpad.TrackpadThreeFingerDrag == false;
          assert defaults.trackpad.TrackpadThreeFingerHorizSwipeGesture == 2;
          assert defaults.WindowManager.AppWindowGroupingBehavior == true;
          assert defaults.WindowManager.AutoHide == false;
          assert defaults.WindowManager.EnableStandardClickToShowDesktop == false;
          assert defaults.WindowManager.EnableTiledWindowMargins == false;
          assert defaults.WindowManager.GloballyEnabled == false;
          assert defaults.WindowManager.HideDesktop == true;
          assert defaults.WindowManager.StageManagerHideWidgets == true;
          assert defaults.WindowManager.StandardHideDesktopIcons == true;
          assert defaults.WindowManager.StandardHideWidgets == true;
          assert defaults.screencapture.disable-shadow == true;
          assert defaults.screencapture.location == "/Users/ignacywielogorski/Pictures/Screenshots";
          assert defaults.screencapture.save-selections == true;
          assert defaults.screencapture.show-thumbnail == false;
          assert defaults.screencapture.type == "png";
          assert customGlobal.AppleMiniaturizeOnDoubleClick == false;
          assert customGlobal.AppleReduceDesktopTinting == true;
          assert customGlobal.NSQuitAlwaysKeepsWindows == false;
          assert customGlobal.QLPanelAnimationDuration == 0;
          assert customLoginwindow.TALLogoutSavesState == false;
          assert
            hitoolbox.AppleEnabledInputSources == [
              dvorakQwerty
              polishPro
            ];
          assert
            hitoolbox.AppleSelectedInputSources == [
              dvorakQwerty
            ];
          assert spotlightHotkey.enabled == false;
          assert
            spotlightHotkey.value.parameters == [
              32
              49
              1048576
            ];
          assert spotlightHotkey.value.type == "standard";
          pkgs.runCommand "gamma-macos-defaults-check" { } ''
            set -eu
            touch "$out"
          '';

        gamma-backup-config =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            agent = homeConfig.launchd.agents.gamma-restic-backup;
            expectedCalendarInterval = [
              {
                Day = null;
                Hour = 20;
                Minute = 0;
                Month = null;
                Weekday = null;
              }
            ];
            expectedProgramArguments = [
              program
              "--scheduled"
            ];
            program = builtins.head agent.config.ProgramArguments;
            backupExcludes = pkgs.writeText "expected-backup-excludes" (
              builtins.readFile ./backup-excludes.txt
            );
          in
          assert agent.enable;
          assert agent.config.ProcessType == "Background";
          assert agent.config.RunAtLoad == true;
          assert agent.config.StartInterval == 21600;
          assert agent.config.StartCalendarInterval == expectedCalendarInterval;
          assert agent.config.ProgramArguments == expectedProgramArguments;
          assert
            agent.config.StandardOutPath
            == "/Users/ignacywielogorski/Library/Logs/gamma-restic-backup/launchd-stdout.log";
          assert
            agent.config.StandardErrorPath
            == "/Users/ignacywielogorski/Library/Logs/gamma-restic-backup/launchd-stderr.log";
          pkgs.runCommand "gamma-backup-config-check" { } ''
            set -eu

            test -x ${program}
            test "$(basename ${program})" = "gamma-restic-backup"
            cmp ${backupExcludes} ${./backup-excludes.txt}

            grep -Fqx "export RESTIC_REPOSITORY=b2:gamma-backup-restic:gamma" ${program}
            grep -Fqx "B2_ACCOUNT_ID=\"\$(/usr/bin/security find-generic-password -a \"\$USER\" -s restic-gamma-b2-account-id -w)\"" ${program}
            grep -Fqx "B2_ACCOUNT_KEY=\"\$(/usr/bin/security find-generic-password -a \"\$USER\" -s restic-gamma-b2-account-key -w)\"" ${program}
            grep -Fqx "RESTIC_PASSWORD=\"\$(/usr/bin/security find-generic-password -a \"\$USER\" -s restic-gamma-password -w)\"" ${program}
            grep -Fqx "export B2_ACCOUNT_ID" ${program}
            grep -Fqx "export B2_ACCOUNT_KEY" ${program}
            grep -Fqx "export RESTIC_PASSWORD" ${program}

            grep -Eq '^retry 3 300 backup restic backup "\$\{backup_args\[@\]\}" --exclude-file /nix/store/[a-z0-9]+-source/backup-excludes\.txt$' ${program}
            grep -Fqx "retry 2 300 retention restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune" ${program}
            grep -Fqx '    "$@" && return 0' ${program}
            grep -Fqx "    printf 'Last successful backup is less than 20 hours old; skipping scheduled catch-up.\n'" ${program}

            grep -Fqx "add_backup_path /Users/ignacywielogorski/Documents" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/Desktop" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/Pictures" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/Projects" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/Developer" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/Downloads" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/typst" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/nix" ${program}
            grep -Fqx "add_backup_path /Users/ignacywielogorski/.ssh" ${program}

            ! grep -Eq "^(export )?(B2_ACCOUNT_ID|B2_ACCOUNT_KEY|RESTIC_PASSWORD)='[^$]" ${program}
            ! grep -Eq "^(export )?(B2_ACCOUNT_ID|B2_ACCOUNT_KEY|RESTIC_PASSWORD)=\"[^$]" ${program}

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
            grep -q 'term = xterm-256color' ${ghosttyConfig}
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
            grep -q "bind-key -n C-n run-shell -b 'cd #{q:pane_current_path} && ~/.local/scripts/open-github-repository'" ${tmuxConfig}
            grep -q 'bind-key -n C-o display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "DEV_COMMAND_RUNNER_TARGET_PANE=' ${tmuxConfig}
            grep -q 'bind-key D display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "DEV_COMMAND_RUNNER_TARGET_PANE=' ${tmuxConfig}
            grep -q 'bind-key Y display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/issue-picker"' ${tmuxConfig}
            grep -q 'bind-key T display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/git-branch-switcher"' ${tmuxConfig}
            ! grep -q 'bind-key -n C-i .*issue-picker' ${tmuxConfig}
            grep -q 'bind-key -n C-h if-shell' ${tmuxConfig}
            grep -q 'bind-key -n C-j if-shell' ${tmuxConfig}
            grep -q 'bind-key -n C-k if-shell' ${tmuxConfig}
            grep -q 'bind-key -n C-l if-shell' ${tmuxConfig}
            grep -q 'bind-key -n C-\\\\ if-shell' ${tmuxConfig}
            grep -q "'select-pane -R'" ${tmuxConfig}
            grep -q 'bind-key -n S-Up copy-mode -u \\; send-keys -X scroll-up' ${tmuxConfig}
            grep -q 'bind-key -n S-Down copy-mode \\; send-keys -X scroll-down' ${tmuxConfig}
            grep -q 'bind-key -n S-PPage copy-mode -u \\; send-keys -X page-up' ${tmuxConfig}
            grep -q 'bind-key -n S-NPage copy-mode \\; send-keys -X page-down' ${tmuxConfig}
            grep -q 'bind-key -T copy-mode-vi S-Up send-keys -X scroll-up' ${tmuxConfig}
            grep -q 'bind-key -T copy-mode-vi S-Down send-keys -X scroll-down' ${tmuxConfig}
            grep -q 'bind-key -T copy-mode-vi S-PPage send-keys -X page-up' ${tmuxConfig}
            grep -q 'bind-key -T copy-mode-vi S-NPage send-keys -X page-down' ${tmuxConfig}
            grep -q "set -g @plugin 'seebi/tmux-colors-solarized'" ${tmuxConfig}
            grep -q "set -g @plugin 'niksingh710/minimal-tmux-status'" ${tmuxConfig}
            grep -q "set -g @plugin 'christoomey/vim-tmux-navigator'" ${tmuxConfig}
            grep -q 'set-environment -g TMUX_PLUGIN_MANAGER_PATH ~/.tmux/plugins/' ${tmuxConfig}
            grep -q 'set -g @minimal-tmux-status "top"' ${tmuxConfig}
            grep -q 'set -g @minimal-tmux-bg "#278BD3"' ${tmuxConfig}
            grep -q "set -g @colors-solarized 'dark'" ${tmuxConfig}
            grep -q "if-shell 'test -x ~/.tmux/plugins/tpm/tpm' 'run-shell ~/.tmux/plugins/tpm/tpm'" ${tmuxConfig}
            grep -q 'unbind-key -n C-h' ${tmuxConfig}
            grep -q 'unbind-key -n C-j' ${tmuxConfig}
            grep -q 'unbind-key -n C-k' ${tmuxConfig}
            grep -q 'unbind-key -n C-l' ${tmuxConfig}
            grep -q 'unbind-key -n C-\\\\' ${tmuxConfig}
            ! grep -q 'bind-key -n C-h .*git-branch-switcher' ${tmuxConfig}
            test -x ${tpmSource}/tpm

            touch "$out"
          '';

        gamma-shell-caffeinate-wrappers =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            zshInit = pkgs.writeText "zsh-init" homeConfig.programs.zsh.initContent;
            zshAliases = homeConfig.programs.zsh.shellAliases;
            sessionPath = homeConfig.home.sessionPath;
            sessionVariables = homeConfig.home.sessionVariables;
            homePackages = homeConfig.home.packages;
            piPackage = builtins.head (
              builtins.filter (package: package.name or "" == "pi-coding-agent-0.79.9") homePackages
            );
            codexPackage = builtins.head (
              builtins.filter (package: package.name or "" == "codex") homePackages
            );
            tmuxWrapper = homeConfig.home.file.".local/bin/tmux".source;
          in
          assert homeConfig.personal.hostName == "gamma";
          assert homeConfig.personal.hostPromptSymbol == "γ";
          assert homeConfig.personal.shell.enableWorkstationIntegrations;
          assert builtins.hasAttr "nix-apply-gamma" zshAliases;
          assert builtins.hasAttr "nix-build-gamma" zshAliases;
          assert builtins.hasAttr "nix-eval-gamma" zshAliases;
          assert !(builtins.hasAttr "nix-apply-eta" zshAliases);
          assert builtins.hasAttr "developer" zshAliases;
          assert builtins.hasAttr "deploy" zshAliases;
          assert builtins.hasAttr "tailscale" zshAliases;
          assert !(builtins.hasAttr "codex" zshAliases);
          assert !(builtins.hasAttr "claude" zshAliases);
          assert builtins.elem "/opt/homebrew/bin" sessionPath;
          assert builtins.elem "/opt/homebrew/sbin" sessionPath;
          assert sessionVariables.NVM_DIR == "$HOME/.nvm";
          assert sessionVariables.PNPM_HOME == "$HOME/.local/share/pnpm";
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

              grep -Fq 'codex() {' ${zshInit}
              grep -Fq '/etc/profiles/per-user/$USER/bin/codex "$@"' ${zshInit}
              ! grep -q 'bin="$(whence -p codex)" || return' ${zshInit}
              grep -q 'bin="$(whence -p claude)" || return' ${zshInit}
              ! grep -q 'caffeinate -dims -t 3600 "$bin" --dangerously-bypass-approvals-and-sandbox "$@"' ${zshInit}
              grep -q 'caffeinate -dims -t 3600 "$bin" --dangerously-skip-permissions "$@"' ${zshInit}
              grep -Fq '/etc/profiles/per-user/$USER/bin' ${zshInit}
              grep -Fq '/run/current-system/sw/bin' ${zshInit}
              grep -Fq '/opt/homebrew/bin' ${zshInit}
              grep -Fq '/opt/homebrew/opt/node@20/bin' ${zshInit}
              grep -Fq '$HOME/Library/pnpm' ${zshInit}
              grep -Fq '$PNPM_HOME' ${zshInit}
              grep -Fq 'typeset -U path' ${zshInit}
              grep -Fq "PROMPT='γ %~/ " ${zshInit}
              grep -Fq 'export SSH_AUTH_SOCK="/Users/ignacywielogorski/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"' ${zshInit}
              ! grep -Fq "PROMPT='η %~/ " ${zshInit}
              grep -q "bindkey -s '\^T' 'git-branch-switcher" ${zshInit}
              grep -q "bindkey -s '\^Y' 'issue-picker" ${zshInit}
              grep -q "bindkey -s '\^N' 'open-github-repository" ${zshInit}
              grep -q 'gamma_dev_command_runner_widget()' ${zshInit}
              grep -q 'tmux display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "DEV_COMMAND_RUNNER_TARGET_PANE=' ${zshInit}
              grep -q "bindkey '\^O' gamma_dev_command_runner_widget" ${zshInit}
              ! grep -q "bindkey -s '\^I' 'issue-picker" ${zshInit}

              test -x ${piPackage}/bin/pi
              test "$(${piPackage}/bin/pi --version)" = "0.79.9"
              test -x ${codexPackage}/bin/codex
              grep -Fq 'pnpm_codex_bin="''${PNPM_HOME:-$HOME/.local/share/pnpm}/codex"' ${codexPackage}/bin/codex
              grep -Fq 'homebrew_codex_bin="/opt/homebrew/bin/codex"' ${codexPackage}/bin/codex
              grep -Fq 'exec /usr/bin/caffeinate -dims -t 3600 "$codex_bin" --dangerously-bypass-approvals-and-sandbox --dangerously-bypass-hook-trust "$@"' ${codexPackage}/bin/codex
              test -x ${tmuxWrapper}
              grep -Fq 'tmux-3.3a/bin/tmux' ${tmuxWrapper}
              grep -Fq '/usr/bin/open -na Ghostty.app --args --term=xterm-256color -e "$tmux_bin" "$@"' ${tmuxWrapper}

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

              cat > "$bin/claude" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'real claude should be wrapped\n'
              EOF
              chmod +x "$bin/claude"

              home="$TMPDIR/home"
              mkdir -p "$home"

              HOME="$home" PATH="$bin:${pkgs.coreutils}/bin:${pkgs.zsh}/bin" zsh -f <<EOF > "$TMPDIR/wrapper.log"
              source ${zshInit}
              claude --version
              EOF

              grep -Eq 'caffeinate args: <-dims> <-t> <3600> <.*/claude> <--dangerously-skip-permissions> <--version>' "$TMPDIR/wrapper.log"

              touch "$out"
            '';

        gamma-eta-remote-access =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            sshSettings = homeConfig.programs.ssh.settings;
            zshAliases = homeConfig.programs.zsh.shellAliases;
            etaShell = pkgs.writeText "eta-shell" homeConfig.home.file.".local/scripts/eta-shell".text;
            etaService = pkgs.writeText "eta-service" homeConfig.home.file.".local/scripts/eta-service".text;
          in
          assert builtins.hasAttr "eta" sshSettings;
          assert sshSettings.eta.data.HostName == "eta.sparrow-pomano.ts.net";
          assert sshSettings.eta.data.User == "ignacywielogorski";
          assert !(builtins.hasAttr "mini" sshSettings);
          assert zshAliases.sm == "ssh eta";
          pkgs.runCommand "gamma-eta-remote-access-check" { } ''
            set -eu

            grep -Fq 'exec ssh eta "$@"' ${etaShell}
            grep -Fq 'eta-service: invoke eta Service Control Commands over SSH.' ${etaService}
            grep -Fq 'Service Control Commands run authoritatively on eta.' ${etaService}
            grep -Fq 'canonical SSH Host Alias eta' ${etaService}
            grep -Fq 'exec ssh eta -- eta-service "$@"' ${etaService}

            ${pkgs.bash}/bin/bash ${etaService} --help > "$TMPDIR/eta-service-help.txt"
            grep -Fq 'Service Control Commands run authoritatively on eta.' "$TMPDIR/eta-service-help.txt"
            grep -Fq 'eta-service inspect <stack>' "$TMPDIR/eta-service-help.txt"

            touch "$out"
          '';

        gamma-claude-config =
          pkgs.runCommand "gamma-claude-config-check"
            {
              nativeBuildInputs = [
                pkgs.jq
              ];
            }
            ''
              set -eu

              jq -e '
                .hooks.PermissionRequest[0].matcher == "*" and
                .hooks.PermissionRequest[0].hooks[0].type == "command" and
                (.hooks.PermissionRequest[0].hooks[0].command | test("notify")) and
                .hooks.Notification[0].matcher == "idle_prompt|elicitation_dialog" and
                (.hooks.Notification[0].hooks[0].command | test("notify")) and
                (.hooks.Stop[0].hooks[0].command | test("notify"))
              ' ${./config/claude/settings.json} >/dev/null

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
          assert builtins.any (name: builtins.match ".*pytest.*" name != null) homePackageNames;
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
            devCommandRunner = homeConfig.home.file.".local/scripts/dev-command-runner".source;
            gitBranchSwitcher = homeConfig.home.file.".local/scripts/git-branch-switcher".source;
            issuePicker = homeConfig.home.file.".local/scripts/issue-picker".source;
            openGithubRepository = homeConfig.home.file.".local/scripts/open-github-repository".source;
            typstSmartOpen = homeConfig.home.file.".local/scripts/typst-smart-open".source;
            backupRestorePicker = homeConfig.home.file.".local/scripts/backup-restore-picker".source;
            typstTemplate = homeConfig.home.file."typst/academic-template.typ".source;
            homebrewBrewfile = pkgs.writeText "Brewfile" gammaConfiguration.config.homebrew.brewfile;
            homebrewBrews = gammaConfiguration.config.homebrew.brews;
            homebrewBrewNames = builtins.map (brew: brew.name) homebrewBrews;
            homebrewCasks = gammaConfiguration.config.homebrew.casks;
            homebrewCaskNames = builtins.map (cask: cask.name) homebrewCasks;
            homebrewMasApps = gammaConfiguration.config.homebrew.masApps;
            defaultAppsModule = ./modules/darwin/default-apps.nix;
            defaultAppsActivation = pkgs.writeText "default-apps-activation" gammaConfiguration.config.system.activationScripts.postActivation.text;
            systemPackages = gammaConfiguration.config.environment.systemPackages;
            packageNames = builtins.map (package: package.name or "") systemPackages;
          in
          assert builtins.elem "mas" homebrewBrewNames;
          assert !(builtins.elem "tmux" homebrewBrewNames);
          assert builtins.elem "goku" homebrewBrewNames;
          assert builtins.elem "libpq" homebrewBrewNames;
          assert builtins.elem "keka" homebrewCaskNames;
          assert builtins.elem "qutebrowser" homebrewCaskNames;
          assert builtins.elem "tailscale-app" homebrewCaskNames;
          assert homebrewMasApps.Bitwarden == 1352778147;
          assert homebrewMasApps.Flighty == 1358823008;
          assert homebrewMasApps.WhatsApp == 310633997;
          assert builtins.any (name: builtins.match ".*chafa.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*bat.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*fzf.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*gh.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*glow.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*git.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*jq.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*lazygit.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*lazysql.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*neovim.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*posting.*" name != null) packageNames;
          assert builtins.any (name: builtins.match ".*restic.*" name != null) packageNames;
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
                pkgs.jq
                pkgs.zsh
              ];
            }
            ''
              set -eu

              test -x ${tmuxSessionizer}
              test -x ${devCommandRunner}
              test -x ${gitBranchSwitcher}
              test -x ${issuePicker}
              test -x ${openGithubRepository}
              test -x ${typstSmartOpen}
              test -x ${backupRestorePicker}
              test -r ${typstTemplate}
              grep -q 'tmux session> ' ${tmuxSessionizer}
              grep -q 'issue> ' ${issuePicker}
              grep -q 'issue action> ' ${issuePicker}
              grep -q 'open-github-repository' ${openGithubRepository}
              grep -q 'github_repo_from_remote' ${issuePicker}
              grep -q 'pbcopy' ${issuePicker}
              grep -q 'git switch -c "$branch_name"' ${issuePicker}
              grep -q 'README: %s' ${tmuxSessionizer}
              grep -q 'glow -s dark' ${tmuxSessionizer}
              ! grep -q 'chafa' ${tmuxSessionizer}
              grep -q 'Recent commits:' ${tmuxSessionizer}
              grep -Fq '[[ -d "$HOME/typst" ]] && printf' ${tmuxSessionizer}
              grep -q 'typst document> ' ${typstSmartOpen}
              grep -q 'typst compile --pages 1' ${typstSmartOpen}
              grep -q 'Type a new document name' ${typstSmartOpen}
              grep -q 'dev command> ' ${devCommandRunner}
              grep -q 'package_manager()' ${devCommandRunner}
              grep -q 'pnpm-lock.yaml' ${devCommandRunner}
              grep -q 'git rev-parse --show-toplevel' ${devCommandRunner}
              grep -q 'DEV_COMMAND_RUNNER_TARGET_PANE' ${devCommandRunner}
              grep -q 'tmux send-keys -t "$DEV_COMMAND_RUNNER_TARGET_PANE"' ${devCommandRunner}
              grep -q 'backup snapshot> ' ${backupRestorePicker}
              grep -q 'backup file> ' ${backupRestorePicker}
              grep -q 'backup action> ' ${backupRestorePicker}
              grep -q 'restore-to-review-dir' ${backupRestorePicker}
              grep -q 'Type restore to run this command' ${backupRestorePicker}
              ! grep -q 'restore-original-path' ${backupRestorePicker}
              grep -q 'com.aone.keka' ${defaultAppsModule}
              grep -q 'asc.onlyoffice.ONLYOFFICE' ${defaultAppsModule}
              grep -q '/bin/duti' ${defaultAppsActivation}
              grep -q 'keka-archive-defaults.duti' ${defaultAppsActivation}
              grep -q 'onlyoffice-document-defaults.duti' ${defaultAppsActivation}
              grep -q 'brew link --force libpq' ${defaultAppsActivation}
              grep -q 'brew "koekeishiya/formulae/yabai", trusted: true' ${homebrewBrewfile}
              grep -q 'brew "koekeishiya/formulae/skhd", trusted: true' ${homebrewBrewfile}

              test "$(ISSUE_PICKER_TEST_REMOTE=1 ${issuePicker} git@github.com:IgnacyWie/nix.git)" = "IgnacyWie/nix"
              test "$(ISSUE_PICKER_TEST_REMOTE=1 ${issuePicker} https://github.com/IgnacyWie/nix.git)" = "IgnacyWie/nix"
              test "$(ISSUE_PICKER_TEST_REMOTE=1 ${issuePicker} https://github.com/IgnacyWie/nix)" = "IgnacyWie/nix"
              test "$(OPEN_GITHUB_REPOSITORY_TEST_REMOTE=1 ${openGithubRepository} git@github.com:IgnacyWie/nix.git)" = "https://github.com/IgnacyWie/nix"
              test "$(OPEN_GITHUB_REPOSITORY_TEST_REMOTE=1 ${openGithubRepository} ssh://git@github.com/IgnacyWie/nix.git)" = "https://github.com/IgnacyWie/nix"
              test "$(OPEN_GITHUB_REPOSITORY_TEST_REMOTE=1 ${openGithubRepository} https://github.com/IgnacyWie/nix.git)" = "https://github.com/IgnacyWie/nix"

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

              : > "$TMPDIR/tmux.log"
              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.zsh}/bin" \
                HOME="$home" \
                TMPDIR="$TMPDIR" \
                env -u TMUX ${tmuxSessionizer} 2> "$TMPDIR/sessionizer-notty.err"

              grep -q 'Prepared tmux session example-project' "$TMPDIR/sessionizer-notty.err"
              grep -q 'new-session -ds example-project -c' "$TMPDIR/tmux.log"
              ! grep -q 'attach' "$TMPDIR/tmux.log"
              ! grep -q 'switch-client' "$TMPDIR/tmux.log"

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

              cat > "$bin/gh" <<'EOF'
              #!${pkgs.runtimeShell}
              case "$1 $2" in
                "issue list")
                  printf '#31    feat(scripts): add fuzzy GitHub issue picker                    ready-for-agent \n'
                  ;;
                "issue view")
                  printf '{"number":31,"title":"feat(scripts): add fuzzy GitHub issue picker","url":"https://github.com/IgnacyWie/nix/issues/31"}\n'
                  ;;
                *)
                  printf 'unexpected gh call: %s\n' "$*" >&2
                  exit 1
                  ;;
              esac
              EOF
              chmod +x "$bin/gh"

              cat > "$bin/pbcopy" <<'EOF'
              #!${pkgs.runtimeShell}
              cat > "$TMPDIR/pbcopy.log"
              EOF
              chmod +x "$bin/pbcopy"

              cat > "$bin/open" <<'EOF'
              #!${pkgs.runtimeShell}
              printf '%s\n' "$*" > "$TMPDIR/open.log"
              EOF
              chmod +x "$bin/open"

              mkdir -p "$home/Developer/issue-project"
              cd "$home/Developer/issue-project"
              git init
              git config user.email test@example.com
              git config user.name Test
              git remote add origin git@github.com:IgnacyWie/nix.git
              printf 'main\n' > README.md
              git add README.md
              git commit -m initial

              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.git}/bin" \
                HOME="$home" \
                TMPDIR="$TMPDIR" \
                OPEN_GITHUB_REPOSITORY_OPEN_COMMAND="$bin/open" \
                ${openGithubRepository}

              test "$(cat "$TMPDIR/open.log")" = "https://github.com/IgnacyWie/nix"

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              exit 130
              EOF
              chmod +x "$bin/fzf"

              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.git}/bin:${pkgs.gnused}/bin:${pkgs.jq}/bin" \
                HOME="$home" \
                TMPDIR="$TMPDIR" \
                ${issuePicker}

              test ! -e "$TMPDIR/pbcopy.log"
              test "$(git branch --show-current)" = "master"

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              count_file="$TMPDIR/issue-picker-fzf-count"
              count=0
              if [ -f "$count_file" ]; then
                count=$(cat "$count_file")
              fi
              count=$((count + 1))
              printf '%s\n' "$count" > "$count_file"
              case "$count" in
                1) printf '#31    feat(scripts): add fuzzy GitHub issue picker                    ready-for-agent \n' ;;
                2) printf 'copy-url\n' ;;
              esac
              EOF
              chmod +x "$bin/fzf"
              rm -f "$TMPDIR/issue-picker-fzf-count"

              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.git}/bin:${pkgs.gnused}/bin:${pkgs.jq}/bin" \
                HOME="$home" \
                TMPDIR="$TMPDIR" \
                ${issuePicker}

              test "$(cat "$TMPDIR/pbcopy.log")" = "https://github.com/IgnacyWie/nix/issues/31"

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              count_file="$TMPDIR/issue-picker-fzf-count"
              count=0
              if [ -f "$count_file" ]; then
                count=$(cat "$count_file")
              fi
              count=$((count + 1))
              printf '%s\n' "$count" > "$count_file"
              case "$count" in
                1) printf '#31    feat(scripts): add fuzzy GitHub issue picker                    ready-for-agent \n' ;;
                2) printf 'branch\n' ;;
              esac
              EOF
              chmod +x "$bin/fzf"
              rm -f "$TMPDIR/issue-picker-fzf-count"

              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.git}/bin:${pkgs.gnused}/bin:${pkgs.jq}/bin" \
                HOME="$home" \
                TMPDIR="$TMPDIR" \
                ${issuePicker}

              test "$(git branch --show-current)" = "issue-31-add-fuzzy-github-issue-picker"

              git switch master
              rm -f "$TMPDIR/issue-picker-fzf-count"

              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.git}/bin:${pkgs.gnused}/bin:${pkgs.jq}/bin" \
                HOME="$home" \
                TMPDIR="$TMPDIR" \
                ${issuePicker}

              test "$(git branch --show-current)" = "issue-31-add-fuzzy-github-issue-picker"

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

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'issue-11-check\n'
              EOF
              chmod +x "$bin/fzf"

              : > "$TMPDIR/tmux.log"
              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.zsh}/bin" \
                HOME="$home" \
                TMPDIR="$TMPDIR" \
                env -u TMUX zsh -f ${typstSmartOpen} 2> "$TMPDIR/typst-notty.err"

              grep -q 'Created tmux session typst_' "$TMPDIR/typst-notty.err"
              grep -q 'new-session -d -s typst_' "$TMPDIR/tmux.log"
              grep -q "nvim 'issue-11-check.typ'" "$TMPDIR/tmux.log"
              ! grep -q 'attach-session' "$TMPDIR/tmux.log"
              ! grep -q 'switch-client' "$TMPDIR/tmux.log"

              rm -rf "$TMPDIR/dev-project" "$TMPDIR/dev-command.log" "$TMPDIR/dev-fzf-list.log"
              mkdir -p "$TMPDIR/dev-project/subdir" "$TMPDIR/dev-project/scripts"
              cd "$TMPDIR/dev-project"
              git init
              git config user.email test@example.com
              git config user.name Test
              touch pnpm-lock.yaml
              cat > package.json <<'EOF'
              {
                "name": "dev-command-runner-check",
                "packageManager": "pnpm@10.0.0",
                "scripts": {
                  "dev": "vite --host 127.0.0.1",
                  "lint": "eslint .",
                  "typecheck": "tsc --noEmit",
                  "test": "vitest run"
                }
              }
              EOF
              cat > justfile <<'EOF'
              check:
                nix flake check

              _private:
                echo hidden
              EOF
              cat > Makefile <<'EOF'
              test:
              	echo test

              _internal:
              	echo hidden
              EOF
              cat > flake.nix <<'EOF'
              { outputs = { self }: { }; }
              EOF
              cat > scripts/check <<'EOF'
              #!/usr/bin/env bash
              echo check
              EOF
              chmod +x scripts/check
              git add .
              git commit -m initial

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              printf '%s\n' "$*" > "$TMPDIR/dev-fzf-args.log"
              cat > "$TMPDIR/dev-fzf-list.log"
              if [ "''${FZF_CANCEL:-0}" = 1 ]; then
                exit 130
              fi
              grep -F "$FZF_SELECT" "$TMPDIR/dev-fzf-list.log" | head -n 1
              EOF
              chmod +x "$bin/fzf"

              cat > "$bin/pnpm" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'pwd=%s\nargs=%s\n' "$PWD" "$*" > "$TMPDIR/dev-command.log"
              EOF
              chmod +x "$bin/pnpm"

              cd "$TMPDIR/dev-project/subdir"
              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.git}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.jq}/bin" \
                TMPDIR="$TMPDIR" \
                FZF_SELECT="pnpm run dev" \
                ${devCommandRunner}

              grep -q $'package.json\tpnpm run dev' "$TMPDIR/dev-fzf-list.log"
              grep -q $'package.json\tpnpm run typecheck' "$TMPDIR/dev-fzf-list.log"
              grep -q $'package.json\tpnpm test' "$TMPDIR/dev-fzf-list.log"
              grep -q $'justfile\tjust check' "$TMPDIR/dev-fzf-list.log"
              grep -q $'Makefile\tmake test' "$TMPDIR/dev-fzf-list.log"
              grep -q $'nix\tnix flake check' "$TMPDIR/dev-fzf-list.log"
              grep -q $'scripts\t./scripts/check' "$TMPDIR/dev-fzf-list.log"
              grep -q -- '--bind=left-click:accept' "$TMPDIR/dev-fzf-args.log"
              grep -q "pwd=$TMPDIR/dev-project" "$TMPDIR/dev-command.log"
              grep -q 'args=run dev' "$TMPDIR/dev-command.log"

              rm -f "$TMPDIR/dev-command.log"
              : > "$TMPDIR/tmux.log"
              cd "$TMPDIR/dev-project/subdir"
              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.git}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.jq}/bin" \
                TMPDIR="$TMPDIR" \
                TMUX=1 \
                DEV_COMMAND_RUNNER_TARGET_PANE="%1" \
                FZF_SELECT="pnpm run dev" \
                ${devCommandRunner}

              test ! -e "$TMPDIR/dev-command.log"
              grep -Fq "tmux send-keys -t %1 cd $TMPDIR/dev-project && pnpm run dev C-m" "$TMPDIR/tmux.log"

              rm -f "$TMPDIR/dev-command.log"
              PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.git}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.jq}/bin" \
                TMPDIR="$TMPDIR" \
                FZF_CANCEL=1 \
                FZF_SELECT="pnpm run dev" \
                ${devCommandRunner}
              test ! -e "$TMPDIR/dev-command.log"

              rm -f "$TMPDIR/restic.log" "$TMPDIR/pbcopy.log" "$TMPDIR/fzf.log"

              cat > "$bin/security" <<'EOF'
              #!${pkgs.runtimeShell}
              case "$*" in
                *restic-gamma-b2-account-id*) printf 'b2-account-id\n' ;;
                *restic-gamma-b2-account-key*) printf 'b2-account-key\n' ;;
                *restic-gamma-password*) printf 'restic-password\n' ;;
                *) exit 1 ;;
              esac
              EOF
              chmod +x "$bin/security"

              cat > "$bin/restic" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'restic %s\n' "$*" >> "$TMPDIR/restic.log"
              case "$1" in
                snapshots)
                  cat <<'JSON'
              [
                {
                  "time": "2026-01-02T03:04:05Z",
                  "id": "abc123def456",
                  "short_id": "abc123de",
                  "hostname": "gamma",
                  "paths": ["/Users/ignacywielogorski/Documents"],
                  "tags": ["manual"],
                  "summary": {"total_files_processed": 2}
                }
              ]
              JSON
                  ;;
                ls)
                  cat <<'JSON'
              {"path":"/Users/ignacywielogorski/Documents","type":"dir","mtime":"2026-01-02T03:04:05Z"}
              {"path":"/Users/ignacywielogorski/Documents/check.txt","type":"file","size":12,"mtime":"2026-01-02T03:04:05Z"}
              JSON
                  ;;
                dump)
                  printf 'hello backup\n'
                  ;;
                restore)
                  printf 'restore %s\n' "$*" >> "$TMPDIR/restore.log"
                  ;;
              esac
              EOF
              chmod +x "$bin/restic"

              cat > "$bin/fzf" <<'EOF'
              #!${pkgs.runtimeShell}
              printf 'fzf %s\n' "$*" >> "$TMPDIR/fzf.log"

              preview=""
              args=("$@")
              for ((i = 0; i < $#; i++)); do
                case "''${args[$i]}" in
                  --preview)
                    if [ $((i + 1)) -lt $# ]; then
                      preview="''${args[$((i + 1))]}"
                    fi
                    ;;
                  --preview=*)
                    preview="''${args[$i]#--preview=}"
                    ;;
                esac
              done

              run_preview() {
                local preview_selected="$1"
                local output="$2"
                local quoted_selected
                local preview_command

                if [ -z "$preview" ]; then
                  return 0
                fi

                printf -v quoted_selected '%q' "$preview_selected"
                preview_command="''${preview//\"\{\}\"/$quoted_selected}"
                preview_command="''${preview_command//\{\}/$quoted_selected}"
                ( eval "$preview_command" ) > "$output"
              }

              input=$(cat)
              case "$*" in
                *"backup snapshot> "*)
                  if [ "''${BACKUP_RESTORE_PICKER_CANCEL_STAGE:-}" = snapshot ]; then
                    exit 130
                  fi
                  selected=$(printf '%s\n' "$input" | sed -n '1p')
                  run_preview "$selected" "$TMPDIR/snapshot-preview.out"
                  printf '%s\n' "$selected"
                  ;;
                *"backup file> "*)
                  if [ "''${BACKUP_RESTORE_PICKER_CANCEL_STAGE:-}" = file ]; then
                    exit 130
                  fi
                  selected=$(printf '%s\n' "$input" | grep '/Users/ignacywielogorski/Documents/check.txt')
                  run_preview "$selected" "$TMPDIR/file-preview.out"
                  printf '%s\n' "$selected"
                  ;;
                *"backup action> "*)
                  printf '%s\n' "''${BACKUP_RESTORE_PICKER_ACTION:-print-command}"
                  ;;
                *)
                  exit 1
                  ;;
              esac
              EOF
              chmod +x "$bin/fzf"

              cat > "$bin/pbcopy" <<'EOF'
              #!${pkgs.runtimeShell}
              cat > "$TMPDIR/pbcopy.log"
              EOF
              chmod +x "$bin/pbcopy"

              picker_env="PATH=$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.jq}/bin HOME=$home USER=tester TMPDIR=$TMPDIR BACKUP_RESTORE_PICKER_SECURITY_BIN=$bin/security BACKUP_RESTORE_PICKER_PBCOPY_BIN=$bin/pbcopy BACKUP_RESTORE_PICKER_NOW=20260102-030405"

              env $picker_env BACKUP_RESTORE_PICKER_CANCEL_STAGE=snapshot ${backupRestorePicker} > "$TMPDIR/cancel-snapshot.out"
              ! grep -q 'restore abc123de' "$TMPDIR/restic.log"

              env $picker_env BACKUP_RESTORE_PICKER_CANCEL_STAGE=file ${backupRestorePicker} > "$TMPDIR/cancel-file.out"
              ! grep -q 'restore abc123de' "$TMPDIR/restic.log"

              env $picker_env BACKUP_RESTORE_PICKER_ACTION=print-command ${backupRestorePicker} > "$TMPDIR/print-command.out"
              grep -q 'restic restore abc123de --target .*/Restores/restic-abc123de-20260102-030405 --include /Users/ignacywielogorski/Documents/check.txt' "$TMPDIR/print-command.out"
              ! grep -q -- '--target /Users/ignacywielogorski/Documents' "$TMPDIR/print-command.out"
              grep -q 'summary: {"total_files_processed":2}' "$TMPDIR/snapshot-preview.out"
              grep -q 'hello backup' "$TMPDIR/file-preview.out"

              env $picker_env BACKUP_RESTORE_PICKER_ACTION=copy-command ${backupRestorePicker} > "$TMPDIR/copy-command.out"
              grep -q 'Copied restore command to clipboard' "$TMPDIR/copy-command.out"
              grep -q 'restic restore abc123de --target .*/Restores/restic-abc123de-20260102-030405 --include /Users/ignacywielogorski/Documents/check.txt' "$TMPDIR/pbcopy.log"

              if printf '\n' | env $picker_env BACKUP_RESTORE_PICKER_ACTION=restore-to-review-dir ${backupRestorePicker} > "$TMPDIR/restore-refused.out" 2> "$TMPDIR/restore-refused.err"; then
                printf 'restore-to-review-dir unexpectedly succeeded without confirmation\n' >&2
                exit 1
              fi
              grep -q 'Restore cancelled; confirmation did not match.' "$TMPDIR/restore-refused.err"
              ! grep -q 'restore abc123de' "$TMPDIR/restic.log"

              rm -f "$TMPDIR/restore.log"
              printf 'restore\n' | env $picker_env BACKUP_RESTORE_PICKER_ACTION=restore-to-review-dir ${backupRestorePicker} > "$TMPDIR/restore-confirmed.out"
              grep -q 'restore restore abc123de --target .*/Restores/restic-abc123de-20260102-030405 --include /Users/ignacywielogorski/Documents/check.txt' "$TMPDIR/restore.log"
              grep -q 'Restore completed into review directory: .*/Restores/restic-abc123de-20260102-030405' "$TMPDIR/restore-confirmed.out"
              test -d "$home/Restores/restic-abc123de-20260102-030405"

              cat > "$bin/security-fail" <<'EOF'
              #!${pkgs.runtimeShell}
              exit 1
              EOF
              chmod +x "$bin/security-fail"

              if env $picker_env BACKUP_RESTORE_PICKER_SECURITY_BIN=$bin/security-fail ${backupRestorePicker} > "$TMPDIR/missing-config.out" 2> "$TMPDIR/missing-config.err"; then
                printf 'backup-restore-picker unexpectedly succeeded with missing Restic configuration\n' >&2
                exit 1
              fi
              grep -q 'missing Restic configuration' "$TMPDIR/missing-config.err"

              touch "$out"
            '';

        gamma-window-management-config =
          let
            homeConfig = gammaConfiguration.config.home-manager.users.ignacywielogorski;
            homebrewBrewfile = pkgs.writeText "Brewfile" gammaConfiguration.config.homebrew.brewfile;
            homebrewCasks = gammaConfiguration.config.homebrew.casks;
            homebrewCaskNames = builtins.map (cask: cask.name) homebrewCasks;
            karabinerEdn = homeConfig.xdg.configFile."karabiner.edn".source;
            karabinerConfig = ./config/karabiner/karabiner.json;
            karabinerActivation = pkgs.writeText "generate-karabiner-json-activation" homeConfig.home.activation.generateKarabinerJson.data;
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
              test -r ${karabinerEdn}
              test -r ${karabinerGermanLetters}
              test -r ${karabinerZathura}
              test -r ${skhdConfig}
              test -x ${yabaiConfig}
              test ! -e ${./config/karabiner}/automatic_backups

              grep -q 'GOKU_EDN_CONFIG_FILE=' ${karabinerActivation}
              grep -q '/opt/homebrew/bin/goku' ${karabinerActivation}
              grep -q 'install -m 0644' ${karabinerActivation}
              jq -e '.profiles[] | select(.name == "Default" and .selected == true)' ${karabinerConfig} > /dev/null
              jq -e '.profiles[] | select(.name == "Minecraft")' ${karabinerConfig} > /dev/null
              jq -e '.profiles[] | select(.name == "Default").virtual_hid_keyboard.keyboard_type_v2 == "iso"' ${karabinerConfig} > /dev/null
              grep -q "Map Command + ' to Ctrl+Q only in Zathura" ${karabinerConfig}
              grep -q 'Easier Pane Switching' ${karabinerConfig}
              grep -q 'Easier Pane Sending' ${karabinerConfig}
              grep -q 'Display Brightness simlayer' ${karabinerConfig}
              grep -q ':profiles' ${karabinerEdn}
              grep -q ':Default' ${karabinerEdn}
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

        gamma-sanitized-inventory =
          pkgs.runCommand "gamma-sanitized-inventory-check"
            {
              nativeBuildInputs = [
                pkgs.findutils
                pkgs.gnugrep
              ];
            }
            ''
              set -eu

              test -f ${./inventory/README.md}
              test -f ${./inventory/homebrew-formulae.md}
              test -f ${./inventory/homebrew-casks.md}
              test -f ${./inventory/mas-apps.md}
              test -f ${./inventory/shell.md}
              test -f ${./inventory/editor.md}
              test -f ${./inventory/ssh-gpg.md}
              test -f ${./inventory/directories.md}
              test -f ${./inventory/cloud-services.md}
              test -f ${./inventory/licenses.md}
              test -f ${./inventory/permissions.md}
              test -f ${./inventory/intel-only-apps.md}
              test -f ${./inventory/keyboard-input.md}
              test -f ${./inventory/security-validation.md}
              test -f ${./inventory/future-v2.md}

              grep -q 'Personal Infrastructure' ${./inventory/README.md}
              grep -q 'Workstation' ${./inventory/README.md}
              grep -q 'Host Family' ${./inventory/README.md}
              grep -q 'Host Name' ${./inventory/README.md}
              grep -q 'Primary User' ${./inventory/README.md}
              grep -q 'Primary Editor' ${./inventory/README.md}
              grep -q 'Secret Store' ${./inventory/README.md}

              grep -q 'private SSH keys' ${./inventory/security-validation.md}
              grep -q 'API tokens' ${./inventory/security-validation.md}
              grep -q 'Restic passwords' ${./inventory/security-validation.md}
              grep -q 'raw secret-bearing shell files' ${./inventory/security-validation.md}
              grep -q 'generated Karabiner backups' ${./inventory/security-validation.md}

              grep -q 'Vaultwarden' ${./inventory/future-v2.md}
              grep -q 'Nix installer' ${./inventory/future-v2.md}
              grep -q 'Homebrew cleanup' ${./inventory/future-v2.md}
              grep -q 'SSH key recovery' ${./inventory/future-v2.md}
              grep -q 'project development shells' ${./inventory/future-v2.md}

              ! find ${./inventory} -type f \
                \( \
                  -iname '.env' \
                  -o -iname '.env.*' \
                  -o -iname '*keychain*.json' \
                  -o -iname '*keychain*.plist' \
                  -o -iname '*vaultwarden*.csv' \
                  -o -iname '*vaultwarden*.json' \
                  -o -iname '*bitwarden*.csv' \
                  -o -iname '*bitwarden*.json' \
                  -o -iname '*1password*.csv' \
                  -o -iname '*1password*.json' \
                  -o -iname 'id_rsa' \
                  -o -iname 'id_dsa' \
                  -o -iname 'id_ecdsa' \
                  -o -iname 'id_ed25519' \
                  -o -iname '*.pem' \
                \) | grep -q .

              touch "$out"
            '';
      };
    };
}
