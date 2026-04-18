---
description: Vanilla TS workspace shell — modules, adapters, init flow, container IDs
---

# Shell Framework Reference

Complete vanilla TypeScript workspace shell ported from scitex-cloud.
All modules use adapter interfaces — no hardcoded backend URLs.

## Directory Structure

```
ts/shell/
  _shell-init.ts              ← initShell() orchestrator
  types.ts                    ← Aggregate ShellConfig
  file-tree/                  ← ShellFileTree + 60+ file icons + git badges
    types.ts                  ← FileTreeAdapter interface
    _ShellFileTree.ts         ← Shell wrapper with hidden files toggle
    _file-icons.ts            ← VS Code/Gitea-style icon map
    _git-status.ts            ← Git status badge rendering
  toolbar/                    ← Command registry + keyboard shortcuts
    types.ts                  ← ToolbarCommand, KeyShortcut
    _ToolbarManager.ts        ← Button → stx-shell:command events
    _KeyboardShortcuts.ts     ← Ctrl+S, Emacs C-x chords
  terminal/                   ← Unified xterm.js terminal
    types.ts                  ← TerminalConnectionAdapter
    _TerminalFactory.ts       ← Local vendor + CDN fallback, clipboard
    _OscHandler.ts            ← OSC 9999 (TTS) + 9998 (media overlay)
  chat/                       ← AI chat panel
    types.ts                  ← ChatAdapter, StreamContext
    _stream-handler.ts        ← SSE processor with debounced markdown
    _markdown-render.ts       ← marked.js + DOMPurify
    _chat-mode.ts             ← Core chat messaging (TODO)
    _storage.ts               ← localStorage persistence (40 msg cap)
    _history.ts               ← C-p/C-n command history
    _tool-tags.ts             ← MCP tool badges
    _model-badge.ts           ← AI model display
    _recorder.ts              ← VoiceRecorder + SttAdapter
    _speech.ts                ← TTS + TtsAdapter + browser fallback
    _image-input.ts           ← File picker, paste, thumbnails
    _webcam-capture.ts        ← Camera modal with capture + flip
    _sketch-canvas.ts         ← Freehand drawing canvas
    _config-mode.ts           ← Settings panel (MCP tools, skills)
  viewer/                     ← File viewer
    types.ts                  ← ViewerAdapter, FileType
    _ViewerManager.ts         ← Routes files to correct viewer
    _ImageViewer.ts           ← Zoom (0.1x-10x) + pan + double-click reset
    _PdfViewer.ts             ← PDF.js from CDN, page nav, zoom
  auto-response/              ← Claude Code CLI auto-accept
    _AutoResponseManager.ts   ← Polls xterm buffer, auto-sends responses
    _claude-state-detector.ts ← CLI state pattern matching
    _auto-response-config.ts  ← Safety config (burst, throttle, watchdog)
  workspace-panel-resizer/    ← 3-column panel drag-to-resize
  app-shell/                  ← AppShell layout component
  theme-provider/             ← Dark/light theme switching
  status-bar/                 ← Bottom status bar
```

## Container IDs (standalone_shell.html)

| ID | Purpose |
|----|---------|
| `#ws-ai-pane` | Console/Chat pane container |
| `#stx-shell-ai-console-terminal` | xterm.js terminal |
| `#stx-shell-ai-messages` | Chat message list |
| `#stx-shell-ai-input` | Chat textarea |
| `#ws-worktree-tree` | File tree container |
| `#ws-viewer-content` | Viewer content area |
| `#ws-viewer-pane` | Viewer pane (collapsible) |
| `#main-content` | App content area |
| `#root` | React mount point (inside #main-content) |

## Custom Events

| Event | Detail | Source |
|-------|--------|--------|
| `stx-shell:command` | `{command, data}` | ToolbarManager, KeyboardShortcuts |
| `stx-shell:camera` | none | Toolbar button |
| `stx-shell:sketch` | none | Toolbar button |
| `stx-shell:mic-toggle` | none | Toolbar button |
| `stx-shell:files-changed` | `{toolsUsed}` | Stream handler after AI file ops |
| `stx-shell:hidden-files-changed` | `{showHidden}` | ShellFileTree |

## Panel Resizer Data Attributes

```html
<div data-panel-resizer
     data-target="#stx-shell-ai-panel"
     data-direction="left"
     data-min-width="48"
     data-default-width="300"
     data-storage-key="stx-shell-ai-width"
     data-collapse-key="stx-shell-ai-collapsed"
     data-toggle-btn="stx-shell-ai-toggle">
</div>
```
