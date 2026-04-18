---
topic: test-runner
package: scitex-dev
description: >
  Run pytest locally or on HPC via Slurm. TestConfig configures test
  execution. run_local runs pytest in-process. sync_to_hpc rsyncs the
  project. run_hpc_srun/sbatch submit jobs. poll_hpc_job and
  fetch_hpc_result retrieve status and output.
---

# Test Runner

## TestConfig

Dataclass for test execution configuration.

```python
from scitex_dev import TestConfig

config = TestConfig(
    module: str = "",          # test subdir under tests/ (e.g. "io")
    parallel: str = "auto",    # "-n" value for pytest-xdist; "0" = no parallel
    fast: bool = False,        # -m "not slow"
    coverage: bool = False,    # --cov --cov-report=term-missing
    exitfirst: bool = False,   # -x (stop on first failure)
    pattern: str = "",         # -k pattern
    changed: bool = False,     # --testmon (only changed tests)
    last_failed: bool = False, # --lf
    # HPC (None = resolve via SCITEX_DEV_TEST_* env or defaults)
    hpc_host: str | None = None,       # default: "spartan"
    hpc_cpus: int | None = None,       # default: 16
    hpc_partition: str | None = None,  # default: "sapphire"
    hpc_time: str | None = None,       # default: "00:20:00"
    hpc_mem: str | None = None,        # default: "128G"
    remote_base: str | None = None,    # default: "~/proj"
)
```

HPC defaults resolve via `PriorityConfig`:
1. Direct parameter on `TestConfig`
2. `SCITEX_DEV_TEST_*` environment variables
3. Built-in defaults above

## run_local

Run pytest locally via subprocess.

```python
from scitex_dev import run_local, TestConfig

exit_code = run_local(
    config: TestConfig,
) -> int   # pytest exit code
```

```python
# Run all tests
exit_code = run_local(TestConfig())

# Run specific module, fast, stop on failure
exit_code = run_local(TestConfig(
    module="io",
    fast=True,
    exitfirst=True,
))

# With coverage
exit_code = run_local(TestConfig(coverage=True))
```

## sync_to_hpc

Rsync project to HPC host (excludes .git, __pycache__, dist, build, etc.).

```python
from scitex_dev import sync_to_hpc, TestConfig

success = sync_to_hpc(config: TestConfig) -> bool
```

Auto-detects git root and project name. Target: `{hpc_host}:{remote_base}/{project}/`

## run_hpc_srun

Blocking srun on HPC — waits for completion.

```python
from scitex_dev import run_hpc_srun, TestConfig

exit_code = run_hpc_srun(config: TestConfig) -> int
```

Steps:
1. SSH to `hpc_host`
2. `srun --partition=... --cpus-per-task=... --time=... --mem=...`
3. `cd {remote_base}/{project} && pip install -e .[dev] -q --no-deps`
4. `python -m pytest {test_path} -n {cpus} --dist loadfile -x --tb=short`

## run_hpc_sbatch

Async sbatch — submits job and returns job ID immediately.

```python
from scitex_dev import run_hpc_sbatch, TestConfig

job_id = run_hpc_sbatch(config: TestConfig) -> str | None
# Returns numeric job ID string, or None on failure
# Persists job ID to .last-hpc-job in project root
```

Output written to `{remote_base}/{project}/.pytest-hpc-output/{job_id}.out`

## poll_hpc_job

Check sacct status of an HPC job.

```python
from scitex_dev import poll_hpc_job

result = poll_hpc_job(
    job_id: str | None = None,    # None = reads from .last-hpc-job
    hpc_host: str | None = None,  # None = SCITEX_DEV_TEST_HOST env or "spartan"
) -> dict
# {"state": "COMPLETED"|"FAILED"|"RUNNING"|"PENDING"|..., "output": str|None, "job_id": str}
```

```python
status = poll_hpc_job()
if status["state"] == "COMPLETED":
    print(status["output"])
```

## watch_hpc_job

Poll until job completes (blocks, polls every `interval` seconds).

```python
from scitex_dev import watch_hpc_job

result = watch_hpc_job(
    job_id: str | None = None,
    hpc_host: str | None = None,
    interval: int = 15,
) -> dict  # same as poll_hpc_job when terminal state reached
```

## fetch_hpc_result

Fetch full test output from HPC via scp.

```python
from scitex_dev import fetch_hpc_result

output = fetch_hpc_result(
    job_id: str | None = None,
    hpc_host: str | None = None,
) -> str | None  # stdout content or None if not found
```

## Typical HPC Workflow

```python
from scitex_dev import TestConfig, sync_to_hpc, run_hpc_sbatch, watch_hpc_job

config = TestConfig(module="io", fast=True, hpc_cpus=8)

# 1. Sync project to HPC
sync_to_hpc(config)

# 2. Submit job
job_id = run_hpc_sbatch(config)
print(f"Submitted: {job_id}")

# 3. Wait and get output
result = watch_hpc_job(job_id=job_id, interval=30)
print(result["state"], result["output"])
```

## CLI

```bash
# Local tests
scitex-dev test local
scitex-dev test local --module io --fast --exitfirst

# HPC tests
scitex-dev test hpc --module io
scitex-dev test hpc-poll <job-id>
scitex-dev test hpc-result <job-id>
```

## Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `SCITEX_DEV_TEST_HOST` | `spartan` | HPC SSH hostname |
| `SCITEX_DEV_TEST_CPUS` | `16` | CPUs per Slurm task |
| `SCITEX_DEV_TEST_PARTITION` | `sapphire` | Slurm partition |
| `SCITEX_DEV_TEST_TIME` | `00:20:00` | Slurm time limit |
| `SCITEX_DEV_TEST_MEM` | `128G` | Slurm memory |
| `SCITEX_DEV_TEST_REMOTE_BASE` | `~/proj` | Remote project directory |
