---
description: How a SciTeX app registers with the workspace sidebar — manifest.json to ModuleConfig to sidebar tab. Covers dev-install path, published app path, ModuleConfig fields, frontend integration points, and troubleshooting.
---

# App Registration — How Apps Appear in the Workspace

When a SciTeX app is installed or published, it appears as a tab in the workspace
sidebar. This document traces the full registration flow from `manifest.json` through
`ModuleConfig` to the rendered tab.

---

## Registration Flow

```
manifest.json → ModuleConfig dataclass → register_module() → workspace sidebar
```

Two paths exist depending on development stage:

---

## Path 1: Dev Install (during development)

```bash
export SCITEX_API_TOKEN="your-jwt-token"
scitex-app app dev-install . --server http://127.0.0.1:8000
```

1. Local validation runs (`scitex-app app validate .`).
2. `POST /apps/store/api/dev/install/` is called with `{"owner": "alice", "repo": "my-awesome-app"}`.
3. A `DevInstallation` database record is created:
   - `source_owner` = your username
   - `source_repo` = repo slug from manifest `slug` field
   - `module_name` = `dev__alice__my-awesome-app` (auto-generated)
4. On each workspace page load, `build_module_config(dev_install)` synthesizes a `ModuleConfig` for that user.
5. The app tab appears **only for you** — no global registry pollution.

Templates are served live from `data/users/<owner>/proj/<repo>/templates/` on the
server filesystem. Edits to `index_partial.html` take effect on the next page load
without reinstall.

### Module name convention

Dev modules always follow: `dev__<owner>__<repo>`

Examples:
- Owner `alice`, repo `my-awesome-app` → `dev__alice__my-awesome-app`
- Owner `bob`, repo `data-viz-app` → `dev__bob__data-viz-app`

The `repo` component comes from the manifest `slug` field (hyphen-separated).

---

## Path 2: Published App (after submission and approval)

```bash
scitex-app app submit .
```

1. A PR is opened on the scitex-apps registry at `gitea.scitex.ai/scitex-apps/registry`.
2. After approval:
   - An `AppsModule` database record is created with `visibility="public"`.
   - `load_approved_apps()` runs at Django startup (or immediately after approval).
   - For each public module, `load_single_app()` reads the manifest and calls `register_module(config)`.
   - The module is added to the global registry.
3. The context processor includes it in `workspace_modules` for all users.
4. Users install it from the app catalog (`default_enabled=False` until they do).

---

## ModuleConfig — What Gets Registered

```python
from apps.infra.workspace_app.registry import ModuleConfig

ModuleConfig(
    # Identity
    name="my-awesome-app",      # URL slug → /apps/my-awesome-app/
    label="My Awesome App",     # Sidebar display label
    app_name="apps_app",        # Always "apps_app" for external apps

    # Icon
    icon_fa="fas fa-flask",     # FontAwesome class from manifest "icon"

    # Template
    partial_template="apps_app/user_apps/my-awesome-app_partial.html",

    # Context
    context_builder="apps.workspace.apps_app.services.app_context.build_user_app_context",

    # Ordering
    order=90,                   # Built-ins use 20–50; external apps use 90+

    # Visibility
    default_enabled=False,      # User must add it from catalog

    # Dev flags (dev-install path only)
    is_dev=True,
    status="wip",

    # LLM / accessibility
    ai_hint="Short description injected into LLM context.",

    # Legal
    license="AGPL-3.0",
)
```

### manifest.json fields → ModuleConfig fields

| `manifest.json` field | `ModuleConfig` field | Notes |
|----------------------|----------------------|-------|
| `slug` | `name` | URL path segment (hyphen-separated) |
| `label` | `label` | Sidebar display name |
| `icon` | `icon_fa` | FontAwesome class |
| `version` | stored in `AppsModule` | Semantic version string |
| `privileges` | `privileges` | Declared capabilities |
| `ai_hint` | `ai_hint` | LLM context injection |
| `order` | `order` | Tab position (default 90) |
| `license` | `license` | License identifier |

### Fields set automatically (not from manifest)

| Field | Value | Why |
|-------|-------|-----|
| `app_name` | `"apps_app"` | All external apps go through apps infrastructure |
| `partial_template` | `"apps_app/user_apps/{name}_partial.html"` | Standard location |
| `context_builder` | `"...build_user_app_context"` | Standard external app context |
| `order` | `90` | External apps appear after built-ins (20–50) |
| `default_enabled` | `False` | Requires user to install from catalog |

---

## How the Sidebar Renders the Tab

The workspace context processor (`context_processors.py`) calls `get_all_modules()`
which returns all registered `ModuleConfig` objects. The sidebar template iterates them:

```html
{% for mod in workspace_modules %}
    <a href="{{ mod.get_url }}" class="sidebar-item" data-module="{{ mod.name }}">
        <i class="{{ mod.icon_fa }}"></i>
        <span>{{ mod.label }}</span>
    </a>
{% endfor %}
```

`mod.get_url()` returns `/apps/{name}/` unless `url` is overridden in the config.

Tab order in the sidebar matches the `order` field value — lower numbers appear first.
Built-in SciTeX apps use 20–50; your external apps should use 90+ to appear after them.

---

## How the Partial Gets Loaded

When the user clicks the tab, the workspace AJAX machinery calls:

```
GET /apps/{name}/partial/
```

This calls `build_user_app_context(request)` and renders the template at
`apps_app/user_apps/{name}_partial.html`.

For dev apps, the template is read live from:
```
data/users/<owner>/proj/<repo>/templates/
```

The partial template is your `templates/my_awesome_app/index_partial.html`.

### AJAX load sequence

1. User clicks sidebar tab
2. Workspace JS: `fetch('/apps/my-awesome-app/partial/')`
3. Server resolves `ModuleConfig` for `"my-awesome-app"`
4. For dev apps: reads template from user's source directory
5. Calls `build_user_app_context(request)` to get context dict
6. Renders template with context
7. Returns HTML fragment
8. Workspace JS injects fragment into `#ws-module-pane`

---

## pyproject.toml Entry Point

For the app to be discoverable as a local extension (standalone mode + testing):

```toml
[project.entry-points."scitex_modules"]
my_awesome_app = "my_awesome_app:get_module_config"
```

The `get_module_config()` function returns a `ModuleConfig` object and is defined
in the scaffolded `__init__.py`.

In deployed mode, the server uses the `AppsModule` database record + filesystem path
directly — the entry point is used for local discovery only.

---

## Key Source Files (server-side)

| File | Role |
|------|------|
| `scitex-cloud/apps/infra/workspace_app/registry.py` | `ModuleConfig` dataclass, `register_module()`, `get_all_modules()` |
| `scitex-cloud/apps/workspace/apps_app/services/app_loader.py` | `load_approved_apps()` — published app registration at startup |
| `scitex-cloud/apps/workspace/apps_app/services/dev_app_loader.py` | `build_module_config()` — per-request dev app config synthesis |
| `scitex-cloud/apps/infra/workspace_app/context_processors.py` | Injects `workspace_modules` into template context |

---

## Troubleshooting Registration

### App tab not visible after dev-install

The module was registered but may not show for your user:
- Hard-refresh (`Ctrl+Shift+R`) — context processor output is cached in session
- Log out and log back in to clear the session
- Verify the dev-install API returned the module name `dev__<owner>__<app>`
- Confirm you are logged in as the same user whose token was used for dev-install

### App tab shows but partial fails to load (500 error)

The template loaded but `build_user_app_context` raised an exception:
- Check server logs for the Python traceback
- Common cause: `import` error in `views.py` — a missing dependency
- Test your view in isolation: `python -c "from my_awesome_app.views import partial_view"`

### App tab shows but partial returns blank content

The template rendered but produced no visible output:
- Ensure `index_partial.html` is not empty
- Check that the template is a fragment (no `<html>/<head>/<body>` tags needed but allowed)
- Verify `partial_template` in `manifest.json` points to the right path

### Order of tabs is wrong

Set `"order"` in `manifest.json` to control position. Lower = earlier.
External apps default to `90` if not set. Built-in apps use `20`–`50`.

# EOF
