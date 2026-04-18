---
description: Deploy SciTeX Cloud to staging — sync versions, build Docker, verify.
---

# Deploy to Staging

## Prerequisites
- Ensure scitex packages are latest and synchronized (`scitex dev versions list --json`)
- If scitex version was bumped locally, MUST be released to PyPI before Docker build
  (Dockerfile.prod installs from PyPI, not local source)

## Step 1: Sync versions
```bash
scitex dev versions list --json
scitex dev versions sync --confirm --host nas
```

## Step 2: Verify Dockerfile pins correct version
```bash
grep 'scitex\[all\]==' ~/proj/scitex-cloud/deployment/docker/Dockerfile.prod
```

## Step 3: Sync NAS repo
```bash
ssh nas "cd ~/proj/scitex-cloud && git -C ~/proj/scitex-cloud pull origin develop"
```

## Step 4: Build staging in screen (survives SSH disconnect)

**NEVER run raw `docker build` on NAS** — use `make rebuild` which has cgroup protections:
```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ssh nas "screen -dmS staging-$TIMESTAMP bash -c 'cd ~/proj/scitex-cloud && make ENV=staging YES=1 rebuild 2>&1 | tee /tmp/scitex-staging-$TIMESTAMP.log'"
```

Monitor:
```bash
ssh nas "tail -20 /tmp/scitex-staging-$TIMESTAMP.log"
ssh nas "screen -ls"
```

## Step 5: Verify staging
```bash
# Check containers
ssh nas 'docker ps --format "{{.Names}}: {{.Status}}" | grep staging'
# Check site
ssh nas 'curl -sL -o /dev/null -w "%{http_code}" http://localhost:8001/'
# Read Django logs
ssh nas 'docker logs scitex-cloud-staging-django-1 --tail 30'
```
