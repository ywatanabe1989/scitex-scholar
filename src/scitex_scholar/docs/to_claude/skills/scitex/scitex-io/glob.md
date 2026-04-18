---
description: Pattern-based file matching with natural sorting and path parsing.
---

# Glob

## sio.glob()

```python
def glob(
    expression,
    parse=False,
    ensure_one=False,
) -> Union[List[str], Tuple[List[str], List[dict]]]:
```

- Natural sorting (1, 2, 10 — not 1, 10, 2)
- Supports `**` recursive, `{a,b}` brace expansion
- `ensure_one=True` asserts exactly one match (raises AssertionError otherwise)

### Basic file matching

```python
import scitex_io as sio

# All CSV files in a directory (naturally sorted)
paths = sio.glob("data/*.csv")
# → ['data/file1.csv', 'data/file2.csv', 'data/file10.csv']
#   (not file1, file10, file2 like standard sorted)

# Recursive search with **
paths = sio.glob("project/**/*.npy")
# → ['project/exp1/data.npy', 'project/exp2/sub/data.npy']

# Brace expansion — match multiple directories
paths = sio.glob("results/{exp1,exp2}/*.csv")
# → ['results/exp1/accuracy.csv', 'results/exp2/accuracy.csv']

# Ensure exactly one match
path = sio.glob("config/model_*.yaml", ensure_one=True)
# → ['config/model_final.yaml']   (AssertionError if 0 or 2+ matches)
```

### Parsing with {named} placeholders

Use `{name}` placeholders in the pattern. Each `{name}` acts as a wildcard `*` for matching, and the captured value is returned as a dict.

```python
# Neuroscience BIDS-style directory
paths, parsed = sio.glob(
    "data/sub_{id}/ses_{session}/eeg/sub_{id}_ses_{session}_eeg.vhdr",
    parse=True
)
# paths → [
#   'data/sub_001/ses_pre/eeg/sub_001_ses_pre_eeg.vhdr',
#   'data/sub_001/ses_post/eeg/sub_001_ses_post_eeg.vhdr',
#   'data/sub_002/ses_pre/eeg/sub_002_ses_pre_eeg.vhdr',
# ]
# parsed → [
#   {'id': '001', 'session': 'pre'},
#   {'id': '001', 'session': 'post'},
#   {'id': '002', 'session': 'pre'},
# ]

# ML experiment results
paths, parsed = sio.glob(
    "runs/model_{model}/lr_{lr}/epoch_{epoch}.pt",
    parse=True
)
# parsed → [
#   {'model': 'resnet50', 'lr': '0.001', 'epoch': '100'},
#   {'model': 'resnet50', 'lr': '0.01',  'epoch': '050'},
# ]

# Use parsed values for filtering
for path, p in zip(paths, parsed):
    if p['lr'] == '0.001':
        model = sio.load(path)
```

## sio.parse_glob()

Convenience wrapper — equivalent to `sio.glob(expr, parse=True)`.

```python
paths, parsed = sio.parse_glob("data/subj_{id}/run_{run}.csv")
# Same as: sio.glob("data/subj_{id}/run_{run}.csv", parse=True)
```

## In sio.load()

Glob patterns work directly in `load()` — all matches loaded as a list:

```python
# Load all CSVs as list of DataFrames
dfs = sio.load("results/*.csv")
# → [DataFrame, DataFrame, DataFrame]

# Load all numpy arrays
arrays = sio.load("features/**/*.npy")
```

## Combining with save()

```python
# Process all subjects, save per-subject results
for path, p in zip(*sio.parse_glob("raw/sub_{id}/*.edf")):
    data = sio.load(path)
    result = process(data)
    sio.save(result, f"sub_{p['id']}_processed.csv")
```
