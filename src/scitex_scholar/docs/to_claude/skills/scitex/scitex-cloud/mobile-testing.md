---
name: mobile-testing
description: Mobile responsive testing patterns, key file locations, and Playwright mobile emulation setup
type: reference
---

# Mobile Testing with Playwright

## Viewport Configuration
Use Python Playwright async API with mobile emulation parameters:
- **Viewport:** 390x844 pixels (iPhone 12 Pro)
- **is_mobile:** True
- **device_scale_factor:** 3

```python
await browser.new_context(
    viewport={"width": 390, "height": 844},
    is_mobile=True,
    device_scale_factor=3
)
```

## Authentication
- **Login URL:** `/auth/login/` (NOT `/accounts/login/`)
- **Form selectors:**
  - Username: `id="username"`
  - Password: `id="password"`
  - Submit: form `id="login-form"`
- **Test credentials:** `test-user` / `Password123!`
- **Post-login redirect:** `/workspace/` (not profile page)

## Page Load Waiting
- **Workspace pages:** Use `wait_until="domcontentloaded"` — pages never reach `networkidle` due to WebSocket connections
- **Other pages:** Standard `wait_until="networkidle"` is acceptable

## URL Structure
- `/auth/login/` — Login page
- `/workspace/` — Main workspace shell (modules load internally via JS, not separate routes)
- `/workspace/chat/` and `/workspace/console/` — 404 errors; modules load inside `/workspace/` shell

## Key Mobile Components

| Component | File Path | Notes |
|-----------|-----------|-------|
| Hamburger menu | `templates/global_base_partials/global_header.html:699-761` | Navigation toggle |
| Visitor badge | `static/shared/css/components/header/15-visitor-badge.css` | Header styling |
| Chat input | `static/shared/css/components/workspace-chat.css` | Chat UX |
| Model selector | `static/shared/ts/components/_global-ai-chat/llm-model-selector.ts` | AI model picker |
| Login template | `apps/infra/auth_app/templates/auth_app/signin.html` | Form markup |
| Login logic | `apps/infra/auth_app/views/authentication.py` (login_view) | Auth handler |
| Workspace shell | `apps/infra/workspace_app/views.py` (@login_required) | Main view gate |

## Real Device Testing (iPhone via LAN)

See `deployment/docs/11_MOBILE_DEV_TESTING.md` for full setup.

Quick steps:
1. Set `VITE_HOST_IP=<Windows-LAN-IP>` in `deployment/docker/docker_dev/.env`
2. Windows PowerShell (Admin): forward ports 8000 and 5173 from Windows to WSL
3. Windows Firewall: allow inbound on ports 8000 and 5173
4. Restart dev: `make ENV=dev restart`
5. iPhone Safari: `http://<Windows-LAN-IP>:8000`

Without `VITE_HOST_IP`, templates reference `127.0.0.1:5173` which iPhone resolves to itself.

## Known Mobile Issues

- App-level resizer (`ts/app/resizer/_drag-handler.ts`) only handles mouse events, no touch
- Workspace panel resizer (`ts/shell/workspace-panel-resizer/resizer.ts`) has touch support
- Horizontal swipe can get stuck in split file browser view
- `body.workspace-page.landing-page` at `/` shows footer; auth users at `/` get `workspace-page` only
