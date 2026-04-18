---
description: Emacs monitoring dashboard setup — ETM tabs, repo-monitor, org-mode status, Eisenhower matrix. Use when setting up or managing the Claude monitoring environment.
---

# Emacs Monitoring Dashboard

## Claude Monitoring Tab (ETM)

Create via `(ecc-create-monitoring-tab)` from `ecc-monitoring-tab.el`:
- Left: status.org (home buffer) — task status with inline Eisenhower plot
- Middle: *Repo Monitor* (semi-home) — real-time file change monitoring
- Right: own vterm (results) — see Claude's terminal output

### Self-Detection (vterm probe)
To find own vterm buffer:
1. Fast path: match buffer name containing "claude-instance"
2. Probe path: echo a unique UUID, then scan vterm buffers:
   ```bash
   echo "CLAUDE_PROBE_$(date +%s)_$$"
   ```
   Then in Emacs: `(ecc--probe-vterm-buffers "CLAUDE_PROBE_...")`

## Repo Monitor (emacs-monitor-repository)
- Package: `~/.emacs.d/lisp/emacs-monitor-repository/`
- Start: `(emr-start "~/proj/scitex-cloud")`
- Buffer: `*File Updates*`
- Load manually if not auto-loaded:
  ```elisp
  (load-file "~/.emacs.d/lisp/emacs-monitor-repository/emr/emr-core.el")
  (load-file "~/.emacs.d/lisp/emacs-monitor-repository/emacs-monitor-repository.el")
  ```
- Multiple repos:
  ```elisp
  (emr-start "~/proj/scitex-cloud")
  (emr-start "~/proj/scitex-ui")
  (emr-start "~/proj/scitex-paper-1st")
  ```
- Functions: `emr-start`, `emr-stop`, `emr-check-updates`
- Scroll fix: redefined process-filter to preserve `window-start` on updates

## Eisenhower Matrix
- Script: `GITIGNORED/tasks/eisenhower_plot.py`
- Parses status.org for TODO items with :IMPORTANCE: and :URGENCY: properties (1-5)
- Generates scatter plot with numbered labels and quadrant shading
- Embed in org: `[[file:eisenhower.png]]` with `#+STARTUP: inlineimages`
- Regenerate: `python /path/to/eisenhower_plot.py`

### Adding priorities to org TODO items:
```org
* TODO Task name
:PROPERTIES:
:IMPORTANCE: 4
:URGENCY: 3
:END:
```

## Org-Mode Status File
- Path: `GITIGNORED/tasks/status.org`
- Single source of truth for user-facing task status
- todo.md kept for internal use only
- Auto-revert keeps Emacs buffer in sync with file changes

## Key ETM API
- `(etm-new "TabName")` — create tab
- `(etm-buffer-set "home")` — register buffer type
- `(etm-navigation-jump-by-name "Claude")` — switch to tab
- `(delete-other-windows)` then `(split-window-right)` for layout
- `(balance-windows)` — equalize column widths

## Emacs Screenshot Self-Check
Capture the Emacs frame for visual verification:
```bash
# Get window ID from Emacs
window_id=$(emacsclient --eval '(frame-parameter nil (quote window-id))' | tr -d '"')
# Capture
import -window $window_id /tmp/emacs-screenshot.png
```
Or via MCP:
```elisp
(frame-parameter nil 'window-id)  ;; → "10485793"
```
Then: `import -window 10485793 /tmp/emacs-screenshot.png`

## Multi-Repo Monitoring
```elisp
(repo-monitor-add "~/proj/scitex-cloud" "cloud")
(repo-monitor-add "~/proj/scitex-ui" "ui")
(repo-monitor-remove "ui")        ;; stop one repo
(repo-monitor-filter "cloud")     ;; show only cloud changes
(repo-monitor-filter nil)         ;; show all
```
Files show with `[name]` prefix: `[cloud] src/apps/writer.py`

## Org-Mode TODO Keywords
```org
#+TODO: TODO IN-PROGRESS WAITING | DONE CANCELLED
```
`C-c C-t` cycles keywords. `|` separates active/done states.
