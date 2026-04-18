## Minimize, Clean API Exposure

API must be clean. Users should only see what they need.

---

### Python API

#### Techniques to Hide Internal Code

1. **Underscore-prefix file names** - Rename internal modules:
   ```bash
   mv base.py _base.py
   mv engine_impl.py _engine_impl.py
   ```

2. **Underscore-prefix imports** - Hide re-exported internals:
   ```python
   from .engines import BaseTTS as _BaseTTS  # Hidden
   from scitex._install_guide import warn_module_deps as _warn_module_deps
   ```

3. **Control `__all__`** - Only export public API:
   ```python
   __all__ = ["speak", "TTS"]  # Only these appear as public
   ```

#### Common Things to Hide

- Base/abstract classes (`BaseTTS`, `TTSBackend`)
- Internal modules (`base.py`, `*_engine.py`)
- Utility functions (`warn_module_deps`)
- Implementation details

#### Check APIs

```bash
# Module-level alias (delegates to main command)
scitex audio list-python-apis
scitex plt list-python-apis
scitex stats list-python-apis

# Main command
scitex introspect api scitex.audio

# Verbosity: (none) names, -v sig, -vv +doc, -vvv full
scitex audio list-python-apis -v
```

---

### MCP Tools

#### Single Source of Truth

Module-level commands should **delegate** to main commands, not duplicate logic:

```python
# GOOD: Delegate to main command
@mcp.command("list-tools")
@click.pass_context
def list_tools(ctx, verbose, compact, as_json):
    """List available audio MCP tools (delegates to main MCP)."""
    from scitex.cli.mcp import list_tools as main_list_tools
    ctx.invoke(main_list_tools, verbose=verbose, module="audio", ...)

# BAD: Duplicate implementation
@mcp.command("list-tools")
def list_tools():
    tools = [("audio_speak", "desc"), ...]  # Hardcoded, gets stale
    for name, desc in tools:
        click.echo(f"  {name}: {desc}")
```

#### Check MCP Tools

```bash
# Module-level (delegates to main)
scitex audio mcp list-tools -v

# Main command with module filter
scitex mcp list-tools -v -m audio

# Both should show identical output (single source of truth)
```

---

### Workflow

1. **Check current state**:
   ```bash
   scitex <module> list-python-apis   # Python API
   scitex <module> mcp list-tools -v  # MCP tools
   ```

2. **Identify what to hide** (Python API):
   - Base classes, internal modules, utilities

3. **Apply hiding** (Python API):
   - Rename: `base.py` → `_base.py`
   - Import: `from .x import Y as _Y`
   - **Use `mcp__scitex__dev_bulk_rename`** for file/directory renames — much faster, safer, and more reliable than manual `mv` + `sed` chains. It handles cross-reference updates automatically.
   - **Never use `sed`/`awk` for file edits** — always use the Edit tool. It's safer, reviewable, and doesn't fail on path issues.

4. **Ensure consistency** (MCP):
   - Module commands delegate to main
   - No duplicate implementations

5. **Update references**:
   - Sibling modules, tests, docs
   - The bulk renamer handles most of this automatically

---

### Example: Before/After

**Python API** (30 → 15 items):
```
Before:                          After:
[M] audio                        [M] audio
  [M] engines                      [C] GoogleTTS
    [C] BaseTTS        ←hide       [C] SystemTTS
    [C] TTSBackend     ←hide       [F] speak
    [M] base           ←hide       [M] engines
    [M] gtts_engine    ←hide         [C] GoogleTTS
  [F] warn_module_deps ←hide         [C] SystemTTS
```

**MCP Tools** (consistent output):
```bash
$ scitex audio mcp list-tools -v
$ scitex mcp list-tools -v -m audio
# Both show same 12 tools with identical formatting
```

### Example: Live
Learn from `~/proj/scitex-python` and `~/proj/figrecipe`.
`$ <package-name> mcp list-tools` and `$ <package-name> list-python-apis` should follow the same format and color code with those of `figrecipe`
