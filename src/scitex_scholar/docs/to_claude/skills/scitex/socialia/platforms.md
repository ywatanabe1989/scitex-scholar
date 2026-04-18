---
description: Supported platforms — Twitter/X, LinkedIn, Reddit, Slack, YouTube.
---

# Supported Platforms

| Platform | Class | Features |
|----------|-------|----------|
| Twitter/X | `Twitter` | Post, thread, media |
| LinkedIn | `LinkedIn` | Post, articles |
| Reddit | `Reddit` | Post, subreddit targeting |
| Slack | `Slack` | Channel messages |
| YouTube | `YouTube` | Video metadata |
| Google Analytics | `GoogleAnalytics` | Analytics data |

## Org-file Workflow

```python
from socialia import move_to_scheduled, move_to_posted, ensure_project_dirs

# Manage content lifecycle via org files
ensure_project_dirs("/path/to/project")
move_to_scheduled("post.org")  # Draft → Scheduled
move_to_posted("post.org")     # Scheduled → Posted
```

## MCP Platform Strategies

```python
from socialia import PLATFORM_STRATEGIES
# Platform-specific content adaptation for AI agents
```
