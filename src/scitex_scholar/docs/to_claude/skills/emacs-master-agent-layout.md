---
name: emacs-master-agent-layout
description: Mandatory 3-column Emacs dashboard layout for Master Agent sessions. Left=status.org, Middle=Repo Monitor, Right=vterm.
---

# Emacs Master Agent Layout

## Rule
**The 3-column layout MUST be Left=status.org, Middle=Repo Monitor, Right=vterm. No exceptions.**

## Layout

| Position | Buffer | Purpose |
|----------|--------|---------|
| Left | `status.org` | Progress tracking, task status |
| Middle | `*File Updates*` | Git/file activity monitoring (emr) |
| Right | own vterm | Claude terminal output |

## Setup Steps (Execute in Order)

### Step 1: Create monitoring tab
```elisp
(ecc-create-monitoring-tab)
```

### Step 2: Load emacs-monitor-repository
```elisp
(progn
  (load-file (expand-file-name "~/.emacs.d/lisp/emacs-monitor-repository/emr/emr-core.el"))
  (load-file (expand-file-name "~/.emacs.d/lisp/emacs-monitor-repository/emacs-monitor-repository.el")))
```

### Step 3: Start repo monitoring
```elisp
(emr-start "~/proj/scitex-cloud")
```
This creates the `*File Updates*` buffer.

### Step 4: Verify and fix pane order
Check window layout. If order is wrong, use `(window-swap-states)` or buffer switching.
Take a screenshot to verify before proceeding.

### Step 5: Force org-mode colors on status.org
```elisp
(with-current-buffer "status.org"
  (revert-buffer t t)
  (org-mode)
  (setq-local org-todo-keyword-faces
    '(("TODO" . (:foreground "#FF6B6B" :weight bold))
      ("IN-PROGRESS" . (:foreground "#4ECDC4" :weight bold))
      ("WAITING" . (:foreground "#FFD93D" :weight bold))
      ("DONE" . (:foreground "#95E1D3" :weight bold))
      ("CANCELLED" . (:foreground "#A8A8A8" :weight bold))))
  (font-lock-mode 1)
  (font-lock-ensure))
```

### Step 6: Screenshot verification
Take screenshot and confirm 3-column layout with colored org headings.

## Reference Screenshot
See `~/.claude/skills/emacs-master-agent-layout-reference.jpg` for the correct layout.

## Multiple Repositories in Middle Pane
The middle pane (*File Updates*) should monitor multiple repositories, not just one. Call emr-start for each:
```elisp
(emr-start "~/proj/scitex-cloud")
(emr-start "~/proj/scitex-ui")
(emr-start "~/proj/scitex-paper-1st")
```

## Status Rotation System

### File Rotation (run at session start)
Archive the previous session before setting up the dashboard:
```bash
~/proj/master-agent/scripts/rotate-status.sh
```
This archives `status.org` to `status-YYYY-MM-DD-HHMMSS.org.bak`, creates a fresh template, and prunes backups older than the last 10.

### Display Rotation and Auto-Refresh
Load after opening status.org:
```elisp
(load-file "~/proj/master-agent/scripts/status-rotation.el")
(ma-status-auto-refresh-start)   ;; revert status.org every 30s
```

Optional features:
```elisp
;; Cycle through top-level sections (narrow/widen)
(ma-status-rotate-section)       ;; next section
(ma-status-widen)                ;; show all

;; Header-line ticker showing current IN-PROGRESS task
(ma-status-ticker-mode 1)       ;; enable
(ma-status-ticker-mode -1)      ;; disable
```

## Troubleshooting
- If repo-monitor files not found: skip Steps 2-3, use 2-column layout (status.org | vterm)
- If pane order wrong: swap buffers manually via elisp
- If org colors not showing: run `revert-buffer` + `font-lock-ensure`
