---
name: orochi-cli-conventions
description: SciTeX CLI design conventions — verb-noun structure, standard flags, exit codes, output streams. Apply to all new CLI commands across the ecosystem.
---

# CLI Conventions (SciTeX / Orochi Fleet)

These conventions apply to all CLI tools built within the SciTeX ecosystem and Orochi fleet. The upstream definition lives in `scitex-dev` (`scitex/general/interface-cli.md`); this file extends and clarifies it for fleet use.

## Command Structure

### Verb-Noun Pattern (Preferred)
```bash
scitex-orochi list-agents          # verb-noun, hyphenated
scitex-orochi show-history #general
scitex-orochi send-message #general "hi"
```

### Subcommand Hierarchy (For grouped operations)
```bash
scitex-dev skills list             # noun → verb
scitex-dev skills export
scitex-dev mcp start
scitex-dev mcp doctor
```

Pick one style per package and stay consistent. Existing scitex-orochi uses verb-noun for top-level CLI; scitex-dev uses subcommands.

## Standard Flags (All Commands)

| Flag | Purpose | Required for |
|------|---------|--------------|
| `-h`, `--help` | Show usage with examples | All commands |
| `--help-recursive` | Show help for all subcommands recursively | Commands with subcommands |
| `--json` | Machine-readable JSON output | All data-fetching commands |
| `--dry-run` | Preview changes without applying | All mutating commands |
| `--version` | Print package version | Top-level entry point |
| `--verbose`, `-v` | Increase verbosity | Optional |
| `--quiet`, `-q` | Suppress non-error output | Optional |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Generic error (operation failed) |
| 2 | Usage error (bad flags, missing args) |
| 3+ | Domain-specific errors (document in `--help`) |

## Output Streams

- **stdout**: Data, JSON, parseable output. Pipe-friendly.
- **stderr**: Logs, progress, warnings, errors. Not for piped data.
- **Rule**: A user must be able to `cmd --json | jq` without log noise mixing in.

## Help Text Requirements

Every command's `--help` must include:
1. One-line description
2. Usage synopsis
3. **At least one example** (concrete invocation)
4. List of flags with descriptions
5. Exit code summary (if non-trivial)

## Environment Variables

- All package-level env vars use the `SCITEX_<PACKAGE>_*` prefix (e.g., `SCITEX_OROCHI_HOST`)
- CLI flags should override env vars
- Document env var fallbacks in `--help`

### Bare prefixes are forbidden (Hard Rule)

**Never use a bare package name as an env var prefix.** Always include `SCITEX_`:

| ❌ Forbidden | ✅ Required |
|---|---|
| `OROCHI_AGENT` | `SCITEX_OROCHI_AGENT` |
| `OROCHI_TOKEN` | `SCITEX_OROCHI_TOKEN` |
| `OROCHI_HOST` | `SCITEX_OROCHI_HOST` |
| `OROCHI_MULTIPLEXER` | `SCITEX_OROCHI_MULTIPLEXER` |
| `AGENT_CONTAINER_*` | `SCITEX_AGENT_CONTAINER_*` |
| `SCHOLAR_*` | `SCITEX_SCHOLAR_*` |

Reason (operator directive 2026-04-12): bare prefixes collide with other tools'
env vars and pollute the global namespace. The `SCITEX_` namespace makes
ownership unambiguous and lets users `env | grep SCITEX_` to see all
SciTeX-related state at once.

When auditing existing code, `grep -rE '^OROCHI_|[^A-Z_]OROCHI_'` finds
violations. Rename and update all references in one commit.

### Scope: scitex-owned vars only

The `SCITEX_<PACKAGE>_*` rule applies **only to env vars that scitex code
defines and reads**. It does **not** apply to env vars defined by
third-party tools, frameworks, or upstream conventions:

- **Out of scope (keep upstream names):** `POSTGRES_*`, `DATABASE_URL`,
  `DJANGO_*`, `ALLOWED_HOSTS`, `VITE_*`, `NODE_ENV`, `PATH`, `HOME`,
  `LANG`, `BUILD_ID`, `CI`, `GITHUB_*`, `AWS_*`, etc.
- **In scope (must rename):** any env var that scitex code originates and
  whose name we control.
- **Borderline cases** (third-party integration configured by scitex —
  e.g. `GITEA_URL`, `CROSSREF_INTERNAL_URL`): if scitex code is the only
  reader and the var is not a standard set by the upstream tool, prefer
  the namespaced form (`SCITEX_CLOUD_GITEA_URL`). If the upstream tool
  reads it directly, leave it.

When in doubt: if removing the `SCITEX_` prefix would break a third-party
tool, keep the upstream name.

**Adapter pattern for framework env vars (preferred):** When a framework
like Django expects a specific env var name (e.g. `ALLOWED_HOSTS`,
`POSTGRES_PASSWORD`), the canonical scitex source of truth should still
be `SCITEX_<PACKAGE>_*`. Translate inside the framework's config file:

```python
# scitex-cloud/settings.py
import os
ALLOWED_HOSTS = os.environ.get("SCITEX_CLOUD_ALLOWED_HOSTS", "").split(",")
DATABASES = {
    "default": {
        "PASSWORD": os.environ["SCITEX_CLOUD_POSTGRES_PASSWORD"],
        ...
    }
}
```

This keeps the operator-facing env namespace clean (`SCITEX_CLOUD_*` only)
while letting Django still receive the values it needs internally.
The operator (2026-04-12) explicitly requested this pattern for scitex-cloud:
"DJANGO で認識されるようにしないといけないのもあるかも。その場合は
settings.py で書きなおす". Apply the same pattern to Vite, Postgres
client libs, etc., when feasible.

### Where SCITEX_* env vars live (canonical location)

All scitex-owned env vars are sourced from
**`~/.dotfiles/src/.bash.d/secrets/010_scitex/`** (one `.src` file per
package: `01_orochi.src`, `01_cloud.src`, `01_agent-container.src`,
`01_scholar.src`, etc.). The aggregator `scitex_entry.src` loads them at
shell startup so all `SCITEX_*` vars are available to every scitex tool.

Rules:
- When adding a new `SCITEX_<PACKAGE>_FOO` var, **add the export to the
  matching `01_<package>.src` file** in `010_scitex/`. Don't scatter
  scitex env vars across other shell init files.
- When renaming a bare-prefix var (e.g. `OROCHI_TOKEN` → `SCITEX_OROCHI_TOKEN`),
  re-import / re-export from the same `01_orochi.src` file so all hosts
  pick up the new name on next shell init.
- Secrets stay in this directory (gitignored from the main dotfiles repo;
  see the operator's secret-dotfiles convention) — never inline secrets in
  package code or YAML.

## MCP Tool Parity

When a CLI command corresponds to an MCP tool:
- Use the same name (or close: `scitex-orochi send-message` ↔ `mcp__scitex-orochi__send`)
- Same arguments
- Same JSON shape for output
- Document parity in the package SKILL.md

## No Interactive Prompts (Hard Rule)

CLI commands MUST be non-interactive by default — they must work in pipelines, CI, and unattended agent runs.

- **Never prompt for input** at runtime (no `input()`, no `read`, no password prompts)
- If credentials are needed, read from env vars, config files, or `--flag` args
- If a value is missing, **fail fast with a clear error message** — do not block waiting

### Fail-First Pattern

Validate all preconditions at the **start** of the command, before doing any work:

```python
def main():
    # 1. Check all preconditions FIRST
    if not have_sudo():
        sys.stderr.write("error: this command requires sudo. Run with sudo or set X.\n")
        sys.exit(2)
    if not config_exists():
        sys.stderr.write("error: missing config at ~/.scitex/config.yaml\n")
        sys.exit(2)

    # 2. Only then proceed with the actual work
    do_work()
```

**Why**: Interactive prompts break agent automation. A command that asks "Are you sure? [y/N]" or prompts for sudo password mid-run will hang forever in a tmux session. Fail-first means failures happen in seconds, not after partial work.

### Acceptable: `--yes` Override

Mutating commands may use `--yes` / `-y` to bypass safety checks, but the **default** must be safe (e.g., `--dry-run` style preview, then `--yes` to apply).

## Audit Checklist (For Existing Commands)

When auditing a SciTeX package's CLI for compliance:

- [ ] Verb-noun OR subcommand structure (consistent)
- [ ] `--help` works on every command
- [ ] `--help-recursive` works at top level
- [ ] `--json` available on all data commands
- [ ] `--dry-run` available on all mutating commands
- [ ] Exit codes follow convention
- [ ] stdout vs stderr separation correct
- [ ] Examples in help text
- [ ] Env var prefix correct (`SCITEX_<PKG>_*`)
- [ ] MCP tool parity (if applicable)

Failing items should be filed as `cli-audit` issues in `the project's issue tracker`.
