---
skill: scitex-container/python-api
description: Full Python API reference for scitex-container with signatures
---

# Python API Reference

```python
import scitex_container.apptainer as apptainer
import scitex_container.docker as docker
import scitex_container.host as host
from scitex_container import env_snapshot
```

---

## apptainer module

### build

```python
apptainer.build(
    def_name: str = "scitex-cloud-shared-v0.1.0",
    output_dir: str | Path | None = None,
    force: bool = False,
    sandbox: bool = False,
) -> Path
```

Build an Apptainer SIF or sandbox directory from a `.def` file.
Auto-detects containers dir. Auto-freezes lock files after SIF builds.
Raises `FileNotFoundError` if `.def` not found; `RuntimeError` on build failure.

### freeze

```python
apptainer.freeze(
    sif_path: str | Path,
    output_dir: str | Path | None = None,
) -> dict[str, Path]
```

Extract pinned versions from a built SIF.
Returns `{"pip": Path, "dpkg": Path, "node": Path}` for available lock files.

### verify

```python
apptainer.verify(
    sif_path: str | Path,
    def_path: str | Path | None = None,
    lock_dir: str | Path | None = None,
) -> dict
```

Verify SIF integrity: SHA256, `.def` origin hash, pip/dpkg lock consistency.
Returns `{"sif": {...}, "def_origin": {...}, "pip_lock": {...}, "dpkg_lock": {...}, "overall": "pass|fail"}`.

### status

```python
apptainer.status(
    containers_dir: str | Path | None = None,
) -> list[dict]
```

List containers and their status (needs_rebuild flag).
Returns list of dicts with keys: `name`, `def_path`, `sif_path`, `sif_size`, `sif_date`, `hash_current`, `hash_stored`, `needs_rebuild`.

---

### SIF versioning

```python
apptainer.list_versions(containers_dir: Path) -> list[dict]
# Each dict: {"version", "path", "size", "date", "active"}

apptainer.get_active_version(containers_dir: Path) -> str | None
# Returns version string from current.sif symlink, or None

apptainer.switch_version(
    version: str,
    containers_dir: Path,
    use_sudo: bool = False,
) -> None

apptainer.rollback(
    containers_dir: Path,
    use_sudo: bool = False,
) -> str
# Returns the version string that is now active

apptainer.deploy(
    source_dir: Path,
    target_dir: Path = Path("/opt/scitex/singularity"),
) -> None
# Copy active SIF + base SIF to target_dir, recreate current.sif symlink

apptainer.cleanup(
    containers_dir: Path,
    keep: int = 3,
) -> list[Path]
# Remove old scitex-v*.sif files; never removes active version or base images
```

---

### Sandbox management

```python
apptainer.sandbox_create(
    source: str | Path,
    containers_dir: str | Path | None = None,
    *,
    output_dir: str | Path | None = None,
) -> Path
# Creates sandbox-YYYYMMDD_HHMMSS/ and updates current-sandbox symlink

apptainer.is_sandbox(path: str | Path) -> bool
# True if path does NOT end with .sif

apptainer.sandbox_maintain(
    sandbox_dir: str | Path,
    command: list[str],
) -> int
# Run command inside sandbox with --writable --fakeroot; returns exit code

apptainer.sandbox_update(
    sandbox_dir: str | Path,
    *,
    proj_root: str | Path | None = None,  # default: ~/proj
    packages: tuple[str, ...] | None = None,  # default: all ecosystem packages
    install_deps: bool = False,
) -> dict[str, str]
# Returns {"pkg_name": "ok|failed|skipped", ...}
# Default packages: scitex, figrecipe, scitex-writer, scitex-dataset,
#                   crossref-local, openalex-local, socialia, scitex-linter, scitex-container

apptainer.sandbox_to_sif(
    sandbox_dir: str | Path,
    output_sif: str | Path,
) -> Path

apptainer.sandbox_configure_ps1(
    sandbox_dir: str | Path,
    default_ps1: str = r"\W $ ",
) -> None
# Writes PS1 to .singularity.d/env/90-environment.sh
# Override at runtime: apptainer exec --env SCITEX_CLOUD_APPTAINER_PS1='(mylab) \W $ '
```

---

### Sandbox versioning

```python
apptainer.list_sandboxes(containers_dir: Path) -> list[dict]
# Each dict: {"version": "YYYYMMDD_HHMMSS", "path", "date", "active"}

apptainer.get_active_sandbox(containers_dir: Path) -> str | None
# Returns timestamp from current-sandbox symlink, or None

apptainer.switch_sandbox(
    version: str,          # timestamp string e.g. "20260225_173700"
    containers_dir: Path,
    use_sudo: bool = False,
) -> None

apptainer.rollback_sandbox(
    containers_dir: Path,
    use_sudo: bool = False,
) -> str
# Returns timestamp of now-active sandbox

apptainer.cleanup_sandboxes(
    containers_dir: Path,
    keep: int = 5,
) -> list[Path]

apptainer.cleanup_sifs(
    containers_dir: Path,
    keep: int = 0,
) -> list[Path]
# Removes *.sif, *.sif.old, *.sif.backup.*, and current.sif symlink
```

---

### Command builders (SLURM / apptainer exec)

```python
apptainer.build_exec_args(
    container_path: str,
    username: str,
    host_user_dir: Path,
    host_project_dir: Path,
    project_slug: str,
    dev_repos: list[dict] | None = None,
    host_mounts: list[dict] | None = None,
    texlive_prefix: str = "",
) -> list[str]
# Returns ["apptainer", "exec", "--containall", "--cleanenv", "--writable-tmpfs", ...]
# dev_repos dicts: {"name": str, "host_path": str}
# host_mounts dicts: {"host_path": str, "container_path": str, "mode": str}

apptainer.build_srun_command(
    container_path: str,
    username: str,
    host_user_dir: Path,
    host_project_dir: Path,
    project_slug: str,
    dev_repos: list[dict] | None = None,
    host_mounts: list[dict] | None = None,
    texlive_prefix: str = "",
    slurm_partition: str = "compute",
    slurm_time_limit: str = "8:00:00",
    slurm_cpus: int = 4,
    slurm_memory_gb: int = 16,
) -> list[str]
# Returns ["srun", "--pty", "--chdir=/tmp", ...]

apptainer.build_sbatch_command(
    instance_name: str,
    script_path: str,
    slurm_partition: str = "compute",
    slurm_time_limit: str = "8:00:00",
    slurm_cpus: int = 4,
    slurm_memory_gb: int = 16,
    username: str = "",
    project_slug: str = "",
) -> list[str]

apptainer.build_instance_start_script(
    container_path: str,
    username: str,
    host_user_dir: Path,
    host_project_dir: Path,
    project_slug: str,
    instance_name: str,
    dev_repos: list[dict] | None = None,
    host_mounts: list[dict] | None = None,
    texlive_prefix: str = "",
) -> str
# Returns bash script content for sbatch submission

apptainer.build_shell_in_allocation_command(
    job_id: str,
    instance_name: str,
    username: str = "",
) -> list[str]
# Returns ["srun", "--pty", "--overlap", "--jobid=...", "apptainer", "exec", ...]

apptainer.build_dev_pythonpath(dev_repos: list[dict]) -> str
# Returns colon-separated PYTHONPATH e.g. "/opt/dev/scitex-python/src:..."
# Each repo dict must have "name" key

apptainer.build_host_mount_binds(
    host_mounts: list[dict] | None = None,
    texlive_prefix: str = "",
) -> list[str]
# Returns flat ["--bind", "spec", "--bind", "spec", ...] list
```

---

### Utilities

```python
apptainer.detect_container_cmd() -> str
# Returns "apptainer" or "singularity"; raises FileNotFoundError if neither found

apptainer.find_containers_dir() -> Path
# Auto-detects containers directory by walking up from cwd
```

---

## docker module

```python
docker.rebuild(
    env: str = "dev",
    project_dir: str | Path | None = None,
) -> int
# Runs: docker compose -f <compose_file> build --no-cache
# Returns exit code (0 = success)

docker.restart(
    env: str = "dev",
    project_dir: str | Path | None = None,
) -> int
# Runs: docker compose down then docker compose up -d
# Returns exit code of up command

docker.status(
    env: str = "dev",
    project_dir: str | Path | None = None,
) -> dict
# Returns {"compose_file": str, "containers": [{"name", "state", "image", "raw"}], "returncode": int}

docker.get_dev_mounts(repos: list[dict]) -> list[str]
# repos: [{"host": str, "container": str, "mode": "ro"|"rw"}]
# Returns ["../../repo:/repo:ro", ...] for docker-compose volumes
```

---

## host module

```python
host.check_packages() -> dict
# Returns {
#   "texlive": {"installed": bool, "version": str, "binaries": [str, ...]},
#   "imagemagick": {"installed": bool, "version": str, "binaries": [str, ...]},
# }

host.install_packages(
    texlive: bool = False,
    imagemagick: bool = False,
    all: bool = False,
    check_only: bool = False,
) -> dict
# Calls scripts/install-host-packages.sh via sudo
# Returns {"texlive": {"status": "installed|failed|skipped", "returncode": int}, ...}

host.get_texlive_binds(prefix: str = "/usr") -> list[dict]
# Returns [{"host": str, "container": str, "mode": "ro"}, ...] for TeXLive mounts

host.get_mount_config(
    texlive_prefix: str = "",
    host_mounts_raw: str = "",
) -> dict
# Returns {"bind_args": ["--bind", spec, ...], "path_additions": [str], "mounts": [dict]}
# host_mounts_raw: comma/newline-separated "host:container[:mode]" specs

# Constants:
host.TEXLIVE_BINARIES  # list[str]: pdflatex, bibtex, latexmk, latexdiff, ...
host.TEXLIVE_DIRS      # list[str]: share/texlive, share/texmf-dist
```

---

## Top-level

```python
from scitex_container import env_snapshot

env_snapshot(
    containers_dir: str | Path | None = None,
    dev_repos: list[str | Path] | None = None,
) -> dict
# Capture JSON-serializable environment snapshot.
# Returns {
#   "schema_version": "1.0",
#   "timestamp": "<ISO8601>",
#   "container": {"version": str, "sif_path": str, "sif_sha256": str, "def_hash": str},
#   "host": {"texlive": {...}, "imagemagick": {...}},
#   "dev_repos": [{"name", "path", "commit", "branch", "dirty"}, ...],
#   "lock_files": {"pip": str, "dpkg": str},
# }
# Never raises; gracefully omits unavailable fields.
```
