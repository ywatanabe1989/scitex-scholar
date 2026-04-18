---
description: "SSH full-mesh bastion architecture — 4 hosts via Cloudflare tunnels"
globs: ["**/.ssh/**", "**/cloudflared*", "**/autossh*"]
alwaysApply: false
---

# SSH Full-Mesh Bastion Architecture

## Overview
4-host fleet connected via Cloudflare tunnels for internet-routed SSH access from anywhere.

## Bastion Endpoints

| Host | Bastion Hostname | Status |
|---|---|---|
| MBA | `bastion.scitex-orochi.com` | Active (cloudflared daemon) |
| NAS | `bastion.scitex.ai` | Active (cloudflared daemon) |
| ywata-note-win | `bastion-win.scitex-orochi.com` | Active (cloudflared user process) |
| Spartan | `bastion-spartan.scitex-orochi.com` | Active (sbatch piggyback) |

## SSH Usage
```bash
# From any machine with cloudflared installed:
ssh bastion-win       # → ywata-note-win (WSL)
ssh bastion-mba       # → MBA
ssh bastion-nas       # → NAS (via bastion.scitex.ai)
ssh bastion-spartan   # → Spartan compute node
```

## SSH Config Entry Template
```
Host bastion-win
  HostName bastion-win.scitex-orochi.com
  User ywatanabe
  ProxyCommand <cloudflared-path> access ssh --hostname %h
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

## Cloudflare API Tunnel Management
Tunnels are managed via Cloudflare API (no dashboard needed):
- API key: `SCITEX_CLOUDFLARE_API_KEY` in `~/.dotfiles/src/.bash.d/secrets/010_scitex/99_cloudflare.src`
- Account ID: `d76d6c5622f131502fb01672fc5a9bb3`

### Create tunnel via API
```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCT_ID/cfd_tunnel" \
  -H "X-Auth-Email: admin@scitex.ai" \
  -H "X-Auth-Key: $SCITEX_CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json" \
  --data '{"name":"<tunnel-name>","tunnel_secret":"<base64-32-bytes>"}'
```

### Add DNS record
```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "X-Auth-Email: admin@scitex.ai" \
  -H "X-Auth-Key: $SCITEX_CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json" \
  --data '{"type":"CNAME","name":"<subdomain>","content":"<tunnel-id>.cfargotunnel.com","proxied":true}'
```

## Host-Specific Setup

### ywata-note-win (WSL)
- cloudflared binary: `/home/ywatanabe/.local/bin/cloudflared`
- Auto-start: Windows Startup folder (`start-wsl-services.bat`) + `ensure-services.sh`
- Systemd service: `cloudflared-bastion-win.service`
- Also has autossh reverse tunnels (port 1229) to MBA + NAS as backup

### MBA (macOS)
- cloudflared: `/opt/homebrew/bin/cloudflared`
- Runs as root daemon (launchd)
- Token-based tunnel

### NAS
- cloudflared: `/home/ywatanabe/bin/cloudflared`
- Config file: `~/.cloudflared/bastion-nas.yml`
- Systemd service

### Spartan (HPC)
- cloudflared: `~/bin/cloudflared`
- Runs inside sbatch job (piggybacks on head-spartan's self-perpetuating loop)
- Tunnel restarts with each job re-submit (IP changes but Cloudflare handles it)
- Login node cannot run tunnels (cgroup nproc=1 limit)

## Redundancy
- MBA ↔ NAS: LAN direct (192.168.11.x) + Cloudflare
- ywata-note-win: Cloudflare + autossh reverse tunnels (port 1229)
- Spartan: Cloudflare + direct SSH (spartan.hpc.unimelb.edu.au)

## Fleet Recovery
- `fleet-recover.sh`: Probes all 4 hosts, reports status, optional `--recover` flag
- `probe-ywata-note-win.sh`: Targeted probe for ywata-note-win
- Both deployed to all hosts at `~/.dotfiles/src/wsl-boot/`

## Port Assignments
| Port | Host |
|---|---|
| 1229 | ywata-note-win (reverse tunnel) |
| 1230 | NAS |
| 1231 | MBA |
| 1232 | Spartan |
