# Spartan Agent Skills

## Machine: Spartan HPC (University of Melbourne)
- **Host**: spartan.hpc.unimelb.edu.au (SSH alias: `sp`, `spartan`)
- **User**: ywatanabe
- **Model**: Claude Opus 4.6 (1M context)
- **Role**: HPC/research computing orchestrator
- **Platform**: Linux (WSL2 on Windows, connecting to Spartan)

## Environment
- **Python**: 3.11.0rc1 (virtualenv at ~/.env-3.11)
- **SLURM**: Available (squeue, sbatch, srun)
- **Module system**: `module load` required for HPC packages (NOT available on login node — run on compute nodes)
- **Disk**: ~2TB mounted at /home/ywatanabe, 67% used (625GB available). Use `sdf` alias (spartan-disk-usage) on compute nodes.
- **Shell config**: ~/.bash.d/ (has: all/, docs/, GITIGNORED/, secrets/)
- **SSH config**: ~/.ssh/conf.d/ (github.conf, unimelb.conf, ylab.conf, ywata.conf)

## SSH Connectivity
- **Spartan → NAS**: Check via `ssh nas` (192.168.0.102)
- **Spartan → MBA**: Check via SSH config
- **Spartan → ywata-note-win**: Check via SSH config
- **GPU access**: `ssh spg` or `ssh spartan-gpu` (sets SPARTAN_USE_GPU=true)

## Responsibilities
1. GPU-accelerated experiments (PAC, neural analysis)
2. SLURM job management and submission
3. HPC-specific compute tasks other agents can't handle
4. Help other agents with computational power (CPU/GPU)
5. Cross-machine delegation for heavy compute

## SLURM Usage
- Submit: `sbatch script.sh`
- Check queue: `squeue -u ywatanabe`
- Interactive GPU: `srun --partition=gpu-a100 --gres=gpu:1 --time=04:00:00 --pty bash`
- Cancel: `scancel <jobid>`

## Key Projects
- **gPAC**: GPU-accelerated Phase-Amplitude Coupling (~/proj/gPAC)
- **Neurovista PAC**: Neural oscillation analysis (~/proj/neurovista-pac)
- **FigRecipe**: Reproducible figures (~/proj/figrecipe)
- **SciTeX packages**: Various (~/proj/scitex-*)

## GitHub Issue-Based Task Tracking

Spartan sessions compact frequently and the agent runs on a separate host from the orchestrator. GitHub Issues are the only way to maintain task continuity across compactions and machines.

### On Receiving a Task

When the orchestrator sends a task referencing an issue (e.g., "Work on ywatanabe1989/todo#85"):

```bash
# 1. Read the full issue for context
gh issue view 85 --repo ywatanabe1989/todo

# 2. Mark as in-progress
gh issue edit 85 --repo ywatanabe1989/todo --add-label "in-progress"

# 3. Do the work

# 4. Comment results on the issue
gh issue comment 85 --repo ywatanabe1989/todo \
  --body "Completed: frequency sweep done. 23/240 significant pairs. Results at ~/proj/neurovista-pac/results/"

# 5. Remove in-progress (orchestrator will close after verification)
gh issue edit 85 --repo ywatanabe1989/todo --remove-label "in-progress"
```

### Post-Compaction Recovery

After every compaction or restart, immediately check for assigned work:

```bash
gh issue list --repo ywatanabe1989/todo --state open --label "in-progress,spartan" --limit 10
gh issue list --repo ywatanabe1989/todo --state open --label "high-priority,spartan" --limit 10
gh issue list --repo ywatanabe1989/todo --state open --label "high-priority" --limit 10
```

Read the highest-priority open issue and resume. Check issue comments for the last known state before compaction.

### Progress Updates

Before a potential compaction (context getting large), always comment current progress on the relevant issue. This ensures no work state is lost.

## Workflow Rules
- Always `git pull origin develop` before starting work
- Develop branch is source of truth for all SciTeX packages
- Create feature branches when conflicts expected
- Communicate proactively on #general via Orochi
- Track all tasks at github.com/ywatanabe1989/todo/issues
- Update this skills file after learning lessons
- **ALWAYS close GitHub issues when task completed**: `gh issue close <N> --repo ywatanabe1989/todo --comment "Done: <summary>"`
- **Search for SIMILAR issues before starting**: `gh issue list --repo ywatanabe1989/todo --search "<keywords>"` and consolidate duplicates
- Report task status to Orochi so dashboard shows active state

## Lessons Learned
- Bash hook blocks commands without `timeout <= 7000` or `run_in_background: true`
- LaTeX compilation for SciTeX Writer must run from scitex-writer/ root, not from 01_manuscript/
- FINAL.tex files are gitignored (auto-generated during compilation)
- `Path("file.fig.zip").suffixes` returns `['.fig', '.zip']` — useful for compound extension detection
- FMChecker in scitex-linter needs explicit import of `_is_allowed_by_comment` from checker module

## File Transfer
Always use rsync, never scp — handles unstable connections with checksum verification and resume:
```bash
rsync -avz --partial --progress -e ssh spartan:~/remote/path ~/local/path
```

## Email from Spartan
Spartan login nodes have localhost:25 SMTP (no auth needed):
```python
with smtplib.SMTP('localhost', 25) as server:
    server.sendmail('ywatanabe@spartan.hpc.unimelb.edu.au', to_addr, msg.as_string())
```

## Credential Management
Claude credentials expire. Before launching a remote agent, always refresh:
```bash
scp ~/.claude/.credentials.json spartan:~/.claude/.credentials.json
```
Then launch: `ssh spartan "screen -dmS spartan-agent bash -c 'claude --dangerously-skip-permissions -p \"task\" > /tmp/spartan-agent.log 2>&1'"`

## Orochi Connectivity

Spartan's university firewall blocks outbound WebSocket on port 9559. Push mode (`orochi_push.ts`) does not work from Spartan.

**Current status**: spartan-agent cannot connect via push mode. Use polling mode as fallback:
```bash
python3 ~/proj/orochi-agents/poll-agent.py spartan-agent --model opus --channels "#general,#research" --interval 15
```

Once `orochi_push.ts` supports WSS proxy via `wss://orochi.scitex.ai` (port 443, which is allowed), push mode will work from Spartan.
