---
description: Refactoring rules for scitex-cloud Django/TypeScript codebase.
---

# Refactoring Rules

## File Size Thresholds
| Type       | Threshold  |
|------------|------------|
| Python     | 512 lines  |
| TypeScript | 512 lines  |
| CSS        | 512 lines  |
| HTML       | 1024 lines |

Check: `./scripts/maintenance/check_file_sizes.sh --verbose`

Proactively refactor when approaching thresholds — don't wait until files exceed limits.

## No Inline CSS/Script
- NEVER use inline CSS (`style="..."`) or `<script>` tags in templates
- Always use external `.css` and `.ts` files
- Link them properly in templates

## TypeScript Only
- NEVER use JavaScript — always TypeScript (`.ts` files)
- Vite handles all TS compilation (see `vite.config.ts`)

## Extraction Patterns

### TypeScript: Extract Class
```typescript
// Before: 500-line file with mixed concerns
// After: Focused modules
// managers/StateManager.ts (~150 lines)
// managers/EventManager.ts (~100 lines)
// renderers/TreeRenderer.ts (~150 lines)
```

### CSS: Split by Component
```css
/* Before: 800-line monolith */
/* After: component/layout.css, component/typography.css */
```

### HTML: Use Partials
```django
{# Before: 1200-line template #}
{# After: #}
{% include "feature/_header.html" %}
{% include "feature/_sidebar.html" %}
{% include "feature/_main.html" %}
```

## Commit Strategy
- Commit after each logical chunk of refactoring
- Only commit when tests pass
- Write E2E tests before refactoring, run after each change
