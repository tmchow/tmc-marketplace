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

In Full mode, the orchestrator can also run **external model CLIs** (Gemini, Codex, Claude) for independent, model-diverse perspectives (experimental, opt-in). See External Reviewers below.

## Review Modes

### Full Mode (default)
Uses all 5 built-in reviewers. Optionally includes external model CLIs (experimental, opt-in) for model-diverse independent review — the user selects which CLIs to include. Full mode always runs the 5 built-in reviewers regardless of external CLI availability.

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

## External Reviewers (Experimental)

External reviewers invoke a **different model's CLI** for an independent code review, providing model diversity. This feature is experimental; CLI availability and behavior may vary.

The orchestrator runs external CLIs **directly** (not via subagents) — this ensures Bash calls happen in the main agent context where the user can approve them normally, avoiding permission issues with subagent CLI access.

| CLI | Invocation | Safety mode |
|-----|------------|-------------|
| Google Gemini | `gemini -s -p "..."` | Sandboxed (reads diff file, no write access) |
| OpenAI Codex | `codex exec review --base <branch>` | Built-in review preset (read-only, filesystem access) |
| Anthropic Claude | `claude -p "..." --max-turns 3` | Bounded turns, no session persistence |

External CLIs are Full mode only — never run in Quick mode. If all CLIs are unavailable or skipped, the 5 built-in reviewers still provide comprehensive coverage.

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

**Step 2a: Spawn built-in reviewers (team members).**

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

**Step 2b: Run external model CLIs (opt-in).**

In Quick mode, skip this step entirely. In Full mode:

**1. Self-identification.** Determine your own model family. Exclude the matching CLI:

- If you are Claude → exclude the `claude` CLI
- If you are Codex/GPT → exclude the `codex` CLI
- If you are Gemini → exclude the `gemini` CLI

If uncertain, keep all three — each invocation is safe (sandboxed, read-only, or turn-bounded).

**2. Check availability.** Run `which` for each non-excluded CLI in parallel. Drop any CLI that isn't installed. Do not attempt to install missing CLIs or fall back to reviewing the code yourself.

**3. Ask the user.** If no CLIs remain after steps 1-2, skip to Step 3 silently. Otherwise, ask the user which external CLIs to include. The 5 built-in reviewers always run regardless of this choice.

**If 2+ CLIs available:** Use the interactive question tool with multi-select, listing each available CLI as an option:

> **Add external model reviews? (Experimental)** The 5 built-in reviewers always run.
>
> - **Gemini** — Experimental. Independent review from Google's model
> - **Codex** — Experimental. Independent review from OpenAI's model. Can take 5+ minutes

The user can select any combination (both, one, or neither).

**If 1 CLI available:** Use a simple yes/no question for that CLI:

> **Also run {CLI name} for independent review? (Experimental)** The 5 built-in reviewers always run.
>
> - **Yes** — Experimental. Add an independent perspective from {model family}. {If Codex, add: "Can take 5+ minutes."}
> - **No** — Continue with the 5 built-in reviewers

Run only the CLIs the user selected. If none selected, skip to Step 3.

**4. Invoke CLIs.** Stage the diff and prompt as local files so CLIs read them from disk instead of receiving inlined content. This avoids shell `ARG_MAX` limits on large diffs and keeps permission approval prompts short.

**Stage files locally.** Write both files to the repo root (avoids plugin directory permission prompts). Clean up in Step 4.

Write the diff from Step 1 to `.external-review-diff.txt`. Then write the prompt template below to `.external-review-prompt.txt`:

```
You are a senior engineer reviewing code. Be thorough and actionable.

Read the diff from .external-review-diff.txt in the current directory. State assumptions; do not ask questions.

METHODOLOGY:
1. Summarize the intent in 1-2 sentences.
2. Analyze diff hunks for issues.

FOCUS AREAS (use exact names):
1. Correctness — Logic errors, edge cases, null/error handling, incorrect conditions
2. Security — Injection, auth gaps, input validation, secrets exposure
3. Performance — Complexity, N+1 queries, resource leaks, blocking operations
4. Simplicity — Over-engineering, YAGNI, unnecessary abstraction
5. Testing — Missing coverage, inadequate assertions, untested edge cases

CONSTRAINTS:
- Only comment on changed lines (+ or -). Only report demonstrable issues.
- Do NOT say "check/confirm/verify/ensure" — state the issue directly.
- Do NOT explain what the code does or comment on style/formatting.
- Group repeated issues: state once, list other locations.
- Tag pre-existing issues (unchanged code, unrelated to diff) with [Pre-existing].
- No issues? Say: "No issues found."

SEVERITY:
- CRITICAL: Security holes, system-breaking bugs, data loss
- HIGH: Incorrect behavior, performance bottlenecks, resource leaks
- MEDIUM: Missing validation, edge case gaps, simplification opportunities
- LOW: Refactoring opportunities, minor improvements

OUTPUT FORMAT:
<NUMBER>. [<SEVERITY>] <FOCUS_AREA> — <file_path>:<line_number> — <one-line summary>
<why this is an issue and what could go wrong>
Fix: <specific remediation>

Pre-existing issues go under a separate "PRE-EXISTING ISSUES" header.
```

Run the user-selected CLIs in parallel via separate Bash calls. Each CLI has different correct invocation syntax:

**Gemini** — reads the prompt via `$(cat ...)`, then reads the diff file as instructed by the prompt. Sandbox mode (`-s`) allows file reads but blocks writes:

```
gemini -s -p "$(cat .external-review-prompt.txt)"
```

**Codex** — uses the built-in `review` preset with `--base` flag. Codex computes and reviews the branch diff internally with full filesystem access. Replace `<branch>` with the base branch from Step 1 (e.g., `main`). Does not use the staged prompt or diff files:

```
codex exec review --base <branch>
```

**Claude** — reads the prompt via `$(cat ...)`, then reads the diff file as instructed by the prompt. `-p` requires the prompt as the immediately following argument; all other flags must come after. Parse the `result` field from JSON output:

```
claude -p "$(cat .external-review-prompt.txt)" --max-turns 3 --output-format json --no-session-persistence
```

**Important:** Claude's `-p` consumes the next token as the prompt string. Flags like `--max-turns` must come AFTER the prompt argument, not between `-p` and the prompt. `claude -p --max-turns 3` would incorrectly use `--max-turns` as the prompt text.

If a CLI errors or produces no output, note it and move on. Do not retry on any error.

**5. Parse results.** For each CLI that returned output, extract findings and reformat into the standard reviewer format (Location, Issue, Fix, Severity). Tag findings with their source (e.g., "Gemini", "Codex", "Claude"). Tag any pre-existing issues with **[Pre-existing]**.

**Step 3: Collect findings.**

Wait for findings from all sources: built-in reviewers report via team messages, external CLI results are available from the Bash output in Step 2b. When you receive a reviewer's message, do not output or echo its content — silently collect it. Only output once in Step 4 when assembling the final results. A brief one-line status like "All reviewers have reported" is fine when ready to proceed.

**Step 4: Synthesize and present.**

Shut down the built-in reviewer teammates (send shutdown requests), wait for confirmations, then delete the team using the coding agent's team management tools (e.g. `TeamDelete` in Claude Code, `delete_agent` in Codex). **Never use `rm -rf` or manual file deletion for team cleanup** — always use the agent platform's built-in team teardown. If teardown fails (e.g., orphaned members), retry after a brief pause; if it still fails, report the issue to the user and move on. Delete the staged files (`rm -f .external-review-prompt.txt .external-review-diff.txt`). Assemble the final output:

1. **Reconcile.** Merge findings from two sources: the built-in team's collaborative results and any external CLI results. When multiple reviewers flagged the same issue, attribute to the most relevant reviewer and note cross-reviewer agreement. When an external CLI independently flags the same issue as a built-in reviewer, note the cross-model agreement — these findings were produced by truly independent processes, which strengthens confidence.
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

If agent teams/swarms are not available, spawn the built-in reviewers in parallel as independent subagents instead of teammates. Each analyzes independently. Skip the cross-validation instruction. External CLIs are always run inline regardless, so their behavior is unchanged in fallback mode — only built-in reviewers change (team members → subagents). Everything else (Steps 1, 3, 4, output format) stays the same.