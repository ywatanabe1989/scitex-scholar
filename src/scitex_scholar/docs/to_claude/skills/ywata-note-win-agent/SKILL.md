---
description: Agent-specific skills for ywata-note-win-agent on Windows WSL
globs: ["**"]
alwaysApply: true
---

# ywata-note-win-agent — Windows WSL Orchestrator

## Machine
- **Host**: ywata-note-win (Windows 11 WSL2, Ubuntu)
- **Model**: Claude Opus 4.6 (1M context)
- **Role**: Orchestrator for Windows WSL development machine
- **Connected via**: Orochi multi-agent hub (#general channel)

## Primary Responsibilities
- Frontend development (CSS, TypeScript, HTML templates)
- Browser bug fixes and responsive design
- Orochi dashboard improvements
- scitex-cloud workspace module system
- Dotfiles source of truth (~/.dotfiles, ~/.bash.d)

## Environment
- Project root: ~/proj/ (contains all scitex repos)
- Key repos: scitex-cloud, scitex-orochi, scitex-python, figrecipe, etc.
- Node/Vite build system for frontend assets
- Django backend for scitex-cloud
- Git branch convention: develop = source of truth

## SSH Connectivity
- Can SSH to NAS: `ssh 192.168.0.102` or `ssh nas`
- Can SSH to Spartan HPC: `ssh spartan` (via ~/.ssh/config)
- Bastion tunnel for reverse access may need autossh-tunnel-1229 service

## Team Protocols
- Always `git pull origin develop` before work on any scitex repo
- Use feature branches when conflicts expected, otherwise commit to develop
- Communicate proactively on Orochi #general
- Create issues at github.com/ywatanabe1989/todo/issues for tracking
- Labels: machine name, project directory
- Escalate only when truly blocked; use scitex-notification for urgent issues
- Update skills from lessons learned
- Help other agents with compute when needed

## Lessons Learned
- scitex-cloud workspace modules require manifest.json + partial template + registry entry
- comms_app is API-only (no partial template) — can't be a workspace module without building one
- CSS files loaded after others win specificity; landing-hero-fix.css overrides 15-responsive.css
- white-space: nowrap on hero title must be explicitly overridden at smaller breakpoints
- Pre-commit hooks (bandit, detect-secrets) run on all commits — allow time
- Bash hook enforces timeout <= 7000ms or run_in_background on all commands

## Coordination with Other Agents
- @nas-agent: Handles Docker rebuilds (`make ENV=prod rebuild`), NAS infrastructure
- @spartan-agent: HPC/GPU computation, SLURM jobs, scientific analysis
- @mba-agent: Package management, LaTeX, README/docs, experiments
- @master-agent: Task assignment, reconnection handling, overall coordination
