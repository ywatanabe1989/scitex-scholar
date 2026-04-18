---
description: All environment variables used by scitex-app — storage, cloud API, standalone Django, and LLM configuration.
---

# Environment Variables

## Storage and Path Resolution

| Variable | Purpose | Used by |
|----------|---------|---------|
| `SCITEX_BASE_DIR` | Base directory for app path resolution | `scitex_app.paths.get_base_dir()` |
| `SCITEX_WORKING_DIR` | Working directory for standalone file tree | `run_standalone()` |

```bash
export SCITEX_BASE_DIR=/data/scitex
export SCITEX_WORKING_DIR=/home/user/projects
```

## Cloud API

| Variable | Purpose | Default |
|----------|---------|---------|
| `SCITEX_API_TOKEN` | JWT token for cloud API authentication | — |
| `SCITEX_API_URL` | Cloud API base URL | `http://127.0.0.1:8000` |
| `SCITEX_SERVER_URL` | Server URL for `app dev-install` and `app submit` | `http://127.0.0.1:8000` |

`SCITEX_API_TOKEN` is the trigger for automatic cloud backend selection in `get_files()`. When set, `get_files()` routes to the cloud backend instead of the local filesystem.

```bash
export SCITEX_API_TOKEN="eyJhbGci..."
export SCITEX_API_URL="https://scitex.ai"
export SCITEX_SERVER_URL="https://scitex.example.com"
```

## Standalone Django

| Variable | Purpose | Default |
|----------|---------|---------|
| `DJANGO_SECRET_KEY` | Django secret key for standalone mode | `"scitex-standalone-dev-key"` |
| `DJANGO_DEBUG` | Django debug mode | `"true"` |
| `SCITEX_UI_STATIC` | Path to scitex-ui static files | auto-detected |

```bash
export DJANGO_SECRET_KEY="your-production-secret-key"
export DJANGO_DEBUG="false"
```

## LLM / Chat

| Variable | Purpose | Default |
|----------|---------|---------|
| `ANTHROPIC_API_KEY` | API key for Anthropic chat backend | — |
| `LLM_MODEL` | LLM model identifier for chat features | `claude-sonnet-4-20250514` |

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export LLM_MODEL="claude-opus-4-5"
```

## Usage Examples

### Local development (default)

No environment variables needed. `get_files("./project")` uses local filesystem.

### Cloud-connected development

```bash
export SCITEX_API_TOKEN="your-jwt-token"
export SCITEX_API_URL="https://scitex.ai"
```

Then `get_files()` (no arguments) routes through the cloud REST API.

### Remote local server

```bash
export SCITEX_API_TOKEN="your-jwt-token"
export SCITEX_API_URL="http://192.168.1.100:8000"
```

### Production standalone app

```bash
export DJANGO_SECRET_KEY="$(python -c 'import secrets; print(secrets.token_hex(50))')"
export DJANGO_DEBUG="false"
export SCITEX_WORKING_DIR="/data/user_projects"
```
