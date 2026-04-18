---
name: scitex-resource-management
description: How agents query machine + SLURM resources via the standalone scitex-resource package, and why live queries are banned on the hot path.
---

# Resource Management

SciTeX agents never call `sinfo`/`squeue`/`nvidia-smi` directly on the hot path. They use the standalone [`scitex-resource`](https://github.com/ywatanabe1989/scitex-resource) package, which reads from a cache populated by a separate heartbeat process.

## Why

- Live SLURM queries are slow (seconds) and noisy on login nodes.
- Multiple agents hammering `squeue` wastes the shared login node's budget.
- A 60s-tick heartbeat is free, and agents read files in microseconds.
- History accumulates in the cache → enables trend-based decisions.

## API

Three functions, all returning plain dicts (JSON-safe):

```python
from scitex_resource import machine_status, slurm_status, available

machine_status()
# {'timestamp': '...', 'cpu_pct': 12.3, 'ram_gib_used': 4.2,
#  'ram_gib_total': 16.0, 'disk_gib_free': 120.5,
#  'gpu_pct': None, 'vram_gib_used': None, 'vram_gib_total': None}

slurm_status()
# {'source': 'cache', 'cache_timestamp': '...',
#  'nodes_raw': '<sinfo output>', 'my_jobs_raw': '<squeue output>'}

available()
# {'machine': machine_status(), 'slurm': slurm_status()}
```

CLI equivalents:

```bash
scitex-resource            # all resources
scitex-resource machine    # machine only
scitex-resource slurm      # SLURM only
```

## Cache Contract

`scitex-resource` reads from `~/.scitex/cache/`:

| File | Producer | Consumer |
|------|----------|----------|
| `machine_mem.txt` | `heartbeat/collect.sh` via `free -h` | (informational) |
| `slurm_nodes.txt` | `sinfo -o "%N %t %C %m %G"` | `slurm_status()` |
| `slurm_jobs.txt`  | `squeue -u $USER -o "%i %T %R %C %m"` | `slurm_status()` |
| `last_update.txt` | ISO-8601 timestamp | staleness check |

If the cache is missing, `slurm_status(use_cache=False)` falls back to a direct `sinfo`/`squeue` call (with 10s timeout). **Agents should not rely on the fallback** — it exists only for first-run bootstrap.

## Staleness

Callers inspect `cache_timestamp` themselves. Rules of thumb:
- `< 2 * interval` — fresh
- `< 5 * interval` — warn
- `> 5 * interval` — escalate via `#escalation` (heartbeat process likely dead)

## Not in this Package

- Resource **acquisition** (`salloc`/`srun` wrappers, context managers) is out of scope for the initial release. For now, agents compose their own SLURM commands using info from `slurm_status()`.
- Cross-fleet aggregation (rsync-ing caches between hosts) is handled by `scitex-orochi/resource-hub.md`.

## Related

- `resource-heartbeat.md` — how to install and run the heartbeat sampler
- `scitex-orochi/resource-hub.md` — fleet-wide aggregation
- memory: `project_spartan_login_node.md` — login1 is controller-only; workloads go via SLURM
