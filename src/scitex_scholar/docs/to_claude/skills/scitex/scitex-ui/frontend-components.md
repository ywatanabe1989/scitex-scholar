---
description: Frontend components reference — DataTable, FileBrowser, MediaViewer, Bridge infrastructure, CSS theme variables, usePanelResize
---

# SciTeX App Developer Guide

How to build a SciTeX workspace app using `scitex-ui` components.
Reference implementation: [figrecipe](https://github.com/ywatanabe1989/figrecipe)

---

## 1. Quick Start

`bridge/bridge-init.ts` — entry point, auto-discovered by the workspace shell:

```typescript
import "scitex-ui/css/app.css";
import { mountMyApp } from "./MountPoint";

const HANDLED_EXTS = [".myext"];

function init(): void {
  const mount = document.getElementById("app-mount");
  if (!mount) return;
  const opts = {
    container: mount,
    workingDir: mount.dataset.workingDir,
    darkMode: document.body.classList.contains("dark-theme"),
  };
  if (mount.dataset.embedded === "true") {
    mountMyApp(opts);
  } else {
    document.addEventListener("click", (e) => {
      const link = (e.target as Element)?.closest("[data-file-path]");
      const path = link?.getAttribute("data-file-path") || "";
      if (HANDLED_EXTS.includes(path.substring(path.lastIndexOf(".")))) {
        e.preventDefault(); e.stopPropagation();
        mountMyApp({ ...opts, initialFile: path });
      }
    });
  }
}
document.readyState === "loading"
  ? document.addEventListener("DOMContentLoaded", init)
  : init();
```

`bridge/MountPoint.ts`:

```typescript
import React from "react";
import { installFetchOverride, mountReactApp, unmountReactApp }
  from "scitex-ui/react/app/bridge";
import type { BridgeConfig, BridgeMountOptions } from "scitex-ui/react/app/bridge";
import { MyAppRoot } from "../MyAppRoot";

const CONFIG: BridgeConfig = {
  slug: "myapp",
  mountId: "app-mount",
  apiPaths: ["/api/files", "/api/save"],
  fileExtensions: [".myext"],
};

export function mountMyApp(options: BridgeMountOptions): void {
  installFetchOverride(CONFIG);
  mountReactApp(options.container, React.createElement(MyAppRoot, {
    apiBaseUrl: `/apps/${CONFIG.slug}/${CONFIG.slug}`,
    workingDir: options.workingDir,
    initialFile: options.initialFile,
    darkMode: options.darkMode,
  }));
}

export const unmountMyApp = unmountReactApp;
```

---

## 2. React Components

All imports from `scitex-ui/react/app/{component}`.

### DataTable

Full spreadsheet: multi-select, editing, clipboard, virtual scroll (>100 rows), sort, column resize.

```typescript
import { DataTable } from "scitex-ui/react/app/data-table";
import type { Dataset } from "scitex-ui/react/app/data-table";
// Dataset = { columns: string[]; rows: Array<{ [key: string]: string | number }> }
```

Key props: `data?: Dataset`, `csvContent?: string`, `readOnly?: boolean`,
`onDataChange?: (d: Dataset) => void`, `onCellSelect?: (pos: {row,col}) => void`,
`onStatusUpdate?: (msg: string) => void`, `showRowNumbers?`, `sortable?`, `resizable?`.

```tsx
<DataTable csvContent={rawCsv} onDataChange={(d) => save(d)} onStatusUpdate={setStatus} />
```

### FileBrowser

File tree with search, git badges, context menu, sort by name or mtime.

```typescript
import { FileBrowser } from "scitex-ui/react/app/file-browser";
import type { FileNode } from "scitex-ui/react/app/file-browser";
// FileNode = { name, path, type: "file"|"directory", children?, git_status?, mtime? }
```

Key props: `data?: FileNode[]`, `apiUrl?: string`, `onFileSelect?: (n: FileNode) => void`,
`onFileDoubleClick?`, `onContextAction?: (action, node) => void`,
`extensions?: string[] | null`, `searchable?: boolean`, `sortMode?: "name" | "mtime"`.

```tsx
<FileBrowser apiUrl="/api/file-tree" extensions={[".yaml"]} searchable
  onFileSelect={(n) => openFile(n.path)} />
```

### MediaViewer

Images (zoom/pan), PDFs, Mermaid, Graphviz, binary placeholder. Returns `null` for text files.

```typescript
import { MediaViewer } from "scitex-ui/react/app/media-viewer";
// Props: filePath, getFileUrl(path,raw?,download?)=>string, fileType?, onDownload?
```

```tsx
<MediaViewer filePath={file} getFileUrl={(p, raw) => `/api/files${p}${raw ? "?raw=1" : ""}`} />
```

### ConfirmModal

```typescript
import { ConfirmModal } from "scitex-ui/react/app/confirm-modal";
// Props: open, message, title?, confirmText?, cancelText?, onConfirm?, onCancel?
```

```tsx
<ConfirmModal open={show} message="Delete?" onConfirm={del} onCancel={() => setShow(false)} />
```

---

## 3. Bridge Infrastructure

All exports from `scitex-ui/react/app/bridge`.

### BridgeConfig

```typescript
interface BridgeConfig {
  slug: string;           // must match Django app slug
  mountId: string;        // DOM element id, e.g. "app-mount"
  apiPaths: string[];     // path prefixes to rewrite (e.g. ["/api/", "/save"])
  fileExtensions: string[]; // handled file types (e.g. [".yaml"])
}
```

### installFetchOverride(config)

Patches `window.fetch` once per slug. Paths matching any `apiPaths` prefix are rewritten:

```
/api/save  →  /apps/{slug}/{slug}/api/save
```

Safe to call multiple times. Must run before any API fetch.

### mountReactApp / unmountReactApp

```typescript
mountReactApp(container: HTMLElement, element: React.ReactElement): void
unmountReactApp(): void   // tears down React root
```

`mountReactApp` always unmounts the previous root first.

### emitBridgeEvent / onBridgeEvent

Slug-namespaced `CustomEvent` bus on `document`. Full event name: `{slug}:{eventName}`.

```typescript
emitBridgeEvent<T>(slug: string, eventName: string, detail: T): void
onBridgeEvent<T>(slug: string, eventName: string, handler: (d: T) => void): () => void
// returns cleanup fn — return it from useEffect
```

```typescript
emitBridgeEvent("myapp", "fileSelect", { path: "/data.yaml" });
const cleanup = onBridgeEvent("myapp", "fileSelect", ({ path }) => load(path));
```

---

## 4. Panel Resize Hook

```typescript
import { usePanelResize } from "scitex-ui/react/app/usePanelResize";
```

Config (all required except `maxWidth`, `containerRef`, `onBoundaryOverflow`):

```typescript
{
  direction: "left" | "right",  // "left" = resizer on right side of panel
  minWidth: number,             // auto-collapse below this
  defaultWidth: number,
  storageKey: string,           // localStorage key for width
  collapseKey: string,          // localStorage key for collapsed state
  maxWidth?: number,
  containerRef?: React.RefObject<HTMLElement>,  // prevents pushing siblings off-screen
  onBoundaryOverflow?: (px: number, dir: "left"|"right") => void,
}
```

Returns: `{ width, collapsed, panelRef, resizerProps, headerProps, toggleCollapse }`

```tsx
const containerRef = useRef<HTMLDivElement>(null);
const panel = usePanelResize({
  direction: "left", minWidth: 40, defaultWidth: 280,
  storageKey: "myapp-sidebar-w", collapseKey: "myapp-sidebar-c", containerRef,
});

<div ref={containerRef} style={{ display: "flex", height: "100%" }}>
  <aside ref={panel.panelRef as React.RefObject<HTMLDivElement>}
         style={{ width: panel.collapsed ? 40 : panel.width }}>
    <header {...panel.headerProps}>Files</header>
    <FileBrowser ... />
  </aside>
  <div className="resizer" {...panel.resizerProps} />
  <main style={{ flex: 1 }}>...</main>
</div>
```

Width and collapsed state persist via localStorage. Double-click resizer or header to toggle.

---

## 5. CSS Theme Variables

```typescript
import "scitex-ui/css/app.css"; // provides all tokens
```

Never hardcode colors. Use semantic variables:

```css
/* Text */
color: var(--text-primary);  color: var(--text-secondary);  color: var(--text-muted);

/* Backgrounds */
background: var(--bg-page);
background: var(--workspace-bg-primary);   /* panel backgrounds */
background: var(--workspace-bg-elevated);  /* floating surfaces */

/* Borders */
border-color: var(--workspace-border-default);
border-color: var(--workspace-border-subtle);
border-color: var(--workspace-border-hover);

/* Status */
color: var(--status-success);  color: var(--status-warning);  color: var(--status-error);

/* App accent (declare per-app in theme.css) */
color: var(--app-accent-myapp);
background: var(--app-accent-myapp-tint);

/* Sizing */
width: var(--ui-collapsed-pane-width);  /* 48px collapsed panel */
font-size: var(--icon-md);              /* 16px */
```

Dark/light is `<html data-theme="dark|light">` on the shell — no app code needed.

---

## 6. Reference Implementation

**figrecipe** — [github.com/ywatanabe1989/figrecipe](https://github.com/ywatanabe1989/figrecipe)

All paths under `src/figrecipe/_django/frontend/src/`:

| File | What it demonstrates |
|------|----------------------|
| `bridge/bridge-init.ts` | Embedded vs standalone branching, init pattern |
| `bridge/MountPoint.ts` | BridgeConfig, fetch override, React root mount |
| `bridge/EventBus.ts` | Typed event helpers wrapping emitBridgeEvent/onBridgeEvent |
| `bridge/WorkspaceIntegration.ts` | WorkspaceResizeContext cross-boundary propagation |
| `FigrecipeEditor.tsx` | Root component with inner usePanelResize layout |

### WorkspaceResizeContext (advanced — optional)

Register inner panels so shell-level resize can propagate across the app boundary:

```typescript
import { useWorkspaceResize }
  from "scitex-ui/react/shell/workspace/WorkspaceResizeContext";

const { registerPane, unregisterPane } = useWorkspaceResize();

useEffect(() => {
  registerPane({
    id: "myapp-sidebar",
    getWidth: () => panel.width,
    setWidth: (w) => { if (panel.panelRef.current) panel.panelRef.current.style.width = `${w}px`; },
    minWidth: 40,
    collapse: panel.toggleCollapse,
    isCollapsed: () => panel.collapsed,
  });
  return () => unregisterPane("myapp-sidebar");
}, [panel.width, panel.collapsed]);
```

Only needed when your app's inner resizers should push/pull shell column widths.

## 7. Packaging Requirement for Bridge Apps

Apps with a `bridge` key in `_django/manifest.json` must keep `_django/frontend/src/` in their source tree. scitex-cloud discovers bridge paths by scanning sibling directories for `manifest.json` files, so the frontend TypeScript source must be present in the repo.

**For pip packaging**, use an `[app]` optional extra for Python dependencies needed by the platform integration:

```toml
[project.optional-dependencies]
app = [
    "django>=4.2.0",
    "Pillow>=9.0.0",
    "scitex-app>=0.1.0",
    "scitex-ui>=0.1.0",
]
```

**For CI**, clone the app repo as a sibling directory so the bridge discovery finds `manifest.json` and `frontend/src/`. Not all apps are pip packages, so sibling cloning is the standard approach.
