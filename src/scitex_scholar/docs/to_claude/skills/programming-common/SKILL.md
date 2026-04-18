---
name: programming-principles
description: >
  Use this skill when writing, reviewing, or refactoring any code.
  Provides a checklist of essential programming principles (DRY, KISS,
  SOLID, YAGNI, etc.) to verify before finalizing any implementation.
  Triggers: "check my code", "review this", "refactor", "write a module",
  "create a class", "implement a function", "does this follow best practices".
---

# Programming Principles Checklist

A comprehensive checklist of programming principles for writing clean,
maintainable, and robust code. Apply this checklist when writing new code,
reviewing existing code, or refactoring.

---

## Skills To Load (Required)
- skill:examples

## Instructions

When invoked:
1. Read the code or description provided by the user.
2. Go through each section of the checklist below.
3. For each item, mark: ✅ (pass) / ❌ (fail) / ⚠️ (partial) / N/A.
4. For every ❌ or ⚠️, provide a specific, actionable suggestion.
5. Summarize findings at the end with a priority fix list.

---

## Checklist

### 1. Foundational Principles

| # | Principle | Check |
|---|-----------|-------|
| 1.1 | **DRY** – Don't Repeat Yourself: No duplicated logic or data | [ ] |
| 1.2 | **KISS** – Keep It Simple, Stupid: No unnecessary complexity | [ ] |
| 1.3 | **YAGNI** – You Ain't Gonna Need It: No speculative features | [ ] |
| 1.4 | **SoC** – Separation of Concerns: Each module has one clear purpose | [ ] |
| 1.5 | **CoC** – Convention over Configuration: Follows language/framework conventions | [ ] |

---

### 2. SOLID Principles

| # | Principle | Check |
|---|-----------|-------|
| 2.1 | **S** – Single Responsibility: Each class/function does exactly one thing | [ ] |
| 2.2 | **O** – Open/Closed: Open for extension, closed for modification | [ ] |
| 2.3 | **L** – Liskov Substitution: Subtypes are substitutable for their base types | [ ] |
| 2.4 | **I** – Interface Segregation: No forced dependency on unused interfaces | [ ] |
| 2.5 | **D** – Dependency Inversion: Depend on abstractions, not concretions | [ ] |

---

### 3. Naming & Readability

| # | Principle | Check |
|---|-----------|-------|
| 3.1 | Names are honest — they describe exactly what the thing does | [ ] |
| 3.2 | Names are pronounceable and searchable | [ ] |
| 3.3 | No abbreviations unless universally understood (e.g., `i`, `url`, `id`) | [ ] |
| 3.4 | Functions are named as verbs (`get_`, `compute_`, `is_`, `has_`) | [ ] |
| 3.5 | Booleans read as questions (`is_valid`, `has_data`, `can_run`) | [ ] |
| 3.6 | No magic numbers — use named constants | [ ] |
| 3.7 | Comments explain **why**, not **what** (the code explains what) | [ ] |

---

### 4. Functions & Methods

| # | Principle | Check |
|---|-----------|-------|
| 4.1 | Functions do one thing only | [ ] |
| 4.2 | Functions are small (ideally < 20 lines) | [ ] |
| 4.3 | No more than 3–4 parameters (use a config object/dataclass if more needed) | [ ] |
| 4.4 | No side effects unless explicitly intended and documented | [ ] |
| 4.5 | Return types are consistent and predictable | [ ] |
| 4.6 | No deeply nested logic (max 2–3 levels; use early returns / guard clauses) | [ ] |
| 4.7 | **Fail fast** — validate inputs at entry points, raise early | [ ] |

---

### 5. Architecture & Design

| # | Principle | Check |
|---|-----------|-------|
| 5.1 | **Loose coupling** — modules can change independently | [ ] |
| 5.2 | **High cohesion** — related things are together | [ ] |
| 5.3 | **Idempotency** — running the same operation twice has the same result | [ ] |
| 5.4 | **Principle of least privilege** — access only what is needed | [ ] |
| 5.5 | **Law of Demeter** — only talk to immediate neighbors, not strangers | [ ] |
| 5.6 | No circular dependencies | [ ] |
| 5.7 | Abstractions are at the right level — not too leaky, not too opaque | [ ] |

---

### 6. Error Handling

| # | Principle | Check |
|---|-----------|-------|
| 6.1 | All exceptions are caught at the appropriate level | [ ] |
| 6.2 | Errors are informative — include context, not just the exception type | [ ] |
| 6.3 | No silent failures (`except: pass`) | [ ] |
| 6.4 | Resources are always released (use `with` / `finally` / context managers) | [ ] |
| 6.5 | Edge cases are handled (empty input, None, zero, overflow) | [ ] |

---

### 7. Testing

| # | Principle | Check |
|---|-----------|-------|
| 7.1 | Code is testable — pure functions, injectable dependencies | [ ] |
| 7.2 | Tests exist for the happy path | [ ] |
| 7.3 | Tests exist for edge cases and error paths | [ ] |
| 7.4 | **Tests are the specification** — they document intent, not just behavior | [ ] |
| 7.5 | No test logic in production code | [ ] |

---

### 8. Performance & Scalability

| # | Principle | Check |
|---|-----------|-------|
| 8.1 | **No premature optimization** (Knuth: "root of all evil") — profile first | [ ] |
| 8.2 | O(n²) or worse loops are justified or replaced | [ ] |
| 8.3 | No unnecessary I/O inside loops | [ ] |
| 8.4 | Caching is used where appropriate and invalidated correctly | [ ] |

---

### 9. Maintainability

| # | Principle | Check |
|---|-----------|-------|
| 9.1 | **Boy Scout Rule** — code is cleaner than when you found it | [ ] |
| 9.2 | **No broken windows** — no known issues left unaddressed without a TODO | [ ] |
| 9.3 | Dependencies are minimal and justified | [ ] |
| 9.4 | Version-controlled — all changes are committed with meaningful messages | [ ] |
| 9.5 | Configuration is external (env vars, config files) — not hardcoded | [ ] |

---

### 10. Security (Baseline)

| # | Principle | Check |
|---|-----------|-------|
| 10.1 | No secrets or credentials in source code | [ ] |
| 10.2 | All user inputs are validated and sanitized | [ ] |
| 10.3 | SQL / shell commands use parameterized queries, not string formatting | [ ] |
| 10.4 | Dependencies are up-to-date and checked for known vulnerabilities | [ ] |

---

## Summary Template

After completing the checklist, provide:

```
## Review Summary

**Score**: X / Y checks passed

### ❌ Critical Issues (fix before merge)
1. [item] — [specific suggestion]

### ⚠️ Warnings (fix soon)
1. [item] — [specific suggestion]

### 💡 Suggestions (nice to have)
1. [item] — [specific suggestion]

### ✅ What's done well
- [positive observations]
```

---

## Key Quotes to Keep in Mind

- *"Debugging is twice as hard as writing the code in the first place."* — Brian Kernighan
- *"Premature optimization is the root of all evil."* — Donald Knuth
- *"Make it work, make it right, make it fast."* — Kent Beck
- *"Any fool can write code that a computer can understand. Good programmers write code that humans can understand."* — Martin Fowler


---
name: shell-scripting
description: Shell scripting best practices for bash and other shells. Use when writing shell scripts, bash functions, or command-line automation.
---

# Shell Scripting Skill

## When to Use
- Writing bash scripts
- Creating shell functions
- Automating command-line tasks
- Setting up environment configurations
- Writing CI/CD scripts

## Guidelines
Comprehensive shell scripting best practices:
@general.md

## Key Principles
- Use shellcheck for validation
- Handle errors with set -e and set -u
- Quote variables properly
- Use meaningful variable names
- Document complex logic
- Test scripts thoroughly
