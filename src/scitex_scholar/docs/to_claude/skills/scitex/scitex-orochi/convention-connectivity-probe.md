---
name: orochi-connectivity-probe
description: Canonical way to probe remote host liveness, tmux sessions, and process counts over SSH without the non-interactive-shell pitfalls that bite every naive implementation.
---

# Connectivity Probe

Every fleet healer, quality checker, and fleet_watch-style agent eventually needs to ask another host "are you alive, and how many claude/tmux/bun processes are running?" This skill codifies the one correct way to do it after repeated false positives (primary workstation reporting zero tmux sessions from secondary workstation on 2026-04-13, msg#8283 / #8319).

## The non-interactive shell pitfall

Naive:
```bash
ssh <host> 'tmux ls'          # often reports "no sessions"
ssh <host> 'pgrep -f claude'  # often reports 0
```

Why it fails: `ssh host 'cmd'` runs a **non-interactive, non-login** shell. That shell has not sourced `~/.bashrc` / `~/.profile` / `~/.bash_profile`, so:

- `$PATH` lacks user tools installed via Homebrew, nvm, pyenv, mise, uv, etc.
- `$TMUX_TMPDIR` is unset, so `tmux ls` looks in the wrong socket directory and finds nothing.
- `$DBUS_SESSION_BUS_ADDRESS` is missing on Linux, breaking `systemctl --user` calls.
- On macOS, the launchctl user agent environment is not inherited, hiding sessions started at login.

The result is silent under-reporting: probes claim a host has zero sessions when in reality it has nine. That's an operational-false-positive that triggers unnecessary `#escalation` pages.

## The fix: `bash -lc`

Wrap every remote command in a **login shell**:

```bash
ssh -o ConnectTimeout=5 -o BatchMode=yes mba "bash -lc 'tmux ls 2>/dev/null | wc -l'"
ssh -o ConnectTimeout=5 -o BatchMode=yes mba "bash -lc 'pgrep -cf claude'"
```

`bash -l` forces the shell to read profile files, restoring `$PATH`, `$TMUX_TMPDIR`, and any user environment that the sampled commands rely on. The single-quote wrapping prevents the local shell from expanding variables that should be resolved on the remote host.

## Required SSH flags

Every probe must set:

| Flag | Why |
|---|---|
| `-o ConnectTimeout=5` | Probe must not block the scan loop if a host is unreachable. |
| `-o BatchMode=yes` | Never prompt for a password — probes run unattended. |
| `-o StrictHostKeyChecking=accept-new` | New fleet hosts join without manual key dance; still rejects *changed* keys. |
| `-o ServerAliveInterval=5 -o ServerAliveCountMax=1` | Kill half-dead TCP sessions quickly. |

Combine:

```bash
SSH_OPTS=(-o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
          -o ServerAliveInterval=5 -o ServerAliveCountMax=1)

probe_host() {
  local host="$1"
  ssh "${SSH_OPTS[@]}" "$host" "bash -lc '
    tmux ls 2>/dev/null | wc -l;
    pgrep -cf claude 2>/dev/null || echo 0;
    pgrep -cf \"bun\" 2>/dev/null || echo 0;
    awk \"{print \\\$1}\" /proc/loadavg 2>/dev/null || uptime | awk -F\"load average:\" \"{print \\\$2}\" | awk -F, \"{print \\\$1}\"
  '"
}
```

## Graceful failure

Probe must distinguish three outcomes:

1. **SSH failed** (host unreachable, auth denied, timeout) — mark host `ssh=down`, do **not** infer anything about tmux/procs. Emit `unknown`, not `0`.
2. **SSH succeeded but the command errored** (e.g. `tmux` not installed) — mark `tmux=n/a`, continue.
3. **SSH succeeded and the command returned data** — trust the numbers.

Counter-pattern: treating "SSH succeeded + tmux returned 0" as "host has no sessions" when the real cause was a missing env. Always require a secondary signal (claude procs > 0, load > 0) before concluding that a host is degraded. Escalation policy should require **both** `ssh=down` *and* `claude_procs=0` for a confirmed outage, never just one.

## Canonical reference implementation

head-<host> owns the canonical implementation at `fleet_watch.sh` + `probe_remote.sh` (see msg#8098, 2026-04-13), producing JSON snapshots under `~/.scitex/orochi/fleet-watch/`. Fields:

```json
{
  "host": "<host-a>",
  "ts": "2026-04-13T06:00:00Z",
  "ssh": "up",
  "tmux_count": 9,
  "tmux_names": ["head-<host-a>", "worker-healer-<host-a>", ...],
  "claude_procs": 12,
  "bun_procs": 18,
  "load1": 2.34,
  "mem_used_pct": 51.0,
  "fork_pressure_pct": 7
}
```

Healers and quality checkers should **read these snapshots** rather than re-running probes themselves (see `infra-resource-hub.md` + rule #6 of `fleet-communication-discipline.md`). Running your own probe is acceptable only when:

- You need a field the canonical snapshot doesn't have, or
- You are the canonical implementation (head-<host>).

## Cross-OS semantics — Darwin is not Linux

The same metric name means different things on macOS and Linux. Probes that assume Linux semantics produce false positives on Darwin hosts (primary workstation). Observed 2026-04-13, msg#8603 — third probe false positive of the session after the tmux-socket and stale-LAN-IP ones.

### Memory

**Wrong** (assumes Linux `free -m` semantics):
```bash
# Darwin "Pages free" is always tiny (~100 MB) by design — macOS uses
# inactive + speculative pages as reclaimable cache. Reporting this as
# "free memory" triggers bogus CRITICAL alerts.
vm_stat | awk '/Pages free/ {print $3 * 4096}'
```

**Right** on Darwin — any one of:
```bash
memory_pressure | awk '/System-wide memory free percentage/ {print $NF}'
# or
sysctl -n vm.page_free_count vm.page_inactive_count vm.page_speculative_count | \
  awk '{sum += $1} END {print sum * 4096}'
# or
vm_stat | awk '/Pages (free|inactive|speculative)/ {sum += $NF} END {print sum * 4096}'
```

**Right** on Linux:
```bash
free -m | awk '/Mem:/ {print $7}'   # "available" column, not "free"
# or
awk '/MemAvailable/ {print $2 * 1024}' /proc/meminfo
```

### Load average

`/proc/loadavg` is Linux-only. On Darwin use `sysctl -n vm.loadavg` or `uptime | awk -F'load average:' '{print $2}'`.

### Process counts

`pgrep -cf <pattern>` works the same on both, but `pgrep -x` behaves differently — on Darwin it matches only the process name (truncated at 15 chars historically). Prefer `pgrep -cf` unconditionally for probes.

### Disk usage

`df -h /` columns differ between GNU coreutils and BSD df. Parse by field name (`df -h / | awk 'NR==2 {print $4}'` for available) rather than by fixed column index.

### Shell alias override guard

Even after branching on `uname -s`, a login shell can still sabotage a probe by aliasing a coreutil to something interactive. Observed 2026-04-13: a user-level `alias free='watch -n 1 free -m'` on one host would have turned the memory probe into an endless `watch` loop had the probe used `bash -lc 'free -m'` (the `bash -lc` wrapper pulls in `.bashrc` aliases). Defenses:

- **`command free -m`** — `command` bypasses aliases and functions, calling the PATH builtin directly.
- **`\free -m`** — a leading backslash also disables alias expansion for that one invocation.
- **Absolute path**: `/usr/bin/free -m` / `/bin/free -m`.
- **`env free -m`** — runs `free` via `env`, which ignores shell aliases.
- **Subprocess list form** (Python / TS): `subprocess.run(["free", "-m"], shell=False)` — no shell, no aliases. This is what `scitex-agent-container snapshot.py` already does, so snapshot.py is immune even without the guards above.

Apply the same guard to any coreutil a probe calls: `ls`, `cp`, `mv`, `rm`, `grep`, `date`, `df`, `du`, `ps`, `free`, `uptime`. The user's dotfiles are not your dotfiles, and you will lose this fight on someone else's host.

Counter-pattern that motivates this rule: four unrelated probe false positives in one session (2026-04-13) all traced to the probing code trusting login-shell state on the target:
1. `tmux ls` without `$TMUX_TMPDIR` — socket mismatch
2. `ssh nas` routed to a stale LAN IP — host alias
3. `vm_stat Pages free` treated as free memory — Darwin semantics
4. `free` aliased to `watch -n 1 free` on one user — alias override

Each one looked like a different bug; the common root is "probe assumed shell/OS state instead of verifying it".

### Rule: branch on `uname -s`, never assume

Every probe that reads OS-level metrics must branch on the target host's OS, not the probing host's:

```bash
probe_mem() {
  local host="$1"
  ssh "${SSH_OPTS[@]}" "$host" "bash -lc '
    case \"\$(uname -s)\" in
      Darwin) memory_pressure | awk \"/System-wide memory free percentage/ {print \\\$NF}\" ;;
      Linux)  awk \"/MemAvailable/ {print \\\$2 * 1024}\" /proc/meminfo ;;
      *)      echo unknown ;;
    esac
  '"
}
```

The canonical `probe_remote.sh` under head-<host>'s `fleet_watch.sh` owns the cross-OS branching. If you find yourself writing OS-specific parsing outside that script, stop — extend `probe_remote.sh` instead of forking a second implementation.

## Common mistakes checklist

Before shipping any probe code, verify:

- [ ] `bash -lc` around every remote command
- [ ] `ConnectTimeout` and `BatchMode=yes` set on every `ssh` call
- [ ] SSH failure and empty result are distinguished in the output schema
- [ ] Escalation requires a compound condition, not a single metric
- [ ] Probe results written to a file, not just printed — rule #6 forbids routine chat posts
- [ ] Cross-OS metric parsing: every OS-level read (memory, load, disk) branches on `uname -s` of the **target** host, not the probing host. No Linux-only shortcuts (`/proc/loadavg`, `free -m $7`, `vm_stat Pages free` treated as free memory).
- [ ] Alias override guard: every coreutil invocation uses `command <tool>` / `\<tool>` / absolute path / subprocess list form. Never trust that `free`, `ls`, `df`, `ps`, etc. on a remote host resolve to the OS binary — user dotfiles can alias them to anything.
- [ ] primary workstation-specific: `tmux ls` works because `TMUX_TMPDIR` is set in `.bashrc` — confirm with `ssh <host> 'bash -lc "env | grep TMUX"'`. Memory probes must use `memory_pressure` / `vm.page_*_count`, never raw `Pages free` (that's always ~100 MB by design; treating it as a critical threshold false-alarms every tick).
- [ ] Spartan-specific: login1 has `squeue`/`sinfo`; compute nodes have a different view. Never probe compute nodes via ssh for fleet state.

## Adoption Checklist

Every fleet healer and fleet_watch-style loop must satisfy all of these before being considered canonical. Use this list when updating an existing `/loop` prompt.

- [ ] **Remote command wrap**: every `ssh host 'cmd'` call uses `bash -lc 'cmd'`.
- [ ] **SSH flags**: `ConnectTimeout=5`, `BatchMode=yes`, `StrictHostKeyChecking=accept-new`, `ServerAliveInterval=5`, `ServerAliveCountMax=1` on every probe.
- [ ] **Three-outcome schema**: SSH failure, command error, and command success are all distinguished — never collapse to a single "0" that means "unknown".
- [ ] **Compound escalation gate**: no host is marked down on a single metric. Minimum compound condition = `ssh=down` **AND** (`claude_procs=0` **OR** `orochi_presence=absent`).
- [ ] **Silent success**: routine all-green scans are written to a local log file only, never posted to any channel (see `fleet-communication-discipline.md` rule #6).
- [ ] **Snapshot reuse**: before running a fresh probe, check whether head-<host>'s `fleet_watch.sh` already captured the same data in `~/.scitex/orochi/fleet-watch/`. If yes, read the snapshot instead.
- [ ] **Host-specific gotchas**:
  - primary workstation: confirm `ssh <host> 'bash -lc "env | grep TMUX"'` shows `TMUX_TMPDIR`.
  - Spartan: probe login1 only, never compute nodes. Respect `project_spartan_login_node` memory.
  - WSL hosts: remote aliases may route via cloudflared bastion, not LAN IP (see #292/#301 for history).
  - NAS/storage hosts: `tmux` may run under a different user's socket; confirm before escalating on `tmux_count=0`.

## Per-host adoption status

Tracked 2026-04-13. Agents responsible for each lane must update this list when they land changes.

| Host | Healer | Canonical compliant? | Notes |
|---|---|---|---|
| host-a (WSL) | worker-healer-<host-a> | ✅ 2026-04-13 (cron job 40c61ea4 / msg#8406) | `bash -lc`, compound gate, silent success verified |
| host-b (primary workstation) | worker-healer-<host-b> | 🔄 in-progress (2026-04-13) | Owner: head-<host-b>. Canonical /loop prompt drafted by worker-skill-manager; head-<host-b> to apply. |
| host-c (NAS/storage) | worker-healer-<host-c> | ⏳ pending (depends on fleet_watch snapshot reuse) | Owner: head-<host-c>. Consume `~/.scitex/orochi/fleet-watch/` instead of re-probing. |
| spartan | head-<host> (no mamba-healer yet) | ⏳ feasibility note only | Constraint: login1-only, never compute nodes. Probe must use `bash -lc`. |

## Per-lane issue templates

Copy-paste these into #agent / issue tracker when assigning adoption work to a host owner.

### Primary workstation lane (owner: head-<host>)
> **Task**: Align `worker-healer-<host>` `/loop` with `convention-connectivity-probe.md` canonical pattern.
>
> **Acceptance**:
> 1. Every remote probe wrapped in `bash -lc`.
> 2. SSH flags as in skill doc.
> 3. Compound escalation gate (SSH fail **AND** (claude=0 **OR** orochi absent)).
> 4. Routine all-green: written to `~/.scitex/healer/last-scan.json`, **not** posted.
> 5. Consume `~/.scitex/orochi/fleet-watch/` if head-<host> snapshot is available; fall back to own probe otherwise.
>
> **Done signal**: one-line post to #agent: `worker-healer-<host> adoption complete, job <id>`, then mark this row ✅ in `convention-connectivity-probe.md`.

### NAS/storage lane (owner: head-<host>)
> **Task**: Align `worker-healer-<host>` `/loop` with canonical pattern and switch it to **pure consumer** of its own `fleet_watch.sh` output (no duplicate probes).
>
> **Acceptance**:
> 1. Healer reads `~/.scitex/orochi/fleet-watch/*.json` on every tick; no direct `ssh` calls.
> 2. Escalation decisions use the same compound gate as the canonical skill.
> 3. Silent success (no routine posts).
> 4. If the snapshot is older than 2× `fleet_watch` interval, escalate staleness once and stop probing until fresh.
>
> **Done signal**: same as primary workstation lane.

### HPC cluster lane (owner: head-<host>)
> **Task**: Feasibility note for a future `worker-healer-<host>`. No implementation until #283 resolved.
>
> **Acceptance**:
> 1. Document whether a long-lived probe loop can run on login1 (policy: controller-only is OK, see `project_spartan_login_node` memory).
> 2. List which metrics are obtainable on login1 vs require a compute allocation.
> 3. Post a short design note to #agent; update this skill's per-host row with link.
>
> **Done signal**: feasibility note posted; skill row updated to 📝 feasibility-complete.

## Related

- `infra-resource-hub.md` — the aggregated snapshot store that consumes probe output
- `fleet-communication-discipline.md` rule #6 — silent success, no routine OK posts
- `agent-health-check.md` — the 8-step health checklist that depends on these probes
- memory `project_spartan_login_node.md` — probe Spartan on login1 only
