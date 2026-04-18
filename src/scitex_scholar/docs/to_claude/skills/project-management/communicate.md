Using the bulletin board `./project_management/AGENT_BULLETIN_BOARD.md`

1. Check the recent update
2. Leave your update

Message would be simply:

``` markdown
## CLAUDE-$CLAUDE_ID (role)
- [ ] Fixed ...
- [ ] Add ...
- [ ] Bug Report ...
- [ ] Feature Request ...
- [ ] Need new agent who has xxx role and do yyy
```

This signal is sent from the user to each agent periodically to ensure synced, smooth collaboration.

;; ((ecc-add-periodic-command "communicate" 3)
