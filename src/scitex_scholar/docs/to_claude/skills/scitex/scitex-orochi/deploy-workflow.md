---
name: orochi-deploy-workflow
description: End-to-end deployment process for Orochi hub and agent restart procedures.
---

# Deploy Workflow

## Hub Deployment

The Orochi hub runs on NAS via Docker. Production URL: `https://scitex-orochi.com/`

### Steps

1. **Bump version** (on dev machine):

   ```bash
   cd ~/proj/scitex-orochi
   ./scripts/bump-version.sh patch   # or minor, major
   ```

2. **Commit and push**:

   ```bash
   git add -A && git commit -m "Bump version to X.Y.Z"
   git push origin develop
   ```

3. **Pull on NAS**:

   ```bash
   ssh nas 'cd ~/proj/scitex-orochi && git pull'
   ```

4. **Build and restart Docker**:

   ```bash
   ssh nas 'cd ~/proj/scitex-orochi && docker compose -f docker-compose.stable.yml build && docker compose -f docker-compose.stable.yml up -d'
   ```

5. **Purge Cloudflare cache** (cached HTML/JS causes stale dashboard UI).

6. **Verify**:
   - Check `/api/config` shows new version
   - Confirm agents reconnect (check `/api/agents`)
   - Test media uploads (attach/paste/drag-drop)

### Dual Instance Setup

| Instance | Dashboard | WebSocket | Docker Compose |
|----------|-----------|-----------|----------------|
| stable (`orochi.scitex.ai`) | `:8559` | `:9559` | `docker-compose.stable.yml` |
| dev (`orochi-dev.scitex.ai`) | `:8560` | `:9560` | shares stable DB |

Dev connects to stable's WS via `SCITEX_OROCHI_DASHBOARD_WS_UPSTREAM`.

## Agent Restart

### Single Agent

```bash
scitex-orochi restart <agent-name>
# or manually:
scitex-orochi stop <agent-name>
scitex-orochi launch head <agent-name>
```

### All Agents on a Host

SSH to the host and restart each screen session, or use the CLI to iterate:

```bash
for agent in head-mba mamba-mba caduceus-mba; do
    scitex-orochi restart "$agent"
done
```

### Dev Channel Dialog

After restart, agents using `--dangerously-load-development-channels` may get stuck on a TUI confirmation prompt. `scitex-agent-container` handles this automatically via `screen -X stuff`, but if an agent is unresponsive:

```bash
ssh <host> screen -S <agent-name> -X stuff $'\n'
```

## Data Persistence

Media files must survive container rebuilds. The Docker volume mount ensures this:

```yaml
volumes:
  - /data/orochi-media/:/app/media/
  - /data/orochi-stable/:/data/
```
