---
description: Basic social media posting — Twitter, LinkedIn, Reddit.
---

# Quick Start

```python
from socialia import Twitter, LinkedIn, Reddit, Slack, YouTube

# Post to Twitter/X
twitter = Twitter()
twitter.post("New paper published! #research")

# Post to LinkedIn
linkedin = LinkedIn()
linkedin.post("Excited to share our latest findings...")

# Post to Reddit
reddit = Reddit()
reddit.post("r/MachineLearning", "New approach to ...", body="...")

# Slack notification
slack = Slack()
slack.post("#general", "Experiment complete!")
```
