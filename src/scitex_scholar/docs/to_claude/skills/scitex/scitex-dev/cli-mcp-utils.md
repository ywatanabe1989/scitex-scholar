---
topic: cli-mcp-utils
package: scitex-dev
description: >
  Adapters for consuming Result objects in CLI (exit codes, text/JSON output)
  and MCP (JSON string) contexts. Also provides reusable Click option factories
  for --json and --dry-run flags.
---

# CLI and MCP Utilities

## handle_result

Format and print a Result to stdout/stderr; return exit code.

```python
from scitex_dev import handle_result

exit_code = handle_result(
    result: Result,
    as_json: bool = False,    # True: full JSON; False: human-friendly text
    file=None,                # output stream; defaults to stdout/stderr
) -> int
```

- Success + `as_json=False`: prints `result.data` (dicts as JSON, else str).
- Failure + `as_json=False`: prints `Error: <message>` to stderr + hints.
- Any + `as_json=True`: prints `result.to_json()`.

```python
r = Result(success=True, data={"count": 5})
code = handle_result(r)            # prints {"count": 5}, returns 0
code = handle_result(r, as_json=True)  # prints full Result JSON, returns 0
```

## run_as_cli

Call a `@supports_return_as` function and exit with proper code.

```python
from scitex_dev import run_as_cli

run_as_cli(
    fn: Callable,       # function decorated with @supports_return_as
    as_json: bool = False,
    **kwargs,           # passed to fn
) -> None               # calls sys.exit(code)
```

```python
@supports_return_as
def get_count(n: int) -> int:
    return n * 2

# In a Click command:
run_as_cli(get_count, as_json=False, n=5)
# prints "10", exits 0
```

## wrap_as_cli

Call any plain function and display its result as CLI output. Does not
require `@supports_return_as`; wraps exceptions automatically.

```python
from scitex_dev import wrap_as_cli

wrap_as_cli(
    fn: Callable,
    as_json: bool = False,
    **kwargs,
) -> None               # calls sys.exit(code)
```

```python
def plain_func(path: str) -> dict:
    return {"files": 3}

wrap_as_cli(plain_func, as_json=False, path=".")
# prints {"files": 3}, exits 0
```

## run_as_mcp

Call a `@supports_return_as` function and return MCP-ready JSON string.

```python
from scitex_dev import run_as_mcp

json_str = run_as_mcp(
    fn: Callable,   # @supports_return_as function
    **kwargs,
) -> str            # JSON string with full Result structure
```

## wrap_as_mcp

Call any plain function and return Result JSON. Use this to retrofit
existing handlers without modifying the underlying function.

```python
from scitex_dev import wrap_as_mcp

json_str = wrap_as_mcp(
    fn: Callable,
    *,
    side_effects: list[str] | None = None,   # e.g. ["file_create: /tmp/x"]
    hints_on_error: list[str] | None = None,
    idempotent: bool = False,
    **kwargs,
) -> str
```

```python
def load_data(path: str) -> dict:
    ...

result_json = wrap_as_mcp(
    load_data,
    side_effects=None,
    hints_on_error=["Check path exists"],
    path="/data/file.csv",
)
```

## async_wrap_as_mcp

Async version of `wrap_as_mcp` for async MCP handlers.

```python
from scitex_dev import async_wrap_as_mcp

json_str = await async_wrap_as_mcp(
    coro_fn: Callable,    # async coroutine function
    *,
    side_effects: list[str] | None = None,
    hints_on_error: list[str] | None = None,
    idempotent: bool = False,
    **kwargs,
) -> str
```

## result_to_mcp

Convert an existing Result object directly to MCP JSON.

```python
from scitex_dev import result_to_mcp

r = Result(success=True, data=42)
json_str = result_to_mcp(r)    # same as r.to_json()
```

## Click Option Factories

Lazy-import decorators (Click optional; stdlib-only core).

### json_option

Adds `--json` flag (`as_json` parameter) to a Click command.

```python
from scitex_dev import json_option
import click

@click.command()
@json_option
def my_cmd(as_json):
    ...
```

### dry_run_option

Adds `--dry-run` flag to a Click command.

```python
from scitex_dev import dry_run_option

@click.command()
@dry_run_option
def my_cmd(dry_run):
    ...
```

### add_json_argument / add_dry_run_argument

Argparse equivalents:

```python
from scitex_dev import add_json_argument, add_dry_run_argument
import argparse

parser = argparse.ArgumentParser()
add_json_argument(parser)     # --json / dest="as_json"
add_dry_run_argument(parser)  # --dry-run / dest="dry_run"
```

## Typical MCP Tool Pattern

```python
from scitex_dev import wrap_as_mcp, supports_return_as

# Pattern A: wrap plain function
@mcp_server.tool()
def my_tool(path: str) -> str:
    return wrap_as_mcp(plain_handler, path=path)

# Pattern B: @supports_return_as + run_as_mcp
@supports_return_as
def my_handler(path: str) -> dict:
    return {"result": path}

@mcp_server.tool()
def my_tool(path: str) -> str:
    return run_as_mcp(my_handler, path=path)
```
