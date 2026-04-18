# Centralized Project Settings System

Control all project-specific hook settings from one location: `.claude/hooks/project-switch/`

## Overview

All project-specific settings are centralized in the `project-switch/` directory:
- **One** `switch.yaml` controls ALL hook types (pre-tool-use, post-tool-use, notification, etc.)
- **One** `project-root-pollution-criteria.yaml` defines allowed root files
- **Pattern-based sync**: Only files with `*example*` in the name are synced
- All other files in `project-switch/` are **project-specific** and never synced

## Setup

1. Navigate to the centralized settings directory:
   ```bash
   cd .claude/hooks/project-switch/
   ```

2. Copy example files:
   ```bash
   cp switch-example.yaml switch.yaml
   cp project-root-pollution-criteria-example.yaml project-root-pollution-criteria.yaml
   ```

3. Edit `switch.yaml` to control ALL hooks:
   ```yaml
   on:
     # Pre-tool-use
     limit_line_numbers.sh

     # Post-tool-use
     run_lint.sh

     # Notification
     notify_voice.sh

   off:
     # Pre-tool-use
     prevent_project_root_pollution.sh

     # Post-tool-use
     run_tests.sh
   ```

4. Hooks automatically check the centralized `switch.yaml` and skip if disabled

## Adding Switch Support to Hooks

Add this code near the top of your hook script:

```bash
# Check if hook is enabled via centralized project-switch/switch.yaml
HELPER_SCRIPT="$(dirname "$THIS_DIR")/project-switch/hook_switch_helper.sh"
if [[ -f "$HELPER_SCRIPT" ]]; then
    # shellcheck source=/dev/null
    source "$HELPER_SCRIPT"
    check_hook_enabled_or_exit "$(basename "$0")"
fi
```

This pattern:
- Automatically uses centralized `project-switch/switch.yaml`
- No need to specify paths - helper finds it automatically
- Works for ALL hook types: pre-tool-use, post-tool-use, notification, stop, session-start

## Directory Structure

```
.claude/hooks/
├── project-switch/                                 # Centralized project settings
│   ├── hook_switch_helper.sh                       # Shared helper (synced)
│   ├── switch-example.yaml                         # Template (synced)
│   ├── switch.yaml                                 # Your config (never synced)
│   ├── project-root-pollution-criteria-example.yaml  # Template (synced)
│   └── project-root-pollution-criteria.yaml        # Your config (never synced)
├── pre-tool-use/
│   ├── limit_line_numbers.sh
│   └── prevent_project_root_pollution.sh
├── post-tool-use/
│   ├── run_lint.sh
│   └── run_tests.sh
└── notification/
    ├── notify_voice.sh
    └── notify_email.sh
```

## Behavior

| Hook Listed | Location | Behavior |
|------------|----------|----------|
| In `on:` | switch.yaml | Runs |
| In `off:` | switch.yaml | Skipped |
| Not listed | - | Runs (default) |
| No switch.yaml exists | - | All hooks run |

## Example Use Cases

**Development projects**: Disable strict checks
```yaml
off:
  prevent_project_root_pollution.sh
  limit_line_numbers.sh
  run_tests.sh
```

**Production projects**: Enable all checks
```yaml
on:
  prevent_project_root_pollution.sh
  limit_line_numbers.sh
  run_tests.sh
  run_lint.sh
```

**Quiet work**: Disable notifications
```yaml
off:
  notify_voice.sh
  notify_email.sh
```

**Temporary disable**: Quick toggle without deleting hooks
```yaml
off:
  run_tests.sh  # Temporarily disabled for debugging
```

## Benefits of Centralization

1. **Single source of truth**: One file controls all hooks across all types
2. **Easy to review**: See all project settings in one place
3. **No scattered configs**: No need to check multiple directories
4. **Simpler hooks**: Hooks don't need to specify paths
5. **Pattern-based sync**: Any new `*example*` file automatically syncs
6. **Maintainable**: No need to update exclusion lists for new templates
