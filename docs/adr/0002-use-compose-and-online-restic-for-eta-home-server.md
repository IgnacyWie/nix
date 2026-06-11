# Use Compose and online Restic for eta Home Server

`eta` is a macOS Home Server that will keep OrbStack as the container runtime, use per-stack Docker Compose service definitions under `services/eta/<stack>/`, and store durable service state under `~/Services`. The v1 recovery contract is not full-machine macOS recovery: rebuild the host from Nix, restore the single `eta` Restic repository from Backblaze B2, bring back Vaultwarden first, then restore the remaining Tier 1 service stacks.

This chooses declarative Compose over native Nix services because the current services are Docker-shaped and OrbStack is already the intended runtime. It chooses online backups with per-service pre-backup artifacts and logical database dumps over global service shutdown, because `eta` should keep services running during daily backups. It also chooses one Restic repository for v1, with restore granularity handled by service-stack paths and drills rather than separate repositories.
