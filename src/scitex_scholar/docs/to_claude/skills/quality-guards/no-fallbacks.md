---
name: no-fallbacks
description: No silent failures, no fallbacks unless explicitly requested. Errors must be visible.
---

## No fallbacks and No silent failures
- [ ] Do never allow for silent failures.
- [ ] Do never implement fallbacks unless user explicitly requests
- [ ] This is crucial to show errors as errors without hiding actual problems.
  - [ ] For fallbacks user confirmed, please comment it in source code.
  - [ ] Otherwise, no fallbacks accepted.
- [ ] Red cases are useful. We have opportunities to improve. Do not hide them.
- [ ] False positives are really difficult to find and fix. Do not workaround problems silently.
- [ ] Not working must be not working.
- [ ] Not complete must be not complete.
- [ ] Just make everything clear and honest without false information.

---

## SciTeX Error Policy

**Principle**: try/except (and equivalent in all languages) is prohibited by default.

**Reason**:
- Hidden errors multiply bugs
- "Appears to work" is the most dangerous state
- Logged but unread errors are effectively silent

**Exception**: Only allowed with explicit `stx-allow: fallback` directive:
```python
# stx-allow: fallback (reason: network retry on transient failure)
try:
    response = requests.get(url, timeout=5)
except ConnectionError:
    time.sleep(1)
    response = requests.get(url, timeout=5)
```

**Languages**:
- Python: `# stx-allow: fallback (reason: ...)`
- JS/TS: `// stx-allow: fallback (reason: ...)`
- CSS: `/* stx-allow: fallback (reason: ...) */`
- Shell: `# stx-allow: fallback (reason: ...)`

**Without stx-allow**: Linter blocks (ERROR, not WARNING)

### Enforcement

The `no-silent-fallback` linter rule (see scitex-linter) scans for try/except,
try/catch, trap, and equivalent patterns. If the preceding line does not contain
a valid `stx-allow: fallback (reason: ...)` directive, the linter emits an ERROR
and blocks the commit via pre-commit hook.
