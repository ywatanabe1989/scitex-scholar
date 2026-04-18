# Self-Management

## Context Monitoring

Check context usage via claude-hud in the vterm status bar:
```
[Opus 4.6 (1M context) | Max] ████░░░░░░ 40%
```

1M context = ~1,000,000 tokens. 40% = ~400K tokens used.
System reminders (skills list) consume significant tokens each turn.

## Self-Compact

### If running in Emacs vterm
Use eval_elisp to send /compact to your own buffer:
```elisp
(with-current-buffer "YOUR-BUFFER"
  (vterm-send-string "/compact")
  (vterm-send-return)
  (sit-for 5)
  (vterm-send-string "continue")
  (vterm-send-return))
```

### If running in screen (cldm)
Cannot directly self-compact. Workaround:
1. Create a vterm that attaches to the screen session:
   ```elisp
   (let ((buf (vterm (generate-new-buffer-name "master-view"))))
     (with-current-buffer buf
       (vterm-send-string "screen -x cld-master")
       (vterm-send-return))
     (buffer-name buf))
   ```
2. Then send /compact via the "master-view" buffer

### Auto-compact hook (PostToolUse)
A hook at `~/.dotfiles/src/.claude/to_claude/hooks/post-tool-use/auto_compact.sh`:
- Counts every PostToolUse invocation (per-session counter in /tmp/)
- Every 30 invocations, sends `/compact` via `screen -X stuff` (screen sessions only)
- Sends `continue` 3 seconds later in background
- Registered in settings.json with `matcher: ".*"`

### Auto-compact bug (as of 2026-03)
- Known Anthropic issue (#31828, #34925, #38483)
- No CLI flag to configure auto-compact threshold
- Settings key `autoCompactEnabled` is not recognized
- Workaround: manual self-compact via vterm, or PostToolUse hook (above)

## Self-Restart

restart-loop.sh at ~/proj/master-agent/restart-loop.sh:
- /exit triggers restart with Telegram reconnection
- `touch /tmp/cld-master-stop` prevents restart
- Max 100 restarts, 3s delay between

## Permissions

### CLI flag (recommended)
Add to cld launch command: `--permission-mode auto`

### Settings.json broad permissions
```json
"allow": ["Bash(*)", "Edit(*)", "Write(*)", "mcp__scitex__*"]
```

### Known issue
Even with broad permissions in settings.json, permission prompts may still appear.
The `--permission-mode` CLI flag is more reliable.
