# Script Templates

## Key Rules

- Every script and function gets `-h|--help`
- Show env var names in help defaults: `(default: \$MY_TOOL_OUTPUT_DIR)` — not resolved values
- Include one-line description + example usage for each function
- Use `set -euo pipefail` for strict mode where appropriate
- Quote all variables: `"$var"` not `$var`
- Use `shellcheck` for validation
- Log to hidden file: `LOG_FILE=".$0.log"`

## Bash Script Template

```bash
#!/bin/bash
# script-name.sh
# Author: ywatanabe (ywatanabe@alumni.u-tokyo.ac.jp)
# Date: $(date +"%Y-%m-%d-%H-%M")

LOG_FILE=".$0.log"

usage() {
    echo "Usage: $0 [-s|--subject <subject>] [-m|--message <message>] [-h|--help]"
    echo
    echo "Options:"
    echo "  -s, --subject   Subject (default: \$MY_TOOL_SUBJECT, or 'Subject')"
    echo "  -m, --message   Message body (default: \$MY_TOOL_MESSAGE, or 'Message')"
    echo "  -h, --help      Display this help message"
    echo
    echo "Example:"
    echo "  $0 -s \"About Project A\" -m \"Hi, ...\""
    exit 1
}

main() {
    local subject="Subject"
    local message="Message"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--subject) subject="$2"; shift 2 ;;
            -m|--message) message="$2"; shift 2 ;;
            -h|--help) usage ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    echo "${subject}: ${message}"
}

main "$@" 2>&1 | tee "$LOG_FILE"

# EOF
```

## Function Ordering

Top-down hierarchy with section comments:

```bash
# 1. Main entry point
# ----------------------------------------

# 2. Core functions
# ----------------------------------------

# 3. Helper functions
# ----------------------------------------
```

## SLURM Template

File name: `*_sbatch.sh`

```bash
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --time=12:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-15

patient_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ./data/IDS.txt | tr -d '\n')
./scripts/process.py --id "$patient_id"

# sbatch ./scripts/my_job_sbatch.sh
# EOF
```
