# Personal Infrastructure

This context defines the language for a personal infrastructure repository that starts with one macOS workstation and may later include home servers.

## Language

**Personal Infrastructure**:
A reproducible description of the user's machines, tools, configuration, and supporting recovery process. It begins with the personal Mac and is allowed to grow to home servers without pretending to be a general-purpose platform.
_Avoid_: Dotfiles, backup repo, Nix platform

**Workstation**:
The personal macOS machine used for daily work and development.
_Avoid_: Laptop, Mac, client

**Personal Assistant Agent**:
An AI-assisted Home Server capability for the user's calendar, tasks, documents, and email. It is intended to be always available, remotely reachable through the Home Server Access Model, and centered on personal services rather than Workstation-local app state.
_Avoid_: Bot, secretary, automation script

**Assistant Runtime Home**:
The host family boundary where the Personal Assistant Agent normally runs. In v1, the Assistant Runtime Home is the Home Server rather than the Workstation.
_Avoid_: Deployment target, agent host, assistant machine

**Assistant Interaction Surface**:
The primary channel through which the user talks to the Personal Assistant Agent. In v1, the Assistant Interaction Surface is a Telegram bot rather than Pi CLI, direct web UI, or email.
_Avoid_: Chat UI, frontend, command channel

**Assistant Runtime Shape**:
The process form of the Personal Assistant Agent. In v1, the assistant is a long-running Pi SDK service on the Home Server rather than an interactive Pi extension, with an optional Pi extension reserved for later debugging or administration.
_Avoid_: App type, service architecture, bot daemon

**Host-Managed Assistant Service**:
A Personal Assistant Agent service managed directly by the Home Server operating system rather than as a Docker Compose Service Stack. In v1, this shape is used because the assistant depends on Home Server local app automation.
_Avoid_: Containerized assistant, compose bot, unmanaged script

**Assistant Durable State**:
The Personal Assistant Agent state that must survive service restarts and Home Server recovery. In v1, pending approvals, staged actions, audit history, and conversation summaries live under the Service Data Root, likely in SQLite plus an append-only audit log.
_Avoid_: Bot database, memory, chat history

**Assistant Secret Projection**:
The local untracked copy of Personal Assistant Agent credentials used by the Home Server service. In v1, `apps/personal-assistant/.env` may project secrets from the Secret Store and be protected by local backup, but it is not the canonical Secret Store and must never be committed.
_Avoid_: Secret source, checked-in environment, credential store

**Assistant Audit Boundary**:
The accountability scope for Personal Assistant Agent activity. In v1, every write and staged action is audited, while reads are recorded only as selective summaries when needed to explain later actions.
_Avoid_: Logging, telemetry, full trace

**Assistant Task Timing Defaults**:
The conventional dates and times the Personal Assistant Agent may apply when creating tasks from vague natural language. In v1, vague times may be applied immediately when they match approved defaults, while recurring tasks still require preview.
_Avoid_: Date parsing, reminder rules, schedule guesses

**Assistant User Boundary**:
The human identity boundary for the Personal Assistant Agent. In v1, only the owner's allowlisted Telegram user ID may issue commands.
_Avoid_: Bot users, access control, authentication

**Assistant Integration Boundary**:
The rule for how the Personal Assistant Agent connects to external personal systems. In v1, integrations are network-first except for Things, which is allowed as a Home Server local app automation exception.
_Avoid_: API strategy, connector pattern, integration style

**Home Server Local App Automation**:
A Personal Assistant Agent integration that depends on a macOS app installed and signed in on the Home Server. In v1, this is an explicit exception for Things rather than a general Home Server pattern.
_Avoid_: GUI automation, AppleScript hack, desktop automation

**Assistant Authority Model**:
The permission boundary for Personal Assistant Agent actions. The v1 model allows autonomous low-risk actions within explicit rules and requires confirmation for high-risk actions.
_Avoid_: Full autopilot, manual-only approval, permissions

**Low-Risk Assistant Action**:
A Personal Assistant Agent action that is read-only, staged for later review, or a reversible personal write such as creating a tentative private calendar hold. Low-risk actions exclude external side effects, deletion, modification of existing calendar events, and changes outside approved staging areas.
_Avoid_: Safe action, harmless automation, background permission

**External Assistant Side Effect**:
A Personal Assistant Agent action that affects another person or a shared system, such as sending email, inviting attendees, modifying shared calendar events, or publishing document changes. External side effects require explicit confirmation in v1.
_Avoid_: Send action, real-world action, irreversible action

**Home Server**:
A macOS machine used to run household and self-hosted services, plus the recovery process for those services. The current home server's host name is `eta`.
_Avoid_: Server box, Mac Mini, Docker host

**Home Server Recovery Contract**:
The expected way to rebuild a Home Server from the infrastructure repository, service definitions, recovered secrets, and restored service data. Full-machine macOS recovery is optional convenience, not the v1 source of truth.
_Avoid_: Full image backup, clone, bare-metal restore

**Service Data Root**:
The canonical filesystem root for durable Home Server service state that must survive rebuilds. On `eta`, service data lives under `~/Services`.
_Avoid_: Docker data, app data, volumes folder

**Service Definition**:
A versioned Docker Compose definition in this repository that declares how a Home Server service is run. Service definitions are the source of truth for container topology on `eta`; OrbStack remains the runtime.
_Avoid_: Container config, Docker setup, compose dump

**Service Control Command**:
A helper command that starts, stops, or inspects Home Server service stacks through their Compose definitions. Service control runs on `eta`; other hosts such as `gamma` may provide SSH convenience wrappers.
_Avoid_: Autostart, deployment tool, remote script

**Service Stack**:
A group of related containers that share one operational lifecycle and one Compose project. Home Server services are organized as separate service stacks rather than one host-wide Compose project.
_Avoid_: App group, compose folder, container bundle

**Service Definition Layout**:
The repository layout for Home Server service definitions. `eta` service stacks live under `services/eta/<stack>/` with host-specific Compose files and supporting documentation.
_Avoid_: Compose directory, services folder, Docker files

**Logical Database Dump**:
A database-native export used as the primary restore input for database-backed Home Server service stacks. Restic protects these dumps along with service files, but raw database directories are not the only restore contract.
_Avoid_: Database backup, volume backup, dump file

**Home Server Backup Repository**:
The single Restic repository that protects `eta` Home Server service data and recovery material for v1. Restore granularity is defined by service-stack paths and drills, not by separate repositories.
_Avoid_: Per-service repository, backup bucket, archive

**Online Backup**:
A Home Server backup that runs without stopping all services. In v1, Restic runs against service data and pre-backup artifacts while services remain live.
_Avoid_: Shutdown backup, maintenance backup, cold backup

**Home Server Retention Policy**:
The v1 Restic retention policy for `eta`: keep 7 daily, 4 weekly, and 12 monthly snapshots, then prune. Storage growth is controlled by backup scope before changing retention.
_Avoid_: Backup schedule, pruning rule, snapshot cleanup

**Home Server Backup Cadence**:
The managed backup schedule for `eta`: one successful automatic backup per day, with a primary nightly run at 03:00 and catch-up attempts when needed.
_Avoid_: Cron time, backup timer, launchd job

**Migration Scope**:
The set of Home Server service stacks intentionally moved into declarative service definitions and restore drills. Migration Scope is not the same thing as current running Docker or OrbStack state. Matrix, Synapse, Mautrix bridges, and the Arr media stack are outside the v1 migration scope.
_Avoid_: Everything running, container list, server contents

**Personal Cloud**:
The Copyparty-backed service stack used as personal cloud storage on `eta`. It is a high-value service stack and must be treated as important backup and restore scope.
_Avoid_: File share, experiment, miscellaneous app

**Tier 1 Service Stack**:
A Home Server service stack whose data loss would be painful enough that migration is incomplete without declared data paths, backup coverage, and a restore drill. The v1 Tier 1 service stacks are Vaultwarden, Immich, Paperless, Home Assistant with Matter Server, Baikal, Linkding, and Personal Cloud.
_Avoid_: Critical container, must-have app, production service

**Tier 2 Service Stack**:
A Home Server service stack that may matter operationally but is not a v1 migration blocker and does not receive Tier 1 backup-gating or restore-drill requirements unless a later issue promotes it. FreshRSS and Local AI Service Stacks are Tier 2 for v1.
_Avoid_: Forgotten service, in-scope Tier 1 service

**Local AI Service Stack**:
A Home Server service stack that runs local model-serving or AI-assisted workflows on `eta` without depending on hosted AI APIs for normal operation.
_Avoid_: Cloud AI, generic AI setup, hosted model service

**Local Model Runtime**:
The Home Server component that loads local language models and exposes them to AI-facing services. It should be treated as replaceable behind a standard API where practical.
_Avoid_: Model app, inference thing, AI backend

**AI-Written Document Metadata**:
Paperless document metadata that a Local AI Service Stack writes automatically after analyzing a document. In v1, AI-written metadata must be visibly marked so it can be audited later.
_Avoid_: AI magic, enrichment, autocategorization

**Keystone Service**:
The Tier 1 service stack that must be restored first because it unlocks recovery of other service secrets. Vaultwarden is the v1 Keystone Service for `eta`.
_Avoid_: Most important app, password manager, first container

**Keystone Data Store**:
The storage model used by the Keystone Service. In v1, Vaultwarden uses its SQLite data directory rather than an external database service.
_Avoid_: Password database, Vaultwarden backend, DB choice

**Durable Service State**:
Service data that must persist across container restarts, host rebuilds, and restore drills. Tier 1 service stacks must not depend on anonymous or misplaced container storage for durable service state.
_Avoid_: Container filesystem, runtime data, local cache

**Corrective Migration**:
A migration that intentionally changes a current service layout because the existing setup violates the desired recovery contract. Linkding is a corrective migration because its current volume layout does not preserve bookmarks across restarts.
_Avoid_: Lift-and-shift, copy current setup, preserve behavior

**Ingress Layer**:
The Traefik-backed routing layer for browser-facing Home Server service stacks. On `eta`, migrated services use Traefik whenever their protocols and integrations allow it.
_Avoid_: Reverse proxy, exposed ports, web routing

**Home Server Access Model**:
The network exposure policy for migrated Home Server service stacks. In v1, services are accessed through Tailscale rather than public internet exposure.
_Avoid_: Public services, LAN apps, remote access

**Tailscale Enrollment**:
The manual trust step that authorizes `eta` into the tailnet after the Tailscale app is installed. The app can be installed declaratively, but tailnet sign-in and device authorization remain manual recovery steps in v1.
_Avoid_: VPN setup, auth key, network bootstrap

**Workstation Defaults**:
Low-risk macOS system preferences for the `gamma` Workstation that are declared through nix-darwin when they are supported and verifiable. App-managed preferences and privacy permissions stay manual unless clean declarative support exists.
_Avoid_: macOS tweaks, dotfile defaults, hidden settings

**Input Source Baseline**:
The native macOS keyboard layouts expected on the `gamma` Workstation: `DVORAK - QWERTY CMD` as the selected layout and `Polish Pro` as an enabled secondary layout.
_Avoid_: Keyboard preference, language setup, typing mode

**Host Family**:
A grouping of machines by operating system and configuration model, such as Darwin workstations or NixOS servers.
_Avoid_: Platform, role, environment

**Host Name**:
The canonical short name for a machine across the flake output and operating system identity. Current host names include the `gamma` Workstation and the `eta` Home Server.
_Avoid_: Computer name, device name, machine alias

**SSH Host Alias**:
The managed SSH name used for remote Home Server commands from another trusted host. The canonical SSH host alias for `eta` is `eta`.
_Avoid_: Remote name, server shortcut, SSH target

**Current Home Server Access**:
The current, pre-Nix `eta` Home Server is reachable from this Workstation with `ssh eta`. Agents may use that access to inspect current state when a task calls for live inventory or verification, while still treating this repository as the target source of truth.
_Avoid_: Assuming current live state is desired declarative state

**Primary User**:
The local macOS account managed for a host. On both `gamma` and `eta`, the primary user is `ignacywielogorski`.
_Avoid_: Account, profile, owner

**Host Shell Baseline**:
The shared interactive shell configuration reused across managed hosts, with host-specific identity where needed. `eta` should use the `gamma` zsh baseline with an `eta` prompt identity instead of the `gamma` prompt identity.
_Avoid_: Dotfiles, terminal setup, zsh copy

**Host Prompt Symbol**:
The short visual host identity shown in the managed shell prompt. `gamma` uses `γ`; `eta` uses `η`.
_Avoid_: Prompt letter, hostname marker, shell emoji

**Primary Editor**:
The editor whose configuration is managed as part of the workstation setup. On `gamma`, the primary editor is Neovim.
_Avoid_: Editor, IDE

**Secret Store**:
The external place where credentials and private keys are kept outside the repository. `gamma` is a Vaultwarden client; it does not host Vaultwarden.
_Avoid_: Password manager, secrets backend

**Bootstrap Secret Set**:
The minimal secrets and recovery notes required to recover `eta` before the self-hosted Vaultwarden service is available. In v1, this set is stored in iCloud Keychain with a second offline emergency copy.
_Avoid_: All secrets, password dump, Vaultwarden backup
