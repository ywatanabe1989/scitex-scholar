---
description: Django full-stack conventions — 1:1:1:1 correspondence, directory structure, naming, URL patterns, no inline styles.
---

# Django Full-Stack Conventions

## Core Principle
**1:1:1:1 correspondence** across the entire stack:
```
Frontend:  HTML <-> CSS <-> TypeScript
Backend:   View <-> Service <-> Model
```
Every feature has corresponding files at every layer.

## Directory Structure
```
apps/workspace/
  {app_name}/
    templates/{app_name}/
      {feature}.html
      {feature}_partials/
        _{component}.html
    static/{app_name}/
      css/{feature}/
        {component}.css
      ts/{feature}/
        {component}.ts
    views/
      {feature}/
        __init__.py
        api/
          {endpoint}.py
    services/
      {feature}_service.py
```

## No Inline Styles/Scripts
**FORBIDDEN**: `style="padding: 10px"` in HTML/TypeScript
**FORBIDDEN**: `<script>doSomething()</script>` in templates

**REQUIRED**: External CSS classes for all styling, external `.ts` files for all logic.

## URL Patterns
```python
path('{feature}/', include([
    path('', views.index, name='{feature}'),
    path('api/', include([
        path('{action}/', views.api.action, name='{feature}-{action}'),
    ])),
])),
```

## Naming Conventions
- Templates: `{feature}.html`, `_{partial}.html`
- CSS: `{feature}.css`, `{component}.css`
- TypeScript: `{Feature}.ts`, `{Component}.ts`
- Views: `{feature}_views.py` or `views/{feature}/`
- Services: `{feature}_service.py`

## TypeScript Only
- NEVER write JavaScript — always TypeScript (`.ts` files)
- Vite handles all TS compilation automatically
- Use `.ts` extension in imports

## App Registry URL Pattern

Modules in the registry may or may not have an explicit `url` field. Always use `mod.get_url()` — never `mod.url` directly:

```python
# Good
url = mod.get_url()   # defaults to /apps/{name}/ if no explicit url

# Bad — AttributeError or wrong URL for modules without explicit url field
url = mod.url
```

## Edit Local Files Only
- Never edit files directly in Docker containers
- All changes must be in local project files (volume-mounted)

## Legacy Code

When old code causes confusion (e.g., outdated patterns, deprecated approaches), move it to a `legacy/` subdirectory rather than patching it. Let errors surface instead of masking them with compatibility shims. Delete or isolate, don't wrap.

## Design Reference: Anthropic (守破離)

When unsure about UX/design decisions, follow Anthropic's patterns:
- Page layout (desktop/mobile): reference claude.ai
- Branding: snake icon only in chat/AI context, keep generic icons elsewhere
- Don't push brand in every UI element — subtlety over saturation
- Mobile responsiveness: match Anthropic-level polish

This is the Shu-Ha-Ri principle — master by imitation first, then innovate.
