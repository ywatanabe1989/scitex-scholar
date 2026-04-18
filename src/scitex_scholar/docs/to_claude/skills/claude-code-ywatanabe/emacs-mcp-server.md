# Emacs MCP Server

Repo: `~/proj/emacs_mcp_server/`

## Working Tools
- `eval_elisp` — always works, use as primary fallback

## Broken Tools (as of 2026-03-26)
- `list_buffers` — returns `{'buffers': [], 'total_count': 0}` even when buffers exist
- `list_vterm_buffers` — fails: `parse_vterm_buffer_list` is not defined
- `create_vterm_buffer` — fails: `parse_vterm_creation_result` is not defined
- `send_command_to_vterm` — fails if no vterm is current: "Current buffer is not a vterm buffer"
- `get_vterm_output` — fails: `parse_output_result` is not defined

**Root cause:** All `_parse_*` methods in `_VTermManager.py` are placeholder stubs — functions are referenced but never defined. The elisp execution works, but results are never parsed.

## Workaround: Use eval_elisp Directly

```python
# Create vterm
(vterm "my-buffer-name")

# Send command
(with-current-buffer "my-buffer-name"
  (vterm-send-string "your command")
  (vterm-send-return))

# Read output (last N chars)
(with-current-buffer "my-buffer-name"
  (buffer-substring-no-properties
    (max (- (point-max) 1000) (point-min))
    (point-max)))

# List all buffers
(mapcar (function buffer-name) (buffer-list))

# List only vterm buffers
(mapcar #'buffer-name
  (seq-filter (lambda (b)
    (with-current-buffer b (derived-mode-p 'vterm-mode)))
    (buffer-list)))

# Read non-empty lines (last 10) from vterm
(with-current-buffer "BUFFER"
  (let* ((content (buffer-substring-no-properties (point-min) (point-max)))
         (lines (seq-filter
                  (lambda (l) (not (string-empty-p (string-trim l))))
                  (split-string content "\n")))
         (last-lines (last lines 10)))
    (mapconcat #'identity last-lines "\n")))

# Create vterm + send command in one step
(let ((buf (vterm (generate-new-buffer-name "my-agent"))))
  (with-current-buffer buf
    (vterm-send-string "cld")
    (vterm-send-return))
  (buffer-name buf))
```

## New Tools Needed

### `get_vterm_output_clean` — strip trailing whitespace
```elisp
(with-current-buffer "BUFFER"
  (let* ((content (buffer-substring-no-properties (point-min) (point-max)))
         (lines (split-string content "\n"))
         (trimmed (mapcar #'string-trim-right lines))
         (cleaned (string-join (reverse (seq-drop-while #'string-empty-p (reverse trimmed))) "\n")))
    cleaned))
```

### `get_vterm_state` — check if Claude Code is idle before sending commands
```elisp
(with-current-buffer "BUFFER"
  (let* ((content (buffer-substring-no-properties
                   (max (- (point-max) 200) (point-min)) (point-max)))
         (trimmed (string-trim-right content))
         (last-line (car (last (split-string trimmed "\n")))))
    (list :last-line last-line
          :has-prompt (string-match-p "^❯" last-line)
          :is-thinking (string-match-p "thinking\\|Thinking\\|Running" last-line)
          :ready (and (string-match-p "^❯" last-line)
                      (not (string-match-p "thinking\\|Running" last-line))))))
```

Use `get_vterm_state` before `self-compact` to ensure Claude Code is at the `❯` prompt and not mid-task.

### `self_compact` — compound tool
1. Get vterm state (check `❯` prompt, not thinking)
2. If ready: send `/compact` + delay + `continue` message
3. If busy: wait and retry, or return error

## Architecture

```
~/.emacs.d/lisp/emacs-claude-code/   ← Elisp: vterm state detection, self-compact logic
~/proj/emacs_mcp_server/              ← Python: MCP server exposing tools to Claude Code
```

Elisp defines the functions, MCP server calls them via `emacsclient --eval`.

## Fix Plan

### Elisp side (`~/.emacs.d/lisp/emacs-claude-code/`)
1. Add `emacs-claude-code-vterm-state` function (detect `❯` prompt, thinking state)
2. Add `emacs-claude-code-vterm-output-clean` function (trimmed output getter)
3. Add `emacs-claude-code-self-compact` function (state check → /compact → continue)

### Python MCP side (`~/proj/emacs_mcp_server/`)
File: `src/emacs_mcp_server/vterm/_VTermManager.py`
1. Replace `vterm--process-alive-p` with `process-live-p` (public API)
2. Implement real elisp result parsers (parse plist format `:key value`)
3. Add `get_vterm_output_clean` tool → calls elisp function
4. Add `get_vterm_state` tool → calls elisp function
5. Add `self_compact` compound tool → calls elisp function

## Gotchas
- vterm in Emacs sources `~/.bashrc`, NOT `~/.bash_profile` — Bun/other tools need PATH in bashrc
- Sending text to a vterm running Claude Code becomes a prompt input, not a shell command
- Use Ctrl-C (`vterm-send-key "c" nil nil t`) to exit Claude Code before sending shell commands

## Additional Gotchas (2026-03-26)
- **MCP reconnect does NOT reload Python modules** — code changes need full Claude Code restart
- **server.py is 626 lines** (over 512) — needs refactoring before adding tools
- `claude plugin install` works from CLI — no interactive `/plugin install` needed
- `list_buffers` returns empty — separate bug in buffer module
- Context % should come from plugin stdin API, not terminal parsing (see claude-hud)
- Bun PATH: now in `~/.bash.d/all/001_ENV_PATH.src`
