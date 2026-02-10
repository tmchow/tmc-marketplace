# Code Review Strategy

## Overview

The code review system combines 5 built-in domain experts with up to 2 external reviewers from different model families.

## Built-in Reviewers

Five reviewers run natively on the host platform, each focused on a specific domain:

| Reviewer | Domain | Key Question |
|----------|--------|--------------|
| Correctness | Logic, edge cases, bugs, error handling | Does this work correctly? |
| Security | Vulnerabilities, auth, input validation | Is this safe? |
| Performance | Complexity, queries, memory, caching | Is this fast enough? |
| Simplicity | YAGNI, over-engineering, abstraction | Is this minimal? |
| Testing | Coverage, quality, edge cases, plan scenarios | Is this well-tested? |

Built-in reviewers run as an agent team, enabling cross-validation: reviewers can read each other's findings and challenge them.

## External Reviewers (Experimental)

Five reviewers powered by the same model share the same training data, reasoning patterns, and blind spots. External reviewers address this by invoking a different model family's CLI for an independent review. This feature is experimental; CLI availability and behavior may vary. Codex reviews can take 5+ minutes.

Three external CLIs are supported:

| CLI | Invocation | Safety mode |
|-----|------------|-------------|
| Google Gemini | `gemini -s -p "..."` | Sandboxed (diff inlined, no tool access needed) |
| OpenAI Codex | `codex review --sandbox read-only` | Sandboxed read-only, review-dedicated subcommand |
| Anthropic Claude | `claude -p "..." --max-turns 3` | Bounded turns, no session persistence |

### Execution Model

The orchestrator runs external CLIs **directly** via Bash, not via subagents. This ensures CLI commands execute in the main agent context where the user can approve Bash access normally, avoiding permission issues that occur when subagents try to invoke CLIs.

In Full mode, the user selects which external CLIs to include (multi-select when 2+ are available, yes/no for a single CLI). The orchestrator runs the selected CLIs in parallel alongside the built-in reviewer team. The orchestrating skill reconciles findings from both sources during synthesis.

### Self-Identification

The orchestrator determines its own model family and skips the matching CLI:

- Running in Claude Code: Gemini + Codex CLIs run, Claude CLI skipped
- Running in Codex: Gemini + Claude CLIs run, Codex CLI skipped

CLIs that aren't installed are also skipped (checked via `which`).

### Diff Handling

All external CLIs receive the same unified prompt with the diff injected at runtime via `$(git diff ...)` command substitution. The diff is not pre-computed and pasted into the prompt. Instead, each CLI command uses an unquoted heredoc (`<<PROMPT`, not `<<'PROMPT'`) or string argument containing `$(git diff -U10 <range> -- . ':!*.md')`, which the shell expands at execution time. Two benefits:

1. **Clean permission prompts.** In Claude Code (and similar agent frameworks), Bash calls show the full command text for user approval. Command substitution keeps the approval prompt short and readable: the user sees `$(git diff ...)` rather than thousands of lines of diff text.
2. **Local prompt staging.** The review prompt template is embedded in the skill definition (SKILL.md). The plugin directory (`~/.claude/plugins/...`) is outside the project sandbox, and any tool accessing it triggers a permission dialog with no global-approve option. By embedding the template, the orchestrator writes it to `.external-review-prompt.txt` using the Write tool (no permission needed for local paths), then CLI invocations reference the local copy via `$(cat .external-review-prompt.txt)`. The file is deleted during synthesis (Step 4).

Each CLI re-runs `git diff` via the command substitution. This is a fast local operation (negligible compared to model inference time) and guarantees each CLI analyzes the exact same repo state.

The prompt explicitly instructs the model: "DO NOT run any commands, read files, or use tools." Each CLI also enforces restrictions at the invocation level: Gemini uses `-s` (sandbox mode); Codex uses `--sandbox read-only` (restricts to read-only file access) via its `review` subcommand's `ReviewTarget::Custom` path; Claude is bounded to 3 turns with no session persistence. The invocation syntax also differs: Gemini and Claude use `-p "prompt"` (string argument), while Codex uses heredoc stdin to its `review` subcommand. Claude's `-p` flag consumes the immediately following token as the prompt, so other flags like `--max-turns` must come after the prompt string, not between `-p` and the prompt.

Extended context (`-U10` = 10 lines before/after each hunk instead of the default 3) compensates for the model not being able to read full files. This adds some tokens but far fewer than letting each CLI make tool calls to read entire files. Markdown files are excluded because they are token-heavy and reviewed separately by plan reviews.

### Safety

Each CLI runs in its most restrictive read-only mode. Since the diff is inlined in the prompt, no CLI needs tool access to perform the review:

| CLI | Safety flags | Effect |
|-----|-------------|--------|
| Gemini | `-s` | Sandboxed (diff inlined, no tool access needed) |
| Codex | `codex review --sandbox read-only` | Review-dedicated subcommand + sandboxed read-only file access |
| Claude | `-p "..." --max-turns 3 --no-session-persistence` | Bounded turns; `-p` requires prompt as immediately following arg |

### Graceful Degradation

External CLIs are additive and opt-in. If a CLI isn't installed, the orchestrator notes it and moves on. If all external CLIs are unavailable or the user declines, the review proceeds with the 5 built-in reviewers. The system never fails because of a missing external tool.

## Diff-Anchored Scope

All reviewers (built-in and external) follow a three-tier scope model:

| Tier | Rule |
|------|------|
| **Primary** | Issues in the changed lines themselves |
| **Secondary** | Issues in unchanged code directly caused or exposed by the changes |
| **Pre-existing** | Significant issues in unchanged code unrelated to the changes, tagged `[Pre-existing]` |

This prevents two failure modes:
1. **Noise**: Flagging pre-existing issues at the same priority as change-related findings, overwhelming the author
2. **Suppression**: Ignoring a real vulnerability just because it wasn't in the diff

Pre-existing findings are separated in the final output and excluded from the merge verdict. They can be triaged independently (e.g., filed as a separate issue).

## Review Modes

### Full Mode (default)
All 5 built-in reviewers + external model CLIs (opt-in). Used for final branch reviews and standalone reviews.

### Quick Mode
2-3 built-in reviewers auto-selected by change type. No external reviewers. Used for incremental section reviews during implementation.

| Changed files | Reviewers |
|---------------|-----------|
| Auth/security code | Security + Correctness |
| Database/queries | Performance + Correctness |
| New feature code | Correctness + Testing |
| Refactoring | Correctness + Simplicity |
| Tests only | Correctness + Testing |
| Config/CI only | Correctness (minimal) |

## Synthesis

The skill orchestrator (not the individual reviewers) synthesizes all findings:

1. **Reconciliation.** Merge findings from two sources: the built-in team's collaborative results and any external CLI results. When multiple reviewers flag the same issue, merge them and note agreement. Cross-model agreement (built-in team + external CLI flagging the same issue independently) strengthens confidence.
2. **Pre-existing separation.** Findings tagged `[Pre-existing]` are pulled into their own section, excluded from the verdict.
3. **Structured output.** Strengths section, then per-reviewer findings tables, then pre-existing issues, then verdict.
4. **Verdict.** Based only on change-related findings: Ready to merge / Ready with fixes / Not ready.

## Design Principles

**Model diversity over model quantity.** Two models catching the same bug is stronger signal than five instances of the same model agreeing. External reviewers exist for genuine perspective diversity, not throughput.

**Reviewers report, the skill synthesizes.** Individual reviewers (built-in or external) only find and report issues. They never fix code, invoke other skills, or make decisions about what to do with findings. The orchestrating skill owns deduplication, presentation, and next-step decisions.

**Inline for opaque wrappers, teams for collaborators.** External CLIs are opaque wrappers that can't cross-validate, so they run inline via the orchestrator. Built-in reviewers can read each other's findings and challenge them, so they belong as team members. Match the execution model to the agent's actual capabilities.

**Graceful degradation everywhere.** No component is required for the system to function. Missing CLI? Skip. Missing agent teams? Fall back to parallel subagents. Missing all external reviewers? The 5 built-in reviewers still provide comprehensive coverage.

**Diff-anchored, not file-anchored.** Reviewers focus on what changed, flag what's caused by the changes, and separately tag what's pre-existing. This keeps reviews actionable for the PR author while not discarding useful observations.

## Unified Prompt Design

All three external CLIs (Gemini, Codex, Claude) use the same unified review prompt template with the diff inlined. The template is embedded directly in the skill definition (SKILL.md) rather than a separate file, so the orchestrator can write it locally without accessing plugin directory paths that trigger sandbox permission prompts.

Key design decisions:

- **Diff inlined, no tool calls.** The full diff is embedded in the prompt. The model is explicitly told not to run any commands. This eliminates wasted turns on redundant `git diff` calls and ensures all CLIs analyze identical input.
- **Focus areas match built-in reviewers.** The 5 focus areas (Correctness, Security, Performance, Simplicity, Testing) are identical to the built-in reviewer domains. Each finding includes a `FOCUS_AREA` label, so the orchestrator can slot external findings directly into the matching reviewer section during reconciliation.
- **Headless, no interaction.** The prompt explicitly says "Do not ask clarifying questions" because these are headless CLI invocations with no user interaction. If context is ambiguous, the model states its assumption and proceeds.
- **Intent-first methodology.** Summarize the change's purpose before looking for issues.
- **Constraint-heavy.** Over half the prompt is about what NOT to do (don't explain code, don't nitpick style, don't say "check" or "verify").
- **Diff-anchored.** Only comment on changed lines; pre-existing issues go under a separate header.
- **Structured output.** Numbered findings with severity, focus area, location, issue, and fix.
- **Deduplication instruction.** State repeated issues once, list other locations.
- **Markdown excluded.** Markdown files are filtered out of the diff before inlining. They are token-heavy and reviewed separately by plan reviews, not code review.

This design reduces the most common LLM code review failure modes: hand-wavy non-actionable feedback, reviewing the entire file instead of the changes, and walls of repeated findings.
