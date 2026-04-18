# Self-Identify Vterm Buffer

## Problem
After compaction or context loss, a Claude Code agent loses track of which Emacs vterm buffer it is running in. This prevents self-management tasks like `/reload-plugins` when the Telegram channel listener dies.

## Pattern: Keyword Echo + Buffer Search

### Step 1: Echo a unique keyword into your own terminal
```bash
echo "CLAUDE_VTERM_ID_$(date +%s)"
```
This prints a unique timestamp-tagged marker into the vterm scrollback. Save the exact keyword you echoed (e.g., `CLAUDE_VTERM_ID_1743292800`).

### Step 2: Search all vterm buffers for the keyword via eval_elisp
```elisp
(let (result)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (eq major-mode 'vterm-mode)
        (when (save-excursion
                (goto-char (point-min))
                (search-forward "CLAUDE_VTERM_ID_1743292800" nil t))
          (push (buffer-name buf) result)))))
  result)
```
Replace `CLAUDE_VTERM_ID_1743292800` with your actual echoed keyword. This returns a list of matching vterm buffer names (should be exactly one).

### Step 3: Send commands to your own vterm
Once you know your buffer name, use the MCP tool:
```
mcp__emacs-server__send_command_to_vterm(buffer_name="your-vterm-name", command="/reload-plugins")
```
Or via eval_elisp:
```elisp
(with-current-buffer "your-vterm-name"
  (vterm-send-string "/reload-plugins")
  (vterm-send-return))
```

## Use Cases
- `/reload-plugins` when Telegram channel listener dies after compaction
- Self-compact recovery (need to know own buffer to verify prompt state)
- Agent self-restart via `/exit` in the correct vterm
- Any post-compaction self-management requiring terminal access

## Proposed MCP Tool: `identify_own_vterm`

A future `emacs-server` MCP tool should automate this 3-step pattern into a single call:

```
identify_own_vterm(keyword_prefix="CLAUDE_VTERM_ID")
```

Behavior:
1. Generate a unique keyword: `{prefix}_{timestamp}_{random}`
2. Echo it into the calling agent's stdin (requires stdin API access or cooperative echo)
3. Search all vterm buffers for the keyword
4. Return the matching buffer name

See GitHub Issue: ywatanabe1989/todo -- "MCP tool: identify-own-vterm for Claude Code self-management"

## Limitations
- Step 1 (echo) must happen via Bash tool in the agent's own session -- it cannot be done via eval_elisp because eval_elisp runs in Emacs, not in the agent's terminal
- The keyword must be unique enough to avoid false matches across agents
- Scrollback buffer size limits may cause old keywords to be lost; re-echo if needed
