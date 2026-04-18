---
name: scitex-resource-heartbeat
description: How to run the scitex-resource heartbeat collector so agents can read SLURM and machine state from ~/.scitex/cache/ instead of hammering sinfo/squeue.
---

# Resource Heartbeat

A long-lived, lightweight collector that refreshes `~/.scitex/cache/` on a fixed interval. Never run it under Claude Code — it must outlive any agent session.

## Cache Contract

Path: `~/.scitex/cache/`

| File | How it's produced | Consumed by |
|------|-------------------|-------------|
| `machine_mem.txt` | `free -h` | operators (informational) |
| `slurm_nodes.txt` | `sinfo -o "%N %t %C %m %G"` | `scitex_resource.slurm_status()` |
| `slurm_jobs.txt`  | `squeue -u $USER -o "%i %T %R %C %m"` | `scitex_resource.slurm_status()` |
| `last_update.txt` | `date --iso-8601=seconds` | staleness check |

Default interval: `SCITEX_HEARTBEAT_INTERVAL=60` (seconds). Set to `0` for a single-shot cron-driven run.

## Collector Script

Ships with the package at `scitex_resource/heartbeat/collect.sh`:

```bash
#!/usr/bin/env bash
CACHE_DIR="${HOME}/.scitex/cache"
INTERVAL="${SCITEX_HEARTBEAT_INTERVAL:-60}"
mkdir -p "${CACHE_DIR}"

collect_once() {
    free -h > "${CACHE_DIR}/machine_mem.txt" 2>/dev/null
    if command -v sinfo &>/dev/null; then
        sinfo -o "%N %t %C %m %G" > "${CACHE_DIR}/slurm_nodes.txt" 2>/dev/null
        squeue -u "${USER}" -o "%i %T %R %C %m" > "${CACHE_DIR}/slurm_jobs.txt" 2>/dev/null
    fi
    date --iso-8601=seconds > "${CACHE_DIR}/last_update.txt"
}

collect_once
if [[ "${INTERVAL}" -gt 0 ]]; then
    while true; do sleep "${INTERVAL}"; collect_once; done
fi
```

## Launch Methods

Pick one per host. Agents don't care which — they only read `~/.scitex/cache/`.

### tmux (fastest bring-up, fine for dev/login nodes)
```bash
tmux new-session -d -s heartbeat \
  'SCITEX_HEARTBEAT_INTERVAL=60 ~/.scitex/heartbeat/collect.sh'
```

### system cron (simplest, survives reboots)
```cron
* * * * * SCITEX_HEARTBEAT_INTERVAL=0 ~/.scitex/heartbeat/collect.sh >> ~/.scitex/cache/heartbeat.log 2>&1
```
`INTERVAL=0` makes `collect.sh` run once and exit, so cron can schedule it.

### systemd user (Linux, production)
`~/.config/systemd/user/scitex-heartbeat.service`:
```ini
[Unit]
Description=SciTeX resource heartbeat
[Service]
Environment=SCITEX_HEARTBEAT_INTERVAL=60
ExecStart=%h/.scitex/heartbeat/collect.sh
Restart=always
[Install]
WantedBy=default.target
```
```bash
systemctl --user enable --now scitex-heartbeat
```

### launchd (macOS)
`~/Library/LaunchAgents/com.scitex.heartbeat.plist` with `KeepAlive=true`, `ProgramArguments` pointing at `collect.sh`.

## Spartan-Specific Notes

- Run the collector **on login1** only (agents there are controllers, not workloads — see memory `project_spartan_login_node.md`).
- Never run `collect.sh` inside a compute allocation; compute nodes see a different SLURM view and will pollute the cache.
- `SCITEX_HEARTBEAT_INTERVAL=60` is fine on login nodes. Go lower only if you have a specific reason.

## Debugging

- `cat ~/.scitex/cache/last_update.txt` — is it stale?
- `ls -la ~/.scitex/cache/` — which files are present?
- `python -c "from scitex_resource import slurm_status; print(slurm_status())"` — does the reader see `source=cache`?
- If `source=direct` shows up unexpectedly, the cache is missing and the heartbeat has died → restart it.

## Related

- `resource-management.md` — the reader-side API
- `scitex-orochi/resource-hub.md` — aggregating caches across the fleet
