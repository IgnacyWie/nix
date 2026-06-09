# Personal Infrastructure

This context defines the language for a personal infrastructure repository that starts with one macOS workstation and may later include home servers.

## Language

**Personal Infrastructure**:
A reproducible description of the user's machines, tools, configuration, and supporting recovery process. It begins with the personal Mac and is allowed to grow to home servers without pretending to be a general-purpose platform.
_Avoid_: Dotfiles, backup repo, Nix platform

**Workstation**:
The personal macOS machine used for daily work and development.
_Avoid_: Laptop, Mac, client

**Host Family**:
A grouping of machines by operating system and configuration model, such as Darwin workstations or NixOS servers.
_Avoid_: Platform, role, environment

**Host Name**:
The canonical short name for a machine across the flake output and operating system identity. The current workstation's host name is `gamma`.
_Avoid_: Computer name, device name, machine alias

**Primary User**:
The local macOS account managed for the workstation. On `gamma`, the primary user is `ignacywielogorski`.
_Avoid_: Account, profile, owner

**Primary Editor**:
The editor whose configuration is managed as part of the workstation setup. On `gamma`, the primary editor is Neovim.
_Avoid_: Editor, IDE

**Secret Store**:
The external place where credentials and private keys are kept outside the repository. `gamma` is a Vaultwarden client; it does not host Vaultwarden.
_Avoid_: Password manager, secrets backend
