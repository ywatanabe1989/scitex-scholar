---
topic: full-update
package: scitex-dev
description: >
  Full ecosystem release workflow — pre-flight checks, version bump, PyPI publish,
  local sync, NAS deploy (including scitex-cloud special handling), and verification.
  Use via /update-scitex-full command.
---

# Full Ecosystem Update

End-to-end release pipeline for all SciTeX packages. Follow phases strictly in order;
steps within a phase may run in parallel via subagents.

## Packages

Retrieved programmatically from the ecosystem config — never hard-code the list.

```python
from scitex_dev.config import load_config
config = load_config()
packages = list(config.ecosystem.keys())  # canonical list
```

Or via MCP: `mcp__scitex__dev_ecosystem_list` returns all registered packages.

Skip alpha/beta packages (e.g., scitex-cloud) unless explicitly requested.

## Full Update Levels (1–5)

Each level includes ALL steps from the previous level.

| Level | Scope | Steps |
|-------|-------|-------|
| 1 | **Local** | diff check -> bump `pyproject.toml` + `__init__.py` -> commit -> `git tag vX.Y.Z` -> `git push origin develop --tags` |
| 2 | **GitHub Release** | Level 1 + `gh release create vX.Y.Z --generate-notes` |
| 3 | **PyPI** | Level 2 + verify `publish-pypi.yml` triggered (or manual `twine upload` for first publish) + confirm version on PyPI |
| 4 | **Hosts** | Level 3 + `pip install -e .` locally + `mcp__scitex__dev_ecosystem_sync` (NAS, Spartan) + verify remote versions |
| 5 | **Skills** | Level 4 + `scitex-dev skills export` (stamps MANIFEST.md version from pyproject.toml) |

Pick the highest applicable level. Most packages need Level 4.
Packages with `_skills/` directories need Level 5.

---

## Phase 1: Pre-flight

**Goal:** Ensure every repo is in a releasable state before touching versions.

### 1. check_ci — Verify GitHub Actions pass

- **Python**: `from scitex_dev.ci import check_ci, get_failing_packages`
  - `check_ci(packages=None)` → `{pkg: CIStatus}`
  - `get_failing_packages(packages=None)` → `list[str]`
- **CLI**: `gh run list -R ywatanabe1989/PACKAGE --limit 3`
- **MCP**: `mcp__scitex__dev_ecosystem_list` (includes CI-adjacent version checks)

If any package is failing, fix CI before proceeding. Do not skip.

### 2. detect_mismatches — Find version inconsistencies

- **Python**: `from scitex_dev.fix import detect_mismatches`
  - `detect_mismatches(packages=None)` → `{pkg: {status, issues, local, git, remote}}`
- **CLI**: `scitex-dev ecosystem fix-mismatches --dry-run`
- **MCP**: `mcp__scitex__dev_ecosystem_fix_mismatches(confirm=False)`

### 3. fix_init_version — Sync `__init__.py` with `pyproject.toml`

- **Python**: `from scitex_dev.fix import fix_init_version`
  - `fix_init_version(package_path, confirm=False)` → `{toml_version, init_version, action, status}`
- **CLI**: manual `sed` or editor
- **MCP**: via `fix_init_version` Python API (planned as MCP tool)

These block PyPI publish. Fix and commit before bumping.

### 4. verify_pypi_config — Check trusted publisher setup

- **Python**: `from scitex_dev.ci import verify_pypi_config, verify_all_pypi_configs`
  - `verify_pypi_config(repo)` → `{repo, workflow_exists, needs_first_publish}`
  - `verify_all_pypi_configs(packages=None)` → `{pkg: {...}}`
- **CLI**: `gh api repos/ywatanabe1989/PACKAGE/actions/workflows`
- **MCP**: via `mcp__scitex__dev_ecosystem_list` (planned)

First-publish packages need manual `twine upload` before OIDC works.

---

## Phase 2: Version Bump + Release

**Goal:** Bump, tag, release, and publish to PyPI. Independent packages run in parallel.

### 5. determine_bump_type — Check diff and classify as minor/patch

- **Python**: `from scitex_dev.fix import determine_bump_type`
  - `determine_bump_type(package_path)` → `{has_diff, commits_since_tag, has_feat, bump_type, current_version, suggested_version}`
- **CLI**:
  ```bash
  git -C ~/proj/PACKAGE diff $(git -C ~/proj/PACKAGE describe --tags --abbrev=0)..HEAD --stat
  git -C ~/proj/PACKAGE log $(git -C ~/proj/PACKAGE describe --tags --abbrev=0)..HEAD --oneline
  ```
- **MCP**: `mcp__scitex__dev_ecosystem_list` (includes `commits_since_tag` field)

**Rule: If HEAD differs from the last tag, version MUST be incremented.**

- Any `feat:` commit → **minor** bump
- Otherwise (fix, chore, docs, refactor) → **patch** bump
- Identical to last tag (no diff) → **skip** (only case where skipping is allowed)

### 6. bump_version — Edit `pyproject.toml` and `__init__.py`

- **Python**: `from scitex_dev.fix import bump_version`
  - `bump_version(package_path, new_version, confirm=False)` → `{old_version, new_version, toml_updated, init_updated, status}`
- **CLI**: `sed -i 's/^version = "OLD"/version = "NEW"/' pyproject.toml`
- **MCP**: via `mcp__scitex__dev_ecosystem_fix_mismatches` (planned)

### 7. verify_docs_and_skills — Ensure docs/skills match codebase

- **Python**: `from scitex_dev.skills import verify_docs_and_skills`
  - `verify_docs_and_skills(package_path=None)` → `{skills_stale, stale_files, readme_version_match, issues, status}`
- **CLI**: `scitex-dev skills export --dry-run` (preview skill changes)
- **MCP**: via `mcp__scitex__dev_ecosystem_list` (planned)

Check before pushing:
- Skill files reference functions that actually exist
- API examples in skills are runnable
- CLI commands in skills match `--help` output

If stale, update and commit before tagging.

### 8. commit_and_tag — Commit version bump and tag

- **Python**: `subprocess` (no convenience wrapper — git is the tool)
- **CLI**:
  ```bash
  git -C ~/proj/PACKAGE add pyproject.toml src/
  git -C ~/proj/PACKAGE commit -m "chore: bump version to X.Y.Z"
  git -C ~/proj/PACKAGE tag -a vX.Y.Z -m "Release vX.Y.Z"
  ```
- **MCP**: not applicable

### 9. check_ci_before_push — Last CI gate before push

- **Python**: `from scitex_dev.ci import check_ci`
  - `check_ci(packages=["PACKAGE"])` → `{pkg: CIStatus}`
- **CLI**: `gh run list -R ywatanabe1989/PACKAGE --limit 1`
- **MCP**: `mcp__scitex__dev_ecosystem_list` (check status field)

If failures found, fix now. This is the last opportunity before release.

### 10. push — Push commit and tags

- **Python**: `subprocess`
- **CLI**: `git -C ~/proj/PACKAGE push origin develop --tags`
- **MCP**: not applicable

### 11. create_github_release — Create release on GitHub

- **Python**: `from scitex_dev.ci import create_github_release`
  - `create_github_release(repo, tag, generate_notes=True, confirm=False)` → `{repo, tag, url, status}`
- **CLI**: `gh release create vX.Y.Z --repo ywatanabe1989/PACKAGE --generate-notes`
- **MCP**: via `mcp__scitex__dev_ecosystem_list` (planned)

### 12. wait_for_pypi — Watch PyPI publish (background)

- **Python**: `from scitex_dev.ci import wait_for_workflow, check_pypi_publish`
  - `wait_for_workflow(repo, workflow="publish-pypi.yml", timeout=600, poll_interval=30)` → `WorkflowRun | None`
  - `check_pypi_publish(repo)` → `WorkflowRun | None`
- **CLI**:
  ```bash
  run_id=$(gh run list -R ywatanabe1989/PACKAGE -w publish-pypi.yml --limit 1 --json databaseId -q '.[0].databaseId')
  gh run watch "$run_id" -R ywatanabe1989/PACKAGE  # run_in_background=true
  pip index versions PACKAGE 2>/dev/null | head -1  # verify after completion
  ```
- **MCP**: via `wait_for_workflow` Python API (planned as MCP tool)

Launch as background task. Do not block.
Failure: no workflow → `twine upload dist/*` | failed → `gh run view --log-failed` | timeout → check GitHub Actions page.

---

## Phase 3: Local Sync

**Goal:** Update the local dev environment to match published versions.

### 13. fix_local — Reinstall bumped packages locally

- **Python**: `from scitex_dev.fix import fix_local`
  - `fix_local(packages=["figrecipe", "scitex-dev"], confirm=True)` → `{pkg: {status, output}}`
- **CLI**: `pip install -e ~/proj/PACKAGE`
- **MCP**: `mcp__scitex__dev_ecosystem_sync_local(packages=["..."], confirm=True)`

### 14. verify_versions — Confirm local versions aligned

- **Python**: `from scitex_dev.fix import verify_versions`
  - `verify_versions(packages=None)` → `{pkg: "ok" | "mismatch: ..."}`
- **CLI**: `scitex-dev ecosystem fix-mismatches --dry-run` (should show no mismatches)
- **MCP**: `mcp__scitex__dev_ecosystem_list` (all statuses should be "ok")

All packages must show "ok" before proceeding.

---

## Phase 4: Host Sync (NAS)

**Goal:** Deploy updated packages to remote hosts.

### 15. fix_remote — [Custom] Sync packages to NAS

- **Python**: `from scitex_dev.fix import fix_remote`
  - `fix_remote(hosts=["nas"], packages=None, install=True, confirm=True)` → `{host: {pkg: {status}}}`
  - Timeout fallback: `fix_remote(hosts=["nas"], install=False, confirm=True)`
- **CLI**: `scitex-dev ecosystem sync --host nas --confirm`
- **MCP**: `mcp__scitex__dev_ecosystem_sync(hosts=["nas"], confirm=True)`

### 16. deploy_scitex_cloud — [Custom] scitex-cloud NAS deploy

- **Python**: `from scitex_dev.deploy import deploy_scitex_cloud`
  - `deploy_scitex_cloud(host="nas", branch="develop", confirm=False)` → `{host, commands, outputs, status}`
- **CLI**:
  ```bash
  ssh nas "cd ~/proj/scitex-cloud && git pull origin develop"
  ssh nas "cd ~/proj/scitex-cloud && docker compose stop"
  ssh nas "cd ~/proj/scitex-cloud && npm install && npx vite build"
  ssh nas "cd ~/proj/scitex-cloud && docker compose up -d"
  ```
- **MCP**: via `deploy_scitex_cloud` Python API (planned as MCP tool)

**Important:** Stop Docker before Vite build to avoid OOM on NAS.

### 17. verify_production — [Custom] Check scitex.ai is live

- **Python**: `from scitex_dev.deploy import verify_production`
  - `verify_production(url="https://scitex.ai", timeout=10)` → `{url, status_code, status}`
- **CLI**: `curl -s -o /dev/null -w "%{http_code}" https://scitex.ai`
- **MCP**: `mcp__scitex__capture_screenshot(url="https://scitex.ai")`

---

## Phase 5: Verification

**Goal:** Confirm everything is consistent and working. Every check must PASS.

### 18. verify_versions — Final ecosystem status check

- **Python**: `from scitex_dev.fix import verify_versions`
  - `verify_versions()` → all must be `"ok"`
- **CLI**: `scitex-dev ecosystem fix-mismatches --dry-run`
- **MCP**: `mcp__scitex__dev_ecosystem_list`

### 19. check_readme — Verify READMEs reflect current codebase

For each released package, confirm README.md contains:
- Correct version number (matches pyproject.toml)
- Four Interfaces section (Python API, CLI, MCP Server, Skills)
- Installation instructions with current package name
- No stale API examples referencing removed functions

```bash
# Quick check: version in README
for repo in scitex-python figrecipe crossref-local scitex-writer scitex-dataset scitex-dev; do
  dir=~/proj/$repo
  ver=$(grep '^version' "$dir/pyproject.toml" | head -1 | sed 's/.*"\(.*\)"/\1/')
  in_readme=$(grep -c "$ver" "$dir/README.md" 2>/dev/null || echo 0)
  printf "%-20s ver=%s in_readme=%s\n" "$repo" "$ver" "$in_readme"
done
```

### 20. check_rtd — Verify Read the Docs builds

- **Python**: `from scitex_dev.rtd import check_all_rtd`
  - `check_all_rtd()` → `{pkg: {status, url, build_status}}`
- **CLI**: `scitex-dev rtd check`
- **MCP**: `mcp__scitex__docs_list`

All RTD builds must show "passing". If failing, check build logs and fix.

### 21. check_dashboard — Verify version dashboard loads

- **CLI**: `curl -s http://127.0.0.1:5000/api/versions | python3 -m json.tool | head -5`
- **MCP**: `mcp__scitex__capture_screenshot(url="http://127.0.0.1:5000/")`

Dashboard must show all packages with correct versions, no "Loading..." stuck state.

### 22. verify_production — [Custom] Visual verification

- **CLI**: `playwright-cli screenshot https://scitex.ai --viewport 1920x1080`
- **MCP**: `mcp__scitex__capture_screenshot(url="https://scitex.ai")`

Desktop + mobile viewport. Screenshot as proof.

### 23. report_summary — Generate summary table

```
Package             Old     New     PyPI    NAS     README  RTD     Status
scitex-python       2.27.0  2.27.1  ok      ok      ok      ok      PASS
figrecipe           0.28.0  0.28.1  ok      ok      ok      ok      PASS
...
```

---

## Parallel Execution Strategy

Launch one subagent per package (or batch of 2-3 small packages).
Use `GitHandlerAgent-SONNET` subagent type.
All agents must use `git -C /full/path` for git commands (hook requirement).

## Choice Presentation

When invoked via `/update-scitex-full`, present:

```
Current ecosystem state:
  Package           toml        tag         PyPI        diff   bump
  scitex-python     2.27.0      v2.27.0     2.27.0      0      skip
  figrecipe         0.28.0      v0.28.0     0.28.0      3      patch
  ...

Recommendation: Level 4 for all, Level 5 for scitex-dev

  1. Audit only (dry run)
  2. Local + GitHub Release
  3. + PyPI
  4. + Host sync          <-- recommended
  5. + Skills export
```

## Common Failure Modes

| Failure | Cause | Fix |
|---------|-------|-----|
| PyPI 403 | Trusted publisher not configured | Configure OIDC on pypi.org or `twine upload` for first publish |
| Duplicate wheel | Version already on PyPI | Bump to next patch, re-release |
| NAS OOM on Vite | Docker consuming memory | `docker compose stop` before build |
| `__init__.py` mismatch | Version not synced | `fix_init_version(path, confirm=True)` |
| Tag wrong commit | Tagged before fixing | `git tag -d vX.Y.Z && git tag -a vX.Y.Z HEAD && git push origin vX.Y.Z --force` |
| NAS conflicts | Uncommitted changes | `mcp__scitex__dev_ecosystem_diff` then commit or stash |
| NAS timeout | pip install >120s | `fix_remote(install=False)` then SSH pip manually |
