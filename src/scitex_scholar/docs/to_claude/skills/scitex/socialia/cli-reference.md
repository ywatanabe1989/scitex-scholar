---
description: Complete CLI reference for socialia — posting, scheduling, analytics, and management.
---

# CLI Reference

```bash
# Posting
socialia post "Hello world!" --platform twitter
socialia thread <file> --platform twitter
socialia delete <post-id> --platform twitter

# Status & Discovery
socialia status                  # Show all platform connection status
socialia check                   # Verify connections to all platforms
socialia me                      # Get authenticated user info
socialia feed                    # Get recent posts from platforms
socialia setup                   # Show platform setup instructions

# Scheduling
socialia schedule list
socialia schedule cancel <id>
socialia schedule run
socialia schedule daemon
socialia schedule update-source

# Analytics (Google Analytics)
socialia analytics track <event_name>
socialia analytics realtime
socialia analytics pageviews [--start <date>] [--end <date>]
socialia analytics sources [--start <date>] [--end <date>]

# Growth
socialia grow                    # Discover and follow users

# Org mode
socialia org                     # Org mode draft management

# YouTube
socialia youtube                 # YouTube batch operations

# MCP server
socialia mcp start
socialia mcp list-tools
socialia mcp doctor

# Introspection
socialia list-python-apis [-v]
```
