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
   Spawn each with a detailed prompt that includes:
   ├── Their review focus, the code scope, and project context
   ├── Max 5 issues with file:line, severity, description, and suggested fix
   └── Cross-validation instruction (see below)

   Include this in every reviewer's spawn prompt:
   "You are on a review team with other reviewers. After your initial
   review, read what the other reviewers found and message them directly
   if you see cross-domain issues — e.g., if security finds a vulnerability
   and testing confirms there's no coverage, or if performance and simplicity
   disagree on approach. Challenge each other's findings."

4. Let reviewers work and cross-validate
   ├── Reviewers do their initial review, then discuss with each other
   ├── Brief one-line status is fine (e.g., "Correctness and security done, waiting on 3 more")
   ├── Don't repeat status, narrate your thinking, or fill the wait with commentary
   └── Wait until discussion settles before synthesizing

5. Synthesize, present, and clean up
   ├── Collect final findings from all reviewers (post-discussion)
   ├── REFORMAT into the Output Structure below
   │   ### [Reviewer] header → pipe table (| # | Location | Issue | Severity |) → repeat → --- → Summary
   │   Do NOT pass through reviewer output as-is
   ├── Put synthesis insights (including cross-reviewer debates) in summary blockquotes
   └── Then clean up the team
```

**Benefits of team mode:**
- Reviewers message each other directly — cross-domain insights emerge from debate, not just lead synthesis
- Security finds vulnerability, testing confirms no coverage — through direct conversation
- Trade-offs surfaced through actual disagreement (performance vs simplicity)

**Note:** Agent teams use more tokens than subagents. For small changes, subagent mode may be sufficient.

### Mode B: Parallel Subagents (fallback)

When agent teams are not available:

```
1. Identify code to review and determine Full/Quick mode

2. Detect project context

3. Spawn reviewer agents via Task tool in parallel
   └── Each analyzes code independently

4. Collect findings from all agents

5. Synthesize and reformat into the Output Structure below
   ├── Deduplicate overlapping issues
   ├── REFORMAT all findings into:
   │   ### [Reviewer] header → pipe table (| # | Location | Issue | Severity |) → repeat → --- → Summary
   │   Do NOT pass through agent output as-is
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
