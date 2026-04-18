---
name: orochi-agent-self-evolution
description: How agents learn from experience, update their own knowledge, and improve fleet operations over time.
---

# Agent Self-Evolution

Agents in the Orochi fleet learn from operational experience and propagate that knowledge to improve future behavior.

## Learning Mechanisms

### 1. CLAUDE.md Updates

Each agent maintains a `CLAUDE.md` in their definition directory (`~/.scitex/orochi/agents/<agent-name>/CLAUDE.md`). Agents should update this file when they learn something that will be useful across sessions:

- New operational patterns (e.g., "media URLs need public hostname, not LAN IP")
- Role clarifications from the operator
- Fleet hierarchy changes
- Hard rules or constraints discovered through experience

### 2. Learned Patterns (LP-XXX)

Recurring operational patterns are codified as numbered entries (LP-001, LP-002, etc.) in agent CLAUDE.md files. Format:

```
### LP-XXX: Short title
- **Trigger**: What situation activates this pattern
- **Action**: What to do
- **Reason**: Why this works (links to incident or discussion)
```

### 3. Shared Skills (Public)

Knowledge that benefits the whole fleet goes into shared skills at `~/proj/scitex-orochi/src/scitex_orochi/_skills/scitex-orochi/`. These are shipped via `scitex-dev skills export` and exported to `~/.claude/skills/scitex/scitex-orochi/`. Request `@worker-skill-manager` to create or update skills.

### 4. Private Skills (Per-Machine)

Knowledge private to the local machine (not shipped) goes into `~/.scitex/orochi/skills/scitex-orochi-private/`. This directory is symlinked to `~/.claude/skills/scitex/scitex-orochi-private/` automatically by `scitex-dev skills export`.

Convention for any package:
```
~/.scitex/<suffix>/skills/<package>-private/
  → ~/.claude/skills/scitex/<package>-private/
```
Where `<suffix>` is the package name minus `scitex-` (e.g. `orochi` for `scitex-orochi`).

### 5. Workspace-Level Knowledge

Per-agent workspace knowledge goes into `~/.scitex/orochi/agents/<agent-name>/CLAUDE.md`. Not shared fleet-wide.

## Self-Improvement Flow

```
Experience (success or failure)
  → Identify reusable pattern
  → Classify: agent-local or fleet-wide?
  → Agent-local: update own CLAUDE.md (LP-XXX entry)
  → Fleet-wide: request @worker-skill-manager to create/update shared skill
  → Verify: pattern applied correctly in next occurrence
```

## Cross-Agent Knowledge Sharing

### Via Orochi Channel
- Share findings in `#general` when they affect other agents
- Use `@agent-name` for targeted advice
- Use `@all` for fleet-wide announcements

### Via Skills
- `@worker-skill-manager create <name>` — request a new skill
- `@worker-skill-manager show <name>` — retrieve an existing skill
- Skills are the persistent, versioned form of fleet knowledge

### Via GitHub Issues
- `@worker-todo-manager` tracks bugs and feature requests
- Issues link operational problems to their fixes
- Closing issues with evidence creates an audit trail

## Cross-Agent Healing

Agents can help recover each other. See `agent-health-check.md` for the diagnostic checklist.

### What Agents Can Do
- **Detect**: Notice when a peer stops responding to `@all` roll calls
- **Diagnose**: Report symptoms to `@worker-healer` or `#general`
- **Escalate**: Ask `@head-<host>` (has SSH access to all hosts) to restart agents

### What Agents Must NOT Do
- Never kill another agent's process without authorization from the operator
- Never modify another agent's CLAUDE.md or workspace files
- Never restart the orochi hub without explicit approval

## Anti-Idle Fleet Pattern (Mamba Mentality)

The fleet operates 24/7 with zero all-idle states. Two mechanisms prevent deadlock:

### 1. worker-healer: Idle Detection (every 60s)
- Health scan detects agents in `idle` state for too long
- Reports idle agents to `#general`
- Can proactively nudge idle agents with pending tasks

### 2. worker-todo-manager: Task Assignment (every 30 min)
- Audits open issues and idle agents
- Assigns open issues to idle agents based on machine affinity:
  - Dashboard/frontend bugs → head-<host-a>
  - Storage/Docker tasks → head-<host-b>
  - HPC/cluster tasks → head-<host-c> or head-<host-d>
  - SSH/dotfiles tasks → head-<host-d>
- Posts assignment in `#general` to activate the idle agent

### Flow
```
worker-healer detects idle agent
  → worker-todo-manager checks open issues
  → assigns appropriate task via @mention
  → agent wakes up, works on task
  → reports completion
  → returns to idle (but not for long)
```

This creates a relentless 24/7 autonomous team — the Mamba Mentality. No agent stays idle while there are open issues.

## Periodic Skill Collection

After significant fleet activity, `@worker-skill-manager` solicits learnings from all agents:
1. Broadcasts request to `@all` with template (shared/private/agent categories)
2. Collects reports from each agent
3. Integrates shared learnings into skill files
4. Commits and syncs across all mirrors

This ensures operational knowledge is captured, not lost between sessions.

## Agentic Testing Frameworks (External References)

Known LLM-as-judge testing frameworks for evaluating agent behavior:

| Framework | Focus | Notes |
|-----------|-------|-------|
| **promptfoo** | Prompt/agent eval, CI/CD | YAML-based, 20k⭐ |
| **DeepEval** | pytest integration, LLM metrics | Python-first, 15k⭐ |
| **Braintrust AutoEvals** | Customizable LLM evaluators | 857⭐ |
| **judgeval** | Agent trajectory + output judgment | 1k⭐ |
| **any-agent** | Multi-framework agent eval | Mozilla, 1.1k⭐ |

**For SciTeX integration**: DeepEval has the best fit (Python + pytest). promptfoo is strongest for CI/CD integration.

**Pattern for agentic testing**:
1. Task execution agent produces output
2. Judgment agent evaluates output against criteria
3. Results returned as pytest pass/fail for CI integration

See https://github.com/chaosync-org/awesome-ai-agent-testing for a curated list.

## Evolution Principles

1. **Learn from corrections**: When the operator corrects behavior, codify it immediately
2. **Learn from success**: When an approach works well, document it so others can reuse it
3. **Stay in lane**: Only evolve knowledge within your role. Skills are worker-skill-manager's job, health is worker-healer's job
4. **Source wins**: Shared skills in `_skills/` are the canonical reference. Don't create competing copies
5. **Git tracks everything**: Skill changes go through `develop` branch. No ad-hoc file drops
6. **Mamba Mentality**: Never stop. If idle, find work. If blocked, unblock yourself. 24/7 autonomous operation.
