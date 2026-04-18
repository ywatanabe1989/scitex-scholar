---
description: Master-worker architecture for Claude Code with Telegram
---

# Master-Worker Architecture

## Architecture

```
~/proj/                        <- master agent + Telegram bot (cld-master)
├── scitex-cloud/              <- screen: cld-scitex-cloud
├── scitex-python/             <- screen: cld-scitex-python
├── scitex-ui/                 <- screen: cld-scitex-ui
└── scitex-app/                <- screen: cld-scitex-app
```

One Telegram bot, one master at `~/proj`, workers in screen sessions per project.

## Shell Commands

Source: `~/.bash.d/all/010_claude/020_claude_agents_in_screen.src`

| Command | Description |
|---------|-------------|
| `cld_master` | Master + Telegram at `~/proj` (screen `cld-master`) |
| `cld_screen <project>` | Worker in screen for a project |
| `cld_screen_all [projects]` | Start multiple workers (auto-detect if none) |
| `cld_screen_ls` | List running agents |
| `cld_screen_stop [projects]` | Stop agents |
| `cld_screen_attach <project>` | Attach to screen |
| `cld_screen_send <project> "msg"` | Send text to agent terminal |

## Key Implementation Details

- Screen sessions use `cld-` prefix (e.g., `cld-master`, `cld-scitex-cloud`)
- Must `unset CLAUDE_ID` before calling `_cld_start_session` in screen — otherwise the guard at line 268 silently aborts
- Uses `bash --rcfile` + `screen -X stuff` pattern to get interactive bash with all functions loaded
- `sleep 2` between screen creation and command stuffing to let bash initialize
- Telegram token loaded from `~/.claude/channels/telegram/.env`

## Typical Workflow

```bash
cld_screen scitex-cloud scitex-python scitex-ui scitex-app
cld_master                    # Telegram hub
cld_screen_send scitex-cloud "run tests"
cld_screen_attach scitex-cloud
cld_screen_stop               # stop all
```

## Telegram Orchestration

The master agent can orchestrate work entirely from Telegram:

**Capabilities demonstrated:**
- Receive commands via Telegram messages
- Plot figures (SciTeX MCP) and send images back to Telegram
- Speak via TTS (scitex audio_speak)
- Launch Claude Code instances in Emacs vterm buffers
- Monitor vterm output of launched agents
- Coordinate multiple MCP servers (Telegram + Emacs + SciTeX)

**Launching agents via Emacs vterm (eval_elisp):**
```elisp
;; Launch a new Claude instance
(let ((buf (vterm (generate-new-buffer-name "agent-name"))))
  (with-current-buffer buf
    (vterm-send-string "cld")
    (vterm-send-return))
  (buffer-name buf))

;; Check agent output (non-empty lines only)
(with-current-buffer "agent-name"
  (let* ((content (buffer-substring-no-properties (point-min) (point-max)))
         (lines (seq-filter
                  (lambda (l) (not (string-empty-p (string-trim l))))
                  (split-string content "\n")))
         (last-lines (last lines 10)))
    (mapconcat #'identity last-lines "\n")))

;; Send a prompt to a running Claude instance
(with-current-buffer "agent-name"
  (vterm-send-string "your prompt here")
  (vterm-send-return))
```

**Use vterm over screen when:** Emacs is running and you need real-time output monitoring from the master agent. Screen is better for persistent sessions that survive Emacs restarts.
