{
  config,
  lib,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;

  devForwards = [
    "3000 localhost:3000"
    "3001 localhost:3001"
    "3002 localhost:3002"
    "3003 localhost:3003"
    "3004 localhost:3004"
    "3005 localhost:3005"
    "8787 localhost:8787"
    "8384 localhost:8385"
  ];

  workstationHost = hostName: {
    HostName = hostName;
    User = "bean";
    ForwardAgent = true;
    ExitOnForwardFailure = false;
    LogLevel = "Quiet";
    LocalForward = devForwards;
    ControlPath = "~/.ssh/sockets/%r@%h-%p";
  };
in
{
  home.activation.createSshSocketsDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${homeDirectory}/.ssh/sockets"}
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.orbstack/ssh/config"
    ];

    settings = {
      kubernetes-1 = {
        HostName = "192.168.178.41";
        User = "bean";
      };

      lxc-docker = {
        HostName = "192.168.178.170";
        User = "bean";
      };

      vps = {
        HostName = "server.wie.dev";
        User = "root";
      };

      eta = {
        HostName = "eta.sparrow-pomano.ts.net";
        User = "ignacywielogorski";
      };

      mini = {
        HostName = "eta.sparrow-pomano.ts.net";
        User = "ignacywielogorski";
      };

      mycard = {
        HostName = "mycard.sparrow-pomano.ts.net";
        User = "mycard";
      };

      dev = workstationHost "workstation-1.sparrow-pomano.ts.net";
      dev-old = workstationHost "workstation.sparrow-pomano.ts.net";

      "*" = {
        AddKeysToAgent = "yes";
        Compression = false;
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
        ForwardAgent = false;
        HashKnownHosts = false;
        IdentityFile = "~/.ssh/id_ed25519_github";
        ServerAliveCountMax = 3;
        ServerAliveInterval = 0;
        SetEnv = {
          TERM = "xterm-256color";
        };
        UseKeychain = "yes";
        UserKnownHostsFile = "~/.ssh/known_hosts";
      };
    };
  };
}
