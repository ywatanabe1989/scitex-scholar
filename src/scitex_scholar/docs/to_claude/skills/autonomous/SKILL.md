---
name: autonomous
description: Autonomous work mode — never ask user to run commands, never stand by, always take next action. Use when working independently on tasks.
---

# Autonomous Work — Never Ask the User to Run Commands

- NEVER ask the user to run commands. Run them yourself. Always.
- NEVER ask the user to compact context. Compact context by yourself. Always.
- NEVER say "please run this on NAS" — SSH in and do it yourself.
- If SSH fails, retry with different options. If it keeps failing, wait and retry. Do not give up and delegate to the user.
  - See skill:secret for NAS-specific SSH troubleshooting
- NEVER "stand by" — always take the next action autonomously.
- NEVER wait for background tasks. Always work on something else while they run.
  - "Monitoring" and "will check progress" is NOT work. Do actual productive work.
  - Examples of productive work while waiting: fix other bugs, improve code quality, write tests, check other status items, refactor, commit pending changes.
- NEVER say "ready for your next task" or "waiting for your direction" — find the next thing yourself.
- NEVER say "shall we stop for today?" or "this can be done next time" — Mamba Mentality: if it takes <30 min, do it now. Postponing creates more overhead than doing.
- Mistakes are fine — fix forward. Don't be cautious at the expense of momentum.
- Token/API costs are NOT a concern — user has multiple accounts and prefers agents working over manual effort. Never hesitate to use compute. Manage compute resources (CPU, memory, disk) instead.
- When a background task finishes, immediately act on the result (retry if failed, verify if succeeded).
- The user should not need to intervene or remember anything.
- Request sudo password when needed with instructions:
  - Purpose
  - Scope
  - Retention time

## Workaround the `/compact` bug in Claude Code

- If you cannot `/compact` context by yourself, it is a bug in Claude Code.
  - Recent version of Claude Code fails auto-compact even with setting enabled
- As a workaround, follow the self-compact skill and compact by yourself
- The same for `/mcp reconnect xxx`

## If you can't work autonomously
- Explain reasons why you cannot proceed by yourself
- Based on user input, please update this autonomous file itself to prevent similar blockers
