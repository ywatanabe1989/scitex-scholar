## Quick Start

```bash
# Setup a tunnel (port 22 exposed via bastion)
scitex-tunnel setup --port 22 --bastion jump.example.com --secret-key ~/.ssh/id_rsa

# Check status
scitex-tunnel status

# Check specific port
scitex-tunnel status --port 22

# Remove tunnel
scitex-tunnel remove --port 22
```

```python
from scitex_tunnel import setup, status, remove

# Create tunnel
result = setup(port=22, bastion_server="jump.example.com", secret_key_path="~/.ssh/id_rsa")
# Returns: {"success": True, "stdout": "...", "stderr": "..."}

# Check all tunnels
result = status()

# Check specific port
result = status(port=22)

# Remove tunnel
result = remove(port=22)

# Check availability
from scitex_tunnel import AVAILABLE, get_version
print(AVAILABLE)       # True/False
print(get_version())   # "0.x.y"
```
