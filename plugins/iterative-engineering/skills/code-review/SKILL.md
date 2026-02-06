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

Create a review team with specialized teammates:

```
1. Identify code to review and determine Full/Quick mode
   ├── Use diff from argument (file, commit, branch)
   ├── Or infer from recent changes (git diff)
   └── Or ask user to specify scope

2. Detect project context
   ├── Read CLAUDE.md, AGENTS.md for conventions
   └── Detect language from package.json, Gemfile, etc.

3. Create agent team with reviewer teammates
   Spawn each with a detailed prompt including context, for example:

   "Review the code changes in [scope] for security vulnerabilities.
   The project uses [language/framework]. Focus on auth, input validation,
   and secrets exposure. Return up to 5 issues with file:line, severity,
   description, and suggested fix."

4. Wait for all teammates to complete their reviews
   └── Do NOT start synthesizing until all reviewers report back

5. Synthesize findings and format output
   ├── Collect issues from all reviewers
   ├── Deduplicate overlapping issues
   ├── Identify cross-domain insights and fix order
   ├── Present to user using the exact Output Structure below
   └── Put synthesis insights in the summary blockquotes at the end — not as a preamble

6. Clean up the team when done
```

**Benefits of team mode:**
- Cross-domain validation (security finds issue, testing confirms no coverage)
- Multiple reviewers flagging same issue = high confidence
- Trade-offs surfaced (performance vs simplicity)

**Note:** Agent teams use more tokens than subagents. For small changes, subagent mode may be sufficient.

### Mode B: Parallel Subagents (fallback)

When agent teams are not available:

```
1. Identify code to review and determine Full/Quick mode

2. Detect project context

3. Spawn reviewer agents via Task tool in parallel
   └── Each analyzes code independently

4. Collect findings from all agents

5. Synthesize findings and format output
   ├── Deduplicate overlapping issues
   ├── Identify cross-domain insights and fix order
   ├── Present to user using the exact Output Structure below
   └── Put synthesis insights in the summary blockquotes at the end — not as a preamble
```

## Output Structure

**The output must follow this exact structure, in this order. Nothing else.**

```
## Code Review Results (Full|Quick)

### [Reviewer Name]              ← one section per reviewer
| # | Location | Issue | Severity |  ← pipe-delimited table, immediately after header
|---|----------|-------|----------|
| 1 | `file:line` | ...  | High   |

### [Next Reviewer]
| # | Location | Issue | Severity |
|---|----------|-------|----------|
| 1 | `file:line` | ...  | Medium |

[...repeat for each reviewer...]

---

**Summary:** N issues found. X critical, Y high, Z medium, W low.

> **Cross-domain insight:** ...
>
> **Fix order:** ...
```

**Rules:**
- **This structure is the entire output.** Do not add anything before `## Code Review Results` — no introductory paragraphs, no "here's what I found" narrative.
- **One `###` section per reviewer**, each containing only a pipe-delimited table. No prose between the header and the table.
- **Pipe-delimited markdown tables only** (`| col | col |` with `|---|---|`). Do NOT use ASCII box-drawing characters (`┌─┬─┐`, `│`, `└─┴─┘`).
- **Always include `file:line` location** and **severity** (Critical/High/Medium/Low) in code review tables.
- **One summary section at the end**, after the `---` rule. This is the only place for cross-domain insights and fix order. Do not put summary content anywhere else.
- **Skip empty reviewer sections.** If a reviewer found no issues, omit that section entirely.

See `references/review-output-template.md` for a complete example.

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
- Fix issues now
- Fix issues, then another review round
- Accept as-is and continue
