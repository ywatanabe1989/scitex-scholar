---
description: Deploy SciTeX Cloud to production — zero-downtime build, swap, verify.
---

# Deploy to Production

**WARNING: This affects the live site (scitex.ai). Confirm with user before proceeding.**

## CRITICAL: Build Rules

**NEVER run `docker build` directly on NAS.** ALWAYS use:
```bash
ssh nas 'cd ~/proj/scitex-cloud && make ENV=prod YES=1 rebuild'
```

`make rebuild` calls `scripts/deploy/rebuild.sh` which has:
- `nice -n 10` — lowers build priority so SSH stays responsive
- `systemd-run --slice` — isolates build in its own cgroup
- `DOCKER_BUILDKIT=1` — uses BuildKit (not legacy builder)
- Proper `docker compose down` before build

Running raw `docker build` bypasses ALL these protections and **will crash the NAS** (Intel N100, 4 cores — builds saturate all CPUs and starve sshd).

## Prerequisites
- Staging MUST be deployed and verified first (see `deployment-staging.md`)
- All changes committed and pushed to `origin/develop`
- CI passes on develop
- Dependency packages (scitex-ui, figrecipe, etc.) published to PyPI
- Dockerfile version pins updated: `deployment/docker/docker_prod/Dockerfile.prod`

## Step 1: Sync NAS repo
```bash
ssh nas 'cd ~/proj/scitex-cloud && git pull origin develop'
```

## Step 2: Build prod in screen (survives SSH disconnect)
```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ssh nas "screen -dmS rebuild-$TIMESTAMP bash -c 'cd ~/proj/scitex-cloud && make ENV=prod YES=1 rebuild 2>&1 | tee /tmp/scitex-rebuild-$TIMESTAMP.log'"
```

Before rebuild — stop non-essential containers to free memory for npm install:
```bash
ssh nas 'docker stop ai-ielts-nas-django-1 ai-ielts-nas-nginx-1 ai-ielts-nas-redis-1 ai-ielts-nas-cloudflared-1 2>/dev/null'
```

## Step 3: Monitor build
```bash
ssh nas "tail -20 /tmp/scitex-rebuild-$TIMESTAMP.log"
ssh nas "screen -ls"
```

## Step 4: Verify Production — ALWAYS READ LOGS

**DO NOT just poll HTTP status codes.** Always read actual container logs.

```bash
# 1. Check container health
ssh nas 'docker ps --format "{{.Names}}: {{.Status}}" | grep scitex-cloud'

# 2. READ Django logs — this is where real errors show
ssh nas 'docker logs scitex-cloud-prod-django-1 --tail 50'

# 3. READ Celery worker logs — stale task names cause KeyError
ssh nas 'docker logs scitex-cloud-prod-celery_worker-1 --tail 30'

# 4. Check site HTTP
curl -sL -o /dev/null -w "%{http_code}" https://scitex.ai/
```

## Known Issues & Lessons

### When to Use --no-cache
- `--no-cache` forces full rebuild (~25 min) — **usually NOT needed**
- Dockerfile version pin changes automatically invalidate cache at that layer
- Only use when: PyPI package republished with same version, or build cache corrupted
- Default: `docker compose build` (with cache) — much faster (~5 min)

### NAS Resource Protection (systemd cgroup limits)

**Layer 1 — containerd** (`/etc/systemd/system/containerd.service.d/resource-limit.conf`):
- `CPUQuota=80%`, `MemoryMax=85%`, `MemoryHigh=80%`, `IOWeight=50`

**Layer 2 — docker** (`/etc/systemd/system/docker.service.d/resource-limit.conf`):
- `CPUQuota=90%`, `MemoryMax=90%`

**Layer 3 — sshd** (`/etc/systemd/system/ssh.service.d/protect.conf`):
- `OOMScoreAdjust=-900`, `CPUWeight=1000`, `IOWeight=1000`, `MemoryLow=256M`

Verify: `cat /sys/fs/cgroup/system.slice/containerd.service/cpu.max` (should show `80000 100000`)

Re-apply after NAS firmware update (may reset systemd overrides):
```bash
NAS_PASS=$(decrypt.sh -t ugreen.ssl)
sshpass -p "$NAS_PASS" ssh nas "echo '$NAS_PASS' | sudo -S systemctl daemon-reload && sudo -S systemctl restart containerd docker"
```

### Docker DNS Resolution Failure in Build
- Symptom: `wget: bad address 'github.com'`
- Fix: Pre-download binaries on host and `COPY` into Docker image
- Pre-downloaded binaries: `deployment/docker/docker_prod/bin/` (git-ignored)
- daemon.json DNS: `{"dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"]}`

### Celery Stale Task Names
- After renaming apps, old task names persist in Redis
- Fix: `docker exec scitex-cloud-prod-redis-1 redis-cli FLUSHALL`

### Dockerfile Intentional Double Install (Cache Strategy)
- **Layer C0** (pinned): `uv pip install --system "scitex-ui==X.Y.Z"` — sets cache baseline
- **Layer C1** (latest): `uv pip install --system --upgrade "scitex-ui"` — only downloads delta
- **Always update C0 version pin** when bumping package versions

### Django Startup Slow on NAS
- Full startup: migrations + collectstatic + pip install apps = 3-5 min
- **Do not restart Django repeatedly** — each restart resets the timer

### Cloudflare Tunnel
- 503 = tunnel up but Django not ready
- 520 = Django returning unexpected response

### Common Log Patterns
- `pip install -e ...` hanging = slow NAS hardware, wait 3-5 min
- `KeyError: 'apps.public_app.tasks...'` = stale Celery task names in Redis
- `health: starting` for 2-3 min = normal cold start
- `unhealthy` after 5+ min = read `docker logs` for actual error

### Broken pyproject.toml in Ecosystem Packages (Common Root Cause)
- **Symptom:** Empty page / Django entrypoint crash / `uv pip install` fails
- **Root cause:** `pyproject.toml` in an ecosystem package (e.g. scitex-ui, figrecipe) is malformed or missing a field
- **Fix:** Repair the `pyproject.toml`, then run a full rebuild:
  ```bash
  ssh nas 'cd ~/proj/scitex-cloud && make env=prod rebuild YES=1'
  ```
- **Verify after rebuild:**
  ```bash
  ssh nas 'docker ps --format "{{.Names}} {{.Status}}" | grep scitex-cloud'
  ```

### Missing Imports in Visitor Pool (Critical Silent Failure)
- **Symptom:** Visitors see "pool full" but pool has free slots; visitor allocation silently fails
- **Root cause:** `decorators.py` used `timezone.now()` without `from django.utils import timezone`
- **Impact:** ALL 16 visitor slot allocations fail, making the site appear broken for anonymous users
- **Why it was hard to find:** The middleware caught `Exception` and only logged `str(e)`, hiding the traceback
- **Fix:** Add missing import; also log full `traceback.format_exc()` not just `str(e)`
- **Lesson:** Follow no-fallbacks — never silently swallow errors. Log full tracebacks.

### Bulk sed Breaks pyproject.toml (Ecosystem-Wide)
- **Symptom:** Dev container fails to start; `uv pip install` errors during editable install
- **Root cause:** Bulk sed/replace operations strip closing `]` from TOML arrays
- **Affected:** scitex-stats, scitex-audio (found 2026-03-26)
- **Prevention:** After ANY bulk rename/replace, validate ALL pyproject.toml files:
  ```bash
  for f in ~/proj/scitex-*/pyproject.toml; do
    python3 -c "import tomllib; tomllib.load(open('$f', 'rb'))" && echo "OK: $f" || echo "FAIL: $f"
  done
  ```

### Screen Session with Timestamps (Preferred for Monitoring)
Use named screen sessions with dates so you can find and re-attach them:
```bash
ssh nas "screen -S deploy-$(date +%Y%m%d)"
# Or inline:
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ssh nas "screen -dmS deploy-$TIMESTAMP bash -c 'cd ~/proj/scitex-cloud && make env=prod rebuild YES=1 2>&1 | tee /tmp/scitex-rebuild-$TIMESTAMP.log'"
```
