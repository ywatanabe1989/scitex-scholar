---
name: element-inspector
description: Inspect DOM elements via playwright-cli eval for autonomous CSS/layout debugging.
---

# Element Inspector — Autonomous DOM Debugging

## MCP Tool (preferred)
```
mcp__scitex__ui_inspect_element(selector="#ws-worktree-resizer")
mcp__scitex__ui_inspect_elements(selector=".panel-resizer", limit=5)
```
Standalone — works on any website open in playwright-cli.

## Manual via playwright-cli eval
When MCP tool unavailable, use playwright-cli eval directly:

### Single element computed styles
```bash
playwright-cli eval 'JSON.stringify({position: getComputedStyle(document.querySelector("#SELECTOR")).position, width: getComputedStyle(document.querySelector("#SELECTOR")).width})'
```

### Multiple properties at once
```bash
playwright-cli eval 'var cs = getComputedStyle(document.querySelector("#SELECTOR")); JSON.stringify({position: cs.position, width: cs.width, height: cs.height, cursor: cs.cursor, display: cs.display, flex: cs.flex, flexDirection: cs.flexDirection})'
```

### Check inline styles (set by JS)
```bash
playwright-cli eval 'document.querySelector("#SELECTOR").style.cssText'
```

### Parent chain
```bash
playwright-cli eval 'var p = document.querySelector("#SELECTOR").parentElement; var chain = []; for(var i=0; i<4 && p; i++) { chain.push(p.tagName + (p.id ? "#"+p.id : "")); p = p.parentElement; } JSON.stringify(chain)'
```

### Element dimensions/position
```bash
playwright-cli eval 'Math.round(document.querySelector("#SELECTOR").getBoundingClientRect().top)'
```

## Key Patterns for CSS Debugging

### !important specificity wars
When mobile CSS uses `!important` and JS can't override:
- CSS `!important` beats inline styles
- JS must use `el.style.setProperty("prop", "value", "important")` to win
- Check with: computed style shows CSS value, not JS-set value

### Inline vs computed style mismatch
- `el.style.cssText` shows inline styles (JS-set)
- `getComputedStyle(el).property` shows final computed value
- If they differ, a CSS rule with higher specificity is winning

### Resizer not responding to drag
1. Check computed `position` — should be `relative` not `absolute` on mobile
2. Check computed `cursor` — should be `row-resize` not `col-resize` on mobile
3. Check if `flex` property is locked — JS may not be able to override `!important`
4. Check `flexDirection` of parent container — determines which axis the resizer uses
5. Check if `mousedown` event fires — add debug listener or check console
6. Check if resizer is inside sidebar (nested) vs direct child of flex container

## Anti-patterns
- NEVER claim "CSS applied" without checking `getComputedStyle` on the actual element
- NEVER claim "drag working" without performing an actual drag and measuring pane height change
- Console log showing "initialized" does NOT mean the feature works
- A static screenshot does NOT prove drag interaction works
