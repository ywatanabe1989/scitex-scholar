---
name: self-compact
description: Workaround for Claude Code auto-compact bug. Self-compact via Emacs MCP server.
---

## Self-Compact via Emacs MCP Server

When auto-compact fails (recent Claude Code bug), compact context yourself:

### Steps
1. Find your vterm buffer name:
   ```
   mcp__emacs-server__eval_elisp: (mapcar #'buffer-name (buffer-list))
   ```
   Look for a buffer matching `<project>-<digits>-<digits>-<digits>-<digits>`

2. Send `/compact` + follow-up in ONE call with delays:
   ```
   mcp__emacs-server__eval_elisp:
     code: |
       (let ((buf (get-buffer "<your-vterm-buffer-name>")))
         (when (and buf (buffer-live-p buf))
           (with-current-buffer buf
             (vterm-send-string "/compact")
             (vterm-send-return)
             (sit-for 2)
             (vterm-send-string "continue")
             (vterm-send-return)
             (list :success t :commands-sent 2))))
   ```

### Multi-Command with Delays Pattern
Use `eval_elisp` with `sit-for` to send sequential commands:
```elisp
(let ((buf (get-buffer "BUFFER-NAME")))
  (with-current-buffer buf
    (vterm-send-string "COMMAND-1")
    (vterm-send-return)
    (sit-for DELAY-SECONDS)
    (vterm-send-string "COMMAND-2")
    (vterm-send-return)
    (sit-for DELAY-SECONDS)
    (vterm-send-string "COMMAND-3")
    (vterm-send-return)))
```

### Key: sit-for delays
- `(sit-for 1)` = 1 second delay
- `(sit-for 2)` = 2 second delay
- Must be in ONE eval_elisp call — after /compact the buffer state changes
- send_command_to_vterm only sends ONE command — use eval_elisp for sequences

### MCP Reconnect Pattern
```elisp
(let ((buf (get-buffer "BUFFER-NAME")))
  (with-current-buffer buf
    (vterm-send-string "/mcp reconnect scitex")
    (vterm-send-return)))
```

### When to use
- Context is getting large and auto-compact hasn't triggered
- User says "compact" or context feels heavy
- NEVER ask the user to compact — do it yourself
- MCP server disconnected — reconnect yourself

### Notes
- `list_vterm_buffers` may fail with `vterm--process-alive-p` error — use `eval_elisp` instead
- `list_buffers` may return empty — use `eval_elisp` with `(buffer-list)` directly
- Always send commands in a SINGLE eval_elisp call with sit-for between them
