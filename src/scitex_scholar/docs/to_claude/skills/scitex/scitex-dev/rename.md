---
topic: rename
package: scitex-dev
description: >
  Bulk rename utility for files, file contents, directories, and symlinks
  with cross-reference updates. Ported from rename.sh. Safe by default
  (preview_rename before execute_rename). Supports regex patterns.
---

# Bulk Rename

## Execution Order

Critical for path integrity — always applied in this sequence:

1. File contents — safe, does not change paths
2. Symlink targets — updated to future paths (before renaming nodes)
3. Symlink names — renamed (leaf nodes)
4. File names — renamed (leaf nodes)
5. Directory names — renamed (deepest first: children before parents)

## RenameConfig

```python
from scitex_dev import RenameConfig

RenameConfig(
    pattern: str,               # string or regex pattern to find
    replacement: str,           # replacement string
    directory: str = ".",       # root directory to search
    regex: bool = False,        # treat pattern as Python regex
    extra_excludes: list[str] = [],  # paths containing these substrings are skipped
)
```

Default excludes (always applied):
`.git`, `__pycache__`, `*.pyc`, `.eggs`, `*.egg-info`, `dist`, `build`,
`node_modules`, `.tox`, `.mypy_cache`, `.pytest_cache`.

## RenameResult

```python
from scitex_dev import RenameResult

RenameResult(
    contents_changed: list[str],    # files with modified content
    symlinks_retargeted: list[str], # symlinks with updated targets
    symlinks_renamed: list[str],    # symlinks renamed
    files_renamed: list[str],       # files renamed
    dirs_renamed: list[str],        # directories renamed
    errors: list[str],              # errors encountered
    dry_run: bool,                  # True if no actual changes made
)
```

## preview_rename

Show what would be changed without modifying anything.

```python
from scitex_dev import preview_rename

result = preview_rename(
    pattern: str,
    replacement: str,
    directory: str = ".",
    regex: bool = False,
    extra_excludes: list[str] = [],
) -> RenameResult  # dry_run=True, no changes made
```

```python
r = preview_rename(
    pattern="old_module",
    replacement="new_module",
    directory="/home/user/myproject",
)
print("Files to rename:", r.files_renamed)
print("Contents to update:", r.contents_changed)
```

## execute_rename

Actually perform the rename operation.

```python
from scitex_dev import execute_rename

result = execute_rename(
    pattern: str,
    replacement: str,
    directory: str = ".",
    regex: bool = False,
    extra_excludes: list[str] = [],
) -> RenameResult  # dry_run=False, changes applied
```

```python
r = execute_rename(
    pattern="old_module",
    replacement="new_module",
    directory=".",
)
print("Renamed files:", r.files_renamed)
print("Errors:", r.errors)
```

## bulk_rename

Low-level function taking a `RenameConfig` directly.

```python
from scitex_dev import bulk_rename, RenameConfig

config = RenameConfig(
    pattern="foo",
    replacement="bar",
    directory=".",
    regex=False,
    extra_excludes=["GITIGNORED"],
)
result = bulk_rename(config, dry_run=True)
```

## Regex Examples

```python
# Replace version strings: "0.2.3" -> "0.3.0"
preview_rename(
    pattern=r"0\.2\.\d+",
    replacement="0.3.0",
    directory=".",
    regex=True,
)

# Rename class prefix: FooBar -> BazBar
execute_rename(
    pattern=r"Foo(\w+)",
    replacement=r"Baz\1",
    directory="src/",
    regex=True,
    extra_excludes=["tests"],
)
```

## CLI

```bash
# Preview (dry-run)
scitex-dev rename old_name new_name --dry-run
scitex-dev rename old_name new_name --root ./src --dry-run

# Execute
scitex-dev rename old_name new_name
scitex-dev rename old_name new_name --root ./src --exclude tests --exclude docs

# Regex mode
scitex-dev rename "Foo(\w+)" "Baz\1" --regex --dry-run

# JSON output
scitex-dev rename old_name new_name --dry-run --json
```
