## CLI Commands

```bash
# Core
scitex-tunnel setup --port <port> --bastion <host> --secret-key <path>
scitex-tunnel status [--port <port>]
scitex-tunnel remove --port <port>

# MCP server
scitex-tunnel mcp start [--transport <str>] [--host <host>] [--port <port>]
scitex-tunnel mcp doctor
scitex-tunnel mcp list-tools
scitex-tunnel mcp installation

# Introspection
scitex-tunnel list-python-apis [-v]
```
