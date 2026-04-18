---
description: Common scitex-clew workflows — claims, DAG patterns, stamps, and reproducibility auditing.
---

# Common Workflows

## Register a manuscript claim

Claims link manuscript assertions (statistics, figures, tables) to the verification chain.

```python
import scitex_clew as clew

# Register a statistic assertion
claim = clew.add_claim(
    file_path="paper.tex",
    claim_type="statistic",       # statistic | figure | table | text | value
    line_number=42,
    claim_value="p = 0.003",
    source_file="results/stats_output.csv",
    source_session="2025Y-11M-18D-09h12m03s_HmH5",  # optional, auto-detected
)
print(claim.claim_id)    # e.g., 'claim_a1b2c3d4e5f6'

# Register a figure assertion
clew.add_claim(
    file_path="paper.tex",
    claim_type="figure",
    line_number=115,
    source_file="figures/fig3_accuracy.png",
)
```

Claim types: `"statistic"`, `"figure"`, `"table"`, `"text"`, `"value"`

## List and filter claims

```python
# All claims
claims = clew.list_claims()

# Filter by file
claims = clew.list_claims(file_path="paper.tex")

# Filter by type
claims = clew.list_claims(claim_type="statistic")

# Filter by verification status
claims = clew.list_claims(status="verified")  # verified | mismatch | missing | partial | registered
```

## Verify a claim

```python
# By claim_id
result = clew.verify_claim("claim_a1b2c3d4e5f6")

# By location string
result = clew.verify_claim("paper.tex:L42")

print(result["source_verified"])   # True/False
print(result["chain_verified"])    # True/False
print(result["details"])           # list of explanation strings
```

## DAG verification patterns

```python
# Verify the entire DAG from all registered claims
dag_result = clew.dag(claims=True)
print(dag_result.is_verified)
print(dag_result.topological_order)

# Verify DAG for specific output files
dag_result = clew.dag([
    "/data/results/fig1.png",
    "/data/results/table1.csv",
])

# Rerun full DAG in topo order (sandbox — does not overwrite originals)
dag_result = clew.rerun_dag(timeout=300)

# Rerun DAG for specific targets
dag_result = clew.rerun_dag(
    targets=["/data/results/model_accuracy.csv"],
    timeout=600,
    cleanup=True,   # remove sandbox dirs after verification
)
```

## Rerun all claim-backing sessions

```python
# Rerun every session that produced a file referenced by a claim
dag_result = clew.rerun_claims()

# Filter by manuscript and claim type
dag_result = clew.rerun_claims(
    file_path="paper.tex",
    claim_type="statistic",
    timeout=300,
)
```

## Temporal stamps

Stamps record a Merkle-like root hash of all verified runs at a point in time, with an external timestamp as proof.

```python
# File-based stamp (local JSON file)
s = clew.stamp(backend="file")
print(s.stamp_id)      # e.g., 'stamp_a1b2c3d4e5f6'
print(s.root_hash)     # SHA256 over all run hashes
print(s.timestamp)     # ISO 8601 UTC

# RFC 3161 timestamping authority (requires rfc3161ng)
s = clew.stamp(
    backend="rfc3161",
    service_url="http://zeitstempel.dfn.de",   # default
)

# Stamp only specific sessions
s = clew.stamp(
    backend="file",
    session_ids=["2025Y-11M-18D-09h12m03s_HmH5", "2025Y-11M-19D-10h30m00s_AbC1"],
)

# List all stamps
stamps = clew.list_stamps()

# Check a stamp against current state
result = clew.check_stamp()                   # latest stamp
result = clew.check_stamp("stamp_a1b2c3d4e5f6")
print(result["matches"])     # True if state unchanged since stamp
print(result["details"])     # explanation strings
```

Stamp backends: `"file"` (local), `"rfc3161"` (TSA standard), `"scitex_cloud"` (SciTeX Cloud)

## Full reproducibility audit workflow

```python
import scitex_clew as clew

# 1. Check overall state
summary = clew.status()
print(f"Verified: {summary['verified']}/{summary['total']}")

# 2. List any problematic runs
runs = clew.list_runs(limit=100)
for r in runs:
    rv = clew.run(r["session_id"])
    if not rv.is_verified:
        print(f"PROBLEM: {r['session_id']} ({rv.status.value})")
        for f in rv.mismatched_files:
            print(f"  mismatch: {f.path}")
        for f in rv.missing_files:
            print(f"  missing:  {f.path}")

# 3. Verify claims
for claim in clew.list_claims():
    res = clew.verify_claim(claim.claim_id)
    print(f"{claim.claim_id}: {res['claim']['status']}")

# 4. Create stamp as proof
stamp = clew.stamp(backend="file")
print(f"Stamped at {stamp.timestamp}: {stamp.root_hash[:16]}...")
```

## Example pipeline scaffold

```python
# Generate a complete example multi-script pipeline with clew tracking
clew.init_examples(dest="./clew_examples")
```

Creates numbered scripts (`01_source_a.py`, `02_preprocess_a.py`, ...) that demonstrate the full tracking → verification → DAG workflow.
