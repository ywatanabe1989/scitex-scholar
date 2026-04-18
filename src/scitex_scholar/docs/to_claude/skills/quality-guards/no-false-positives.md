---
name: no-false-positives
description: Verification before declaration. Never claim done without evidence at all levels.
---

# No False Positives — Verification Before Declaration

**NEVER claim "fixed", "working", "done", or "confirmed" without completing ALL verification steps.**
**ALL steps are REQUIRED. No exceptions. Split into smaller sub-steps when needed.**

## Verification Checklist (ALL required, in order)

### 1. Log-level verification
- [ ] Read actual container/service logs (not just exit codes)
- [ ] Check for errors, warnings, stack traces
- [ ] Confirm the specific operation completed (e.g., "Vite build complete", not just "container started")
- [ ] If logs are truncated, fetch the full relevant section

### 2. Tests-level verification
- [ ] Run relevant unit/integration tests
- [ ] Read test output line by line — PASS/FAIL for each
- [ ] If no tests exist, note it explicitly — don't skip silently

### 3. Visual verification (REQUIRED — not optional)
- [ ] Open the page with `playwright-cli`
- [ ] Navigate to the exact page the user reported broken
- [ ] Log in if auth is required (use Playwright fill/click)
- [ ] Take a screenshot with `playwright-cli screenshot`
- [ ] Read the screenshot file with the Read tool to see it
- [ ] Compare against the expected layout (reference screenshot from local dev)
- [ ] Do NOT rely on HTTP status codes — 200 does not mean CSS loaded
- [ ] Do NOT rely on curl — it cannot see rendered layout

### 4. Functional verification (REQUIRED — not optional)
- [ ] Test the exact user scenario that was reported broken
- [ ] Verify on the actual environment (prod, not local dev)
- [ ] Interact with the page (click, type) to confirm functionality
- [ ] Check browser console for errors (use `playwright-cli console`)
- [ ] Only after ALL sub-steps pass, declare the result

## Rules

- ALL 4 levels are REQUIRED for every fix/deployment claim
- Each step must produce evidence (log output, screenshot, test result)
- If ANY step fails, the fix is NOT confirmed — say so honestly
- NEVER call the user to confirm before YOU have verified ALL steps
- NEVER say "standing by" — actively investigate and verify
- If you cannot complete a step, explain WHY and what you tried

## Anti-patterns (NEVER do these)

- Declaring "fixed" based on `curl -s -o /dev/null -w "%{http_code}"`
- Calling the user to "confirm" when you haven't checked yourself
- Saying "should be working now" without visual proof
- Claiming "CSS applied" without seeing the rendered page
- Saying "standing by" instead of actively investigating
- Reporting HTTP 302 as "site is up" without checking the actual page content
- **Trusting rebuild log output without verifying containers are actually running**
  - "rebuild complete" in log does NOT mean the site is up
  - ALWAYS check `docker ps` and `docker logs` AFTER rebuild
  - ALWAYS verify the screen session is still alive (`screen -ls`)
  - A screen session disappearing means it either completed OR crashed — investigate which
- **Trusting background task output without reading the actual logs**
  - Read `docker logs <container>` not just rebuild script output
  - Check container health status: `healthy`, `unhealthy`, `health: starting`
  - Look for error messages in the FULL log, not just the last 5 lines
- **Polling HTTP status codes instead of reading logs**
  - 503/530 tells you the site is down — but NOT why
  - Always SSH in and read `docker logs` to find the actual error
  - Root causes this session: mermaid package break, npm OOM, PyPI network timeout
- **Declaring "code loaded" as "feature working"**
  - Console log showing "initialized" or "touch: enabled" does NOT mean the feature works
  - Code loading ≠ code functioning — the code may load but have logic bugs, CSS conflicts, or wrong selectors
  - For interactive features (drag, resize, swipe): MUST test the actual interaction via playwright-cli drag/click
  - For CSS changes: MUST inspect the element's computed styles, not just check if the file loaded
  - A screenshot showing layout ≠ drag working — screenshots are static, interactions are dynamic
  - ALWAYS test the exact user scenario: "drag resizer down → pane grows" not just "resizer element exists"
