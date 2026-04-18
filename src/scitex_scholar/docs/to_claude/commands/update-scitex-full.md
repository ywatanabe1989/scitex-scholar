## Skills to Load (Required)
skill:scitex-dev-full-update
skill:speak-and-signature
skill:autonomous
skill:quality-guards

## Task: Full Ecosystem Release

Follow the full-update skill strictly — 5 phases, 20 steps, in order.

1. **Phase 1: Pre-flight** (steps 1–4) — check_ci, detect_mismatches, fix_init_version, verify_pypi_config
2. **Phase 2: Version Bump + Release** (steps 5–12) — determine_bump_type, bump_version, verify_docs_and_skills, commit_and_tag, check_ci_before_push, push, create_github_release, wait_for_pypi
3. **Phase 3: Local Sync** (steps 13–14) — fix_local, verify_versions
4. **Phase 4: Host Sync** (steps 15–17) — fix_remote [Custom], deploy_scitex_cloud [Custom], verify_production [Custom]
5. **Phase 5: Verification** (steps 18–20) — verify_versions, verify_production [Custom], report_summary

Each step has Python API, CLI, and MCP tool — use the most appropriate for the context.
Use parallel subagents for independent packages within a phase.
Present ecosystem summary table when done.

## Arguments
$ARGUMENTS

(If no arguments, process all packages with appropriate version increments)
