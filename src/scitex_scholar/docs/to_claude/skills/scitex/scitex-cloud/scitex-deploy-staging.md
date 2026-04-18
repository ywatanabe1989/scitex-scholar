# SciTeX Cloud - Deploy Staging

## Prerequisites
- Ensure scitex packages are latest and synchronized (run `/scitex-versions` first)
- If scitex version was bumped locally, it MUST be released to PyPI before Docker build
  (Dockerfile.prod installs from PyPI, not local source)

## Step 1: Sync versions
```bash
# Check current state
scitex dev versions list --json

# Sync to NAS
scitex dev versions sync --confirm --host nas
```

## Step 2: Ensure Dockerfile.prod pins correct scitex version
```bash
# Check pinned version
grep 'scitex\[all\]==' ~/proj/scitex-cloud/deployment/docker/Dockerfile.prod

# If outdated, update the pin, commit, push, and sync to NAS
```

## Step 3: Build staging image on NAS (no downtime)
```bash
ssh nas "cd ~/proj/scitex-cloud/deployment/docker && \
  nohup docker compose --env-file ./envs/.env.staging \
    -f docker-compose.yml -f docker-compose.staging.yml \
    build --no-cache > /tmp/staging-rebuild.log 2>&1 &"
```

## Step 4: Monitor build progress
```bash
ssh nas "tail -15 /tmp/staging-rebuild.log"
ssh nas "ps aux | grep 'docker.*build' | grep -v grep"
```

## Step 5: Restart containers (seconds of downtime)
```bash
ssh nas "cd ~/proj/scitex-cloud/deployment/docker && \
  docker compose --env-file ./envs/.env.staging \
    -f docker-compose.yml -f docker-compose.staging.yml down && \
  docker compose --env-file ./envs/.env.staging \
    -f docker-compose.yml -f docker-compose.staging.yml up -d"
```

## Step 6: Verify
```bash
# All 9 containers should be healthy
ssh nas "docker ps --format '{{.Names}} {{.Status}}' | grep stag"

# Django responds
ssh nas "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:31294/"
# Expected: 200
```

## Key Details
- Staging port: 31294 (Django), 2213 (SSH), 5434 (Postgres), 6380 (Redis)
- Staging env file: deployment/docker/envs/.env.staging
- Compose files: docker-compose.yml + docker-compose.staging.yml (overlay)
- ALLOWED_HOSTS: localhost, 127.0.0.1, 0.0.0.0 (NAS-local only)
- Access from WSL: `ssh -L 31294:127.0.0.1:31294 nas`
- Build takes ~25-30 min (full no-cache), restart takes ~10 seconds
- Use nohup to prevent SSH timeout during build
- Docker build cache: use --no-cache when PyPI package version changed

## Containers (9 total)
django, celery_worker, celery_beat, flower, postgres, redis, pgbouncer, gitea, umami
