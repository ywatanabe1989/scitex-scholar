---
description: Cloud SDK — DataStore (JSON CRUD), FileVault (file storage), JobQueue (background compute). CLI and Python API. SDK code lives in scitex-app but re-exported from scitex-cloud for backward compatibility.
---

# Cloud SDK

Three services: DataStore (JSON records), FileVault (files), JobQueue (async jobs).

## CLI

All commands under `scitex-cloud sdk`.

### DataStore

```bash
scitex-cloud sdk data list   <app> <schema> [--filter key=val ...] [--project ID]
scitex-cloud sdk data get    <app> <schema> <record_id>
scitex-cloud sdk data create <app> <schema> --json '{"title": "Experiment 1"}'
scitex-cloud sdk data update <app> <schema> <record_id> --json '{"status": "done"}'
scitex-cloud sdk data delete <app> <schema> <record_id>
scitex-cloud sdk data search <app> <schema> -q "query string"
```

### FileVault

```bash
scitex-cloud sdk files list     <app> [--path subdir] [--project ID] [--ext .csv]
scitex-cloud sdk files upload   <app> <local_path> <remote_path> [--project ID]
scitex-cloud sdk files download <app> <remote_path> [--project ID]
scitex-cloud sdk files delete   <app> <remote_path> [--project ID]
```

### JobQueue

```bash
scitex-cloud sdk jobs submit <app> <job_name> [--params '{"fmt":"xlsx"}'] [--project ID]
scitex-cloud sdk jobs status <app> <job_id>
scitex-cloud sdk jobs list   <app>
scitex-cloud sdk jobs cancel <app> <job_id>
```

## Python API

```python
from scitex_cloud.sdk import data, files, jobs
# (Preferred: from scitex_app.sdk import _cloud_data as data, ...)

# DataStore
records = data.list_records(app, schema, filters={"status": "active"}, project_id=None)
record  = data.get(app, schema, record_id)
created = data.create(app, schema, {"title": "Experiment 1", "params": {...}})
updated = data.update(app, schema, record_id, {"status": "done"})
data.delete(app, schema, record_id)
results = data.search(app, schema, "query string")

# FileVault
listing = files.list_files(app, path="", project=None, extensions=None)
result  = files.upload(app, remote_path, content: bytes, project=None)
result  = files.download(app, remote_path, project=None)
result  = files.delete(app, remote_path, project=None)

# JobQueue
job     = jobs.submit(app, job_name, params={"fmt": "xlsx"}, project_id=None)
status  = jobs.status(app, job_id)
all_jobs = jobs.list_jobs(app)
result  = jobs.cancel(app, job_id)
```

## PlatformClient

```python
from scitex_cloud.sdk import PlatformClient, get_client, reset_client

client = get_client()         # singleton
client = PlatformClient(...)  # explicit
reset_client()                # clear singleton
```

## MCP Tools

| Tool | What it does |
|------|-------------|
| `cloud_cloud_sdk_data_list` | List DataStore records |
| `cloud_cloud_sdk_data_create` | Create record |
| `cloud_cloud_sdk_data_get` | Get record by ID |
| `cloud_cloud_sdk_data_update` | Update record |
| `cloud_cloud_sdk_data_delete` | Delete record |
| `cloud_cloud_sdk_data_search` | Full-text search |
| `cloud_cloud_sdk_files_list` | List files |
| `cloud_cloud_sdk_files_upload` | Upload file |
| `cloud_cloud_sdk_files_download` | Download file |
| `cloud_cloud_sdk_files_delete` | Delete file |
| `cloud_cloud_sdk_jobs_submit` | Submit job |
| `cloud_cloud_sdk_jobs_status` | Get job status |
| `cloud_cloud_sdk_jobs_list` | List jobs |
| `cloud_cloud_sdk_jobs_cancel` | Cancel job |

## Examples

```bash
# Store experiment results
scitex-cloud sdk data create my_app Experiment \
  --json '{"title": "Run 1", "accuracy": 0.95}'

# Upload output CSV
scitex-cloud sdk files upload my_app ./results.csv exports/results.csv

# Submit background export job, then poll
scitex-cloud sdk jobs submit my_app export_csv --params '{"fmt":"xlsx"}'
# -> {"job_id": "j_abc123"}
scitex-cloud sdk jobs status my_app j_abc123
```

# EOF
