## Skills To Load (Required)
- skill:no-fallbacks
- skill:no-false-positives
- skill:no-long-term-memory
- skill:scitex-package-standards
- skill:programming-common

## Commands to Read (Required)
- command:cli-commands
- command:publish-pypi

## Audit

Is everything clean and professional? For example:

### Pyproject.toml
- [ ] This is the place where first author is credited. For me, use:
  - [ ] Name: Yusuke Watanabe
  - [ ] Contact: ywatanabe@scitex.ai

### Documents
- [ ] Organized
- [ ] up-to-date
- [ ] No redundant information
- [ ] Necessary and sufficient

### Shell Script
- [ ] Have argparser, usage command, help option

### Python API
- [ ] Internal code are not exposed to users
- [ ] APIs are minimized for high UX

### Tests
- [ ] Coverage must be calculated and sufficient (minimal: 50%)?

### CI
- [ ] Is CI correctly setup?
- [ ] Is the last CI passed? If failed, are they already fixed?

### Cleanliness
- [ ] Is project root clean without unnecessary artifacts?

### The project will work as expected and documented
- [ ] Run small experiments for verification if needed 

### Version consistency
- [ ] toml, __init__.py, tag, release, pypi and so on

### No personal info
- [ ] If package is designed for publication, do not include my own setups and keep generic tones
- [ ] Exceptions: .env contents (gitignored), name, email, github info
  
### Environmental Variables
- [ ] Safe for name conflict with prefix (e.g., NG: "ENV_NAME", OK: "PROJECT_NAME_ENV_NAME")
- [ ] PROJECT_NAME_DEBUG_MDOE=1
- [ ] .env file in project root

## SciTeX-specific standards
See skill:scitex-package-standards for architecture, README format, CLI/MCP/API requirements.



If you find room for improvement, do not hesitate but keep on working the remaining tasks
