# Check GitHub actions and suggest how we can improve the quality of this project
```bash
gh repo set-default <github-username>/<repository-name>
# e.g., gh repo set-default ywatanabe1989/scitex-code

# List recent workflow runs
gh run list --limit 10 --branch develop

#View spefic run details
gh run view <RUN_ID>
# e.g., gh run view 18892191254

# Get logs from a run
gh run view <RUN_ID> --log
# e.g., gh run view 18892191254 --log

# Get specific workflow information
gh workflow list
gh workflow view <WORKFLOW_ID>
```

# Check Read the Docs Builds Status and fix if needed

## Project Build Status Page
https://app.readthedocs.org/projects/<package-name>/builds/<build-id>/

## Full Log
https://app.readthedocs.org/api/v2/build/<build-id>.txt
