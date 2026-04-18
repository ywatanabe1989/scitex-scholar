---
description: STX-IO001–007 lint rules detected by scitex-linter when scitex-io is installed.
---

# Linting Rules

Detected by [scitex-linter](https://github.com/ywatanabe1989/scitex-linter) via entry point `scitex_linter.plugins`.

| Rule | Detects | Suggestion |
|------|---------|------------|
| STX-IO001 | `np.save()` | → `stx.io.save(arr, path)` |
| STX-IO002 | `np.load()` | → `stx.io.load(path)` |
| STX-IO003 | `pd.read_csv()` | → `stx.io.load(path)` |
| STX-IO004 | `.to_csv()` | → `stx.io.save(df, path)` |
| STX-IO005 | `pickle.dump()` | → `stx.io.save(obj, "file.pkl")` |
| STX-IO006 | `json.dump()` | → `stx.io.save(obj, "file.json")` |
| STX-IO007 | `.savefig()` | → `stx.io.save(fig, path)` for metadata embedding |

All rules: severity `warning`, category `io`.

**Why**: `stx.io.save/load` provides provenance tracking, auto-CSV export for figures, metadata embedding, and centralized format dispatch. Direct library calls bypass these.
