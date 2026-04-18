# NAS Stability Guidelines

## Deployment Checklist (scitex-orochi)
1. `git pull origin develop` on NAS
2. `docker rm -f scitex-orochi` (avoid container name conflict)
3. `docker compose up -d --build`
4. Purge Cloudflare cache after every deploy (mandatory)
5. Verify with `curl -s http://192.168.0.102:8559/api/stats`

## Deployment Checklist (scitex-cloud)
1. `git pull origin develop` on NAS
2. `make ENV=prod rebuild` (includes Vite build + collectstatic)
3. Purge Cloudflare cache after every deploy (mandatory — stale Vite manifests cause 404s)
4. Verify in incognito browser — check for console 404 errors

## Docker Image Management
- NEVER prune Docker images without explicit human approval
- Dangling images (`<none>:<none>`) are safe to prune but ALWAYS ask first
- Scholar databases (crossref, openalex) are in volumes/bind mounts, NOT images
- Command if approved: `docker image prune --filter "until=72h"` (NOT `-a` which removes all unused)

## Cloudflare Cache
- Stale cache causes Vite chunk 404s (browser gets old manifest with wrong hashes)
- Must purge after every deploy that changes frontend assets
- Cache-Control headers set to `no-cache, must-revalidate` for /static and /media paths

## Media Persistence
- Orochi uses bind mount: `/home/ywatanabe/data/orochi:/data`
- Media stored under `MEDIA_ROOT/<YYYY-MM>/<uuid>.<ext>`
- Survives container rebuilds

## Resource Monitoring
- Automated heartbeat cron runs every 60s on NAS
- Reports to Orochi #monitoring channel
- Dashboard Resources tab/sidebar shows CPU/RAM/Disk bars

## Known Issues
- sshd OOM on NAS — needs sudo scripts (awaiting human approval)
- Docker memory limits — not yet configured
