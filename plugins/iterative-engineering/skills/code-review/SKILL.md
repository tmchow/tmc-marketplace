---
name: code-review
description: Multi-agent code review with 5 specialized reviewers. This skill should be used when the user says "review my code", "check these changes", or wants feedback before a PR. Supports full and quick modes, language-agnostic.
allowed-tools: Glob, Grep, Read, Task
---

# Code Review

Reviews code changes using specialized reviewers. Uses agent teams when available for richer cross-validation.

## When to Use

- After completing a parent task (during `iterative:implement` skill)
- Before finishing work and creating a PR
- When you want feedback on any code changes
- Can be invoked standalone

## Reviewers

| Agent | Focus | Key Question |
|-------|-------|--------------|
| `correctness-reviewer` | Logic, edge cases, bugs, error handling | Does this work correctly? |
| `security-reviewer` | Vulnerabilities, auth, input validation, secrets | Is this safe? |
| `performance-reviewer` | Algorithmic complexity, queries, memory, caching | Is this fast enough? |
| `simplicity-reviewer` | YAGNI, over-engineering, unnecessary abstraction | Is this minimal? |
| `testing-reviewer` | Coverage, test quality, edge cases, integration | Is this well-tested? |

Each reviewer returns **max 5 issues** to keep feedback actionable.

## Review Modes

### Full Mode (default)
Uses all 5 reviewers for comprehensive coverage.

### Quick Mode
When explicitly requested, uses 2-3 reviewers based on change type:
- Auth/security changes → security + correctness
- Performance-sensitive → performance + correctness
- New feature → correctness + testing
- Refactoring → correctness + simplicity

## Execution Mode

**First, check if agent teams are enabled for this session.**

**When using Agent Teams, tell the user exactly this:**

> Using Agent Teams 🐝 — reviewers will run as teammates who can cross-validate findings.

### Mode A: Agent Team (if enabled)

**Step 1.** Identify code to review and determine Full/Quick mode (from argument, git diff, or ask user). Detect project context from CLAUDE.md, AGENTS.md, package.json, etc.

**Step 2.** Create agent team with reviewer teammates. Spawn each with a prompt that includes their review focus, the code scope, project context, max 5 issues with file:line and severity, and this cross-validation instruction:

> "You are on a review team with other reviewers. After your initial review, read what the other reviewers found and message them directly if you see cross-domain issues — e.g., if security finds a vulnerability and testing confirms no coverage, or if performance and simplicity disagree. Challenge each other's findings."

**Step 3.** Let reviewers work and cross-validate. Brief one-line status is fine. Don't repeat status or narrate your thinking. Wait until discussion settles.

**Step 4.** Synthesize and present. Collect final findings from all reviewers. **You must reformat all findings into the exact output format shown below — do NOT pass through raw reviewer text.** Then clean up the team.

### Mode B: Parallel Subagents (fallback)

**Step 1.** Identify code to review and determine Full/Quick mode. Detect project context.

**Step 2.** Spawn reviewer agents via Task tool in parallel. Each analyzes code independently.

**Step 3.** Collect findings. Deduplicate overlapping issues.

**Step 4.** **You must reformat all findings into the exact output format shown below — do NOT pass through raw agent text.**

### Benefits of team mode

- Reviewers message each other directly — cross-domain insights emerge from debate, not just lead synthesis
- Security finds vulnerability, testing confirms no coverage — through direct conversation
- Trade-offs surfaced through actual disagreement (performance vs simplicity)

**Note:** Agent teams use more tokens than subagents. For small changes, subagent mode may be sufficient.

## Output Format

**Your output for Step 4 must look exactly like this example. Copy this structure.**

```markdown
## Code Review Results (Full)

### Correctness

| # | Location | Issue | Severity |
|---|----------|-------|----------|
| 1 | `task-service.ts:142` | Off-by-one in pagination — skips last page when total is exact multiple | High |
| 2 | `claim.ts:87` | Race condition if two agents claim simultaneously without transaction | High |

### Security

| # | Location | Vulnerability | Severity |
|---|----------|---------------|----------|
| 1 | `auth.ts:34` | User-supplied ID used directly in SQL query — injection risk | Critical |

### Performance

| # | Location | Issue | Impact |
|---|----------|-------|--------|
| 1 | `list.ts:156` | N+1 query — fetches dependencies per task in loop | High at scale |

### Simplicity

| # | Location | Suggestion |
|---|----------|------------|
| 1 | `utils/format.ts` | Three formatting helpers do the same thing — consolidate |

### Testing

| # | Location | Gap |
|---|----------|-----|
| 1 | `claim.ts` | No test for concurrent claim scenario | High |

---

**Summary:** 6 issues found. 1 critical, 2 high, 2 medium, 1 low.

> **Cross-domain insight:** The SQL injection in `auth.ts:34` has no test coverage (flagged by both security and testing reviewers).
>
> **Fix order:** Critical/high security first → correctness bugs → add missing tests → simplicity cleanup.
```

**Rules:**
- Start with `## Code Review Results` — nothing before it. No "here's what I found" or "let me synthesize."
- One `### Section` per reviewer, each containing **only** a pipe-delimited markdown table.
- Pipe tables use `| col | col |` with `|---|---|` separators. **Never** ASCII box-drawing (`┌─┬─┐`), key-value lists (`#: 1`, `Issue:`), or `────` separators.
- Always include `file:line` location and severity (Critical/High/Medium/Low).
- Column headers vary by reviewer (Issue/Severity, Vulnerability/Severity, Suggestion, Gap, etc.).
- Single summary section after `---` with blockquotes. This is the only place for cross-domain insights and fix order.
- Skip empty reviewer sections.

## Language-Agnostic

This skill does NOT use language-specific reviewer agents (no Rails-reviewer, Python-reviewer, etc.).

Instead, it:
1. Detects project context from config files
2. Adapts general review criteria to the language/framework
3. Uses project conventions from CLAUDE.md/AGENTS.md

This keeps the skill simple and avoids maintaining parallel reviewers per language.

## Multiple Rounds

After fixing issues, run another round. Continue until:
- No critical issues remain
- User chooses to proceed
- Reasonable iteration limit reached

## After Review

Use AskUserQuestion with options:
- Fix issues and re-review (Recommended)
- Fix issues and proceed to [name the actual next step based on context, e.g., "create a PR" if code is ready, "continue implementing" if mid-task]
- Continue without changes
