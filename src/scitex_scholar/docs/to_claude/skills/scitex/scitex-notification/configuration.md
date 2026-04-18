---
description: scitex-notification configuration — YAML config file, UIConfig singleton, environment variables, and level-based backend routing.
---

# Configuration

## Priority Resolution

Configuration is resolved in this order (later overrides earlier):

1. Built-in defaults (hardcoded in `DEFAULT_CONFIG`)
2. YAML config file (path from `SCITEX_NOTIFICATION_CONFIG` env var)
3. Environment variable overrides (`SCITEX_NOTIFICATION_*`)
4. Direct arguments passed to `alert()` / `UIConfig()`

## YAML Config File

Point to a YAML file with `SCITEX_NOTIFICATION_CONFIG=/path/to/config.yaml`.

```yaml
notification:
  default_backend: audio
  backend_priority:
    - audio
    - emacs
    - desktop
    - matplotlib
    - playwright
    - email
    - webhook
  level_backends:
    info:     [audio]
    warning:  [audio, emacs]
    error:    [audio, emacs, desktop, email]
    critical: [audio, emacs, desktop, matplotlib, email]
  timeouts:
    matplotlib: 5.0
    playwright: 5.0
```

Both `notification:` and `ui:` are accepted as top-level keys (backward compat).

## Environment Variables

Primary prefix `SCITEX_NOTIFICATION_*` is checked first. Fallback prefixes `SCITEX_NOTIFY_*` and `SCITEX_UI_*` are checked as backward-compatible alternatives.

| Variable | Purpose | Default |
|----------|---------|---------|
| `SCITEX_NOTIFICATION_CONFIG` | Path to YAML config file | — |
| `SCITEX_NOTIFICATION_ENV_SRC` | Path to `.env`/`.src` file or directory to auto-load at import | — |
| `SCITEX_NOTIFICATION_DEFAULT_BACKEND` | Default backend when none specified | `audio` |
| `SCITEX_NOTIFICATION_BACKEND_PRIORITY` | Comma-separated fallback order | `audio,emacs,desktop,...` |
| `SCITEX_NOTIFICATION_INFO_BACKENDS` | Backends for `level="info"` | `audio` |
| `SCITEX_NOTIFICATION_WARNING_BACKENDS` | Backends for `level="warning"` | `audio,emacs` |
| `SCITEX_NOTIFICATION_ERROR_BACKENDS` | Backends for `level="error"` | `audio,emacs,desktop,email` |
| `SCITEX_NOTIFICATION_CRITICAL_BACKENDS` | Backends for `level="critical"` | `audio,emacs,desktop,matplotlib,email` |
| `SCITEX_NOTIFICATION_PHONE_CALL_N_REPEAT` | Default phone call repeat count | `1` |
| `SCITEX_NOTIFICATION_TIMEOUT_MATPLOTLIB` | Popup timeout (seconds) | `5.0` |
| `SCITEX_NOTIFICATION_TIMEOUT_PLAYWRIGHT` | Browser popup timeout (seconds) | `5.0` |

## Env File Auto-Loading

Set `SCITEX_NOTIFICATION_ENV_SRC` to a `.env`/`.src` file or a directory containing `*.src` files. Variables are loaded at `import scitex_notification` time before any backend is used.

```bash
export SCITEX_NOTIFICATION_ENV_SRC=~/.config/scitex/notification.src
```

File format (bash-compatible):
```bash
export SCITEX_NOTIFICATION_TWILIO_SID=ACxxxxxxxxxxxxxxxx
export SCITEX_NOTIFICATION_TWILIO_TOKEN=your_token
SCITEX_NOTIFICATION_EMAIL_FROM=agent@example.com
SCITEX_NOTIFICATION_EMAIL_PASSWORD="app_password_here"
```

Variables already set in `os.environ` are **not** overwritten by the env file.

## UIConfig Singleton

```python
from scitex_notification._backends._config import get_config, UIConfig

cfg = get_config()                      # returns cached singleton
cfg = get_config("/path/to/config.yaml") # creates new instance with custom path

cfg.default_backend                     # str: "audio"
cfg.backend_priority                    # list[str]: ["audio", "emacs", ...]
cfg.get_available_backend_priority()    # filters by package availability
cfg.get_first_available_backend()       # str: first in priority that is available
cfg.get_backends_for_level(NotifyLevel.ERROR)           # list[str]
cfg.get_available_backends_for_level(NotifyLevel.ERROR) # filtered list
cfg.get_timeout("matplotlib")           # float: 5.0
cfg.reload()                            # re-reads files and env vars
UIConfig.reset()                        # clears singleton (useful for tests)
```

## Default Config (Built-in)

```python
DEFAULT_CONFIG = {
    "default_backend": "audio",
    "backend_priority": [
        "audio", "emacs", "desktop",
        "matplotlib", "playwright", "email", "webhook",
    ],
    "level_backends": {
        "info":     ["audio"],
        "warning":  ["audio", "emacs"],
        "error":    ["audio", "emacs", "desktop", "email"],
        "critical": ["audio", "emacs", "desktop", "matplotlib", "email"],
    },
    "timeouts": {
        "matplotlib": 5.0,
        "playwright": 5.0,
    },
}
```

## is_backend_available()

```python
from scitex_notification._backends._config import is_backend_available

is_backend_available("matplotlib")  # True if matplotlib is importable
is_backend_available("playwright")  # True if playwright is importable
is_backend_available("audio")       # True (no required package)
is_backend_available("email")       # True (uses stdlib smtplib)
```

Note: `is_backend_available()` only checks Python package presence. `backend.is_available()` additionally checks runtime conditions (env vars, services running).
