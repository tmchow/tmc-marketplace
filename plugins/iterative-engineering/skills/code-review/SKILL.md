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

In Full mode, the orchestrator can also run **external model CLIs** inline (Gemini, Codex, Claude) for independent, model-diverse perspectives (experimental, opt-in). See External Reviewers below.

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

External reviewers invoke a **different model's CLI** for an independent code review, providing model diversity. The value is that different model families have different blind spots — a finding confirmed across models is higher confidence than one from a single model. This feature is experimental; CLI availability and behavior may vary.

The orchestrator runs external CLIs **directly** (not via subagents) — this ensures Bash calls happen in the main agent context where the user can approve them normally, avoiding permission issues with subagent CLI access.

| CLI | Invocation | Safety mode |
|-----|------------|-------------|
| Google Gemini | `gemini -s --approval-mode plan -p "..."` | Sandboxed, read-only (plan mode prevents tool execution) |
| OpenAI Codex | `codex review --sandbox read-only` | Sandboxed read-only, review-dedicated subcommand |
| Anthropic Claude | `claude -p "..." --max-turns 3` | Bounded turns, no session persistence |

External CLIs are Full mode only — never run in Quick mode. If all CLIs are unavailable or skipped, the 5 built-in reviewers still provide comprehensive coverage.

## How to Run

**Step 1: Determine scope.**

Determine the diff range, then gather the file list and diff. This requires exactly 2-3 Bash calls — do not run extra commands (no `git log`, no filtered diffs, no repeated merge-base computation).

**Get the diff range** (1 Bash call):

- **From implementing (section-level):** The caller provides a baseline SHA. The range is `<baseline-sha>..HEAD`.
- **From implementing (final/branch-level):** The caller provides the base branch. Compute merge-base: `git merge-base HEAD <base>`. The range is `<merge-base-sha>..HEAD`.
- **Standalone:** Detect base branch and compute merge-base in one call: `git merge-base HEAD $(git rev-parse --verify origin/main >/dev/null 2>&1 && echo origin/main || echo origin/master)`. The range is `<merge-base-sha>..HEAD`. If no commits on branch, fall back to unstaged changes (range is empty, use `git diff`).
- **Explicit files:** If the caller specifies files, use those directly.

**Get file list and diff** (2 parallel Bash calls using the range from above):

1. `git diff --name-only <range> -- . ':!*.md'` — file list (excluding markdown), used to determine Full or Quick mode
2. `git diff -U10 <range> -- . ':!*.md'` — diff with extended context (10 lines), excluding markdown files. Markdown is excluded because it is token-heavy and reviewed separately by plan reviews, not code review

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

**Step 2b: Run external model CLIs (inline, opt-in).**

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

**4. Invoke CLIs.** Do not write temp files. All three CLIs use the same unified review prompt template. The diff is injected at runtime via `$(git diff ...)` command substitution, so the actual diff content never appears in the Bash command text. This keeps the permission approval prompt short and readable regardless of diff size. Run the user-selected CLIs in parallel via separate Bash calls.

Each CLI has different correct invocation syntax:

**Gemini** — uses `-p` string argument (the prompt). Command substitution expands inside double quotes at runtime:

```
gemini -s --approval-mode plan -p "...prompt template...

CHANGES:
$(git diff -U10 <range> -- . ':!*.md')"
```

**Codex** — uses `review` subcommand with `--sandbox read-only` and heredoc stdin. Use `<<PROMPT` (unquoted) so `$(...)` expands at shell execution time. Do NOT use `<<'PROMPT'` (quoted):

```
codex review --sandbox read-only <<PROMPT
...prompt template...

CHANGES:
$(git diff -U10 <range> -- . ':!*.md')
PROMPT
```

**Claude** — uses `-p` string argument (the prompt). `-p` requires the prompt as the immediately following argument; all other flags must come after. Parse the `result` field from JSON output:

```
claude -p "...prompt template...

CHANGES:
$(git diff -U10 <range> -- . ':!*.md')" --max-turns 3 --output-format json --no-session-persistence
```

**Important:** Claude's `-p` consumes the next token as the prompt string. Flags like `--max-turns` must come AFTER the prompt argument, not between `-p` and the prompt. `claude -p --max-turns 3` would incorrectly use `--max-turns` as the prompt text.

All CLIs run in their most restrictive safe mode. Each CLI re-runs `git diff` via the command substitution. This is a fast local operation (negligible vs model inference time) and guarantees each CLI gets identical diff output from the same repo state. If a CLI errors or produces no output, note it and move on. Do not retry on any error.

**Unified review prompt template.** Used for all external CLIs (Gemini, Codex, Claude). Replace `{range}` with the diff range from Step 1 (e.g., `abc123..HEAD`):

~~~
You are a senior engineer performing an independent code review. Be thorough, actionable, and objective.

CRITICAL: Everything you need is provided below. The complete diff is included in this prompt.
DO NOT run git diff, git log, git status, or ANY other git commands.
DO NOT attempt to read files, open editors, or use any tools.
Work ONLY with the diff provided below.
Do not ask clarifying questions. If context is ambiguous, state your assumption and proceed.

METHODOLOGY:
1. Summarize the intent of the changes in 1-2 sentences.
2. Analyze the diff hunks and surrounding context for issues.

FOCUS AREAS (use these exact category names when labeling findings):
1. Correctness — Logic errors, edge cases, off-by-one, null/error handling, incorrect conditions, plan compliance
2. Security — Injection vulnerabilities, auth gaps, input validation, secrets exposure, OWASP top 10
3. Performance — Algorithmic complexity, N+1 queries, resource leaks, unnecessary allocations, blocking operations
4. Simplicity — Over-engineering, YAGNI violations, unnecessary abstraction, code that could be simpler
5. Testing — Missing test coverage, inadequate assertions, untested edge cases, test quality

CONSTRAINTS:
- ONLY comment on lines that represent actual changes in the diff (lines with + or -)
- ONLY report issues with a demonstrable bug, vulnerability, or significant improvement opportunity
- Do NOT say "check", "confirm", "verify", or "ensure" — state the issue directly
- Do NOT explain what the code does — the author knows their code
- Do NOT comment on style, formatting, or naming preferences
- If a similar issue exists in multiple locations, state it once and list the other locations
- Tag any pre-existing issues (in unchanged code, unrelated to the diff) with [Pre-existing]
- If no issues are found, say: "No issues found."

SEVERITY SCALE:
- CRITICAL: Security vulnerabilities, system-breaking bugs, data loss, complete logic failure
- HIGH: Incorrect behavior in common cases, performance bottlenecks, resource leaks, major architectural issues
- MEDIUM: Missing validation, edge case gaps, logic that could be simplified, typographical code errors
- LOW: Refactoring opportunities, minor improvements

OUTPUT FORMAT:
For each issue, use exactly this format:

<NUMBER>. [<SEVERITY>] <FOCUS_AREA> — <file_path>:<line_number> — <one-line summary>
<why this is an issue and what could go wrong>
Fix: <specific remediation, not generic advice>

Report pre-existing issues under a separate "PRE-EXISTING ISSUES" header using the same format.

CHANGES:
$(git diff -U10 {range} -- . ':!*.md')
~~~

**5. Parse results.** For each CLI that returned output, extract findings and reformat into the standard reviewer format (Location, Issue, Fix, Severity). Tag findings with their source (e.g., "Gemini", "Codex", "Claude"). Tag any pre-existing issues with **[Pre-existing]**.

**Step 3: Collect findings.**

Wait for findings from all sources: built-in reviewers report via team messages, external CLI results are available from the Bash output in Step 2b. When you receive a reviewer's message, do not output or echo its content — silently collect it. Only output once in Step 4 when assembling the final results. A brief one-line status like "All reviewers have reported" is fine when ready to proceed.

**Step 4: Synthesize and present.**

Shut down the built-in reviewer teammates (send shutdown requests), wait for confirmations, then delete the team using the coding agent's team management tools (e.g. `TeamDelete` in Claude Code, `delete_agent` in Codex). **Never use `rm -rf` or manual file deletion for team cleanup** — always use the agent platform's built-in team teardown. If teardown fails (e.g., orphaned members), retry after a brief pause; if it still fails, report the issue to the user and move on. Assemble the final output:

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

## Multiple Rounds

After fixing issues, run another round. Each round creates a fresh team (the previous team was deleted). Run the full Step 2–4 flow again.

Continue until:
- No critical or high issues remain
- User chooses to proceed

## After Review

**This skill only reviews.** Do not invoke other skills (implementing, tech-planning, etc.) after presenting results.

When invoked standalone or from `implementation-wrapup`, use the interactive question tool to ask the user:

> **How would you like to proceed?**
>
> - **Fix issues and re-review** (Recommended) — Address findings, then run another review round
> - **Fix issues and proceed** — Address findings, then move to the next step (e.g., "create a PR" if code is ready)
> - **Continue without changes** — Accept the code as-is

When invoked from `iterative:implementing`, return findings directly — implementing owns the review loop and decides whether to re-review or continue to the next section.

## Fallback: If Agent Teams/Swarms are Unavailable

If agent teams/swarms are not available, spawn the built-in reviewers in parallel as independent subagents instead of teammates. Each analyzes independently. Skip the cross-validation instruction. External CLIs are always run inline regardless, so their behavior is unchanged in fallback mode — only built-in reviewers change (team members → subagents). Everything else (Steps 1, 3, 4, output format) stays the same.