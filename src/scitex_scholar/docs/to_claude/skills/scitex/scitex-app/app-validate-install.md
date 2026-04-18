---
description: Validate, dev-install, browser testing, and troubleshooting for SciTeX apps. Steps 3–5 of the app lifecycle.
---

# Validate, Dev-Install, and Test

Steps 3–5 of the [app lifecycle](app-lifecycle.md).

---

## Step 3: Validate

```bash
scitex-app app validate .
```

**Pass output:**
```
All checks passed! App is ready for submission.
```

**Fail output:**
```
Found 2 issue(s):
  ✗ manifest.json missing required fields: icon, version
  ✗ static/my_awesome_app/css/my_awesome_app.css: targets shell selector '.workspace-sidebar'
```

### What validation checks

| Check | What it verifies |
|-------|-----------------|
| `validate_manifest` | manifest.json exists, has required fields, semver version |
| `validate_structure` | `views.py` and `urls.py` exist at root or `_django/` subdir |
| `validate_css` | No CSS targeting reserved shell selectors |
| `validate_js` | No dangerous JS patterns |
| `validate_bundle_size` | Total size under 50 MB |
| `validate_privileges` | Declared privileges use valid types and scopes |

**Forbidden CSS selectors:**
`#scitex-ai-panel`, `#main-content`, `.ws-module-pane`, `.workspace-header`,
`.workspace-sidebar`, `.stx-shell-*`, `#workspace-container`, `.ws-app-sidebar`

**Forbidden JS patterns:**
`eval(`, `Function(`, `document.cookie`, `window.parent`, `window.top`,
`__import__`, `os.system`, `subprocess`, `exec(`

**Skipped directories during scanning:**
`node_modules`, `dist`, `.vite`, `_docs`, `__pycache__`, `assets`

### Python API

```python
from scitex_app.appmaker import validate
from scitex_app.validator import AppValidator

# Simple wrapper — returns list of error strings
errors = validate("./my_awesome_app")
if not errors:
    print("Ready for submission")
else:
    for e in errors:
        print(f"ERROR: {e}")

# Full control
validator = AppValidator("./my_awesome_app", max_bundle_size=50 * 1024 * 1024)
result = validator.validate()
print(result.passed)     # bool
print(result.errors)     # List[str]
print(result.warnings)   # List[str]
print(result.manifest)   # dict | None
# result.add_error(msg)    — appends and sets passed=False
# result.add_warning(msg)  — appends, does not fail
```

---

## Step 4: Dev-Install

Registers the app on a running SciTeX Cloud instance. App appears in the workspace
sidebar immediately, visible only to your account.

```bash
export SCITEX_API_TOKEN="your-jwt-token"   # from Profile → Settings → API Tokens
scitex-app app dev-install . --server http://127.0.0.1:8000
```

**Expected output:**
```
Dev-installing from: /path/to/my_awesome_app
Server: http://127.0.0.1:8000
Dev install successful!
  Module: dev__alice__my-awesome-app
  Your app should appear in the workspace sidebar.
```

### Getting your JWT token

1. Navigate to your SciTeX Cloud instance (e.g. `http://127.0.0.1:8000`)
2. Log in → Profile → Settings → API Tokens
3. Generate a new token and copy it
4. `export SCITEX_API_TOKEN="<the-token>"`

### Options

| Flag | Env var | Default | Purpose |
|------|---------|---------|---------|
| `--server` | `SCITEX_SERVER_URL` | `http://127.0.0.1:8000` | Server base URL |
| `--token` | `SCITEX_API_TOKEN` | required | JWT access token |
| `--owner` | — | auto-detected from token | Your Gitea username |
| `--repo` | — | from manifest `slug` | Gitea repo name |

### What happens on the server

1. Local validation runs before making the API call
2. `POST /apps/store/api/dev/install/` is called with `{"owner": ..., "repo": ...}`
3. A `DevInstallation` database record is created:
   - `source_owner` = your username
   - `source_repo` = repo slug
   - `module_name` = `dev__<owner>__<repo>`
4. On each workspace page load, `build_module_config(dev_install)` synthesizes
   a `ModuleConfig` for your user only
5. Templates are served live from your source directory — no reinstall needed for template edits

### When to re-run dev-install

Re-run `dev-install` only if you change:
- `manifest.json` fields (name, slug, label, icon, order, etc.)
- Python module structure or app registration

You do **not** need to reinstall after editing:
- `index_partial.html` (reloads on next page load)
- `views.py` (if Django auto-reload is on)
- CSS files
- Static assets

---

## Step 5: Test in Browser

Navigate to `http://127.0.0.1:8000/` and verify your app works.

**Testing checklist:**
- [ ] Tab appears in sidebar with correct icon and label
- [ ] Clicking the tab loads the partial template without HTTP errors
- [ ] Browser DevTools console shows no JS errors
- [ ] API endpoints respond correctly (test with browser DevTools Network tab)
- [ ] CSS is scoped — no style leakage into workspace shell
- [ ] App works with and without an active project

### Standalone mode (no SciTeX Cloud required)

```bash
# Runs a minimal Django workspace shell at localhost:8050
my-awesome-app gui

# With options
my-awesome-app gui --port 9000 --no-browser

# Or via scitex-app CLI
scitex-app standalone --app my_awesome_app --port 8050
```

Standalone mode is useful for:
- Testing without a full SciTeX Cloud instance running
- Distributing the app as a standalone tool
- CI testing

---

## Troubleshooting

### Tab does not appear after dev-install

- Confirm the API call returned "Dev install successful!" — if it failed silently, check your token
- Verify `SCITEX_API_TOKEN` belongs to the same user you're logged in as on the server
- Hard-refresh the browser (Ctrl+Shift+R) — sidebar is cached
- Check server logs: `tail -f /path/to/scitex.log` — look for import errors in `views.py`

### Validation fails: CSS targets shell selector

```
✗ static/my_awesome_app/css/my_awesome_app.css: targets shell selector '.workspace-sidebar'
```

Rename to use your app's own prefix: `.my-awesome-app-sidebar`.

### Validation fails: views.py not found

```
✗ Missing required file: views.py (checked at root and _django/ subdir)
```

The validator looks at `views.py` at the app root or under `_django/`. Ensure the file exists at one of those locations.

### Template not rendering in workspace

- Check `"partial_template"` in `manifest.json` matches the actual template path
- Path is relative to Django `TEMPLATES` dirs: typically `my_awesome_app/index_partial.html`
- Run `python manage.py check` to surface template syntax errors
- Confirm the template has no `<html>`, `<head>`, or `<body>` tags — partials must be fragments

### React bundle not loading

- Run `npm run build` before `dev-install`
- Check `vite.config.js` outputs to `static/my_awesome_app/dist/`
- Confirm the `<script>` tag in the partial uses `{% load static %}` and `{% static '...' %}`
- Check browser DevTools Network tab for 404 on the JS bundle path

### CSRF error on API POST

Add CSRF token to `fetch` headers:

```javascript
'X-CSRFToken': document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '',
```

Or use the Django `{% csrf_token %}` input and read its value:

```javascript
'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]')?.value || '',
```

### Dev-install: "Authentication failed"

```
Error: Authentication failed (401)
```

Token is invalid or expired. Generate a fresh token from Profile → Settings → API Tokens.

### Dev-install: "Validation failed before install"

```
Error: Validation failed — fix errors before installing
  ✗ manifest.json missing required field: slug
```

Fix the reported validation error first, then re-run `dev-install`.

---

## Environment Variables Reference

| Variable | Purpose | Default |
|----------|---------|---------|
| `SCITEX_API_TOKEN` | JWT token for `dev-install` / `submit` | — (required) |
| `SCITEX_SERVER_URL` | Server URL for `dev-install` / `submit` | `http://127.0.0.1:8000` |
| `SCITEX_API_URL` | Cloud API URL for `get_files()` backend | `http://127.0.0.1:8000` |
| `SCITEX_BASE_DIR` | Base dir for path resolution | — (raises if missing) |
| `SCITEX_WORKING_DIR` | Working dir for standalone file tree | — |
| `DJANGO_SECRET_KEY` | Django secret key (standalone mode) | `"scitex-standalone-dev-key"` |
| `DJANGO_DEBUG` | Django debug mode | `"true"` |

# EOF
