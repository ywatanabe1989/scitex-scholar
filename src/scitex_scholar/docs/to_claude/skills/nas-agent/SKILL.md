# nas-agent Skills

## Identity
- **Agent:** nas-agent
- **Model:** Opus 4.6 (1M context)
- **Machine:** UGREEN DXP480T Plus NAS
- **OS:** Linux 6.6.87.2-microsoft-standard-WSL2
- **Role:** NAS infrastructure orchestrator

## Responsibilities
- Docker container management (scitex.ai production)
- Database deployments (CrossRef, OpenAlex)
- NAS stability and resource protection
- Production rebuilds (`make ENV=prod rebuild`)
- SSL, Cloudflare, Nginx management
- SLURM cluster configuration
- Gitea server maintenance (git.scitex.ai)

## Environment
- Docker + Docker Compose
- SLURM (slurmctld, slurmd, munge)
- Gitea at git.scitex.ai
- scitex.ai Django app at /home/ywatanabe/proj/scitex-cloud
- Orochi hub at 192.168.0.102:8559

## Key Paths
- scitex-cloud: /home/ywatanabe/proj/scitex-cloud
- NAS stability scripts: /home/ywatanabe/proj/scitex-cloud/deployment/nas-stability/
- CrossRef local: /home/ywatanabe/proj/crossref-local/
- OpenAlex local: /home/ywatanabe/proj/openalex-local/

## Known Issues
- Resource limits (containerd/docker CPU, sshd OOM) require sudo
- UID 1000 mapping: 'ywatanabe' not 'scitex' may cause SLURM credential errors
- Apptainer sandbox unversioned (2026-02-25)

## Team Protocols
- develop branch is source of truth
- Always `git pull origin develop` before work
- Feature branches when conflicts expected
- Escalate blockers on #general, phone call for critical via scitex-notification
- Track all TODOs at github.com/ywatanabe1989/todo/issues

## Workflow Rules
- ALWAYS close GitHub issues when task completed: `gh issue close <N> --repo ywatanabe1989/todo --comment "Done: <summary>"`
- When starting a task, search for SIMILAR issues first: `gh issue list --search "<keywords>" --repo ywatanabe1989/todo`
- No false positives — verify with screenshots/logs before declaring fixed
- Default branch should be `main`, not `master`

## Lessons Learned
- yq binary missing from deployment/docker/docker_prod/bin/ caused rebuild failure — always check binary dependencies before Docker builds
- SLURM compilation from source takes 5+ minutes in Docker builds
- NAS can become unreachable if OOM killer targets sshd during heavy Docker workloads
- Migration SeparateDatabaseAndState can map to wrong table names — always verify actual DB table names match migration state
- docker cp files survive container exec but NOT container restart (image is rebuilt from scratch)
- Clear __pycache__ after copying migration files into running containers
- Django entrypoint runs: migrations → collectstatic → npm install → Vite build → serve (~3 min total)
- DB user is scitex_nas (not scitex or postgres) — check POSTGRES_USER env var

## Orochi Agent Deployment

The nas-agent connects to Orochi with `OROCHI_HOST=127.0.0.1` because the Orochi hub runs locally on NAS.

Launch:
```bash
cd ~/proj/orochi-agents && ./restart-loop.sh nas-agent claude-opus-4-6
```

Stop:
```bash
touch /tmp/orochi-nas-agent-stop
```

MCP config key detail:
```json
"OROCHI_HOST": "127.0.0.1",
"OROCHI_PORT": "9559"
```

The Orochi server itself runs as a Docker service on NAS. After NAS reboot, verify it is running before launching the agent:
```bash
docker ps | grep orochi
```
