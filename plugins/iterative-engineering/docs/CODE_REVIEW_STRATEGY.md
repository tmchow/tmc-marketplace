# Code Review Strategy

## Overview

The code review system uses an ensemble of specialized reviewers — 5 built-in domain experts plus up to 2 external reviewers from different model families — to provide comprehensive, multi-perspective code review.

## Built-in Reviewers

Five reviewers run natively on the host platform, each focused on a specific domain:

| Reviewer | Domain | Key Question |
|----------|--------|--------------|
| Correctness | Logic, edge cases, bugs, error handling | Does this work correctly? |
| Security | Vulnerabilities, auth, input validation | Is this safe? |
| Performance | Complexity, queries, memory, caching | Is this fast enough? |
| Simplicity | YAGNI, over-engineering, abstraction | Is this minimal? |
| Testing | Coverage, quality, edge cases, plan scenarios | Is this well-tested? |

Built-in reviewers run as an agent team, enabling cross-validation — reviewers can read each other's findings and challenge them.

## External Reviewers (Model Diversity)

The most valuable code review insight isn't more of the same perspective — it's a genuinely different one. Five reviewers powered by the same model share the same training data, reasoning patterns, and blind spots. External reviewers solve this by invoking a different model family's CLI for an independent review.

Three external reviewer agents exist:

| Agent | CLI | Invocation |
|-------|-----|------------|
| `gemini-reviewer` | Google Gemini | `gemini --sandbox -p` |
| `codex-reviewer` | OpenAI Codex | `codex review --base` / `codex exec` |
| `claude-reviewer` | Anthropic Claude | `claude -p --max-turns 3` |

### Self-Identification

All three are spawned in Full mode. Each agent self-identifies whether it shares a model family with the host platform and skips itself if so. This means:

- Running in Claude Code: Gemini + Codex reviewers run, Claude reviewer skips
- Running in Codex: Gemini + Claude reviewers run, Codex reviewer skips

The skill doesn't need platform detection logic — each agent handles it.

### Diff Handling

External reviewers run in the same working directory on the same branch. Rather than embedding diffs in prompts (which bloats context and loses full-file visibility), each CLI gathers the diff itself:

- **Gemini/Claude**: The prompt includes a `SCOPE` section with the `git diff` command to run. The CLI executes it, reads modified files for full context, then reviews.
- **Codex**: Uses `codex review --base <branch>` which handles diff scoping natively. Falls back to `codex exec` with a scope instruction for SHA-range reviews.

### Safety

Each CLI runs in its most restrictive read-only mode:

| CLI | Safety flag | Effect |
|-----|------------|--------|
| Gemini | `--sandbox` | Cannot write files or execute destructive commands |
| Codex | `--sandbox read-only` | Cannot write files or execute destructive commands |
| Claude | `--max-turns 3` | Bounded cost; no explicit sandbox but prompt-constrained |

### Graceful Degradation

External reviewers are additive. If a CLI isn't installed, the agent reports "skipping" and stops. If all external reviewers are unavailable, the review proceeds with the 5 built-in reviewers — the system never fails because of a missing external tool.

## Diff-Anchored Scope

All reviewers (built-in and external) follow a three-tier scope model:

| Tier | Rule |
|------|------|
| **Primary** | Issues in the changed lines themselves |
| **Secondary** | Issues in unchanged code directly caused or exposed by the changes |
| **Pre-existing** | Significant issues in unchanged code unrelated to the changes — tagged `[Pre-existing]` |

This prevents two failure modes:
1. **Noise**: Flagging pre-existing issues at the same priority as change-related findings, overwhelming the author
2. **Suppression**: Ignoring a real vulnerability just because it wasn't in the diff

Pre-existing findings are separated in the final output and excluded from the merge verdict. They can be triaged independently (e.g., filed as a separate issue).

## Review Modes

### Full Mode (default)
All 5 built-in reviewers + all available external reviewers. Used for final branch reviews and standalone reviews.

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

1. **Deduplication** — When multiple reviewers flag the same issue, merge them and note agreement. Cross-model agreement (built-in + external flagging the same issue) strengthens confidence.
2. **Pre-existing separation** — Findings tagged `[Pre-existing]` are pulled into their own section, excluded from the verdict.
3. **Structured output** — Strengths section, then per-reviewer findings tables, then pre-existing issues, then verdict.
4. **Verdict** — Based only on change-related findings: Ready to merge / Ready with fixes / Not ready.

## Design Principles

**Model diversity over model quantity.** Two models catching the same bug is stronger signal than five instances of the same model agreeing. External reviewers exist for genuine perspective diversity, not throughput.

**Reviewers report, the skill synthesizes.** Individual reviewers (built-in or external) only find and report issues. They never fix code, invoke other skills, or make decisions about what to do with findings. The orchestrating skill owns deduplication, presentation, and next-step decisions.

**Graceful degradation everywhere.** No component is required for the system to function. Missing CLI? Skip. Missing agent teams? Fall back to parallel subagents. Missing all external reviewers? The 5 built-in reviewers still provide comprehensive coverage.

**Diff-anchored, not file-anchored.** Reviewers focus on what changed, flag what's caused by the changes, and separately tag what's pre-existing. This keeps reviews actionable for the PR author while not discarding useful observations.

## Shared Prompt Design (External Reviewers)

All three external reviewers use the same prompt template, derived from Google's Gemini CLI code-review extension with adaptations for our ensemble context:

- **Intent-first methodology** — Summarize the change's purpose before looking for issues
- **Constraint-heavy** — Over half the prompt is about what NOT to do (don't explain code, don't nitpick style, don't say "check" or "verify")
- **Diff-anchored** — Only comment on changed lines; pre-existing issues go under a separate header
- **Structured output** — Numbered findings with severity, location, issue, and fix
- **Deduplication instruction** — State repeated issues once, list other locations

This design reduces the most common LLM code review failure modes: hand-wavy non-actionable feedback, reviewing the entire file instead of the changes, and walls of repeated findings.
