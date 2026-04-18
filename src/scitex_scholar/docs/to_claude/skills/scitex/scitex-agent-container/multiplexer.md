---
name: agent-container-multiplexer
description: tmux vs screen multiplexer support, capture-pane, send-keys.
---

# Multiplexer

Set in YAML: `spec.multiplexer: tmux` (default) or `screen`

## Comparison

| Feature | tmux | screen |
|---------|------|--------|
| `capture-pane` | Works on macOS | Fails on macOS (hardcopy) |
| Auto-accept | Reliable | Unreliable on macOS |
| Socket dir | Consistent | Varies (SSH vs local) |
| Default | Yes (since v0.7) | Legacy |

## Usage

```python
from scitex_agent_container.runtimes.multiplexer import get_multiplexer

mux = get_multiplexer(config)          # TmuxManager or ScreenManager
mux.exists("session-name")             # Check session exists
mux.capture_content("session-name")    # Read pane content
mux.send_keys("session-name", "2", "Enter")  # Send keystrokes
mux.start(name, command, workdir)      # Launch session
mux.stop("session-name")              # Kill session
mux.attach("session-name")            # Interactive attach
```

## Detach shortcuts

- tmux: `Ctrl-B D`
- screen: `Ctrl-A D`
