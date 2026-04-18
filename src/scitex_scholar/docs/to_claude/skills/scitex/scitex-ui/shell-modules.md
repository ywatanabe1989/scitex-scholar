---
description: TypeScript shell framework — initShell, adapters, ShellFileTree, toolbar, terminal, viewer, chat, repo-monitor. Use when wiring the workspace shell to a backend.
---

# scitex-ui Shell Modules

Vanilla TypeScript workspace shell. All imports from `scitex-ui/ts/shell`.

## Entry Point: `initShell(config)`

```typescript
import { initShell } from "scitex-ui/ts/shell";

const instances = await initShell({
  fileTree: {
    adapter: { fetchTree: () => fetch("/api/tree").then(r => r.json()).then(d => d.tree) },
    onFileSelect: (node) => console.log(node.path),
    showHidden: false,
    extensions: null,  // null = all file types
  },
  terminal: {
    adapter: { getWebSocketUrl: () => `ws://127.0.0.1:${port + 1}/` },
    clipboard: true,
    reconnectDelay: 3000,
  },
  toolbar: {
    keybindingMode: "emacs",
  },
  viewer: {
    adapter: {
      readFile: (p) => fetch(`/api/file/${p}`).then(r => r.json()),
      getFileUrl: (p) => `/api/file/${p}?raw=true`,
    },
  },
});
// instances: { fileTree?, toolbar?, shortcuts?, viewer? }
```

All sections are optional — omit to skip that module.

## `ShellConfig` Interface

```typescript
interface ShellConfig {
  fileTree?: {
    adapter: FileTreeAdapter;
    onFileSelect?: (node: FileNode) => void;
    showHidden?: boolean;
    extensions?: string[] | null;
  };
  terminal?: {
    adapter: TerminalConnectionAdapter;
    clipboard?: boolean;
    dragDrop?: boolean;
    onFileDrop?: (files: FileList) => Promise<string[]>;
    reconnectDelay?: number;
  };
  toolbar?: ToolbarConfig;
  chat?: { adapter: ChatAdapter; autoSpeak?: boolean };
  viewer?: {
    adapter: ViewerAdapter;
    onFileOpen?: (file: OpenFile) => void;
  };
}
```

## Adapter Interfaces

### `FileTreeAdapter`

```typescript
interface FileTreeAdapter {
  fetchTree(): Promise<FileNode[]>;
  createFile?(parentPath: string, name: string): Promise<void>;
  createFolder?(parentPath: string, name: string): Promise<void>;
  deleteItem?(path: string): Promise<void>;
  renameItem?(oldPath: string, newName: string): Promise<void>;
}

interface FileNode {
  name: string;
  path: string;
  type: "file" | "directory";
  children?: FileNode[];
  git_status?: string;
  mtime?: number;
}
```

### `TerminalConnectionAdapter`

```typescript
interface TerminalConnectionAdapter {
  getWebSocketUrl(): string;
  onStatusChange?(state: "connecting" | "connected" | "disconnected" | "error"): void;
  onMessage?(data: string, inst: TerminalInstance): string | null;
}
```

### `ViewerAdapter`

```typescript
interface ViewerAdapter {
  readFile(path: string): Promise<{ content: string; language?: string }>;
  saveFile?(path: string, content: string): Promise<void>;
  getFileUrl(path: string): string;
  getFileApiUrl?(path: string): string;
}
```

### `ChatAdapter`

```typescript
interface ChatAdapter {
  streamChat(message: string, context?: AiContext, images?: string[]): Promise<Response>;
  fetchCurrentModel?(): Promise<{ model: string; display?: string; campaign?: boolean } | null>;
  speak?(text: string): void;
}
```

### `RepoMonitorAdapter`

```typescript
interface RepoMonitorAdapter {
  fetchRecentFiles(): Promise<RecentFileEntry[]>;
}
interface RecentFileEntry {
  path: string;
  mtime: number;
  event?: string;
}
```

## Shell Modules Reference

### `ShellFileTree`

```typescript
import { ShellFileTree } from "scitex-ui/ts/shell/file-tree";

const tree = new ShellFileTree({
  container: "#ws-worktree-tree",  // default
  adapter: myAdapter,
  onFileSelect?: (node) => void,
  onDirectoryToggle?: (node, expanded) => void,
  showHidden?: boolean,
  extensions?: string[] | null,
  showGitStatus?: boolean,
  showFolderActions?: boolean,
});
await tree.load();
tree.refresh();          // reload from backend
tree.select(path);       // select by path
tree.getExpanded();      // string[]
tree.toggleHidden();     // toggles dotfiles, persists to localStorage
tree.destroy();
```

System noise always hidden: `.DS_Store`, `Thumbs.db`, `__pycache__`, `node_modules`, `.venv`, `venv`.

Event: `document.dispatchEvent("stx-shell:hidden-files-changed", { detail: { showHidden } })`.

### `ToolbarManager` + `KeyboardShortcuts`

```typescript
import { ToolbarManager, KeyboardShortcuts } from "scitex-ui/ts/shell/toolbar";

// Commands dispatch as CustomEvent on document:
// document.addEventListener("stx-shell:command", (e) => {
//   console.log(e.detail.command, e.detail.data);
// });

// Built-in commands: "save", "delete", "commit", "run", "new-file",
// "new-folder", "rename", "theme-toggle", "next-tab", "prev-tab",
// "new-terminal", "next-terminal", "prev-terminal",
// "shortcuts-editor", "shortcuts-terminal", "copy-terminal"

interface ToolbarConfig {
  buttons?: ButtonBinding[];        // { elementId, command, data? }[]
  shortcuts?: KeyShortcut[];        // { key, ctrlKey?, command, mode? }[]
  keybindingMode?: string;          // default: "emacs"
  keybindingModeSelector?: string;  // default: "keybinding-mode"
}
```

### `initTerminal`

```typescript
import { initTerminal } from "scitex-ui/ts/shell/terminal";

await initTerminal({
  container: "#stx-shell-ai-console-terminal",  // default
  adapter: myTerminalAdapter,
  clipboard?: boolean,      // default: true
  dragDrop?: boolean,       // default: false
  onFileDrop?: (files) => Promise<string[]>,
  reconnectDelay?: number,  // default: 3000ms
  autoInit?: boolean,       // default: true
});
```

Requires xterm.js vendor bundle at `/static/scitex_ui/vendor/xterm/`.

### `ViewerManager`

```typescript
import { ViewerManager, detectFileType } from "scitex-ui/ts/shell/viewer";

const viewer = new ViewerManager({
  container?: string | HTMLElement,      // default: "#ws-viewer-content"
  tabsContainer?: string | HTMLElement,  // default: "#ws-viewer-tabs"
  adapter: myViewerAdapter,
  onFileOpen?: (file: OpenFile) => void,
  onFileSave?: (path: string) => void,
});

// Supported FileType values:
// "text" | "image" | "pdf" | "csv" | "mermaid" | "graphviz" | "audio" | "video" | "binary"
const type = detectFileType("/path/to/file.png");  // => "image"
```

Viewer sub-components: `ImageViewer`, `PdfViewer`, `CsvViewer`, `AudioViewer`,
`VideoViewer`, `MermaidViewer`, `GraphvizViewer`, `MarkdownPreviewPanel`.

PDF requires PDF.js. Monaco/syntax highlighting loaded on demand.

### Chat Module

```typescript
import {
  processStream, renderMarkdown,
  saveMessage, loadMessages, clearMessages,
  loadHistory, pushHistory,
  VoiceRecorder, WebcamCapture, SketchCanvas, ImageInputManager,
  ChatMode, chatSend, SessionsPanel,
} from "scitex-ui/ts/shell/chat";
```

`processStream` handles SSE streaming from `ChatAdapter.streamChat()`, renders markdown, appends tool-use tags, and optionally speaks via TTS.

### `AppShell` + `Sidebar`

```typescript
import { AppShell, Sidebar } from "scitex-ui/ts/shell/app-shell";

// AppShellConfig
{
  sidebarWidth?: number,     // default: 250
  collapsible?: boolean,     // default: true
  startCollapsed?: boolean,  // default: false
  sidebarTitle?: string,
  sidebarIcon?: string,      // e.g. "fas fa-folder"
  accent?: string,           // preset key: "writer", "figrecipe"
  accentColor?: string,      // custom hex, overrides preset
  storageKey?: string,       // localStorage key for sidebar state
  onSidebarToggle?: (collapsed: boolean) => void,
}
```

### `StatusBar`

```typescript
import { StatusBar } from "scitex-ui/ts/shell/status-bar";

// StatusBarConfig
{
  items?: {
    left?: StatusItem[];    // { id, text, icon?, onClick?, title? }
    center?: StatusItem[];
    right?: StatusItem[];
  };
  showThemeToggle?: boolean;  // default: false
}
```

### `ThemeProvider`

```typescript
import { ThemeProvider } from "scitex-ui/ts/shell/theme-provider";

// ThemeProviderConfig
{
  defaultTheme?: "light" | "dark",    // default: "light"
  storageKey?: string,                 // default: "stx-theme"
  target?: HTMLElement,                // default: document.documentElement
  onThemeChange?: (theme) => void,
}
```

### `initRepoMonitor`

```typescript
import { initMonitorToggle, initRepoMonitor } from "scitex-ui/ts/shell/repo-monitor";

initMonitorToggle();  // idempotent; wires collapse/expand header

const client = initRepoMonitor({
  adapter: { fetchRecentFiles: () => fetch("/api/files").then(r => r.json()) },
  pollIntervalMs?: 10000,
});
// Returns RepoMonitorClient or null (if DOM elements missing)
client?.pause();
client?.resume();
```

### Keyboard Shortcuts Modal

```typescript
import { initKeyboardShortcuts, registerShortcuts, toggleShortcutsModal } from "scitex-ui/ts/shell/keyboard-shortcuts";

initKeyboardShortcuts();  // wires Alt+? and modal dismiss
registerShortcuts([
  { section: "Editor", label: "Save", keys: "Ctrl+S" },
]);
toggleShortcutsModal();
```

## Custom Events

| Event | When | `detail` |
|-------|------|----------|
| `stx-shell:command` | Toolbar/shortcut fires command | `{ command, data? }` |
| `stx-shell:files-changed` | AI tools create/modify files | — |
| `stx-shell:hidden-files-changed` | Hidden toggle | `{ showHidden }` |
| `stx-shell:camera` | Camera button clicked | — |
| `stx-shell:sketch` | Sketch button clicked | — |
| `stx-shell:mic-toggle` | Voice button clicked | — |
| `repo-monitor:toggle` | Monitor header toggled | `{ collapsed }` |

## Vendor Assets

- xterm.js (offline) at `/static/scitex_ui/vendor/xterm/`
- Monaco editor (offline) at `/static/scitex_ui/vendor/monaco-editor/`
