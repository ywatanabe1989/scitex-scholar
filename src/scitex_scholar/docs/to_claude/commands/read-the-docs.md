# Check Read the Docs Builds Status and fix if needed

## Project Build Status Page
https://app.readthedocs.org/projects/<package-name>/builds/<build-id>/

## How to Trigger Builds
PR to origin/main

## Full Log (this is long but useful for identifying actual error)
https://app.readthedocs.org/api/v2/build/<build-id>.txt

## Note
- Follow the format of already accomplished projects
  ~/proj/figrecipe
  ~/proj/scitex-writer
- Especially, install[all] is the key. It would be heavy but no package error is much better.
- Often encountered issue:
  ```
  python -m pip install --exists-action=w --no-cache-dir -r docs/sphinx/requirements.txt  
  ERROR: Could not open requirements file: [Errno 2] No such file or directory: 'docs/sphinx/requirements.txt'
  ```
