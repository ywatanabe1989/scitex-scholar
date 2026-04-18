---
description: Docker-based development environment — start/stop, container names, hot reload, access URLs, test user.
---

# Development Environment

## Docker-Based Development
All development runs in Docker containers. Never run Django directly on host.

## Start/Stop Commands
```bash
make env=dev start       # Start development
make env=dev stop        # Stop
make env=dev restart     # Restart
make env=dev status      # Status
```

## Container Names
Project name `scitex-cloud-dev` (set in `deployment/docker/docker_dev/docker-compose.yml`):
- `scitex-cloud-dev-django` — Main Django app
- `scitex-cloud-dev-postgres` — PostgreSQL database
- `scitex-cloud-dev-redis` — Redis cache
- `scitex-cloud-dev-gitea` — Git hosting
- `scitex-cloud-dev-celery_worker` — Background tasks
- `scitex-cloud-dev-celery_beat` — Scheduled tasks

## Running Django Commands
```bash
docker exec scitex-cloud-dev-django-1 python manage.py migrate --settings=config.settings.settings_dev
docker exec -it scitex-cloud-dev-django-1 python manage.py shell --settings=config.settings.settings_dev
```

## Hot Reload
- **Django**: Auto-reloads on Python file changes
- **TypeScript/CSS**: Vite HMR — edit `.ts` -> Vite detects -> HMR to browser (~200ms)
- **Templates**: Auto-reloads via django-browser-reload

Vite dev server runs on port 5173 inside Docker.

## Access URLs
- Main app: http://127.0.0.1:8000
- Gitea: http://127.0.0.1:3001
- Vite HMR: http://127.0.0.1:5173

Note: Flower (Celery monitoring) removed — run on-demand:
```bash
docker compose run --rm django celery -A config flower
```

## Environment Files
- `SECRET/.env.dev` — Development environment variables
- `SECRET/.env.nas` — NAS production environment

## Test User
For testing: `test-user` / `Password123!`

## Console Debugging
Browser console interceptor is active in dev mode:
- Prefixes logs with source file and timestamp
- Saves to `./logs/console.log`
- View live: `tail -f ./logs/console.log`

### Log Patterns
```typescript
console.log('[ModuleName] Loaded');
console.log('[ModuleName] functionName:', param1);
console.error('[ModuleName] Error:', error.message, error);
```
