---
description: End-to-end guide for building a SciTeX app — scaffold, develop, validate, dev-install, test, and submit. Includes actual CLI commands with expected outputs, complete manifest schema, and file structure.
---

# App Lifecycle — End-to-End Guide

Full workflow for building and shipping a SciTeX workspace app from scratch.

```
scaffold → develop → validate → dev-install → test in browser → submit
```

Prerequisites:
- `pip install scitex-app[cli]` — installs the `scitex-app` CLI
- A running SciTeX Cloud instance (for dev-install) at `http://127.0.0.1:8000`
- A JWT token from your profile settings on the server

**Detailed sub-guides:**
- [app-develop](app-develop.md) — views.py, urls.py, templates, CSS, React patterns
- [app-validate-install](app-validate-install.md) — validate, dev-install, test, troubleshoot

---

## Step 1: Scaffold

```bash
# Scaffold into a new directory (HTML frontend, default)
scitex-app app init . --name my_awesome_app --label "My Awesome App" \
    --icon "fas fa-flask" --description "Does something useful."

# React+Vite+Zustand frontend
scitex-app app init . --name my_awesome_app --frontend react

# Overwrite existing files
scitex-app app init . --name my_awesome_app --overwrite
```

**Expected output:**
```
Scaffolding app: my_awesome_app in /path/to/my_awesome_app
  + __init__.py
  + apps.py
  + views.py
  + urls.py
  + tests.py
  + skill.py
  + manifest.json
  + templates/my_awesome_app/index.html
  + templates/my_awesome_app/index_partial.html
  + static/my_awesome_app/css/my_awesome_app.css
  + .agents/agents.json
  + AGENTS.md
  + docs/PLATFORM.md
  + README.md
  + LICENSE
  + .gitignore
  + pyproject.toml
  + _cli.py

Done! Created 18 files.
```

App name **must** end with `_app` or `-app`. The CLI auto-appends the suffix if missing.

React frontend adds: `package.json`, `vite.config.js`, `src/bridge/bridge-init.ts`, `src/components/`, `src/store/`.

### Python API

```python
from scitex_app.appmaker import init_app
from pathlib import Path

created = init_app(
    target_dir=Path("./my_awesome_app"),
    name="my_awesome_app",       # must end with _app or -app
    label="My Awesome App",
    icon="fas fa-flask",
    description="Does something useful.",
    frontend_type="html",        # or "react"
    license_id="AGPL-3.0",
    overwrite=False,
)
print(f"Created {len(created)} files")
```

### Resulting file structure

```
my_awesome_app/
    __init__.py
    apps.py                                  # Django AppConfig
    views.py                                 # HTTP views
    urls.py                                  # URL routing
    tests.py
    skill.py
    manifest.json                            # App metadata (required)
    _cli.py                                  # Standalone CLI entry point
    templates/
        my_awesome_app/
            index.html                       # Full-page view (standalone)
            index_partial.html               # AJAX partial (workspace tab)
    static/
        my_awesome_app/
            css/
                my_awesome_app.css
    .agents/agents.json
    AGENTS.md
    docs/PLATFORM.md
    README.md
    LICENSE
    .gitignore
    pyproject.toml
```

---

## Step 2: Develop

Edit `views.py`, `urls.py`, `templates/`, `static/`, and `manifest.json`.
See [app-develop.md](app-develop.md) for full patterns.

**Key files:**

| File | Purpose |
|------|---------|
| `views.py` | Django views + context builder |
| `urls.py` | URL routing |
| `templates/<name>/index_partial.html` | App HTML (AJAX-loaded into workspace pane) |
| `static/<name>/css/<name>.css` | Scoped CSS — use `.my-awesome-app-*` prefixes |
| `manifest.json` | App metadata, privileges, frontend config |

---

## manifest.json — Complete Schema

```json
{
  "$schema": "scitex-app-manifest",
  "$schema_version": "2.0.0",

  "name": "my_awesome_app",
  "slug": "my-awesome-app",
  "label": "My Awesome App",
  "app_name": "my_awesome_app",
  "version": "0.1.0",
  "icon": "fas fa-flask",
  "subtitle": "Short subtitle (80 chars max)",
  "about": "Longer about text (200 chars max)",
  "description": "Full description shown in app catalog.",
  "author": "Your Name",
  "license": "AGPL-3.0",

  "keyboard_shortcut": "",
  "order": 50,
  "accent_color": "",
  "body_class": "my-awesome-app-page",

  "partial_template": "my_awesome_app/index_partial.html",
  "context_builder": "",
  "ai_hint": "Short description injected into LLM context.",

  "capabilities": [],
  "allowed_extensions": [],
  "hidden_patterns": ["__pycache__", "node_modules", ".git", ".venv"],

  "privileges": [
    {"type": "filesystem", "scope": "project"},
    {"type": "network",    "scope": "none"},
    {"type": "api",        "scope": "scitex"}
  ],

  "wip": true,
  "standalone": true,
  "standalone_command": "my-awesome-app gui",
  "standalone_port": 8050,
  "frontend_type": "html",

  "dependencies": {
    "python": [],
    "system": [],
    "node": [],
    "r": [],
    "other": []
  },
  "container": null
}
```

### Required fields

`name`, `slug`, `label`, `version`, `icon` — missing any causes a validation error.

### Privilege types and valid scopes

| `type` | Valid `scope` values |
|--------|---------------------|
| `filesystem` | `project`, `readonly`, `none` |
| `network` | `none`, `allowlist` |
| `api` | `scitex`, `llm`, `none` |

---

## Steps 3–5: Validate, Dev-Install, Test

See [app-validate-install.md](app-validate-install.md) for full detail.

```bash
# 3. Validate
scitex-app app validate .

# 4. Dev-install
export SCITEX_API_TOKEN="your-jwt-token"
scitex-app app dev-install . --server http://127.0.0.1:8000

# 5. Open http://127.0.0.1:8000/ and check your tab appears
```

---

## Step 6: Submit

```bash
export SCITEX_API_TOKEN="your-jwt-token"
scitex-app app submit .
```

**Expected output:**
```
Submitting app from: /path/to/my_awesome_app
Submission successful!
  PR: https://gitea.scitex.ai/scitex-apps/registry/pulls/42
```

Submission opens a PR to the scitex-apps registry. After approval, the app becomes
visible in the public catalog and `load_approved_apps()` registers it globally on
server startup.

**Before submitting:**
- Set `"wip": false` in `manifest.json`
- Ensure all validation checks pass (`scitex-app app validate .`)
- Write a clear `README.md` and `description` in `manifest.json`
- Confirm `version` is a proper release version (e.g. `"1.0.0"`)

---

## Reference Implementation

The `figrecipe` app is the canonical working example:

```
~/proj/figrecipe/src/figrecipe/
    manifest.json
    views.py
    urls.py
    templates/figrecipe/index_partial.html
    static/figrecipe/css/figrecipe.css
    _django/frontend/          # React frontend (bridge + Zustand store)
```

# EOF
