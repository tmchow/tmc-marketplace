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

In Full mode, the orchestrator also runs **external model CLIs** inline (Gemini, Codex, Claude) for independent, model-diverse perspectives. See External Reviewers below.

## Review Modes

### Full Mode (default)
Uses all 5 built-in reviewers. Optionally includes external model CLIs (Gemini, Codex, Claude) for model-diverse independent review — the user is asked before running them. Full mode always runs the 5 built-in reviewers regardless of external CLI availability.

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

The orchestrator runs external CLIs **directly** (not via subagents) — this ensures Bash calls happen in the main agent context where the user can approve them normally, avoiding permission issues with subagent CLI access.

| CLI | Invocation | Safety mode |
|-----|------------|-------------|
| Google Gemini | `gemini --sandbox -p` | Read-only sandbox |
| OpenAI Codex | `codex review --base` / `codex exec` | Read-only sandbox |
| Anthropic Claude | `claude -p --max-turns 3` | Bounded turns, no session persistence |

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

1. `git diff --name-only <range>` — file list, used to determine Full or Quick mode
2. `git diff <range>` — full diff content, what reviewers analyze

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

If uncertain, keep all three — each invocation is safe (sandboxed, read-only, time-bounded).

**2. Check availability.** Run `which` for each non-excluded CLI in parallel. Drop any CLI that isn't installed. Do not attempt to install missing CLIs or fall back to reviewing the code yourself.

**3. Ask the user.** If no CLIs remain after steps 1-2, skip to Step 3 silently. Otherwise, ask the user whether to include them. Name only the CLIs that are actually available (e.g., in Claude Code with Gemini and Codex installed, name "Gemini, Codex"). Use the interactive question tool with these options:

> **Also run {available CLI names} for independent review?**
>
> - **Yes** — Add model-diverse perspectives alongside the 5 built-in reviewers
> - **No** — The 5-reviewer team (correctness, security, performance, simplicity, testing) has full coverage

If the user declines, skip to Step 3.

**4. Invoke CLIs.** Pass the review prompt directly to each CLI via command argument or heredoc stdin. Do not write temp files (writing to `/tmp` triggers permission prompts). Run all available CLIs in parallel via separate Bash calls:

| CLI | Invocation |
|-----|------------|
| Gemini | `timeout 180 gemini --sandbox -p "<prompt>"` |
| Codex (branch) | `timeout 180 codex review --base <branch> --sandbox read-only - <<'PROMPT' ... PROMPT` |
| Codex (uncommitted) | `timeout 180 codex review --uncommitted --sandbox read-only - <<'PROMPT' ... PROMPT` |
| Codex (SHA range) | `timeout 180 codex exec --sandbox read-only - <<'PROMPT' ... PROMPT` |
| Claude | `timeout 180 claude -p --max-turns 3 --output-format json --no-session-persistence <<'PROMPT' ... PROMPT` |

For Gemini, pass the prompt as the `-p` string argument. For Codex and Claude, pipe via heredoc stdin. For Codex, prefer `codex review --base <branch>` when scope is branch-level, or `--uncommitted` when there are no commits yet (both handle diff internally). Fall back to `codex exec` for SHA-range scopes (embed scope in prompt). For Claude JSON output, parse the `result` field.

All CLIs run in sandbox/read-only mode with 180-second timeouts. If a CLI times out, errors, or produces no output, note it and move on. Do not retry on any error.

**Review prompt template** (shared across all CLIs). Replace `{diff_scope}` with the actual scope from Step 1 (e.g., `$(git merge-base HEAD main)..HEAD`) before passing to the CLI:

~~~
You are a senior engineer performing an independent code review. Be thorough, actionable, and objective.

SCOPE:
Review the changes in this repository. Retrieve the diff by running:
git diff {diff_scope}

METHODOLOGY:
1. Run the git diff command above to retrieve the changes.
2. Summarize the intent of the changes in 1-2 sentences.
3. Read the modified files for full context (not just the diff hunks).
4. Analyze the changes for issues.

FOCUS AREAS:
- Correctness: logic errors, edge cases, off-by-one errors, null/error handling, incorrect conditions
- Security: injection vulnerabilities, auth gaps, input validation, secrets exposure, OWASP top 10
- Performance: algorithmic complexity, N+1 queries, resource leaks, unnecessary allocations, blocking operations
- Real-world failures: partial failures, network issues, race conditions, timeout handling, corrupted state recovery
- API contract mismatches: incorrect library/framework usage, wrong assumptions about method behavior, misread documentation

CONSTRAINTS:
- ONLY comment on lines that represent actual changes in the diff (lines with + or -)
- ONLY report issues with a demonstrable bug, vulnerability, or significant improvement opportunity
- Do NOT say "check", "confirm", "verify", or "ensure" — state the issue directly
- Do NOT explain what the code does — the author knows their code
- Do NOT comment on style, formatting, or naming preferences
- If a similar issue exists in multiple locations, state it once and list the other locations
- If no issues are found, say: "No issues found. Code looks clean."

SEVERITY SCALE:
- CRITICAL: Security vulnerabilities, system-breaking bugs, data loss, complete logic failure
- HIGH: Incorrect behavior in common cases, performance bottlenecks, resource leaks, major architectural issues
- MEDIUM: Missing validation, edge case gaps, logic that could be simplified, typographical code errors
- LOW: Refactoring opportunities, minor improvements

OUTPUT FORMAT:
For each issue, use exactly this format:

<NUMBER>. [<SEVERITY>] <file_path>:<line_number> — <one-line summary>
<why this is an issue and what could go wrong>
Fix: <specific remediation, not generic advice>

If you notice significant issues in unchanged code unrelated to the diff, report them at the end under a "PRE-EXISTING ISSUES" header using the same format.
~~~

For Codex via `codex review --base`, omit the SCOPE section — Codex scopes the diff internally via its flags.

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

When invoked standalone or from `implementation-wrapup`, ask the user to choose:
- Fix issues and re-review (Recommended)
- Fix issues and proceed to [name the actual next step based on context, e.g., "create a PR" if code is ready]
- Continue without changes

When invoked from `iterative:implementing`, return findings directly — implementing owns the review loop and decides whether to re-review or continue to the next section.

## Fallback: If Agent Teams/Swarms are Unavailable

If agent teams/swarms are not available, spawn the built-in reviewers in parallel as independent subagents instead of teammates. Each analyzes independently. Skip the cross-validation instruction. External CLIs are always run inline regardless, so their behavior is unchanged in fallback mode — only built-in reviewers change (team members → subagents). Everything else (Steps 1, 3, 4, output format) stays the same.