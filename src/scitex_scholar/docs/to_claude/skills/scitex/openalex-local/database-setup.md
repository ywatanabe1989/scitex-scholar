---
description: Database architecture, build pipeline, access modes, and deployment options.
---

# Database Setup and Architecture

## Database Contents

| Table | Contents | Size |
|-------|----------|------|
| `works` | 284M+ scholarly works with metadata | ~200 GB |
| `works_fts` | FTS5 index on title + abstract | ~100 GB |
| `sources` | Journal metadata + SciTeX IF | Optional |
| `journal_impact_factors` | Precomputed impact factors | Optional |
| `_metadata` | Pre-computed counts | Auto |

## Build Pipeline

```bash
# 1. Download OpenAlex snapshot (~300 GB compressed)
python scripts/database/01_download_snapshot.py

# 2. Build SQLite database
python scripts/database/02_build_database.py

# 3. Build FTS5 search index
python scripts/database/03_build_fts_index.py

# 4. (Optional) Build sources/journal table
python scripts/database/04_build_sources_table.py

# 5. (Optional) Build citations table
python scripts/database/05_build_citations_table.py

# 6. (Optional) Build impact factor indexes
python scripts/database/06_build_if_indexes.py
```

## Access Modes

### Direct Database (db mode)

```bash
export OPENALEX_LOCAL_DB=/path/to/openalex.db
openalex-local search "CRISPR"
```

### HTTP Relay (http mode)

```bash
# On the server with the database
openalex-local relay --host 0.0.0.0 --port 31292

# On the client
export OPENALEX_LOCAL_MODE=http
export OPENALEX_LOCAL_API_URL=http://server:31292
openalex-local search "CRISPR"

# Or via SSH tunnel
ssh -L 31292:127.0.0.1:31292 your-server
```

## Database Discovery

openalex-local auto-discovers databases at these paths (in order):

1. `$OPENALEX_LOCAL_DB` (environment variable)
2. `./data/openalex.db` (project directory)
3. `/mnt/nas_ug/openalex_local/data/openalex.db` (NAS mount)
4. `~/.openalex_local/openalex.db` (home directory)

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `OPENALEX_LOCAL_DB` | Database path | `/data/openalex.db` |
| `OPENALEX_LOCAL_API_URL` | HTTP API URL | `http://localhost:31292` |
| `OPENALEX_LOCAL_MODE` | Force mode | `db`, `http`, or `auto` |
| `OPENALEX_LOCAL_HOST` | Relay bind host | `0.0.0.0` |
| `OPENALEX_LOCAL_PORT` | Relay port | `31292` |
