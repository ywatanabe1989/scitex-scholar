## Python API

| Function | Signature | Purpose |
|----------|-----------|---------|
| `setup()` | `setup(port, bastion_server=None, secret_key_path=None) -> dict` | Create persistent SSH tunnel |
| `status()` | `status(port=None) -> dict` | Check tunnel status (all or specific port) |
| `remove()` | `remove(port) -> dict` | Remove tunnel by port |
| `get_version()` | `get_version() -> str` | Get package version |
| `AVAILABLE` | `bool` | Whether tunnel dependencies are available |
