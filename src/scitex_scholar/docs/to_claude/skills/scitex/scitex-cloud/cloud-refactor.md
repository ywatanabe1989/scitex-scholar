## Refactoring

### Requests
Refactor the codebase following the rules below.
This aims to reduce numebr of files in an organized, systematic manner to improve maintainability - long file will be cause of issues.

### Rules
See ./GITIGNORED/RULES/*.md

### Checker
`./scripts/check_file_sizes.sh --verbose`

### No inline css/script
DO NEVER USE INLINE CSS and SCRIPT. Instead prepare and link external css/typescript files, following the rules.

### Typescript instead of Javascript
Typescript files are automatically built. Please see tsconfig if you have questions. DO NEVER USE JS BUT TS

### With commits
When an logical chunk of code refactored, please git commit for the logical chunk with proper commit message.

### manual mode
Do not run bulk refactoring as regexp and systematic refactoring often fails and introduce nightmare.

### Work on local files instead of Docker files
Do not change files in docker containers directly as it is meaningless. We need reproducible setup. Neessary files are rsynced, copied, built, or volume-mounted.

## Subagents
When time can be shortened, launch and delegate your tasks to subagents up to 32 instances in parallel, under your supervision. Agents have -{HAIKU,SONNET,OPUS} suffixes so that please specify these model variants based on the difficulty of the task to delegate. HAIKU is faster, SONNET is balanced, and OPUS is more intelligent.
