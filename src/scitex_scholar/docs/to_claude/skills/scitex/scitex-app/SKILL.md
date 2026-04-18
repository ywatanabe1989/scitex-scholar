---
description: App developer SDK — scaffold, validate, dev-install, standalone shell, file operations, and cloud SDK for building SciTeX workspace apps. Use when creating, testing, or deploying SciTeX apps.
allowed-tools: mcp__scitex__app_*
---

# scitex-app — App Developer SDK

Toolkit for building SciTeX workspace apps with scaffold, validation, standalone mode, and cloud integration.

## Sub-skills

* [files-sdk](files-sdk.md) — `get_files()`, `FilesBackend` protocol, `FileSystemBackend`, `build_tree()`
* [app-lifecycle](app-lifecycle.md) — `init_app()`, `validate()`, `AppValidator`, `ValidationResult`
* [paths](paths.md) — Path resolution: `get_base_dir()`, `resolve_*`, `parse_dev_module_name()`
* [standalone](standalone.md) — `run_standalone()` for local Django workspace shell
* [cli](cli.md) — `scitex-app` CLI: file commands, app commands, MCP, introspection
* [environment-vars](environment-vars.md) — All environment variable configuration

## References

* [app-lifecycle](app-lifecycle.md) — End-to-end guide: scaffold → develop → validate → dev-install → test → submit. CLI commands with expected outputs, complete manifest schema, file structure.
* [app-develop](app-develop.md) — Development patterns: views.py, urls.py, templates (AJAX partial), CSS scoping, React bridge setup.
* [app-validate-install](app-validate-install.md) — Validate, dev-install, browser testing, environment variables, troubleshooting.
* [app-registration](app-registration.md) — How apps register with the workspace sidebar: manifest.json → ModuleConfig → sidebar tab. Dev-install vs published paths, frontend integration points, troubleshooting.

## Quick Start

```bash
scitex-app app init . --name my_app
scitex-app app validate .
scitex-app app dev-install . --server http://127.0.0.1:8000
```

```python
from scitex_app.sdk import get_files, build_tree
from scitex_app._standalone import run_standalone

files = get_files("./my_project")
content = files.read("config/settings.yaml")
files.write("output/result.csv", csv_text)
tree = build_tree(files, max_depth=2)
run_standalone(app_module="my_app", port=8050)
```

## MCP Tools

| Tool | Parameters | Purpose |
|------|-----------|---------|
| `app_scaffold` | `name`, `frontend` | Scaffold new app |
| `app_validate` | `path` | Validate app structure |
| `app_read_file` | `path`, `root`, `binary` | Read file content |
| `app_write_file` | `path`, `content`, `root` | Write file |
| `app_list_files` | `directory`, `root`, `extensions` | List directory |
| `app_file_exists` | `path`, `root` | Check file existence |
| `app_delete_file` | `path`, `root` | Delete file |
| `app_copy_file` | `src_path`, `dest_path`, `root` | Copy file |
| `app_rename_file` | `old_path`, `new_path`, `root` | Rename/move file |
