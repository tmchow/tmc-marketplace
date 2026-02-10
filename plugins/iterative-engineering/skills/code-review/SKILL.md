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
| `simplicity-reviewer` | YAGNI, over-engineering, unnecessary abstraction | Is this minimal? |
| `testing-reviewer` | Coverage, test quality, edge cases, plan test scenarios | Is this well-tested? |
| `gemini-reviewer` | Independent review via Google Gemini CLI | What did the other reviewers miss? |
| `codex-reviewer` | Independent review via OpenAI Codex CLI | What did the other reviewers miss? |
| `claude-reviewer` | Independent review via Anthropic Claude Code CLI | What did the other reviewers miss? |

The last three are **external reviewers** — they invoke a different model's CLI for an independent perspective. All three are spawned in Full mode; each self-identifies and skips if it shares a model family with the host platform (see External Reviewers below).

## Review Modes

### Full Mode (default)
Uses all 5 built-in reviewers plus available external reviewers for comprehensive coverage. External reviewers that aren't installed gracefully skip — Full mode always runs the 5 built-in reviewers regardless.

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

## External Reviewers

External reviewers invoke a **different model's CLI** for an independent code review, providing model diversity. The value is that different model families have different blind spots — a finding confirmed across models is higher confidence than one from a single model.

### Spawn All Three

In Full mode, spawn all three external reviewers (`gemini-reviewer`, `codex-reviewer`, `claude-reviewer`). Each agent self-identifies whether it shares a model family with the host platform and skips itself if so. Each also checks whether its CLI is installed and skips if unavailable. No platform detection or external reviewer selection is needed — the agents handle it themselves.

External reviewers are Full mode only — they are never spawned in Quick mode. If all external reviewers skip, Full mode still runs the 5 built-in reviewers as normal.

## How to Run

**Step 1: Determine scope.**

Identify what code to review using the appropriate git diff range:

- **From implementing (section-level):** The caller provides a baseline SHA (captured at section start) and plan context. Use `git diff <baseline-sha>..HEAD` to scope to only the section's changes. Get changed files with `git diff --name-only <baseline-sha>..HEAD`.
- **From implementing (final/branch-level):** The caller provides a merge-base scope. Use `git diff $(git merge-base HEAD <base>)..HEAD` for all branch changes.
- **Standalone:** Detect base branch (`git rev-parse --verify origin/main >/dev/null 2>&1 && echo main || echo master`). Use `git diff $(git merge-base HEAD <base>)..HEAD` to identify changed files. If no commits on branch, fall back to unstaged changes (`git diff`).
- **Explicit files:** If the caller specifies files, use those.

Get the changed file list with `--name-only` to determine Full or Quick mode from change analysis. The full diff content is what reviewers analyze.

**Step 2: Spawn reviewers.**

Create an agent team (e.g. `TeamCreate` in Claude Code, `spawn_agent` in Codex), then spawn reviewers as teammates. **In Full mode, spawn all 5 built-in reviewers plus the appropriate external reviewers (see External Reviewers above).** In Quick mode, spawn 2-3 built-in reviewers based on change type (see Review Modes above) — external reviewers are Full mode only. If the team already exists (e.g., from an interrupted run), reuse it — read its config, check which reviewers are already present, and spawn only the missing ones.

Tell the user:

> Using Agent Team 🐝 — reviewers will run as teammates who can cross-validate findings.

Spawn each built-in reviewer with a prompt that includes the review context:

> Review the following changes for [their focus area].
>
> **Changed files:** [file list from git diff or caller]
> **What was built:** [plan section summary — include if available from implementing]
> **Plan test scenarios:** [relevant test scenarios from the plan — include if available, for correctness and testing reviewers]
>
> You're on a review team with [list other active reviewers]. After your initial review, read what the other reviewers found and message them directly if you see cross-domain issues. Challenge each other's findings.
>
> Your job is to review and report findings — not to fix, remediate, or modify the code. Only report issues you're confident about. Tag any pre-existing issues (unrelated to the current changes) with **[Pre-existing]**. When done, send your findings to the team lead (e.g. `SendMessage` in Claude Code, `send_input` in Codex). Use the severity scale: Critical / High / Medium / Low.

In Full mode, also spawn the appropriate external reviewers (see External Reviewers above) with the same changed files list and diff scope. Each external reviewer handles its own CLI invocation — just provide the diff scope and changed files. If an external reviewer reports that its CLI is unavailable, acknowledge and continue with the remaining reviewers' findings.

**Step 3: Collect findings.**

Wait for all reviewers to send their findings. When you receive a reviewer's message, do not output or echo its content — silently collect it. Only output once in Step 4 when assembling the final results. A brief one-line status like "All reviewers have reported" is fine when ready to proceed.

**Step 4: Synthesize and present.**

Shut down all teammates (send shutdown requests), then delete the team. Assemble the final output:

1. **Deduplicate.** Merge findings that multiple reviewers flagged — attribute to the most relevant reviewer, note cross-reviewer agreement. When an external reviewer flags the same issue as a built-in reviewer, note the cross-model agreement (this strengthens confidence in the finding).
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

## Multiple Rounds

After fixing issues, run another round. Each round creates a fresh team (the previous team was deleted). Run the full Step 2–4 flow again.

Continue until:
- No critical or high issues remain
- User chooses to proceed

## After Review

**This skill only reviews.** Do not invoke other skills (implementing, tech-planning, etc.) after presenting results.

When invoked standalone or from `implementation-wrapup`, present an interactive choice to the user (e.g., `AskUserQuestion` in Claude Code):
- Fix issues and re-review (Recommended)
- Fix issues and proceed to [name the actual next step based on context, e.g., "create a PR" if code is ready]
- Continue without changes

When invoked from `iterative:implementing`, return findings directly — implementing owns the review loop and decides whether to re-review or continue to the next section.

## Fallback: If Agent Teams/Swarms are Unavailable

If agent teams/swarms are not available, spawn the reviewers in parallel as independent subagents instead of teammates. Each analyzes independently. Skip the cross-validation instruction. Everything else (Steps 1, 3, 4, output format) stays the same. External reviewers work identically in both modes — they call external CLIs regardless of team vs. subagent setup.