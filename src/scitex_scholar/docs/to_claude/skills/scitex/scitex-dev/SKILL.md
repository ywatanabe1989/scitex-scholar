---
description: Shared developer utilities for the SciTeX ecosystem — ecosystem management, version checking, bulk rename, docs aggregation, Result types, and HPC test runner.
allowed-tools: mcp__scitex__dev_*
---

# scitex-dev Skills Index

This file is an **index only**. Detailed usage is in the sub-skill files.

> These skills are distributed with the **scitex-dev** package.
> Local edits may be overwritten on update. See [MANIFEST.md](MANIFEST.md) for version and update instructions.

## Sub-skills

| File | Topic |
|---|---|
| result-types.md | Result envelope, ErrorCode, @supports_return_as, SideEffect |
| cli-mcp-utils.md | Adapters: CLI exit codes, MCP JSON, option factories |
| versions.md | list_versions, check_versions, get_mismatches, fix_mismatches |
| ecosystem.md | Package registry, sync_local, sync_all, sync_host, pull_local |
| rename.md | bulk_rename, preview_rename, execute_rename |
| docs-search.md | get_docs, build_docs, search_docs, search |
| test-runner.md | run_local, run_hpc_sbatch, poll_hpc_job, fetch_hpc_result |
| config.md | DevConfig, HostConfig, load_config, create_default_config |
| full-update.md | Full ecosystem release pipeline — audit, bump, release, sync |

## Quick Reference

```bash
# CLI
scitex-dev ecosystem list
scitex-dev ecosystem fix-mismatches --dry-run
scitex-dev rename old_name new_name --root . --dry-run
scitex-dev search "save figure"
scitex-dev mcp start
```

```python
import scitex_dev as dev
dev.check_versions()
dev.fix_mismatches(confirm=False)   # dry-run by default
dev.preview_rename(pattern="old", replacement="new", directory=".")
```

## MCP Tools

| Tool | Purpose |
|---|---|
| `dev_ecosystem_list` | List all ecosystem packages |
| `dev_ecosystem_sync` | Sync packages to remote hosts |
| `dev_ecosystem_sync_local` | Reinstall local packages (pip install -e .) |
| `dev_ecosystem_pull` | Git pull all packages |
| `dev_ecosystem_commit` | Commit across all packages |
| `dev_ecosystem_diff` | Show uncommitted changes |
| `dev_ecosystem_fix_mismatches` | Detect and fix version mismatches |
| `dev_config_show` | Show ecosystem configuration |
| `dev_bulk_rename` | Bulk rename across ecosystem |
| `dev_test_local` | Run local pytest |
| `dev_test_hpc` | Submit HPC Slurm test job |
| `dev_test_hpc_poll` | Poll HPC job status |
| `dev_test_hpc_result` | Fetch HPC test output |
