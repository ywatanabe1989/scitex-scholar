---
name: pull-request
description: Create pull requests for external and internal projects. Handles fork setup, branch conventions, commit style matching, and hook management. Use when contributing to any repository via PR.
---

# Pull Request Skill

## When to Use
- Contributing to any repository via PR (external or internal)

## Principles

1. **Minimal change** — Touch only what's necessary for the feature/fix
2. **Follow their conventions** — Their style, not ours
3. **Atomic PR** — One PR = one feature/fix. Never mix concerns
4. **Read first, code second** — CONTRIBUTING.md, README (how to contribute section), existing PRs

## Workflow

### 1. Read Their Rules
```bash
cat CONTRIBUTING.md .github/CONTRIBUTING.md README.md 2>/dev/null | head -200
git -C /full/path log --oneline -20    # commit message style
git -C /full/path branch -r | head -20 # branch naming
ls .github/PULL_REQUEST_TEMPLATE* 2>/dev/null
```

### 2. Bypass Our Claude Code Hooks for External Projects
Our Claude Code hooks (ruff auto-format, line-limit, pytest-fullpath,
git-C enforcement) WILL corrupt external codebases by reformatting their
files to our style. This is the #1 source of dirty PRs.

**Offending hooks (defined in `.claude/hooks/settings.json`):**
- PostToolUse `format_code.sh` — ruff/black auto-format on Write|Edit
- PostToolUse `run_lint.sh` — linter auto-fix on Write|Edit
- PreToolUse `limit_line_numbers.sh` — blocks files >512 lines
- PreToolUse `enforce_pytest_fullpath.sh` — blocks relative pytest paths
- PreToolUse `enforce_git_dash_C.sh` — blocks git without -C flag

**Solution: Start Claude Code with `cc --disable-hooks`**

This sets `CLAUDE_CODE_DISABLE_HOOKS=true` via `_cld_start_session`
in `~/.bash.d/all/010_claude/010_claude_session.src`, which disables
ALL PreToolUse and PostToolUse hooks (ruff, lint, line-limit, etc.).

```bash
# Start session with hooks disabled
cc --disable-hooks
```

If already in a session WITH hooks enabled, you must exit and restart
with `--disable-hooks`. Setting the env var inside Bash tool mid-session
does NOT retroactively disable Claude Code hooks.

**Fallback if hooks are active (can't restart):**
Use Bash tool with python3 for file edits to bypass Write|Edit matchers:
```bash
python3 -c "
from pathlib import Path
p = Path('src/their_file.py')
t = p.read_text()
t = t.replace('old_code', 'new_code')
p.write_text(t)
"
```

**Always verify diff is minimal before pushing:**
```bash
git -C /full/path diff HEAD~1 -- src/ | head -60
```

**Recovery if hooks already reformatted:**
```bash
git -C /full/path checkout main -- src/their_file.py
# Then re-apply only your changes
```

### 3. Fork and Branch
```bash
# Fork (--clone=false if repo already cloned)
GH_TOKEN="<token>" gh repo fork <owner>/<repo> --clone=false

# Add fork as remote with token auth for push
git -C /full/path remote add fork https://<username>:<token>@github.com/<username>/<repo>.git

# Create branch matching their naming convention
git -C /full/path checkout -b <their-branch-naming-style>
```

### 4. Code, Commit, Push
- Match their commit message format (check `git log --oneline -20`)
- Match their code style / linter / formatter (run theirs, not ours)
- Run their tests (full suite, not just new tests)
- Rebase on their latest main

```bash
# Stage only your files (never git add -A on external repos)
git -C /full/path add src/specific_file.py tests/test_specific.py

# Commit matching their style
git -C /full/path commit -m "Their style commit message"

# Push to YOUR fork, not origin
git -C /full/path push -u fork <branch>
```

### 5. Create PR

#### Token Requirements for External Repos
Fine-grained PATs scoped to your own repos CANNOT create PRs/issues on
external repos. You need either:
- A **classic PAT** with `public_repo` scope
- A fine-grained PAT with "All repositories" access

If the token lacks permission, provide the user with a direct compare URL:
```
https://github.com/<owner>/<repo>/compare/main...<your-username>:<repo>:<branch>
```

#### Creating the PR
```bash
GH_TOKEN="<classic-pat>" gh pr create \
  --repo <owner>/<repo> \
  --head <your-username>:<branch> \
  --base main \
  --title "Short title" \
  --body "$(cat <<'EOF'
## Summary
What and why (1-3 lines).

## Test Plan
How to verify.

Fixes #123
EOF
)"
```

#### If gh CLI fails (token scope issue), use REST API:
```bash
curl -s -X POST \
  -H "Authorization: token <classic-pat>" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/<owner>/<repo>/pulls \
  -d '{"title":"...","head":"<user>:<branch>","base":"main","body":"..."}'
```

#### If both fail, give the user the compare URL to create manually.

## Rules

- **Read CONTRIBUTING.md** before touching code
- **One PR, one concern** — never bundle unrelated changes
- **Their style wins** — commit format, code style, test framework, test runner
- **Minimal diff** — no drive-by cleanups, no extra files
- **Rebase before submit** — clean history on their latest main
- **Use `git -C`** for all git commands
- **Push to fork remote** — never push to origin (upstream)
- **Run their full test suite** — verify zero regressions before PR
- **Token awareness** — check token scope early, don't waste time on auth failures


## PR Template

When PR template does not exist in target project, use this as an template.

```
## Summary
<!-- What this PR does and why. 1-3 lines. -->

## Changes
<!-- Key changes, briefly. -->

## Test Plan
<!-- How you verified this works. -->

## Checklist
- [ ] Follows existing code style
- [ ] Tests pass
- [ ] Documentation updated (if applicable)
```
