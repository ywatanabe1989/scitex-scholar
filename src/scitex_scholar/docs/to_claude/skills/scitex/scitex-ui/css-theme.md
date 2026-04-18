---
description: CSS design tokens, semantic theme variables, dark/light mode. Use when styling SciTeX app components to match the workspace theme.
---

# scitex-ui CSS Theme

## Import

```typescript
import "scitex-ui/css/app.css";    // app component tokens
import "scitex-ui/css/shell/theme.css";  // shell theme (loaded by shell automatically)
```

Never hardcode colors. Use semantic CSS variables.

## Text Variables

```css
color: var(--fg-default);       /* main text */
color: var(--fg-muted);         /* secondary / dimmed text */
color: var(--text-primary);     /* alias: primary text */
color: var(--text-secondary);   /* alias: secondary text */
color: var(--text-muted);       /* alias: muted text */
```

## Background Variables

```css
background: var(--bg-primary);            /* main app background */
background: var(--bg-secondary);          /* panel / card background */
background: var(--bg-page);               /* page-level background */
background: var(--workspace-bg-primary);  /* workspace panel backgrounds */
background: var(--workspace-bg-elevated); /* floating surfaces, modals */
```

## Border Variables

```css
border-color: var(--border-default);           /* standard borders */
border-color: var(--workspace-border-default); /* workspace borders */
border-color: var(--workspace-border-subtle);  /* subtle dividers */
border-color: var(--workspace-border-hover);   /* hover state */
```

## Terminal Variables

```css
background: var(--terminal-bg);   /* terminal background */
color: var(--terminal-fg);        /* terminal foreground */
```

## Status Variables

```css
color: var(--status-success);  /* green */
color: var(--status-warning);  /* yellow/amber */
color: var(--status-error);    /* red */
```

## App Accent (per-app)

Each app declares its own accent in `theme.css`:

```css
/* Declare in your app's theme.css */
:root {
  --app-accent-myapp: #7c3aed;
  --app-accent-myapp-tint: rgba(124, 58, 237, 0.1);
}
```

```css
/* Use in component CSS */
color: var(--app-accent-myapp);
background: var(--app-accent-myapp-tint);
```

Built-in accents: `--app-accent-writer`, `--app-accent-figrecipe`.

## Sizing Variables

```css
width: var(--ui-collapsed-pane-width);  /* 48px — collapsed panel width */
font-size: var(--icon-md);              /* 16px — medium icon size */
```

## Dark / Light Mode

The shell manages `data-theme` on `<html>`. No app code needed.

```html
<html data-theme="dark">  <!-- or "light" -->
```

Toggle via:
```typescript
import { ThemeProvider } from "scitex-ui/ts/shell/theme-provider";
// ThemeProvider reads/writes localStorage "stx-theme" and sets data-theme on <html>
```

CSS responds automatically:

```css
:root[data-theme="dark"] {
  --bg-primary: #1e1e2e;
  --fg-default: #cdd6f4;
}
:root[data-theme="light"] {
  --bg-primary: #ffffff;
  --fg-default: #1e1e2e;
}
```

## CSS File Organization

```
css/shell/         ← Shell CSS (theme.css, app-shell.css, status-bar.css, ...)
css/app.css        ← App component bundle (imports all app CSS)
css/app/           ← Per-component CSS files
```

Shell CSS is loaded automatically by Django template. App components need explicit import.
