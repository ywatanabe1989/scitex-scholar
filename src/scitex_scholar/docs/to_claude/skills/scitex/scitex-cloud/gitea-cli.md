---
description: Gitea Git hosting CLI — repository management, fork, clone, PR, issue, push/pull, auth. Backend is git.scitex.ai via the `tea` CLI wrapper.
---

# Gitea CLI

All commands under `scitex-cloud gitea`. Backend: `git.scitex.ai` (wraps the `tea` CLI).

## Authentication

```bash
scitex-cloud gitea login    # authenticate with Gitea
scitex-cloud gitea logout   # clear credentials
```

## Repository Management

```bash
scitex-cloud gitea create <name>           # create repo on Gitea
scitex-cloud gitea list                    # list your repos
scitex-cloud gitea search <query>          # search repos
scitex-cloud gitea clone <user/repo>       # clone from Gitea
scitex-cloud gitea fork <user/repo>        # fork a repo
scitex-cloud gitea delete <user/repo>      # delete a repo
scitex-cloud gitea status                  # show current repo status
```

## Collaboration

```bash
# Pull requests
scitex-cloud gitea pr create               # open a PR
scitex-cloud gitea pr list                 # list open PRs

# Issues
scitex-cloud gitea issue create            # create an issue
scitex-cloud gitea issue list              # list issues

# Sync committed changes
scitex-cloud gitea push [remote] [branch]  # push to Gitea
scitex-cloud gitea pull [remote] [branch]  # pull from Gitea
```

## MCP Tools

| Tool | What it does |
|------|-------------|
| `cloud_repo_login` | Authenticate with Gitea |
| `cloud_repo_create` | Create repository |
| `cloud_repo_list` | List repositories |
| `cloud_repo_search` | Search repositories |
| `cloud_repo_clone` | Clone repository |
| `cloud_repo_fork` | Fork repository |
| `cloud_repo_delete` | Delete repository |
| `cloud_repo_status` | Repository status |
| `cloud_repo_push` | Push commits to Gitea |
| `cloud_repo_pull` | Pull commits from Gitea |
| `cloud_repo_pr_create` | Create pull request |
| `cloud_repo_pr_list` | List pull requests |
| `cloud_repo_issue_create` | Create issue |
| `cloud_repo_issue_list` | List issues |

## Notes

- `push`/`pull` here are git-level operations on committed changes.
  For uncommitted working file sync, see [sync-architecture.md](sync-architecture.md).
- `tea` binary must be installed: `~/.local/bin/tea`
  Install: `wget https://dl.gitea.com/tea/0.9.2/tea-0.9.2-linux-amd64 -O ~/.local/bin/tea && chmod +x ~/.local/bin/tea`

## Examples

```bash
scitex-cloud gitea login
scitex-cloud gitea create my-new-repo
scitex-cloud gitea clone ywatanabe/my-new-repo
cd my-new-repo
# ... make changes, git commit ...
scitex-cloud gitea push
scitex-cloud gitea pr create
```

# EOF
