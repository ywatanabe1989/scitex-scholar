---
name: orochi-spartan-hpc-startup-pattern
description: Canonical startup pattern for Spartan (and other Lmod/module-based HPC clusters) — module load chain, LD_LIBRARY_PATH hardening for non-interactive SSH, login-node vs compute-node divergence, and avoiding multi-second bash-startup latency. Codified from 2026-04-13 head-<host> fixes (todo#307).
---

# Spartan / HPC Startup Pattern

What every agent running on Spartan (or any Lmod-based HPC cluster) must do at shell startup, and what every *remote* tool invoking Spartan must *not* assume about the target shell's state.

This skill codifies the pattern that was reconstructed over several incidents on 2026-04-13 (non-interactive `pip3.11` missing `libpython3.11.so.1.0`, `squeue` missing from PATH in probes, bash startup ballooning to ~2.7 s on login nodes, and the on-going login1 controller-only policy).

## Why HPC is different

Unlike a normal Linux host, an HPC login node gives you almost nothing by default:

- `$PATH` does **not** include compiler toolchains, Python, CUDA, Apptainer, Node — none of them. You get them by running `module load <name>`.
- `$LD_LIBRARY_PATH` does not include shared libraries from modules — `module load` sets it, but only for the current shell.
- `module` itself is a shell function injected by Lmod's init script. Non-interactive shells (`ssh host 'cmd'`) often do **not** source that init, so `module` doesn't exist and every downstream assumption collapses.
- User quotas on login1 are shared and visible to sysadmins. Anything that runs every 60 s across a fleet of agents is noticed; anything that runs every 5 s is yelled at.

Pragmatically this means an HPC startup has three phases:

1. **Detect whether we're on the cluster at all** (hostname check).
2. **Load modules and export shared-lib paths** — but only if we're actually on login node / compute node, never on non-HPC hosts that happen to source the same dotfiles.
3. **Decide login vs compute semantics** — login1 is controller-only (see `project_spartan_login_node` memory); compute nodes do the actual work.

## Canonical dotfiles snippet

Reference implementation lives in `~/.dotfiles/src/.bash.d/secrets/999_unimelb_spartan.src` (path is under `secrets/` for legacy reasons; the file itself holds no secrets). Essentials:

```bash
has_module_command() { command -v module &>/dev/null; }

_spartan_load_module_if_not_loaded() {
    has_module_command || return 1
    module is-loaded "$1" || module load "$1" || return 1
}

spartan_load_modules() {
    has_module_command || return 1
    # Lmod aborts the whole chain on an unknown module — keep known-good names grouped,
    # and load volatile names (slurm/*) separately with error suppression.
    module load \
        GCCcore/11.3.0 \
        Python/3.11.3 \
        OpenSSL/1.1 \
        Apptainer/1.3.3 \
        bzip2 \
        GLib/2.72.1 \
        GTK3/3.24.33 \
        Gdk-Pixbuf/2.42.8 \
        nodejs/20.13.1 \
        Pandoc/3.1.2
    module load slurm/default 2>/dev/null \
        || module load slurm/latest 2>/dev/null \
        || true
}

# Ensure Python 3.11 shared libs are findable even in non-interactive / agent SSH
# sessions — pip3.11 fails with libpython3.11.so.1.0 not found when modules are not loaded.
_SPARTAN_PY311_LIB="/apps/easybuild-2022/easybuild/software/Compiler/GCCcore/11.3.0/Python/3.11.3/lib"
if [[ $(hostname) == *"spartan"* ]] && [ -d "$_SPARTAN_PY311_LIB" ]; then
    export LD_LIBRARY_PATH="${_SPARTAN_PY311_LIB}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
unset _SPARTAN_PY311_LIB
```

Three invariants this snippet enforces:

1. **Hostname guard** (`[[ $(hostname) == *spartan* ]]`) prevents non-Spartan hosts (non-HPC hosts) that sync the same dotfiles from accidentally exporting a Linux-only library path.
2. **Directory guard** (`[ -d "$_SPARTAN_PY311_LIB" ]`) tolerates the path being moved by a future EasyBuild upgrade — the snippet simply no-ops instead of breaking.
3. **LD_LIBRARY_PATH is exported unconditionally on Spartan**, not gated on `has_module_command`, because non-interactive SSH sessions (where `module` is not available) are exactly the case where `pip3.11` needs the hardcoded fallback.

## The non-interactive SSH trap

Everything in `~/.bashrc` that depends on the `module` function is invisible to `ssh spartan 'cmd'` because the non-interactive shell does not source Lmod's init. Symptoms:

- `ssh spartan 'which python'` → `/usr/bin/python` (system 2.7), not the module Python.
- `ssh spartan 'pip3.11 install foo'` → `libpython3.11.so.1.0: cannot open shared object file`.
- `ssh spartan 'squeue -u $USER'` → `squeue: command not found` if `slurm/` module isn't pre-loaded.
- Fleet connectivity probes that wrap in `bash -lc` (from `convention-connectivity-probe.md`) **do** work for the Lmod parts, but still fail if `spartan_load_modules` hasn't been called in the login shell session.

**Defenses**, in order of preference:

1. **Export LD_LIBRARY_PATH unconditionally** in the dotfiles snippet (done above for the Python 3.11 case). Do the same for any other library a remote probe will depend on.
2. **Call `spartan_load_modules` from `~/.bash_profile`** (login shell) so `bash -lc` wrapping sees the full module environment. Do **not** call it from `~/.bashrc` alone — that fires on every non-interactive SSH invocation and balloons startup latency.
3. **Absolute paths in probes** — `command ssh spartan '/apps/slurm/latest/bin/squeue ...'` sidesteps PATH entirely. Use for health probes where latency matters.
4. **Pass-through env**: `ssh -o SendEnv=LD_LIBRARY_PATH spartan ...` only works if Spartan's `sshd_config` `AcceptEnv` whitelists it, which is rarely the case. Don't rely on this.

## Bash-startup latency budget

Interactive bash startup on Spartan login1 should be **under 500 ms**; it will creep to 2–3 s if every non-interactive SSH invocation re-runs `spartan_load_modules`. Symptoms: probe latency spikes, fleet_watch.sh cycles drift, `ssh spartan 'true'` takes visibly long.

Two-layer fix (applied 2026-04-13 during mamba-mode spike):

1. **Gate module loading on "is this actually an interactive session?"** — the snippet above guards with `if [ -z "$CLAUDE_ID" ]` and `if_host "spartan-login"` so agent sessions and remote probes skip the full chain. Agents get only the unconditional `LD_LIBRARY_PATH` export, not the ~2 s Lmod work.
2. **Separate login vs compute setup** — `spartan_setup_login` runs the full chain on login1; `spartan_setup_gpgpu` runs a subset on GPU compute nodes. Non-interactive probes trigger neither.

After the fix: `time ssh spartan 'bash -lc "true"'` should be well under 1 s; `time ssh spartan 'true'` (no `-lc`) should be near the TCP round-trip only.

## Login node vs compute node policy

Hard-coded fleet rule (memory: `project_spartan_login_node.md`):

- **login1 is controller-only.** Agents on login1 may plan, communicate, orchestrate, and call `salloc`/`sbatch` — but they must not run model training, inference, notebooks, or anything that holds CPU/GPU for more than a few seconds.
- **Compute nodes are where work happens.** Acquire with `salloc --time=HH:MM:SS --partition=<name> --gres=gpu:<n>` and attach with `srun --jobid=$SLURM_JOB_ID --pty bash`. The Claude Code process itself becomes the allocation holder (see `#7935` thread in `#operator` 2026-04-13 for the reasoning).
- **Always set `--time`.** If the agent crashes, the allocation auto-releases at the wall-clock deadline.
- **Never autostart agent workloads on login1 via systemd**. Use the `.bash_profile` + tmux pattern from `agent-autostart.md` §"Spartan (HPC login node)" instead — starts the agent *when the operator ssh-es in*, which is the correct semantic on a shared login node.

## Partition cheatsheet (Spartan, 2026-04-13)

| Partition | Use | Notes |
|---|---|---|
| `physical` | General CPU work | Default for non-GPU jobs. |
| `sapphire` | GPU A100 | Preferred for training runs. head-<host> reports availability here. |
| `gpu-a100` | GPU A100 (legacy name) | worker-todo-manager bridges jobs here when `sapphire` is queued. |

Modules to load inside an `salloc` on a compute node: usually a subset of the login-node chain. For Python 3.11 + CUDA jobs, load `GCCcore/11.3.0`, `Python/3.11.3`, `CUDA/<version>` explicitly, and `module list` in the job script to log which versions were actually picked up — Lmod substitutions silently move the toolchain under your feet.

## Common mistakes checklist

Verify before shipping any Spartan-bound code or probe:

- [ ] Hostname guard wraps any Spartan-only env export so non-HPC hosts don't execute it.
- [ ] Directory existence check guards any hardcoded `/apps/easybuild-*` path.
- [ ] Non-interactive path: `ssh spartan 'pip3.11 --version'` works **without** `bash -lc`.
- [ ] Interactive path: `time ssh spartan 'bash -lc "true"'` is under 1 s after the fix.
- [ ] No module-load side effects on hosts where `$(hostname) != *spartan*`.
- [ ] `spartan_load_modules` is **not** called from every bash startup — only from login-shell entry points.
- [ ] Agent autostart on login1 uses `.bash_profile` + tmux, not systemd / launchd.
- [ ] Compute-heavy work runs inside `salloc`/`srun`, never bare on login1.
- [ ] `--time` is set on every `salloc`/`sbatch` so the allocation can self-release.
- [ ] Probe commands use absolute paths for `/apps/slurm/latest/bin/squeue` etc. when latency matters.

## Related

- memory `project_spartan_login_node.md` — login1 controller-only rule
- `agent-autostart.md` §"Spartan (HPC login node)" — tmux-based startup pattern
- `convention-connectivity-probe.md` — `bash -lc` wrap, cross-OS semantics, compound escalation
- `resource-management.md` (scitex-resource) — the future unified SLURM acquisition API
- scitex-python / scitex-agent-container commit `6900afdf` (2026-04-13): `fix(spartan): export LD_LIBRARY_PATH for Python 3.11 shared libs`

## Change log

- **2026-04-13**: Initial capture from head-<host> bash-load incident (2.73 s interactive startup), Python 3.11 shared-lib fix (commit 6900afdf), and reconstruction of the Lmod / hostname-guard / directory-guard pattern in `999_unimelb_spartan.src`. Trigger: worker-todo-manager dispatch msg#8829 (manba-mode), todo#307. Author: worker-skill-manager.
