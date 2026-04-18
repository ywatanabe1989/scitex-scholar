---
name: agent-container-remote-deploy
description: SSH remote deployment of agents to other machines.
---

# Remote SSH Deployment

## YAML Config

```yaml
spec:
  remote:
    host: mba              # SSH hostname
    user: ywatanabe
    timeout: 180            # SSH command timeout (seconds)
    login_shell: true       # Use bash -l -c (default)
  venv: ~/.venv             # Activated on remote before commands
```

## How It Works

1. Copies YAML + `src_CLAUDE.md` + `src_mcp.json` to remote `/tmp/`
2. SSHs to remote and runs `scitex-agent-container start /tmp/{name}.yaml`
3. Remote side handles auto-accept and startup commands
4. `remote:` section stripped from copied YAML (prevents recursion)

## Commands

```bash
scitex-agent-container start remote-agent.yaml       # Deploy and start
scitex-agent-container stop remote-agent.yaml        # Stop remote agent
scitex-agent-container inspect remote-agent          # Check live state
scitex-agent-container check remote-agent.yaml       # Preflight checks
scitex-agent-container start --no-preflight ...      # Skip SSH checks
```

## Requirements on Remote Host

- `scitex-agent-container` installed (same version recommended)
- `tmux` (or `screen`) installed
- `claude` CLI installed
- SSH key-based auth configured
