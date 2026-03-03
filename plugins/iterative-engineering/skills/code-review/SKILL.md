---
name: code-review
description: This skill should be used when the user says "review my code", "check these changes", or wants feedback on code before creating a PR. Also used after completing a task during iterative implementation.
---

# Code Review

Reviews code changes using specialized reviewers. Uses agent teams when available for richer cross-validation.

## When to Use

- After completing a plan section (during `iterative:implementing` skill)
- Before finishing work and creating a PR
- When feedback is needed on any code changes
- Can be invoked standalone

## Severity Scale

All reviewers use the same 4-level scale:

| Level | Meaning | Action |
|-------|---------|--------|
| **Critical** | Crashes, security holes, data loss, broken core functionality | Must fix before merge |
| **High** | Incorrect behavior, significant logic gaps, inadequate error handling | Should fix |
| **Medium** | Suboptimal patterns, minor gaps, moderate improvement opportunities | Fix if straightforward |
| **Low** | Style, suggestions, edge cases unlikely to occur | User's discretion |

## Reviewers

| Agent | Focus | Key Question |
|-------|-------|--------------|
| `correctness-reviewer` | Logic, edge cases, bugs, error handling, plan compliance | Does this work correctly and match the intent? |
| `security-reviewer` | Vulnerabilities, auth, input validation, secrets | Is this safe? |
| `performance-reviewer` | Algorithmic complexity, queries, memory, caching | Is this fast enough? |
| `simplicity-reviewer` | Unjustified complexity, over-engineering, unnecessary abstraction | Is the complexity justified? |
| `testing-reviewer` | Coverage, test quality, edge cases, plan test scenarios | Is this well-tested? |

## Review Modes

### Full Mode (default)
Uses all 5 built-in reviewers.

### Quick Mode
Uses 2-3 reviewers. Auto-detect from changed files when the caller doesn't specify a type:

| Changed files | Reviewers |
|---------------|-----------|
| Auth/security code | security + correctness |
| Database/queries/migrations | performance + correctness |
| New feature code | correctness + testing |
| Refactoring (same tests, restructured code) | correctness + simplicity |
| Test files only | correctness + testing |
| Config/CI only | correctness (single reviewer — minimal review) |
| Mixed or unclear | Default to full mode |

## How to Run

**Step 1: Determine scope.**

Compute the diff range, file list, and diff in a **single Bash call**. This minimizes permission prompts. Do not run extra commands (no `git log`, no filtered diffs, no separate merge-base computation).

Chain everything into one command using `&&` and labeled output markers (`BASE:`, `FILES:`, `DIFF:`) so you can parse each section from the output:

- **From implementing (section-level):** The caller provides a baseline SHA. Use it directly as the range.
- **From implementing (final/branch-level):** The caller provides the base branch. Compute merge-base inline.
- **Standalone:** Detect base branch and compute merge-base inline.
- **Explicit files:** If the caller specifies files, skip the merge-base and use those directly.

**Standalone example** (single Bash call):

```
BASE=$(git merge-base HEAD $(git rev-parse --verify origin/main 2>/dev/null && echo origin/main || echo origin/master)) && echo "BASE:$BASE" && echo "FILES:" && git diff --name-only ${BASE}..HEAD -- . ':!*.md' && echo "DIFF:" && git diff -U10 ${BASE}..HEAD -- . ':!*.md'
```

Parse the output: `BASE:` gives the merge-base SHA, `FILES:` gives the file list, `DIFF:` gives the diff. If no commits exist on the branch, fall back to unstaged changes (`git diff -U10 -- . ':!*.md'`).

**Step 2: Spawn reviewers.**

Create an agent team (e.g. `TeamCreate` in Claude Code, `spawn_agent` in Codex), then spawn the 5 built-in reviewers as teammates. In Quick mode, spawn 2-3 built-in reviewers based on change type (see Review Modes above). If the team already exists (e.g., from an interrupted run), reuse it — read its config, check which reviewers are already present, and spawn only the missing ones.

Tell the user:

> Using Agent Team 🐝 — built-in reviewers will run as teammates who can cross-validate findings.

Spawn each built-in reviewer with a prompt that includes the review context:

> Review the following changes for [their focus area].
>
> **Changed files:** [file list from git diff or caller]
> **What was built:** [plan section summary — include if available from implementing]
> **Plan test scenarios:** [relevant test scenarios from the plan — include if available, for correctness and testing reviewers]
>
> You're on a review team with [list other active built-in reviewers]. After your initial review, read what the other reviewers found and message them directly if you see cross-domain issues. Challenge each other's findings.
>
> Your job is to review and report findings — not to fix, remediate, or modify the code. Only report issues you're confident about. Tag any pre-existing issues (unrelated to the current changes) with **[Pre-existing]**. When done, send your findings to the team lead (e.g. `SendMessage` in Claude Code, `send_input` in Codex). Use the severity scale: Critical / High / Medium / Low.

**Step 3: Collect findings.**

Wait for all reviewers to report via team messages. When you receive a reviewer's message, do not output or echo its content — silently collect it. Only output once in Step 4 when assembling the final results. A brief one-line status like "All reviewers have reported" is fine when ready to proceed.

**Step 4: Synthesize and present.**

Shut down the reviewer teammates (send shutdown requests), wait for confirmations, then delete the team using the coding agent's team management tools (e.g. `TeamDelete` in Claude Code, `delete_agent` in Codex). **Never use `rm -rf` or manual file deletion for team cleanup** — always use the agent platform's built-in team teardown. If teardown fails (e.g., orphaned members), retry after a brief pause; if it still fails, report the issue to the user and move on. Assemble the final output:

1. **Reconcile.** When multiple reviewers flagged the same issue, attribute to the most relevant reviewer and note cross-reviewer agreement.
2. **Separate pre-existing findings.** Pull out all findings tagged **[Pre-existing]** into a separate list. These do not count toward the verdict.
3. **Format.** Start with a `### Strengths` section highlighting what's well done (with `file:line` refs). Format each reviewer's findings as a table — one issue per row, same structure for every section. Use `### Reviewer Name` headers. Separate sections with clear whitespace. If there are pre-existing findings, add a `### Pre-existing Issues` section at the end (before the verdict) with a note that these are outside the current changes and can be addressed separately.
4. **Verdict.** End with a `---` separator followed by:

> **Verdict:** Ready to merge / Ready with fixes / Not ready
>
> **Reasoning:** [1-2 sentences — overall quality assessment]
>
> **Fix order:** [If fixes needed — prioritized: critical first, then high, etc.]

The verdict is based only on change-related findings. Pre-existing issues are informational and do not affect the verdict.

Do not include time estimates. **When invoked from `iterative:implementing`:** omit the `**Fix order:**` line — implementing handles prioritization through its own severity acceptance flow.

## Language-Agnostic

This skill does NOT use language-specific reviewer agents (no Rails-reviewer, Python-reviewer, etc.).

Instead, reviewers adapt their criteria to the language/framework based on project context (which teammates load automatically). This keeps the skill simple and avoids maintaining parallel reviewers per language.

## After Review

**When invoked from `iterative:implementing`:** return findings directly — implementing owns its own fix loop (severity acceptance, subagent fixes, re-review). Do not enter the standalone fix loop below.

**When invoked standalone or from `implementation-wrapup`:** run the standalone fix loop.

### Standalone Fix Loop

After presenting the synthesized findings and verdict (Step 4), this skill handles the full fix-review cycle when running standalone.

#### Step 5: Severity Acceptance

**This is its own prompt — do not combine it with next-step options.** Present severity acceptance whenever the review has findings at ANY severity, including Medium/Low-only reviews. Do not interpret "no Critical/High" as "clean" — clean means zero findings. If zero findings, skip to Step 8. **Use the interactive question tool** (e.g., `AskUserQuestion` in Claude Code) for all severity acceptance prompts — do not print options as text.

**When Critical or High issues exist:**

Present an interactive choice:
- **Fix Critical + High (Recommended)** — N Critical, N High
- **Choose which severity levels to fix** — select from all levels
- **Skip fixes**

If the user accepts the recommendation, fix Critical + High. If they choose, present an interactive multi-select of severity levels that have findings:
- Critical (N issues)
- High (N issues)
- Medium (N issues)
- Low (N issues)

**When only Medium/Low issues exist (no Critical/High):**

Present an interactive choice:
- **Choose which severity levels to fix** — select from Medium, Low
- **Proceed without fixes (Recommended)**

If the user chooses to fix, present the interactive multi-select of severity levels with findings.

#### Step 6: Apply Fixes via Subagent

Fix only the selected severities. Spawn one or more subagents with the filtered findings, affected file paths, and diff range from Step 1. If using multiple subagents, avoid assigning overlapping files. Each subagent applies its fixes, runs tests, and commits.

Wait for all fixes to complete before proceeding.

#### Step 7: Re-review Offer

After fixes land, present an interactive choice:
- **Run another review round (Recommended)** — verify fixes and check for new issues
- **Proceed without re-review**

If the user chooses another round: run the full Step 1–7 flow again (fresh team, fresh scope). Each round creates a fresh team (the previous team was deleted in Step 4). Continue until clean or the user chooses to proceed.

#### Step 8: Post-fix Options

After the fix-review cycle completes (clean verdict or user chose to stop), present next steps. **Use the interactive question tool** — do not print options as text.

Detect whether the current branch is a feature branch (not `main`/`master`):

**On a feature branch:**
- **Create a PR (Recommended)** — push and open a pull request
- **Continue without PR** — stay on the branch
- **Exit** — done for now

**On main/master:**
- **Continue** — proceed with next steps
- **Exit** — done for now

If the user chooses "Create a PR": push the branch and use `gh pr create` with a title and summary derived from the branch changes. Do not invoke other skills — handle the PR inline.

## Fallback: If Agent Teams/Swarms are Unavailable

If agent teams/swarms are not available, spawn the reviewers in parallel as independent subagents instead of teammates. Each analyzes independently. Skip the cross-validation instruction. Everything else (Steps 1, 3, 4, output format) stays the same.