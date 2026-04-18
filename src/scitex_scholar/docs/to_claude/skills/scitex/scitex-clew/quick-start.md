---
description: Basic scitex-clew API, session tracking, and first verification run.
---

# Quick Start

## Installation

```bash
pip install scitex-clew          # core (no dependencies)
pip install scitex-clew[cli]     # + click for CLI
pip install scitex-clew[mcp]     # + fastmcp for MCP server
pip install scitex-clew[all]     # everything
```

## Public API (19 functions)

```python
import scitex_clew as clew

# Verification
clew.status()                      # git-status-like overview
clew.run(session_id)               # verify one run (hash check)
clew.chain(target_file)            # trace file -> source chain
clew.dag(targets)                  # verify full DAG
clew.rerun(target)                 # re-execute & compare (sandbox)
clew.rerun_dag(targets)            # rerun full DAG in topo order
clew.rerun_claims()                # rerun all claim-backing sessions
clew.list_runs(limit=100)          # list tracked runs
clew.stats()                       # database statistics

# Claims
clew.add_claim(...)                # register manuscript assertion
clew.list_claims(...)              # list registered claims
clew.verify_claim(...)             # verify a specific claim

# Stamping
clew.stamp(...)                    # create temporal proof
clew.list_stamps(...)              # list stamps
clew.check_stamp(...)              # verify a stamp

# Hashing
clew.hash_file(path)               # SHA256 of a file
clew.hash_directory(path)          # SHA256 of all files in dir

# Visualization
clew.mermaid(...)                  # generate Mermaid DAG diagram

# Examples
clew.init_examples(dest)           # scaffold example pipeline
```

## Verification status overview

```python
import scitex_clew as clew

# Like git status — shows verified/mismatch/missing/unknown counts
result = clew.status()
# Returns dict: {verified, mismatch, missing, unknown, total}
```

## Verify a session run

```python
# Verify by session ID (hash check — fast)
rv = clew.run("2025Y-11M-18D-09h12m03s_HmH5")
print(rv.is_verified)       # True / False
print(rv.status.value)      # 'verified' / 'mismatch' / 'missing' / 'unknown'

for f in rv.files:
    print(f.path, f.role, f.is_verified)

# Re-execute in sandbox and compare outputs (slow but thorough)
rv = clew.run("2025Y-11M-18D-09h12m03s_HmH5", from_scratch=True)
```

## Trace provenance chain

```python
# Verify the full dependency chain for a file
chain = clew.chain("/path/to/results/model_accuracy.csv")
print(chain.is_verified)            # True if whole chain passes
print(len(chain.runs))              # number of sessions in chain
print(len(chain.failed_runs))       # number with failures
```

## List tracked runs

```python
runs = clew.list_runs(limit=50)
for r in runs:
    print(r["session_id"], r.get("status"), r.get("script_path"))
```

## Hash utilities

```python
# Hash a single file (returns first 32 hex chars of SHA256)
h = clew.hash_file("data.csv")

# Hash all files in a directory
hashes = clew.hash_directory("/path/to/dir")
# Returns dict: {filename: hash, ...}
```

## Auto-integration with scitex

When scitex is installed, clew integrates automatically:

```python
import scitex as stx

@stx.session
def main(logger=stx.INJECTED):
    # stx.io.load/save automatically records hashes via SessionTracker
    data = stx.io.load("raw_data.csv")
    result = process(data)
    stx.io.save(result, "processed.csv")
    return 0
```

Every `stx.io.load()` call records an input hash; every `stx.io.save()` records an output hash, linked to the current `@stx.session` ID.
