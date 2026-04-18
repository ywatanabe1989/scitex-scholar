---
description: MCP tool reference for AI agents using scitex-clew via the clew_* tools.
---

# MCP Tools for AI Agents

Requires `pip install scitex-clew[mcp]` (adds `fastmcp` dependency).

Start server: `fastmcp run scitex_clew._mcp.server:mcp`

All tools return JSON strings.

## clew_status

Show verification status summary (like git status).

```
clew_status()
```

Returns: `{verified, mismatch, missing, unknown, total}` counts.

## clew_list

List all tracked runs with verification status.

```
clew_list(limit=50, status_filter=None)
```

Parameters:
- `limit` (int, default 50): maximum runs to return
- `status_filter` (str, optional): `"success"`, `"failed"`, `"running"`, or `None` for all

Returns: `{count, runs: [{session_id, script_path, db_status, verification_status, is_verified, started_at, finished_at}]}`

## clew_run

Verify a specific session run by checking all file hashes.

```
clew_run(session_or_path)
```

Parameters:
- `session_or_path` (str): session ID (e.g., `"2025Y-11M-18D-09h12m03s_HmH5"`) or path to a file to find its session

Returns: `{session_id, script_path, status, is_verified, combined_hash_expected, files: [{path, role, status, expected_hash, current_hash, is_verified}], mismatched_count, missing_count}`

## clew_chain

Verify the dependency chain for a target file.

```
clew_chain(target_file)
```

Parameters:
- `target_file` (str): absolute or relative path to the target file

Returns: `{target_file, status, is_verified, chain_length, failed_runs_count, runs: [{session_id, script_path, status, is_verified, mismatched_files, missing_files}]}`

## clew_dag

Verify full DAG for multiple targets or all claims.

```
clew_dag(target_files=None, claims=False)
```

Parameters:
- `target_files` (str, optional): comma-separated list of target file paths
- `claims` (bool, default False): if True, build DAG from all registered claims

Returns: `{target_files, status, is_verified, num_runs, num_edges, topological_order, runs, edges}`

Example — verify DAG for specific files:
```
clew_dag(target_files="/data/results/fig1.png,/data/results/table1.csv")
```

Example — verify DAG from claims:
```
clew_dag(claims=True)
```

## clew_mermaid

Generate Mermaid diagram for verification DAG.

```
clew_mermaid(session_id=None, target_file=None, target_files=None, claims=False)
```

Parameters:
- `session_id` (str, optional): start from this session
- `target_file` (str, optional): start from session that produced this file
- `target_files` (str, optional): comma-separated list of target files
- `claims` (bool, default False): if True, build DAG from all registered claims

Returns: `{mermaid, session_id, target_file, target_files, claims}` where `mermaid` is a Mermaid diagram string.

## clew_rerun_dag

Re-execute entire DAG in topological order and compare outputs.

```
clew_rerun_dag(target_files=None, timeout=300)
```

Parameters:
- `target_files` (str, optional): comma-separated list of target file paths; if omitted, reruns all runs
- `timeout` (int, default 300): max execution time per session in seconds

Returns: DAGVerification JSON (`status`, `is_verified`, `runs`, `edges`, `topological_order`).

Note: each session is re-executed in a sandbox — original outputs are never overwritten.

## clew_rerun_claims

Re-execute all sessions backing manuscript claims.

```
clew_rerun_claims(file_path=None, claim_type=None, timeout=300)
```

Parameters:
- `file_path` (str, optional): filter claims by manuscript file path
- `claim_type` (str, optional): filter by type — `"statistic"`, `"figure"`, `"table"`, `"text"`, `"value"`
- `timeout` (int, default 300): max execution time per session in seconds

Returns: DAGVerification JSON.

## clew_stats

Show verification database statistics.

```
clew_stats()
```

Returns: JSON dict with database statistics.

## Status values

All `status` fields use these values:
- `"verified"` — all file hashes match
- `"mismatch"` — at least one hash differs
- `"missing"` — at least one file is absent
- `"unknown"` — no tracking data available
