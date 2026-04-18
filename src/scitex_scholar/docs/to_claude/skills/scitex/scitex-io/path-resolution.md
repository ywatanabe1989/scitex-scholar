---
description: Auto save-path routing in scitex-io and scitex.path utilities for path splitting, finding, versioning, and symlinks.
---

# Path Resolution

## Auto save-path routing (scitex-io)

`sio.save(obj, "relative/path.csv")` auto-routes based on context:

| Context | Output directory |
|---------|-----------------|
| Script | `{script_dir}_out/{path}` |
| Jupyter | `{notebook_dir}/{notebook_base}_out/{path}` |
| Interactive | `/tmp/{USER}/{path}` |
| Absolute path | Used as-is |

## scitex_io path utilities

```python
from scitex_io import path  # or scitex_io._path

path.split_fpath("data/file.txt")     # → ("data/", "file", ".txt")
path.find(".", type="f", exp="*.csv") # → list of matching files
path.find_latest(".", "model", ".pt") # → "model_v003.pt" (latest version)
path.touch("new_file.txt")            # create or update mtime
path.find_the_git_root_dir()          # → git repo root
```

## scitex.path (full path toolkit)

`scitex.path` (in scitex-python) provides a richer API:

### Path components

```python
import scitex as stx

stx.path.split("data/file.txt")       # → (Path("data"), "file", ".txt")
stx.path.clean("/home/./user/../x")   # → "/home/x"
stx.path.this_path()                  # → Path of calling script
```

### File finding

```python
stx.path.find_file(".", "*.csv")       # recursive, excludes lib/env/build
stx.path.find_dir(".", "config*")      # find directories
stx.path.find_git_root()               # git repo root
```

### Save path creation

```python
stx.path.mk_spath("results.csv")      # → {script_name}_out/results.csv
stx.path.mk_spath("fig.png", makedirs=True)
```

### Versioning

```python
stx.path.increment_version(".", "model", ".pt")
# If model_v001.pt exists → returns path to model_v002.pt

stx.path.find_latest(".", "model", ".pt")
# → path to model_v002.pt (highest version)
```

### Symlinks

```python
stx.path.symlink("src", "dst")                    # create symlink
stx.path.symlink("src", "dst", relative=True)     # relative symlink
stx.path.is_symlink("link")                       # check
stx.path.readlink("link")                         # target
stx.path.resolve_symlinks("link")                 # full resolution
stx.path.list_symlinks("dir/", recursive=True)    # find all symlinks
stx.path.fix_broken_symlinks("dir/", remove=True) # cleanup broken
```

### Other

```python
stx.path.getsize("file.csv")                      # bytes or np.nan
stx.path.get_data_path_from_a_package("pkg", "data.csv")  # package resource
```
