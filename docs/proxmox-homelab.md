# Proxmox homelab topology

This is the durable inventory and access runbook for the current homelab. Do not put credentials or API tokens in this file.

## Architecture

```text
Tailscale clients
    |
    v
homepad (Proxmox VE)
    |
    +-- LXC 110: net-core
    |      +-- Tailscale subnet router
    |      +-- split DNS / dnsmasq
    |
    +-- VM 120: edge
    |      +-- Caddy private reverse proxy
    |      +-- Cloudflare DNS-01 certificates
    |
    +-- VM 100: home-assistant
    |      +-- Home Assistant OS
    |
    +-- VM 121: core-apps
    |      +-- Vaultwarden
    |      +-- Baikal
    |      +-- Uptime Kuma
    |
    +-- future VM: media-apps
           +-- media and download services
           +-- not yet provisioned
```

All guests currently boot automatically. Persistent application state is on Proxmox local SSD-backed storage. Bulk media and long-term backups should move to the future NAS rather than filling Proxmox local storage.

## Proxmox host

| Setting | Value |
|---|---|
| Hostname | `homepad` |
| Tailscale IP | `100.75.205.36` |
| Web UI | `https://100.75.205.36:8006` |
| SSH | `ssh root@100.75.205.36` |
| Storage | `local` and `local-lvm` |

## Guests

| ID | Name | Type | LAN IP | Resources | Role |
|---:|---|---|---|---|---|
| 100 | `home-assistant` | VM | `192.168.1.111` | 4 vCPU, 8 GB RAM, 32 GB disk | Home Assistant OS |
| 110 | `net-core` | LXC | `192.168.1.14` | 2 vCPU, 2 GB RAM, 8 GB disk | Tailscale subnet router and split DNS |
| 120 | `edge` | VM | `192.168.1.15` | 2 vCPU, 4 GB RAM, 3 GB disk | Caddy reverse proxy and TLS |
| 121 | `core-apps` | VM | `192.168.1.16` | 4 vCPU, 8 GB RAM, 32 GB disk | Small persistent Docker applications |
| TBD | `media-apps` | planned VM | TBD | TBD | Future media/download stack; keep separate from core apps |

## Network and DNS

- LAN: `192.168.1.0/24`
- Gateway: `192.168.1.1`
- `net-core` Tailscale IP: `100.122.193.21`
- `net-core` advertises the LAN subnet through Tailscale.
- Tailscale split DNS sends `home.wie.dev` lookups to `100.122.193.21`.
- dnsmasq on `net-core` maps `*.home.wie.dev` to the edge VM at `192.168.1.15`.
- Caddy uses Cloudflare DNS-01 for trusted certificates. Services remain private; Cloudflare is not being used as a public tunnel.

## Private service URLs

| Service | URL | Backend |
|---|---|---|
| Home Assistant | `https://hass.home.wie.dev` | `192.168.1.111:80` |
| Vaultwarden | `https://vault.home.wie.dev` | `192.168.1.16:8080` |
| Baikal | `https://calendar.home.wie.dev` | `192.168.1.16:8081` |
| Uptime Kuma | `https://status.home.wie.dev` | `192.168.1.16:3001` |

## Access commands

```bash
# Proxmox
ssh root@100.75.205.36

# net-core from Proxmox
ssh root@100.75.205.36
pct enter 110

# edge
ssh -J root@100.75.205.36 ignacy@192.168.1.15

# core-apps
ssh -J root@100.75.205.36 ignacy@192.168.1.16
```

## core-apps

Compose stacks and persistent state:

```text
/srv/core-apps/vaultwarden
/srv/core-apps/baikal
/srv/core-apps/uptime-kuma
```

Current containers:

| Container | Image | Published endpoint |
|---|---|---|
| `vaultwarden` | `vaultwarden/server:1.37.1` | `192.168.1.16:8080` |
| `baikal` | `ckulka/baikal:nginx` | `192.168.1.16:8081` |
| `uptime-kuma` | `louislam/uptime-kuma:2` | `192.168.1.16:3001` |

Vaultwarden and Uptime Kuma currently report healthy. All three use `restart: unless-stopped` and Docker starts at boot. Uptime Kuma uses its local persistent SQLite database. Its administrator account has been created; monitors for Home Assistant, Vaultwarden, and Baikal still need to be added/confirmed in the authenticated UI.

## edge security

- Caddy, SSH, and unattended upgrades are active.
- UFW defaults to deny inbound and allow outbound.
- SSH, HTTP, and HTTPS are allowed only from `192.168.1.0/24` and Tailscale `100.64.0.0/10`.
- SSH is key-only, root login is disabled, and only user `ignacy` is allowed.
- Caddy's admin API remains loopback-only.
- Cloudflare credentials live in a root-owned `0600` environment file and must never be committed.

## Operational boundaries

- `edge` should remain a disposable ingress VM: Caddy and security tooling only.
- `core-apps` is for small critical/stateful services such as Vaultwarden, Baikal, and Uptime Kuma.
- `media-apps` will be a separate VM for the future media stack.
- Home Assistant remains isolated in VM 100 for LAN discovery and integrations.
- `net-core` remains the private network control plane; avoid placing unrelated application containers there.
- Keep backups and restore procedures separate from service definitions. Add NAS-backed and offsite backups before treating local VM storage as the sole durable copy.
