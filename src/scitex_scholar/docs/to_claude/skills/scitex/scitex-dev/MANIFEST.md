---
package: scitex-dev
version: 0.5.2
source: github.com/ywatanabe1989/scitex-dev
skills_path: src/scitex_dev/_skills/scitex-dev/
exported_via: installed
---

# Skills Manifest

These skills are distributed with **scitex-dev** and are the source of truth.
Local edits at `~/.claude/skills/scitex/` may be overwritten on update.

## Update

```bash
pip install --upgrade scitex-dev
scitex-dev skills export          # Overwrite all (+ symlink private skills)
scitex-dev skills update          # Preserve local changes
scitex-dev skills upgrade         # Clean replacement
```

## Private Skills

Private (per-machine) skills are symlinked into the export destination automatically:

```
~/.scitex/<suffix>/skills/<package>-private/
  → ~/.claude/skills/scitex/<package>-private/
```

Where `<suffix>` is the package name minus the `scitex-` prefix.
Private skills are never copied or shipped — the symlink keeps edits live.
