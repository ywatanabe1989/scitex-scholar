---
name: orochi-python-venv-convention
description: Canonical Python venv layout across the fleet — version-tagged real venv + active symlink + per-project .venv symlinks. Prevents duplicate venvs, enables atomic Python version switch, keeps disk+inode economy on every host.
---

# Python venv convention

One venv, many projects, one fleet-wide standard. This is the canonical layout the operator specified in 2026-04-14 msgs #10278 / #10269 / #10287 and the follow-up todo#400.

## The layout

Every fleet host uses exactly this chain:

```
~/.venv-<PYTHON_VERSION>                 ← the actual venv (real directory)
~/.venv                    → .venv-<PYTHON_VERSION>
~/proj/<package>/.venv     → ~/.venv
```

Resolution when you `source ~/proj/<package>/.venv/bin/activate`:

1. `~/proj/<package>/.venv` is a symlink to `~/.venv`.
2. `~/.venv` is a symlink to `~/.venv-3.11` (or whatever version is active).
3. `~/.venv-3.11/bin/activate` runs, exports the venv normally.

From the user's perspective, every project "has its own venv at `.venv`". From disk's perspective, there is exactly **one** venv per Python version and every project shares it.

## Why this layout specifically

- **Version in the real path** (`~/.venv-3.11`): multiple Python versions can coexist (`~/.venv-3.11` and `~/.venv-3.12` side by side). No rename is required when a host gets a new Python.
- **`~/.venv` as the active pointer**: switching Python versions for the whole host is a single `ln -snf` operation. No per-project edits, no activate-script rewrites.
- **Per-project `.venv` symlink to `~/.venv`**: preserves the `.venv/bin/activate` habit that tools like `direnv`, `pyright`, `vscode`, `ruff`, and most IDEs assume. No tooling gets confused, no `cwd`-relative activate breaks, no separate per-project venv consumes disk or inodes.
- **Inode economy**: a venv has ~2000 files (depending on installed packages). One real venv + N symlinks = ~2000 inodes, not `N × 2000`. On HPC systems where inode quotas are real constraints (Spartan `/data/gpfs` was at 72 free during the 2026-04-13 NeuroVista backfill — see `hpc-spartan-startup-pattern.md`), this is not a theoretical concern.
- **Atomic version switch**: `ln -snf ~/.venv-3.12 ~/.venv` flips the entire host from 3.11 to 3.12 in a single syscall. All projects pick it up on the next `source .venv/bin/activate`.

## Who owns this

**`worker-scitex-expert-<host>`** is the canonical owner (msg #10269). The fleet-wide adoption, per-host sync, drift detection, and conflict-safe migration are part of its scitex-ecosystem-management mission. Other agents should:

- Read this skill before touching a host's venv.
- Ask `worker-scitex-expert-<host>` via DM if they need to create a new real venv on a host.
- Never create a loose `venv/` or `env/` or `.venv-foo/` — all venvs follow the layout above or they get deleted.

## Creating the layout on a fresh host

```bash
# 1. Build the real version-tagged venv once.
python3.11 -m venv ~/.venv-3.11
~/.venv-3.11/bin/pip install --upgrade pip wheel

# 2. Point ~/.venv at it.
ln -snf ~/.venv-3.11 ~/.venv

# 3. For every project you want to share this venv:
cd ~/proj/<package>
[ -e .venv ] && { echo "BACKUP OR REMOVE existing .venv before proceeding"; exit 1; }
ln -snf ~/.venv .venv

# 4. Verify
source .venv/bin/activate
python -c "import sys; print(sys.executable)"
# → /home/the operator/.venv-3.11/bin/python (not /home/the operator/proj/<package>/.venv/bin/python)
```

Never write step 3 as `rm -rf .venv && ln -snf ...` in a script. The `[ -e .venv ]` guard is mandatory — blowing away someone's half-working venv is a destructive operation.

## Switching Python versions (host-wide, atomic)

```bash
# Build the new real venv alongside the old one.
python3.12 -m venv ~/.venv-3.12
~/.venv-3.12/bin/pip install --upgrade pip wheel

# Reinstall your packages into the new real venv (editable + regular).
~/.venv-3.12/bin/pip install -e ~/proj/scitex-python
~/.venv-3.12/bin/pip install -e ~/proj/scitex-orochi
# ...etc for every project you depend on.

# Flip the active symlink in one syscall.
ln -snf ~/.venv-3.12 ~/.venv

# All existing shells with the old venv activated keep working until they re-activate.
# New shells (and every project's .venv/bin/activate) see ~/.venv-3.12 transparently.

# Keep the old real venv around for rollback until the new one is proven.
# When you are sure: rm -rf ~/.venv-3.11
```

**Rollback** is a single `ln -snf ~/.venv-3.11 ~/.venv`. That is the entire benefit of this layout.

## Migration from legacy layouts

Common "before" states on fleet hosts (2026-04-14 snapshot):

| Host | Before | After |
|---|---|---|
| HPC cluster | `~/.venv-3.11` only, no `~/.venv` symlink | `~/.venv → .venv-3.11` |
| NAS/storage host | `~/.venv-3.11` + `~/.venv-3.10`, no symlink | pick one as active, `ln -snf` |
| Primary workstation | homebrew-site-packages, no venv | create `~/.venv-3.11`, adopt |
| ywata-note-win | unclear | audit + adopt |

**Safe migration recipe**:

1. **Inspect first.** `ls -la ~/.venv* ~/proj/*/.venv`. List what's there before touching anything.
2. **Rename real venvs** to match the `~/.venv-<VER>` convention if they're loose (`~/.venv` is already a real dir → rename to `~/.venv-3.11` first, *then* create the symlink).
3. **Install the packages** you need into the real venv (editable `scitex-*` + whatever else).
4. **Stage the symlinks** one project at a time. Do **not** batch-loop `find ~/proj -name .venv -delete -exec ln ...` without reviewing each candidate. A stale .venv directory sometimes contains the last-known-working environment for a broken project.
5. **Verify activate works** for each project before removing the old real venv.
6. **Stop running agents first** if a project whose `.venv` you're migrating is actively executing. `scitex-agent-container stop <yaml>`, migrate, `start`. Swapping a venv under a running Python process is undefined behavior.

## Forbidden patterns

- **Per-project real venvs**. Every `~/proj/<x>/.venv` must be a symlink, never a real directory. Multiple real venvs per host = duplicate inodes + version drift + editable-install confusion.
- **Loose `venv/` or `env/`**. Tooling looks for `.venv` specifically; `venv/` and `env/` are remnants from tutorials and get mistaken for ignored directories. Delete or rename to `.venv` (as a symlink).
- **Hardcoded Python version in `.venv` itself**. `~/proj/<x>/.venv` pointing directly to `~/.venv-3.11` bypasses the `~/.venv` indirection layer and breaks the atomic switch. Always chain through `~/.venv`.
- **Agent-crafted venv activate scripts**. Never regenerate `activate` by hand or with a shell helper. The stock `python -m venv` output is canonical; anything else drifts.
- **`pip install --user` combined with this layout**. Mixes host-global site-packages with the venv and produces ambiguous `python -c "import X"` results. Always activate the venv or use `~/.venv/bin/pip` directly.
- **Editable install pointing at a different `site-packages` than the activate chain**. If `pip install -e ~/proj/scitex-python` was run against `~/.venv-3.10` but the `~/.venv` symlink points at `~/.venv-3.11`, `import scitex` resolves differently depending on which bin you run. Always `source .venv/bin/activate` first, *then* `pip install -e`.

## direnv / uv / poetry — how they interact

- **`direnv`**: put `layout python-venv` or `source .venv/bin/activate` in `.envrc`. The `.venv` symlink chain is transparent to direnv; it sees the end destination.
- **`uv`**: `uv venv ~/.venv-3.11` creates the real venv with uv's fast resolver, then adopt the symlinks manually. `uv pip install -e` against the activated venv is compatible.
- **`poetry`**: incompatible with symlinked per-project `.venv` if poetry is set to `poetry config virtualenvs.in-project true`. Either turn that off (poetry uses its own cache) or pick a different package manager for the shared project. In practice, scitex-* uses `pip -e`, so poetry is not in the fleet's path.
- **`pipx`**: orthogonal. `pipx` lives in `~/.local/pipx/venvs/` and does not touch `.venv`. Use `pipx` for user-level CLI tools (`ruff`, `black`, `pre-commit`) that should not pollute the shared venv.

## Adoption status (2026-04-14, tracked in todo#400)

| Host | Real venv | Active symlink | Per-project symlinks |
|---|---|---|---|
| HPC cluster | `~/.venv-3.11` ✅ | ❌ | ⏳ partial |
| NAS/storage host | `~/.venv-3.11` ✅ | ❌ | ⏳ partial |
| Primary workstation | homebrew-site only | ❌ | ❌ |
| ywata-note-win | unclear | ❌ | ❌ |

`worker-scitex-expert-<host>` owns the cross-host convergence work. This skill is the contract it implements against.

## Related

- `hpc-spartan-startup-pattern.md` — inode economy is a real constraint on Spartan; this layout is a prerequisite
- `agent-autostart.md` principle #6 — per-agent process isolation is orthogonal, but venv sharing is fleet-wide
- todo #400 — scitex-dev ecosystem sync (implementation side of this skill)
- memory `project_scitex_layering.md` — downward-only dependency rule that the shared venv supports
- the operator msg #10278 / #10269 / #10287 / #10305 (2026-04-14) — source directives

## Change log

- **2026-04-14 (initial)**: Codified from the operator msg #10278 (layout spec), #10269 / #10287 (ownership), todo#400 requirements, and worker-todo-manager msg #10288 / #10291 dispatch. Author: worker-skill-manager.
