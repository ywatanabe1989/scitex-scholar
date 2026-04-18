---
name: orochi-compute-resources
description: Hardware resource requirements and recommendations for Orochi fleet hosts — minimum specs, roles, and scaling options.
---

# Compute Resources

Hardware requirements for running Orochi fleet agents. Use this when planning new hosts or scaling the fleet.

## Per-Agent Resource Footprint

Each Claude Code agent (head or mamba) consumes approximately:
- **CPU**: 0.5-1 core sustained, spikes to 2-4 during active reasoning
- **RAM**: 2-4 GB (Claude process + tmux + MCP sidecar)
- **Disk**: 100-500 MB workspace + skills mirrors
- **Network**: WebSocket persistent (negligible bandwidth)

## Host Role Profiles

### Role 1: Agent Host (head/mamba cluster)
Runs multiple Claude Code agents in tmux sessions.

| Tier | CPU | RAM | SSD | Example | Price (JPY) |
|------|-----|-----|-----|---------|-------------|
| Minimum | 4 cores | 16 GB | 256 GB | Mac mini M4 (base) | ~95k |
| Recommended | 6-8 cores | 32 GB | 512 GB | Mac mini M4 (32GB), Minisforum UM790 | ~130k |
| High-density | 8-16 cores | 64 GB | 1 TB | Desktop workstation | 200k+ |

**Rule of thumb**: 4-6 agents per 16 GB RAM. Plan for Opus (larger context) vs Haiku split.

### Role 2: Docker/CI/Isolation Host
Runs isolated Docker containers (worker-newbie, CI, builds).

| Tier | CPU | RAM | SSD | Example |
|------|-----|-----|-----|---------|
| Minimum | 4 cores | 16 GB | 256 GB | Intel NUC13 |
| Recommended | 6-8 cores | 32 GB | 1 TB | Minisforum N100/N305 mini PC |

### Role 3: Status/Monitor (lightweight, always-on)
Hosts independent status pages, uptime monitors.

| Tier | CPU | RAM | SSD | Example | Price |
|------|-----|-----|-----|---------|-------|
| Minimum | 2 cores | 4 GB | 64 GB | Raspberry Pi 5 (8GB) | ~15-20k |
| Basic | 4 cores (N100) | 8 GB | 128 GB | Intel N100 mini PC | ~30-50k |

**Critical**: This host MUST be on separate infrastructure from the primary server (NAS/storage host) so it survives primary outages.

### Role 4: GPU Compute (ML/inference)
Local LLM, Whisper, image generation, research ML.

| Tier | GPU | VRAM | RAM | Price |
|------|-----|------|-----|-------|
| Minimum | RTX 4070 | 12 GB | 32 GB | ~250k |
| Recommended | RTX 4080 | 16 GB | 64 GB | ~350k |
| High-end | RTX 4090 | 24 GB | 64 GB | ~600k |

**Use case**: Reduces spartan SLURM queue dependency for interactive work.

### Role 5: Storage/Backup
Redundant storage for data, Docker images, backups.

- Existing NAS/storage host sufficient for most cases
- For redundancy: second NAS/storage or cold backup drive
- Target: 4+ TB usable, RAID1 minimum

## Fleet Composition Recommendations

### Minimum Viable Fleet (current)
- 1x Agent host (MBA or Mac mini) — head + mamba agents
- 1x NAS — storage, scitex.ai hosting
- 1x Laptop/Desktop (Windows+WSL or Linux) — file transfer, bridge
- Optional: HPC access (university SLURM)

### Recommended Next Expansion (~¥150-200k)
Priority order:
1. **Mac mini M4 (32GB)** ~130k — dedicated agent cluster, worker-newbie isolation
2. **Raspberry Pi 5** ~15k — independent status page

### Full Home HPC (¥1.5-2M)
For autonomous research without spartan dependency:
1. Agent cluster (Mac mini x2): ~260k
2. GPU workstation (RTX 4090): ~600k
3. NAS redundancy: ~200k
4. Status Pi: ~15k
5. UPS + networking: ~100k

## Network Requirements

- **Stable internet**: Home fiber sufficient. Residential IP with Cloudflare Tunnel is fine.
- **Bastion**: Cloudflare Tunnel (bastion.scitex.ai, scitex-orochi.com) eliminates port forwarding
- **UPS**: Recommended for NAS and primary agent host (prevents corruption during outages)
- **Backup internet**: 4G/5G router as fallback optional

## Power & Operational Costs

| Device | Idle Power | 24h/year kWh | Annual cost (¥25/kWh) |
|--------|-----------|--------------|----------------------|
| Mac mini M4 | ~10 W | ~88 | ~2,200 |
| Raspberry Pi 5 | ~5 W | ~44 | ~1,100 |
| Intel N100 mini | ~10 W | ~88 | ~2,200 |
| RTX 4090 workstation (idle) | ~80 W | ~700 | ~17,500 |
| NAS (4-bay) | ~30 W | ~263 | ~6,600 |

Agent hosts are cheap to run 24/7; GPU workstations should be on-demand.

## Scaling Strategy

1. **Start small**: Current fleet (MBA + NAS + WSL + HPC) is already capable
2. **Add isolation host first**: Mini PC or Pi for worker-newbie + status page (~¥50k)
3. **Add dedicated agent cluster**: Mac mini when MBA load is too high
4. **Add GPU last**: Only when spartan queue delays become research bottleneck
5. **Redundancy**: Always have a backup path — second NAS, external backup drive

## Self-Build PC Example (Research GPU Workstation)

For users experienced with DIY builds. Target: 2-4 GPU research rig.

**Specs:**
- **CPU**: AMD Ryzen 9 7950X or Threadripper 7xxx (many cores + PCIe lanes)
- **RAM**: 128 GB DDR5 ECC preferred
- **GPU**: 2x RTX 4090 (48 GB VRAM total) or 1x RTX 6000 Ada (48 GB single)
- **Storage**: 2 TB NVMe Gen4 (OS + scratch) + 8-16 TB HDD (datasets)
- **PSU**: 1600 W 80+ Platinum (for dual 4090)
- **Case**: Fractal Define 7 XL (airflow for multi-GPU)
- **Cooling**: AIO 360mm CPU cooler + high static-pressure fans

**Budget**: ~¥1,000,000 for dual-4090 build, ~¥600,000 for single 4090

**OS**: Ubuntu 22.04 LTS + NVIDIA driver 545+ + CUDA 12.x

**For quad-GPU**: Need Threadripper Pro or EPYC for sufficient PCIe lanes. Consider air-cooled GPUs with 2-slot spacing. Budget jumps to ~¥2M+.

## Reference

- Mac mini M4: https://www.apple.com/jp/shop/buy-mac/mac-mini
- Minisforum: https://store.minisforum.com/
- Raspberry Pi 5: https://www.raspberrypi.com/products/raspberry-pi-5/
- NVIDIA RTX: manufacturer websites / local retailers
