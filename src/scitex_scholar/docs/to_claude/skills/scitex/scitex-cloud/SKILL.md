---
description: SciTeX Cloud platform CLI — project management, Git hosting (Gitea), three-way sync, app deployment, cloud SDK, and infrastructure. Use when managing projects, syncing code, deploying apps, or running cloud operations.
allowed-tools: mcp__scitex__cloud_*
---

# scitex-cloud Skills Index

## Installation

```bash
pip install scitex-cloud
# Development:
pip install -e /home/ywatanabe/proj/scitex-cloud
```

This directory contains focused skill files for the scitex-cloud package.

## Sub-Skills

| File | Topic |
|------|-------|
| [python-api.md](python-api.md) | Python API — CloudClient, project_*, health_check |
| [project-management.md](project-management.md) | CLI project CRUD — create, list, delete, rename |
| [sync-architecture.md](sync-architecture.md) | Three-way sync — push/pull (git) and sync-to/from (files) |
| [gitea-cli.md](gitea-cli.md) | Gitea Git hosting — repos, PRs, issues, auth |
| [app-management.md](app-management.md) | App plugins — init, validate, submit, prefs, containers |
| [sdk.md](sdk.md) | Cloud SDK — DataStore, FileVault, JobQueue |
| [infrastructure.md](infrastructure.md) | Docker, setup, deploy, MCP server |
| [deployment-staging.md](deployment-staging.md) | Deploy to staging — sync, build, verify |
| [deployment-production.md](deployment-production.md) | Deploy to production — NAS safety, cgroup limits |
| [version-management.md](version-management.md) | Ecosystem version sync and bump |
| [refactoring-rules.md](refactoring-rules.md) | File size thresholds, extraction patterns |
| [development-environment.md](development-environment.md) | Docker dev setup, hot reload, access URLs |
| [django-conventions.md](django-conventions.md) | 1:1:1:1 full-stack conventions, naming |
| [vite-frontend.md](vite-frontend.md) | Vite HMR, entry points, template tags |
| [mobile-testing.md](mobile-testing.md) | Mobile responsive testing — Playwright, viewport, auth selectors |

## Quick Navigation

- Managing cloud projects -> [project-management.md](project-management.md)
- Syncing code between local/workspace -> [sync-architecture.md](sync-architecture.md)
- Git repo operations (clone, fork, PR, issue) -> [gitea-cli.md](gitea-cli.md)
- Developing/publishing apps -> [app-management.md](app-management.md)
- DataStore / FileVault / JobQueue -> [sdk.md](sdk.md)
- Docker, deploy, MCP server -> [infrastructure.md](infrastructure.md)
- Python API programmatic access -> [python-api.md](python-api.md)
- Deploy to staging -> [deployment-staging.md](deployment-staging.md)
- Deploy to production -> [deployment-production.md](deployment-production.md)
- Version sync across ecosystem -> [version-management.md](version-management.md)
- Refactoring rules (file sizes, extraction) -> [refactoring-rules.md](refactoring-rules.md)
- Dev environment setup -> [development-environment.md](development-environment.md)
- Django conventions (1:1:1:1) -> [django-conventions.md](django-conventions.md)
- Vite/TypeScript frontend -> [vite-frontend.md](vite-frontend.md)
- Mobile responsive testing -> [mobile-testing.md](mobile-testing.md)

# EOF
