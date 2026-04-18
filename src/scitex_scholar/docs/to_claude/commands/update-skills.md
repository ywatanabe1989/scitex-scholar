Based on recent experiences, create or update skills.

## Locations

### General (non-SciTeX):
- ~/.dotfiles/src/.claude/to_claude/skills

### SciTeX Modules (submodules within scitex-python):
- ~/proj/scitex-python/src/scitex/<module-name>/_skills

### SciTeX Standalone Packages:
- ~/proj/<package-name>/src/<package_name>/_skills/<pip-name>/

## SciTeX-Specific Rules

- SKILL.md is an index only — content goes in focused sub-skill files
- Include MANIFEST.md with version (auto-stamped from pyproject.toml on export)
- Each SKILL.md should reference MANIFEST.md for update instructions
- Use `<details>/<summary>` in READMEs for "Four Interfaces" (not "Three")

### After Updating SciTeX Skills

```bash
scitex-dev skills list --package <pkg>
scitex-dev skills export --package <pkg> --dry-run
python -m pytest tests/test_skills.py -v
```

## General Skill-Writing Rules

- No checkboxes (`- [ ]`) — use prose, code blocks, tables
- No "Confirmation" / "Understanding Check" sections
- Show `$ENV_VAR_NAME` in CLI help defaults, not resolved values
- Consolidate thin sub-files (< 20 lines each) into SKILL.md

$ARGUMENTS
