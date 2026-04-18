# SciTeX Cloud - Deploy Production

## WARNING: This affects the live site (scitex.ai). Confirm with user before proceeding.

## Prerequisites
- Staging should be deployed and verified FIRST (run `/scitex-deploy-staging`)
- Ensure scitex version is released to PyPI
- Ensure Dockerfile.prod pins correct scitex version

## Step 1: Sync NAS repo to latest
```bash
ssh nas "cd ~/proj/scitex-cloud && git pull origin develop"
```

## Step 2: Build prod image WHILE prod stays running (zero downtime during build)
```bash
ssh nas "cd ~/proj/scitex-cloud/deployment/docker/docker_prod && \
  nohup docker compose build --no-cache > /tmp/prod-build.log 2>&1 &"
```

## Step 3: Monitor build progress
```bash
ssh nas "tail -15 /tmp/prod-build.log"
ssh nas "ps aux | grep 'docker.*build' | grep -v grep"
```

## Step 4: Once build completes, restart containers (minimal downtime ~10s)
```bash
# Confirm with user before this step - it causes brief downtime
ssh nas "cd ~/proj/scitex-cloud/deployment/docker/docker_prod && \
  docker compose down && docker compose up -d"
```

## Step 5: Verify all containers healthy
```bash
# All 13 containers should come up healthy
ssh nas "docker ps --format '{{.Names}} {{.Status}}' | grep prod"

# Django responds
ssh nas "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8012/"
# Expected: 200 or 302
```

## Step 6: Purge Cloudflare cache (if needed)
The rebuild.sh script handles this automatically, but if doing manual deploy:
```bash
ssh nas "cd ~/proj/scitex-cloud && bash scripts/deploy/purge_cache.sh"
```

## Key Details
- Prod directory: deployment/docker/docker_prod/
- Prod Django port: 8012 (internal), exposed via nginx + cloudflared
- Build takes ~25-30 min (full no-cache), restart takes ~10 seconds
- Strategy: build first (no downtime), then quick down/up swap
- Always build with --no-cache when scitex version changed on PyPI
- Use nohup to prevent SSH timeout during build

## Containers (13 total)
django, celery_worker, celery_beat, flower, postgres, redis, pgbouncer,
gitea, umami, nginx, cloudflared, autoheal, ws_ssh_proxy

## Rollback (if something goes wrong)
```bash
# Check recent images
ssh nas "docker images | grep scitex-cloud-prod"

# If containers are crashing, check logs
ssh nas "cd ~/proj/scitex-cloud/deployment/docker/docker_prod && \
  docker compose logs django --tail 50"

# Revert to previous git commit and rebuild
ssh nas "cd ~/proj/scitex-cloud && git checkout HEAD~1"
# Then repeat build + restart steps
```
