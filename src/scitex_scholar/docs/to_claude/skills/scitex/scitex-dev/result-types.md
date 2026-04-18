---
topic: result-types
package: scitex-dev
description: >
  LLM-friendly structured return types. Result wraps function output with
  metadata for CLI and MCP consumers. ErrorCode maps exception types to
  machine-readable codes. @supports_return_as adds opt-in Result wrapping.
  SideEffect declares mutations for LLM transparency.
---

# Result Types

## Result

Structured return value wrapping function output with metadata.

```python
from scitex_dev import Result

Result(
    success: bool,
    data: T | None = None,
    error: str | None = None,
    error_code: str | None = None,   # "E001"–"E999"
    context: dict = {},
    side_effects: list[str] = [],
    hints_on_success: list[str] = [],
    hints_on_warning: list[str] = [],
    hints_on_error: list[str] = [],  # FAQ-style recovery guidance
    idempotent: bool = False,
    version: str | None = None,
)
```

### Key properties and methods

```python
result.exit_code        # int — 0 on success, POSIX code from error_code
result.to_dict()        # dict — drops None values
result.to_json(indent=2)  # str — JSON string
Result.json_schema()    # dict — JSON Schema of the envelope
```

### Example: success

```python
r = Result(success=True, data={"rows": 42})
print(r.exit_code)     # 0
print(r.to_json())
# {"success": true, "data": {"rows": 42}}
```

### Example: failure with hints

```python
r = Result(
    success=False,
    error="Config file not found",
    error_code="E002",
    hints_on_error=["Run: scitex-dev config create"],
)
print(r.exit_code)     # 1
```

## RESULT_SCHEMA

JSON Schema dict describing the Result envelope. Useful for MCP tool
`outputSchema` declarations.

```python
from scitex_dev import RESULT_SCHEMA
print(RESULT_SCHEMA["properties"].keys())
# dict_keys(['success', 'data', 'error', 'error_code', 'context',
#            'side_effects', 'hints_on_success', 'hints_on_warning',
#            'hints_on_error', 'idempotent', 'version'])
```

## ErrorCode

Enum mapping exception categories to machine-readable codes.

```python
from scitex_dev import ErrorCode

ErrorCode.OK            # "E000" — exit 0
ErrorCode.VALIDATION    # "E001" — exit 2
ErrorCode.FILE_NOT_FOUND  # "E002" — exit 1
ErrorCode.PERMISSION    # "E003" — exit 4
ErrorCode.DEPENDENCY    # "E004" — exit 3
ErrorCode.TIMEOUT       # "E005" — exit 5
ErrorCode.RATE_LIMITED  # "E006" — exit 5
ErrorCode.NETWORK       # "E007" — exit 1
ErrorCode.CONFIG        # "E008" — exit 2
ErrorCode.CONFLICT      # "E009" — exit 6
ErrorCode.INTERNAL      # "E999" — exit 1

ErrorCode.FILE_NOT_FOUND.exit_code  # 1
```

## classify_exception

Maps any exception to an ErrorCode.

```python
from scitex_dev import classify_exception

classify_exception(FileNotFoundError("x"))  # ErrorCode.FILE_NOT_FOUND
classify_exception(ValueError("bad"))       # ErrorCode.VALIDATION
classify_exception(ImportError("missing"))  # ErrorCode.DEPENDENCY
```

Checks `exc.error_code` attribute first (SciTeXError convention), then
falls back to built-in exception type mapping.

## @supports_return_as

Decorator that adds `return_as="result"` to any function.

```python
from scitex_dev import supports_return_as

@supports_return_as
def add(a: int, b: int) -> int:
    return a + b

# Default: behaves normally
add(1, 2)              # 3

# With return_as="result": wrapped in Result
r = add(1, 2, return_as="result")
r.success              # True
r.data                 # 3

# Exceptions become Result(success=False)
@supports_return_as
def divide(a, b):
    return a / b

r = divide(1, 0, return_as="result")
r.success              # False
r.error                # "division by zero"
r.error_code           # "E999"
```

## SideEffect

Frozen dataclass declaring a mutation for LLM transparency.

```python
from scitex_dev import SideEffect

SideEffect(
    type: Literal[
        "file_create", "file_modify", "file_delete",
        "network", "state_change", "cache_write"
    ],
    target: str,     # e.g. "/tmp/out.csv" or "https://api.example.com"
    undoable: bool = False,
)

se = SideEffect(type="file_create", target="/tmp/out.csv", undoable=False)
str(se)    # "file_create: /tmp/out.csv"
```

Typically declared alongside `wrap_as_mcp(side_effects=[str(se)])`.
