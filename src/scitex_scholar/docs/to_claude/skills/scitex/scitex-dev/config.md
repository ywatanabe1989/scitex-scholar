---
topic: config
package: scitex-dev
description: >
  Configuration management for scitex developer utilities. DevConfig holds
  packages, SSH hosts, GitHub remotes, and PyPI accounts. Config loaded from
  ~/.scitex/dev_config.yaml with SCITEX_DEV_* environment variable overrides.
---

# Configuration

## Config File Location

Default: `~/.scitex/dev_config.yaml`

Override via environment variable:
```bash
export SCITEX_DEV_CONFIG=/path/to/my_config.yaml
```

## DevConfig

Full developer configuration dataclass.

```python
from scitex_dev import DevConfig

DevConfig(
    packages: list[PackageConfig] = [],
    hosts: list[HostConfig] = [],
    github_remotes: list[GitHubRemote] = [],
    pypi_accounts: list[PyPIAccount] = [],
    branches: list[str] = ["main", "develop"],
)
```

If no packages in config file, all `ECOSYSTEM` packages are used as defaults.

## PackageConfig

```python
from scitex_dev import PackageConfig

PackageConfig(
    name: str,           # e.g. "scitex-io"
    local_path: str,     # e.g. "~/proj/scitex-io"
    pypi_name: str,      # e.g. "scitex-io"
    github_repo: str | None = None,   # e.g. "ywatanabe1989/scitex-io"
    import_name: str | None = None,   # e.g. "scitex_io"
)
```

## HostConfig

SSH host configuration for remote sync operations.

```python
from scitex_dev import HostConfig

HostConfig(
    name: str,           # alias (e.g. "spartan")
    hostname: str,       # SSH hostname or IP
    user: str,           # SSH username
    role: str = "dev",   # "dev" | "staging" | "prod" | "hpc"
    enabled: bool = True,
    ssh_key: str | None = None,   # path to private key
    port: int = 22,
    python_bin: str = "python3",
    pip_bin: str = "pip",
    remote_base: str = "~/proj",
    packages: list[str] = [],  # package names to manage; [] = all configured
)
```

## GitHubRemote

```python
from scitex_dev import GitHubRemote

GitHubRemote(
    name: str,    # e.g. "ywatanabe1989"
    org: str,     # GitHub organization
    enabled: bool = True,
)
```

## PyPIAccount

```python
from scitex_dev import PyPIAccount

PyPIAccount(
    name: str,
    enabled: bool = True,
)
```

## load_config

Load config from YAML with environment variable overrides.

```python
from scitex_dev import load_config

config = load_config(
    config_path: str | Path | None = None,  # None = env var or default path
) -> DevConfig
```

```python
config = load_config()
for host in config.hosts:
    print(host.name, host.hostname, host.enabled)
```

## get_config_path

Get the config file path (may not exist).

```python
from scitex_dev import get_config_path

path = get_config_path()   # Path object
print(path)  # /home/user/.scitex/dev_config.yaml
```

## create_default_config

Create `~/.scitex/dev_config.yaml` with example entries if it doesn't exist.

```python
from scitex_dev import create_default_config

path = create_default_config()  # idempotent — no-op if already exists
print(f"Config at: {path}")
```

## config_to_dict

Serialize DevConfig to plain dict for JSON responses.

```python
from scitex_dev import config_to_dict, load_config, get_config_path

cfg = load_config()
d = config_to_dict(cfg, config_path=get_config_path())
# {"packages": [...], "hosts": [...], "github_remotes": [...], "branches": [...]}
```

## get_enabled_hosts / get_enabled_remotes

```python
from scitex_dev import get_enabled_hosts, get_enabled_remotes

hosts = get_enabled_hosts()      # list[HostConfig] where enabled=True
remotes = get_enabled_remotes()  # list[GitHubRemote] where enabled=True
```

## Example Config File

```yaml
# ~/.scitex/dev_config.yaml

packages:
  - name: scitex-io
    local_path: ~/proj/scitex-io
    pypi_name: scitex-io
    github_repo: ywatanabe1989/scitex-io
    import_name: scitex_io
  - name: scitex-stats
    local_path: ~/proj/scitex-stats
    pypi_name: scitex-stats
    github_repo: ywatanabe1989/scitex-stats
    import_name: scitex_stats

hosts:
  - name: myserver
    hostname: myserver.example.com
    user: myuser
    role: dev
    enabled: true
    remote_base: ~/proj
  - name: hpc
    hostname: hpc.cluster.edu
    user: myuser
    role: hpc
    enabled: true
    partition: gpu

github_remotes:
  - name: ywatanabe1989
    org: ywatanabe1989
    enabled: true

pypi_accounts:
  - name: ywatanabe1989
    enabled: true

branches:
  - main
  - develop
```

## Environment Variable Overrides

| Variable | Purpose |
|---|---|
| `SCITEX_DEV_CONFIG` | Config file path |
| `SCITEX_DEV_HOSTS` | Comma-separated enabled host names |
| `SCITEX_DEV_GITHUB_REMOTES` | Comma-separated enabled remote names |

```bash
# Enable only specific hosts
export SCITEX_DEV_HOSTS=myserver,hpc

# Use alternate config
export SCITEX_DEV_CONFIG=~/.scitex/work_config.yaml
```

## CLI

```bash
scitex-dev config
scitex-dev config --json
```
