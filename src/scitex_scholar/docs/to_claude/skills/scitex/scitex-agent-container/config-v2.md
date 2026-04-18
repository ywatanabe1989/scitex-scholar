---
name: agent-container-config-v2
description: v2 YAML config format with auto-derived fields and src file deployment.
---

# v2 Config Format

## apiVersion: scitex-agent-container/v2

```yaml
apiVersion: scitex-agent-container/v2
kind: Agent
metadata:
  name: my-agent
  labels:
    role: worker
    machine: local
spec:
  runtime: claude-code
  model: opus[1m]
  multiplexer: tmux

  claude:
    flags:
      - --dangerously-skip-permissions
    session: new

  skills:
    required:
      - scitex
```

## Auto-Derived Fields (from metadata.name + labels)

| Field | Derived as |
|-------|-----------|
| `workdir` | `~/.scitex/orochi/workspaces/{name}` |
| `screen_name` | `{name}` |
| `env.CLAUDE_AGENT_ID` | `{name}` |
| `env.CLAUDE_AGENT_ROLE` | `{labels.role}` |
| `env.SCITEX_OROCHI_AGENT` | `{name}` |
| `env.SCITEX_OROCHI_MODEL` | human-readable from `spec.model` |
| `hooks.pre_start` | `mkdir -p {workdir}/.claude` |

All overridable by explicit values in the YAML.

## Agent Definition Directory

```
agents/my-agent/
  my-agent.yaml     # Agent config
  src_CLAUDE.md      # -> section-injected into {workdir}/CLAUDE.md
  src_mcp.json       # -> interpolated and copied to {workdir}/.mcp.json
```

### src_CLAUDE.md

Content between `<!-- Start of scitex-agent-container -->` / `<!-- End -->` tags is injected. Agent-written content outside tags is preserved across restarts.

### src_mcp.json

Supports interpolation:
- `${metadata.name}` -> agent name
- `${ENV_VAR}` -> resolved from os.environ
- `~/` in args -> expanded to full path

```json
{
  "mcpServers": {
    "scitex-orochi": {
      "type": "stdio",
      "command": "bun",
      "args": ["run", "~/proj/scitex-orochi/ts/mcp_channel.ts"],
      "env": {
        "SCITEX_OROCHI_URL": "wss://scitex-orochi.com",
        "SCITEX_OROCHI_AGENT": "${metadata.name}",
        "SCITEX_OROCHI_TOKEN": "${SCITEX_OROCHI_TOKEN}"
      }
    }
  }
}
```

## v1 (legacy): apiVersion: cld-agent/v1

All fields explicit. Still fully supported. No auto-derivation.
