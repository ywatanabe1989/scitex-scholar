# SciTeX Versions Management

## Overview
Manage and sync versions across the SciTeX ecosystem packages on local and remote hosts.
Syncing is **bidirectional**: local → remote (push) and remote → local (pull).

## Dashboard
Check this first:
scitex dev versions list --json
http://127.0.0.1:5000

## Ecosystem Packages (in order)
01. scitex (scitex-python)
02. scitex-cloud
03. figrecipe
04. openalex-local
05. crossref-local
06. scitex-writer
07. scitex-dataset
08. socialia
09. automated-research-demo
10. scitex-research-template
11. pip-project-template
12. singularity-template
... and being cumulated


## PyPI Trusted Publisher

Configure github action in this pattern

``` bash
Repository: ywatanabe1989/figrecipe
Workflow: publish-pypi.yml
Environment name: pypi
```

## Commands

### List versions (read-only)
```bash
scitex dev versions list                         # Local + PyPI versions
scitex dev versions list --json                  # JSON output
scitex dev versions list -p scitex               # Specific package
scitex dev versions list --local-only            # Skip PyPI
scitex dev versions list-hosts                   # SSH host versions
scitex dev versions list-hosts --host nas        # Specific host
scitex dev versions list-remotes                 # GitHub remote versions
scitex dev versions list-rtd                     # Read the Docs status
scitex dev versions check                        # Consistency check
scitex dev versions dashboard                    # Start dashboard GUI
scitex dev versions dashboard --background       # Run as background daemon
scitex dev versions dashboard --stop             # Stop background daemon
scitex dev versions dashboard --no-browser       # Don't open browser
```

### Sync: Local → Remote (push)
```bash
# Remote host sync
scitex dev versions sync                             # Preview (dry run)
scitex dev versions sync --confirm                   # Execute (parallel)
scitex dev versions sync --confirm --host nas        # Sync specific host
scitex dev versions sync --confirm -p scitex         # Sync specific package
scitex dev versions sync --confirm --no-install      # Git pull only

# Local install
scitex dev versions sync --local                     # Preview local install
scitex dev versions sync --local --confirm           # Execute local install

# Tag push
scitex dev versions sync --tags                      # Preview tag push
scitex dev versions sync --tags --confirm            # Execute tag push
```

### Sync: Remote → Local (pull)
```bash
# Check what changed on remote hosts
scitex dev versions diff                             # Show diffs on all hosts
scitex dev versions diff --host nas                  # Specific host
scitex dev versions diff -p scitex                   # Specific package
scitex dev versions diff --json                      # JSON output

# Commit remote changes and push to origin
scitex dev versions commit --host nas                # Preview (dry run)
scitex dev versions commit --host nas --confirm      # Execute commit + push
scitex dev versions commit --host nas -m "fix: msg"  # Custom commit message
scitex dev versions commit --host nas --no-push      # Commit only, no push

# Pull from origin to local
scitex dev versions pull                             # Preview (dry run)
scitex dev versions pull --confirm                   # Execute git pull
scitex dev versions pull -p scitex --confirm         # Specific package
scitex dev versions pull --no-stash                  # Don't stash dirty repos
```

### MCP Tools
```
# Read-only
mcp__scitex__dev_versions_list
mcp__scitex__dev_config_show

# Local → Remote (push)
mcp__scitex__dev_versions_sync        # confirm=False → preview, confirm=True → execute
mcp__scitex__dev_versions_sync_local  # confirm=False → preview, confirm=True → execute

# Remote → Local (pull)
mcp__scitex__dev_versions_diff        # read-only: show remote diffs
mcp__scitex__dev_versions_commit      # confirm=False → preview, confirm=True → execute
mcp__scitex__dev_versions_pull        # confirm=False → preview, confirm=True → execute

# Other
mcp__scitex__dev_bulk_rename          # confirm=False → preview, confirm=True → execute
mcp__scitex__dev_test_local
mcp__scitex__dev_test_hpc
mcp__scitex__dev_test_hpc_poll
mcp__scitex__dev_test_hpc_result
```

### Python API
```python
from scitex._dev import sync_all, sync_local, sync_tags
from scitex._dev import remote_diff, remote_commit, pull_local

# Local → Remote (preview by default)
preview = sync_all()                          # dry run
results = sync_all(confirm=True)              # parallel across hosts
results = sync_all(hosts=["nas"], confirm=True)
results = sync_local(confirm=True)
results = sync_tags(confirm=True)

# Remote → Local (preview by default)
diffs = remote_diff()                         # read-only
diffs = remote_diff(host="nas", packages=["scitex"])
results = remote_commit(host="nas", confirm=True)
results = pull_local(confirm=True)
results = pull_local(confirm=True, stash=True)  # auto-stash dirty repos
```

## RULES: Never Sync Blind

1. **NEVER push local → remote without first checking remote state** (`diff`)
2. **NEVER pull remote → local without first checking local state** (`git status`)
3. **NEVER discard uncommitted changes without reading the diff contents**
4. **Always classify changes** before acting: improvement, artifact, or obsolete

## Workflow: Bidirectional Sync

### 1. Check BOTH sides first (MANDATORY)
```bash
# Check remote state
scitex dev versions diff                             # What's dirty on remote?

# Check local state
scitex dev versions list                             # Version alignment?
git status                                           # What's dirty locally?
```

### 2. Triage remote changes (MANDATORY before commit/discard)
For each dirty package on each host, read the diff and classify:

| Classification | Action | Example |
|----------------|--------|---------|
| **IMPROVEMENT** | Commit + pull | Real work: bug fixes, new features, config changes |
| **ARTIFACT** | Discard | `__pycache__`, `.pyc`, build outputs, `.egg-info` |
| **OBSOLETE** | Discard or archive | Dead experiments, abandoned branches |

```bash
# Read the actual diff contents before deciding
scitex dev versions diff --host nas --json

# Commit only improvements (per-package)
scitex dev versions commit --host nas -p scitex -m "feat: improvement from NAS" --confirm

# Discard artifacts only AFTER confirming contents (never blindly)
# ssh nas "cd ~/proj/scitex-python && git diff"           # READ FIRST
# ssh nas "cd ~/proj/scitex-python && git checkout -- ."   # Then discard
```

### 3. Pull remote → local
```bash
scitex dev versions pull                             # Preview first
scitex dev versions pull --confirm                   # Execute
```

### 4. Push local → remote
```bash
scitex dev versions sync                             # Preview first
scitex dev versions sync --confirm                   # Execute
scitex dev versions sync --local --confirm           # Local install
```

### 5. Verify
```bash
scitex dev versions list
scitex dev versions diff                             # Should be clean now
```

### Full round-trip (typical)
```bash
# 1. Check both sides
scitex dev versions diff
git status
# 2. Triage + commit real improvements on remote
scitex dev versions commit --host nas --confirm
# 3. Pull to local
scitex dev versions pull --confirm
# 4. Do local work...
# 5. Check remote again before pushing
scitex dev versions diff
# 6. Push to remote
scitex dev versions sync --confirm
# 7. Verify
scitex dev versions list
```

### Manual workflow (if needed)
```bash
# Push changes to origin
for repo in scitex-python scitex-cloud figrecipe openalex-local crossref-local scitex-writer scitex-dataset socialia; do
    cd ~/proj/$repo && git push origin develop 2>/dev/null || git push origin main
done

# Verify
scitex dev versions list
```

## Version Increment Workflow

### 0. Major, minor, and patch

We use version in the form of vX.Y.Z, where

X is Major
Y is Minor
Z is Patch and may have -alpha, -beta suffix

When increment version, check the difference and determine if it is minor or patch. No major update please as long as user explicitly requests.

### 1. Update version in pyproject.toml
```bash
# Edit pyproject.toml: version = "X.Y.Z"
```

### 2. Commit and tag
```bash
git add pyproject.toml
git commit -m "chore: bump version to X.Y.Z"
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin develop --tags
```

### 3. Sync to all hosts
```bash
scitex dev versions sync --tags --confirm
scitex dev versions sync --confirm
```

## Tag Syncing

### Fix tag not reachable from current branch
When `git describe --tags` shows an older tag because the latest tag is on a different branch (e.g., main vs develop):
```bash
cd ~/proj/PACKAGE
git tag -d vX.Y.Z                           # Delete local tag
git tag -a vX.Y.Z -m "Release vX.Y.Z" HEAD  # Retag on current HEAD
git push origin vX.Y.Z --force               # Force-push updated tag
```

### Sync all tags from remote
```bash
cd ~/proj/PACKAGE && git fetch --tags
```

### Push all local tags to remote
```bash
cd ~/proj/PACKAGE && git push origin --tags
```

### List tags sorted by version
```bash
cd ~/proj/PACKAGE && git tag --sort=-v:refname | head -10
```

## Environment Paths
- **Local (WSL)**: `~/.env-3.11/bin/activate`
- **NAS**: `~/.venv-3.11/bin/activate`
- **Spartan**: `~/python3.11/bin/python3.11` (no venv, user-local install)

## Troubleshooting

### Merge conflicts on NAS/Spartan
**WARNING: ALWAYS check diff contents before discarding anything.**
```bash
# Step 1: READ what's there (MANDATORY)
scitex dev versions diff --host nas -p PACKAGE
# or: ssh nas "cd ~/proj/PACKAGE && git diff && git status"

# Step 2: Decide — is it improvement, artifact, or obsolete?

# Step 3a: If improvement → commit it first
scitex dev versions commit --host nas -p PACKAGE -m "preserve: work from NAS" --confirm

# Step 3b: If artifact/obsolete → safe to stash or discard
ssh nas "cd ~/proj/PACKAGE && git stash && git checkout develop && git pull && git stash pop"
# or if truly disposable (ONLY after reading contents):
# ssh nas "cd ~/proj/PACKAGE && git checkout -- . && git clean -fd && git pull"
```

### Check installed version
```bash
pip show PACKAGE | grep Version
```

### Stale dist-info directories
If `importlib.metadata` reports wrong version (e.g., old version instead of current):
```bash
# Find all dist-info for the package
ls ~/.env-3.11/lib/python3.11/site-packages/PACKAGE_NAME-*.dist-info
# Remove stale ones (keep only the current version)
rm -rf ~/.env-3.11/lib/python3.11/site-packages/PACKAGE_NAME-OLD_VERSION.dist-info
```
