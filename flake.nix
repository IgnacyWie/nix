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

      checks.${system}.gamma-backup-config =
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
    };
}
