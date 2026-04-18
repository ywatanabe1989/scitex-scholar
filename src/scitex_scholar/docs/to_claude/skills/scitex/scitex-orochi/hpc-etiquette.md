---
name: orochi-hpc-etiquette
description: How to be a good citizen on shared HPC clusters — any site, Spartan or otherwise. General rules (login nodes, schedulers, quotas, filesystems, metadata, modules, network) plus Spartan-specific specifics. Response to the 2026-04-14 Sean Crosby (UniMelb HPC admin) complaint about unbounded find.
scope: fleet-internal
---

# HPC etiquette

Shared HPC filesystems have hundreds of millions of files and are watched by admins who can and will revoke access. A single agent scripting `find / -name X` across `/data/gpfs` hits the filesystem as hard as any real workload and is indistinguishable from a denial-of-service from the storage layer's perspective.

This skill is the fleet's rulebook for being a good HPC guest, written specifically after the 2026-04-14 incident where Sean Crosby (Head of Research Computing Infrastructure, UniMelb) emailed the operator to stop running `find / -name pdflatex` on Spartan (msg #10971). That `find` was started by an agent trying to locate a binary — the kind of operation that is free on a laptop and catastrophic on a shared cluster.

## General HPC rules (apply to every cluster the fleet touches — Spartan, NCI, future sites)

Before the Spartan-specific section below, the general rules every agent must follow on **any** HPC system. These generalize the Sean Crosby incident so that the same lesson does not need to be relearned on NCI / Gadi / Pawsey / DataCrunch / AWS ParallelCluster / etc.

### Compute + jobs

- **Never run compute on a login node.** Login nodes are for SSH, `cp`, `git`, `module avail`, `sbatch`, `squeue`, and short file inspection. They are not for training, inference, `pip install`ing large wheels, building C++, or running Jupyter kernels. Every site has at least one way to enforce this (Spartan: `cgroup nproc=1`; NCI: SIGKILL after N minutes; others: admin email). Do not fight the enforcement; use `srun` or `sbatch` to get onto a compute node.
- **Every long-running job goes through the scheduler** — SLURM, PBS/Torque, LSF, Kubernetes, whichever the site uses. Raw `nohup python train.py &` or `tmux new -d ...` on the login node is a policy violation on every site. If you need interactive access, use `srun --pty bash -i` / `qsub -I` / equivalent.
- **Always set `--time=HH:MM:SS`** (or PBS `walltime=`, LSF `-W`, etc.). Unbounded jobs are caught by admin sweeps and cancelled with prejudice. 24:00:00 is not "unbounded" — it is 24 hours and the scheduler decides when it ends.
- **Respect fair-share quotas and walltime limits.** Check the site docs for max concurrent jobs, max wall time per partition, max GPUs per user. Submitting 500 jobs at once when the quota is 50 is a policy violation even if the jobs are small.
- **Clean up after yourself**: `scancel` stale / abandoned jobs before submitting new ones (`squeue -u $USER -t CD,F,CA,TO,NF` for already-terminated rows to purge via `sacctmgr` if needed). Leaving a stuck `PENDING` queue behind is visible to admins.
- **Do not poll `sinfo` / `squeue` / `sacct` in tight loops.** Every site's scheduler database is shared; hammering it affects everyone. Minimum interval for polling queues is 60 s; prefer 5 min. Reference cached output where possible (the spartan dashboard for instance, see `infra-spartan-dashboard.md`).

### Filesystems + metadata

- **Never unbounded filesystem walks** — `find /`, `du /`, `ls -R /`, `rsync -a /`, `tar cf - /`. All of these are banned in the absolute rules below. The ban applies to **every** HPC site, not just Spartan.
- **Never walk `$HOME` on shared/NFS home**. Same failure at smaller scale.
- **Respect disk + inode quotas** per user and per project. Check with the site-specific CLI:
    - Spartan: `lfs quota` / `mmlsquota` / dashboard
    - NCI: `nci_account` / `lquota`
    - Generic: the site docs
  Check *before* a large job, not after it fails.
- **Consolidate small outputs into SQLite / Parquet / tarballs** instead of thousands of per-item files. Inode quotas bite faster than byte quotas; one SQLite replacing 10k PNGs buys you 10k inodes. `scitex.archive` + `scitex.db` exist for this.
- **Use `$SCRATCH` for ephemeral / intermediate data**, not `$HOME`. Move persistent results to the project-assigned storage (`/data/gpfs/projects/<punim>/` on Spartan, `/g/data/<proj>/` on NCI) before scratch purge sweeps.
- **Clean `/tmp` and scratch on job exit.** Wrap `sbatch` scripts in a trap:
  ```bash
  trap 'rm -rf "$TMPDIR"/run.$SLURM_JOB_ID' EXIT
  ```
  A terminated job that leaves behind GB in `/tmp` is visible to node operators.
- **Do not metadata-storm.** Creating 100k small files in a loop, stat-ing a directory thousands of times per second, or renaming/touching every file on disk all count as metadata attacks regardless of intent. Batch operations, use `--files-from` lists, aggregate.

### Modules + environment

- **Always use the site module system** (Lmod / Environment Modules / Spack / TCL modules) to load compilers, Python, CUDA, MPI, etc. Do not manually edit `$PATH` / `$LD_LIBRARY_PATH` with hard-coded absolute paths to `/apps/...` — the paths change between upgrades and your script will silently break.
- **Prefer `module load <pkg>/<version>`** with an explicit version over `module load <pkg>` without one. Sites change the default version without notice.
- **`module list`** before and after your job runs confirms the toolchain picked up what you expected. Log it in job output.
- **Do not `source` `/etc/profile` or `~/.bashrc` inside a script** as a way to "make modules work". Use `module load` directly or run the wrapper in an interactive shell that already sourced its profile. Calling `source /etc/profile` in a scripted context is a smell for a deeper `bash -lc` problem; see `convention-connectivity-probe.md` for the proper wrap.

### Network + SSH

- **No parallel SSH fork-bombs.** `parallel-ssh` / `pdsh` to 100+ nodes is a denial-of-service against the cluster's SSH daemon. Use the scheduler's job array or `srun --nodes=N --ntasks=N` instead.
- **Use the site bastion if one is configured.** Direct SSH from a login node to a compute node often goes through cgroup / firewall restrictions; the bastion exists because that path is not blessed.
- **Outbound-only from compute nodes** is the norm. HTTPS + outgoing SSH typically work; opening inbound listeners does not. See `orochi-bastion-mesh` skill for the fleet's way to put persistent reverse tunnels inside long-walltime sbatch jobs.
- **Download once, cache locally.** Do not re-fetch large datasets per script run; pin to `$SCRATCH/cache/` or a site dataset directory and reuse.

### Process + billing hygiene

- **`ps -ef | grep $USER`** on the login node before leaving, to confirm no stray processes are running. An agent that leaves behind a zombie `python` on login1 gets that process killed and the agent flagged.
- **Charge the right project.** `sbatch --account=<project-id>` (or your site equivalent) so compute is billed against the allocated project, not the user default. Wrong-account billing creates admin work.
- **Respect submission rate limits.** Some sites throttle `sbatch`; spamming 50 jobs in 10 seconds gets your submission rights rate-limited or revoked temporarily.

### Documentation + first contact

- **Read the site's user guide before your first job.** Most sites publish a wiki (Spartan: `https://dashboard.hpc.unimelb.edu.au/` links to the user guide; NCI: `https://opus.nci.org.au/`). Partition names, quota limits, account codes, bastion hosts, storage paths all live there.
- **Start with the smallest possible test job** before submitting a full-scale workload. 5 minutes on one core is a cheap way to discover that your module load chain is wrong.
- **If in doubt, email the site's help desk before running the job**, not after it breaks production. Admins are much happier answering a pre-emptive question than cleaning up a filesystem storm.

### If you are not sure whether a command is HPC-safe

Defensive rules of thumb:

- Does it touch a path that starts with `/`, `/data`, `/scratch`, `/home` **without** a specific subpath? → unsafe
- Does it scan more than ~10k files? → unsafe
- Does it run more than 60 s on a login node? → unsafe, move to `sbatch`
- Does it re-run every cycle in a polling loop faster than 60 s? → unsafe, cache
- Is there a site dashboard page / CLI that gives the same answer? → use that
- Would Sean Crosby email the operator if he saw this in `ps -ef`? → if yes, don't run it

The last one is the canonical test.

## The absolute rules

1. **Never `find /`.** Under any circumstances, on any HPC system, for any reason. Not even with `-maxdepth` limits. Not even with `2>/dev/null`. Not even briefly. The traversal starts before the filter applies; the filesystem pays for the walk regardless of what you filter out.

2. **Never walk the full home directory recursively on NFS.** `find ~/` / `du -sh ~/` / `ls -R ~/` on a GPFS or Lustre home is the same failure mode at a smaller scale. Use specific subpaths.

3. **Never run compute on the login node.** Policy-mandated on most HPC sites (Spartan's `cgroup nproc=1` on login1 enforces this by killing long-running processes). Controllers only; compute goes in `sbatch` / `srun` / `salloc`. See `hpc-spartan-startup-pattern.md` + memory `project_spartan_login_node.md`.

4. **Never run background `sleep inf` loops to hold allocations.** Use `sbatch --time=...` with a real walltime. Indefinite holds look exactly like orphaned jobs to schedulers and draw admin attention.

5. **Never `rsync -r` or `tar cf -` the entire `$HOME`.** Scope the operation to the specific subtree you need.

## Binary location — what to do instead of `find`

The 2026-04-14 incident was an agent trying to locate `pdflatex`. Here is the correct cascade, in order of preference and filesystem friendliness:

```bash
# 1. POSIX shell built-in — zero filesystem cost beyond the PATH cache
command -v pdflatex

# 2. which — same effect, one extra process
which pdflatex

# 3. type — shell builtin variant, extra details
type pdflatex

# 4. Module system — the canonical way on HPC
module avail texlive 2>&1 | head -10
module show texlive/20230313 2>&1

# 5. Loaded module list — find already-loaded tools
module list 2>&1 | head

# 6. Package database — if apt / dnf / rpm available
dpkg -L texlive-latex-base 2>/dev/null | grep bin/pdflatex
```

If all six fail, the binary is not available in any sanctioned location, and running `find` will not change that fact. Stop; install via `module load`, `pip`, `conda`, `pipx`, or ask the HPC help desk.

**Never** script fallbacks like `command -v X || find / -name X` — that is the failure mode the incident surfaced. The fallback *is* the bad behavior.

## Scoping filesystem queries

When you genuinely need to search a directory tree, **scope tight**:

```bash
# OK: scoped to a single subdir, one level deep
find ~/proj/scitex-python -maxdepth 2 -name '*.toml'

# OK: scoped to a single package's artifacts
ls ~/.cache/pip/wheels/

# OK: use cached metadata from the package manager
pip show scitex | grep Location

# BAD: unbounded
find / -name '*.toml'
find /data -name 'foo'
find ~ -name 'bar' -print    # home is NFS on HPC
du -sh ~/
```

Every `find` / `du` / `ls -R` invocation should answer "is the scope I am about to walk smaller than a few thousand files?". If not, it is the wrong tool.

## Inode-aware operations

HPC quotas are **per-user inodes**, not just bytes. The 2026-04-14 NeuroVista backfill hit a project directory with 72 free inodes (#372) because the PAC pipeline created one file per small artifact. Rules:

- **Consolidate small artifacts into SQLite / Parquet / tarballs** rather than thousands of per-item files. `scitex.archive` + `scitex.db` exist specifically for this.
- **Use `scitex.session` + `scitex.archive`** for pipeline outputs so session dirs become one SQLite, not `_out/` trees.
- **Clean up old RUNNING/stale session dirs** — per-session subdirs accumulate if not purged on success.
- **Never write one file per input sample** if you can write one SQLite per batch.

## SLURM etiquette

- Always set `--time=HH:MM:SS`. Unbounded jobs are caught by admin sweeps.
- Never submit more than the site's per-user concurrent job limit. `squeue -u $USER` before submitting a batch.
- Use the correct partition. `long` is for 90-day tunnels and stable services, `sapphire` for GPU work, `physical` for CPU. Misusing `long` for short jobs wastes the partition budget.
- Release unused allocations via `scancel` when you are done. Do not leave an `salloc` shell open overnight "just in case".
- `sbatch` jobs that are holders for long-running tunnels are allowed (see `hpc-spartan-startup-pattern.md`), but they must be single-purpose, documented, and tracked in `~/.scitex/orochi/scripts/`.

## Login-node policy (Spartan-specific but generalizable)

- `login1` / `login2` are **controller-only** nodes. No inference, no training, no `pip install` of heavy wheels (`torch`, `tensorflow`, etc.), no heavy compile, no background loops that stay resident past your ssh session.
- `cgroup nproc=1` on Spartan login1 auto-kills long-running processes. Do not fight it.
- Interactive work needs `srun --pty bash -i` on a compute node, not a login-node screen session.
- `tmux` / `screen` on login1 is OK for short-lived agent coordinators, not for compute. The `worker-healer-<host>` agent runs on login1 as a coordinator; it does not run inference or training.

See also the canonical UniMelb policy section below — the fleet's own login-node rule is a summary, the canonical source is the authority.

## UniMelb Research Computing canonical policy (Spartan)

This section reproduces the relevant parts of the upstream
UniMelb Research Computing Spartan policies page as the
authoritative text. The fleet's summary rules elsewhere in
this file are paraphrases; when there is any doubt about
what Spartan allows, **the upstream text is the source of
truth**, not the fleet paraphrase.

**Canonical source**:
<https://dashboard.hpc.unimelb.edu.au/policies/>

Captured 2026-04-15 via the operator msg#12411 (relayed to the
fleet in msg#12418 by head-<host> with explicit
directive to fold into this skill) and msg#12414 link drop.
Re-fetch the canonical page whenever there is a policy
question — upstream is allowed to change without notifying
the fleet.

### Login-node compute allowlist (canonical)

> No applications other than code editors (`vim`, `emacs`),
> data moving applications (e.g. `rsync`,
> `unimelb-mf-clients`) and Python / R package installations
> (e.g. `pip install`, `install.packages()`) can be run on
> the login nodes. **Applications using CPU or memory will
> be killed when run on the login nodes.**

> For code editors which connect externally, such as
> **VSCode**, **do not run code on Spartan through those
> external code editors** (e.g. running Python code on the
> login nodes).

Fleet implications:

- `tmux` coordinators for `head-<host>` and healer-style
  agents are OK on login1 because they are not compute
  workloads — they are bash-level state machines. The
  `cgroup nproc=1` limit is the enforcement that will kill
  anything that crosses the "compute" line.
- **VSCode remote-execution is forbidden.** Even if the
  VSCode extension itself is lightweight, it will run Python
  kernels / tests / linter subprocesses on the login node
  which is exactly the banned case. If you need an IDE, use
  Open OnDemand's hosted JupyterLab on a compute node, not
  remote VSCode against login1.
- Heavy wheel installations (`pip install torch`, etc.) are
  banned because compilation + disk I/O on login1 competes
  with everyone else's ssh session. Do them inside an
  `srun` / `sbatch` session.

### TCP port policy (canonical)

> Some popular applications (such as Jupyter, RStudio,
> wandb) require TCP ports to be opened during the running
> of the application.
>
> - **No ports are externally accessible on either the
>   login nodes or compute nodes.**
> - **Do not run applications opening TCP ports on the
>   login nodes.**
> - As Spartan is a shared resource, you cannot guarantee
>   that a port you want to use won't be already in use by
>   other users on the worker node you are using. You
>   should check to see if the port is available before you
>   try to use it. If you try to open a port that someone
>   else is using, your job will most likely fail.
>   Example script: `/apps/examples/TCP_Ports` on Spartan.
> - **If you can access a port, so can everyone else on the
>   platform.** That means that others would be able to
>   connect and access the data available through the port
>   you open. **Make sure you secure the application using
>   the port with a username/password.**
> - **Try not to use popular ports or ports you don't have
>   access to** (< 1024, 8080, 8888).
> - If an application is available as part of **Open
>   OnDemand**, please run it there in preference to other
>   ways of running it.

Fleet implications:

- **No inbound tunnels on login1.** The cross-host bastion
  mesh (`orochi-bastion-mesh.md`) keeps Spartan-side
  listeners inside `sbatch` jobs, not on login1.
- **No Jupyter / RStudio / wandb servers on login1.** These
  must run inside an `sbatch` allocation on a compute node
  (and even there, bind to localhost + port collision
  check + HTTP auth).
- **Port collision check before `listen`**: every fleet
  agent that opens a TCP port on Spartan should first check
  `ss -ltn` or equivalent to confirm the port is free. The
  upstream example script at `/apps/examples/TCP_Ports`
  shows the canonical pattern.
- **Prefer Open OnDemand** (`https://dashboard.hpc.unimelb.edu.au/`)
  for any UI app the fleet needs. Running Jupyter through
  OOD is the fleet's default, not running Jupyter manually
  via `ssh -L`.
- **Popular ports are banned**: < 1024 is privileged,
  8080 + 8888 are the "I'll just use the default"
  favorites that collide immediately. Pick a random
  high port (10000–65535) and document it per-job.

### Spartan is for batch, not web apps (canonical)

> Spartan is designed and optimised for batch jobs (i.e. no
> need for user interaction). As such, it is not really
> designed for applications which require users to connect
> via web interfaces. It may be very difficult or
> impossible to make certain applications work with
> Spartan.
>
> **We will not host web applications which need to be
> always on.** If you require this, please consider using
> the Melbourne Research Cloud.

Fleet implications:

- **Always-on fleet services do not belong on Spartan.**
  The scitex-orochi hub, dashboards, cloudflared tunnels,
  and any other persistent web-exposed service live on
  NAS / primary workstation / Melbourne Research Cloud, not on Spartan.
- HPC head agents and project-specific agents are **ssh-triggered**, not
  always-on. They come up when the operator ssh-es in, do
  their batch work, and exit. The unstick loop is the one
  exception, and it is explicitly bash-only with a tiny
  wall-budget per sweep; it does not expose any port or
  web surface.
- If a future fleet need requires a persistent web service
  that is tied to Spartan data (e.g. a live paper rendering
  service per the operator msg#12289), the service host is
  **Melbourne Research Cloud**, and the service reads
  Spartan data via a scheduled data-movement job, not a
  direct bind.

### Account lifecycle (canonical)

> **Keeping account information up to date**: All users
> must keep their account information up to date, including
> their supervisor, position and department. A valid,
> institutional email address is required. To update your
> information, go to Karaage, and click Personal → Edit
> personal details.
>
> **Locking of user accounts**: User accounts will be
> locked when emails sent receive a bounce message,
> indicating the mailbox does not exist anymore.
>
> **User home directories will be deleted 6 months after
> being locked.**

Fleet implications:

- `the operator` is the fleet's canonical Spartan account
  holder. Keeping `the operator`'s UniMelb institutional email
  live and bounce-free is a load-bearing condition for
  every Spartan agent the fleet operates.
- If `the operator` changes email or the account information
  needs to be updated (supervisor transition, department
  change), the update happens through Karaage (the UniMelb
  account self-service portal), **not** via a support
  ticket to HPC admins. Agents do not touch this.
- **Email bounce → lock → 6-month home-dir delete** is a
  hard timeline. If the operator is away for extended periods,
  the fleet's health-daemon should flag account-inactivity
  risk before the lock threshold is reached.

### Project expiration (canonical)

> **Expiration of the Project**: A project will be
> considered to be expired when there are no valid unlocked
> user accounts left in the project.
>
> As per our Managing Data, you should only keep
> computational data on Spartan. Any critical or not used
> data should be uploaded to Mediaflux or another platform.
>
> With no valid unlocked user accounts left in the project,
> the data in project and scratch is inaccessible to all
> users.
>
> We will delete all project and scratch data for the
> project **6 months after the project has expired**
> according to the above criteria. We will attempt to send
> an email to the project leader 1 week before we delete
> the data.

Fleet implications:

- Shared projects (near-full disk, read-only for some agents)
  are the immediate concern. Renewal is owned by the project
  leader, not by the fleet. The fleet's role is **observation
  only** -- detect if a project expires and alert.
- The operator's own project stays active as long as the
  operator's account does.
- **"Computational data only, move critical stuff to
  Mediaflux"** is the canonical storage-tier advice the
  fleet should honor. Critical paper data (manuscripts,
  final figures, published tables) must live in
  Mediaflux or an equivalent long-term store, not on
  Spartan scratch or project directories.
- **1-week delete warning** is the fleet's last-chance
  window. Any Spartan project the fleet owns or
  collaborates on should have an operator (human or
  fleet-coordinator) watching for the warning email so
  the data is preserved before the delete fires.

### Inappropriate use / service denial (canonical)

> Inappropriate use of the service — If a user engages in
> activity that contravenes the University IT policies,
> standards and guidelines, or the processes described
> here, their access to the service will be suspended,
> pending a review. In the case where the user is also
> the project owner, the project may also be suspended,
> effectively denying access to other project
> participants. If the activity is deemed to be
> malicious, the user and the project may be removed
> from the service.
>
> Damage to the service — If a user misuses the service,
> either wittingly or unwittingly, and causes the
> degrading or denial of service for other users, access
> will be suspended pending a review.

Fleet implications:

- **"Unwittingly" is not a defense.** The 2026-04-14 Sean
  Crosby `find /` incident is the canonical example of
  unwitting damage — the agent did not mean harm, the
  admin still complained, and the fleet is on notice. The
  fleet's compliance posture is **assume every unbounded
  filesystem walk is logged at the storage layer** and
  act accordingly.
- **A single project-owner suspension affects every
  collaborator.** Because the operator is the project owner
  for one project and a collaborator on another, a
  suspension would cascade into the fleet's entire
  NeuroVista and gPAC research pipeline. The blast
  radius of a single bad command is huge.
- **Escalation on first complaint** — if any HPC admin
  contacts the operator about fleet behavior, the fleet
  stops the offending pattern immediately, patches the
  anti-pattern catalog in this file, and drafts the
  apology reply in the same hour. See the "Fleet
  escalation" section below for the full protocol.

## Network etiquette

- **Outbound-only from HPC**. UniMelb allows outbound SSH, HTTPS, and a small allowlist of registry hosts. Do not attempt to open inbound ports on login nodes.
- **Cloudflare named tunnels** (`bastion-spartan.scitex-orochi.com`) run inside a compute-node sbatch job, not on login1. See `orochi-bastion-mesh` skill.
- **Download once, cache locally**. Do not re-fetch large datasets on every script run; pin the dataset into `~/scratch/cache/` or equivalent.

## Storage hygiene

- **`$HOME` is small and slow** on HPC. Do not keep datasets there. Use project-assigned `/data/gpfs/projects/<punim>/` or `$SCRATCH`.
- **`$SCRATCH` is fast and ephemeral**. OK for intermediate files; expect periodic purge by admin sweeps. Move anything you want to keep to project storage before the scheduled purge.
- **Check quotas**: `sacctmgr show assoc user=$USER format=account,user,partition,maxsubmitjobs` + `mmlsquota` + `du --max-depth=1 /data/gpfs/projects/<punim>/`.
- **Never `rm -rf` inside a shared project dir without confirming you own every leaf file**. Other group members may have written data you cannot see.

## Shell-level guardrails

Every agent that runs shell commands on HPC should have these aliases available (source from a host-gated bash file, see `hpc-spartan-startup-pattern.md` for the hostname guard pattern):

```bash
# Refuse unbounded find
find() {
    for arg in "$@"; do
        if [[ "$arg" == "/" || "$arg" == "$HOME" ]]; then
            echo "HPC-ETIQUETTE: refusing unbounded find on $arg; use command -v / which / module avail instead" >&2
            echo "                 see scitex-orochi/_skills/scitex-orochi/hpc-etiquette.md" >&2
            return 2
        fi
    done
    command find "$@"
}

# Refuse full-tree du on home
du() {
    for arg in "$@"; do
        if [[ "$arg" == "$HOME" || "$arg" == "~/" ]]; then
            echo "HPC-ETIQUETTE: refusing du on \$HOME; scope tighter" >&2
            return 2
        fi
    done
    command du "$@"
}
```

These are defensive — they catch the common bad patterns at the shell layer so an agent that "tries to be helpful" with a fallback `find /` gets an explicit refusal and a pointer to this skill instead.

## Anti-patterns observed (2026-04-14 incident)

Sean Crosby's email quoted the offending command line:

```
bash -c 'find / -name pdflatex 2>/dev/null | head -5; source /etc/profile 2>&1; which pdflatex 2>&1'
```

What went wrong:

- `find / -name pdflatex` was used as the **primary** location strategy. `which pdflatex` was a fallback, not the primary.
- `2>/dev/null` silenced the errors but not the filesystem load. The traversal still happened.
- `head -5` is useless — the walk does not stop when `head` closes its read side unless the shell propagates SIGPIPE cleanly, and by the time it does the full traversal has already started.
- `source /etc/profile` was a guess — the agent was trying to "fix the environment" to make `which` work, which means it did not understand that `which` already works as long as `PATH` is set; the problem was that the agent was running in a non-interactive SSH context where `PATH` did not include the module-loaded texlive bin dir. The right fix was `bash -lc` + `module load texlive`, not `find`.

Correct refactor for that exact task:

```bash
ssh spartan 'bash -lc "module load texlive 2>/dev/null; command -v pdflatex"'
```

One line, zero filesystem traversal, uses the canonical module path.

## Fleet escalation

If an HPC admin complains about any fleet agent's behavior:

1. **Stop the offending agent immediately** (tmux kill or `scitex-agent-container stop`).
2. **Post to `#escalation`** with the admin's exact message, the offending command, and the host.
3. **Patch the skill (this one) with the specific anti-pattern** so the fleet never repeats it.
4. **Respond to the admin** within one business day, acknowledging the issue + naming the preventive measure.
5. **Verify with `ps -ef | grep $USER` on the affected host** that no similar process is still running.

The 2026-04-14 incident was handled by the operator replying directly to Sean; the preventive measure is this skill. Future incidents: patch first, reply second, verify third.

## Related

- `hpc-spartan-startup-pattern.md` — Lmod module chain, `bash -lc` wrap, login-vs-compute policy, partition cheatsheet
- `convention-connectivity-probe.md` — non-interactive SSH `bash -lc` wrap pattern that the `which pdflatex` fix relies on
- `orochi-bastion-mesh` skill — how to run persistent services on HPC via long-walltime sbatch, not on login1
- memory `project_spartan_login_node.md` — login1 is controller-only
- the operator email exchange with Sean Crosby, 2026-04-14 (relayed via msg #10971)

## Change log

- **2026-04-14 (initial)**: Drafted immediately after the Sean Crosby email (msg #10971). Centers the `find /` anti-pattern but generalizes to filesystem walks, inode management, SLURM etiquette, login-node policy, storage hygiene, network etiquette, and shell-level guardrails. Includes the exact refactor for the offending `find / -name pdflatex` command. Author: worker-skill-manager (knowledge-manager lane).
