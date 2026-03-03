# Code Review Strategy

## Overview

The code review system uses 5 built-in domain experts that run as an agent team.

## Built-in Reviewers

Five reviewers run natively on the host platform, each focused on a specific domain:

| Reviewer | Domain | Key Question |
|----------|--------|--------------|
| Correctness | Logic, edge cases, bugs, error handling | Does this work correctly? |
| Security | Vulnerabilities, auth, input validation | Is this safe? |
| Performance | Complexity, queries, memory, caching | Is this fast enough? |
| Simplicity | Unjustified complexity, over-engineering, abstraction | Is the complexity justified? |
| Testing | Coverage, quality, edge cases, plan scenarios | Is this well-tested? |

Built-in reviewers run as an agent team, enabling cross-validation: reviewers can read each other's findings and challenge them.

## Diff-Anchored Scope

All reviewers follow a three-tier scope model:

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
All 5 built-in reviewers. Used for final branch reviews and standalone reviews.

### Quick Mode
2-3 built-in reviewers auto-selected by change type. Used for incremental section reviews during implementation.

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

1. **Reconciliation.** When multiple reviewers flag the same issue, merge them and note agreement.
2. **Pre-existing separation.** Findings tagged `[Pre-existing]` are pulled into their own section, excluded from the verdict.
3. **Structured output.** Strengths section, then per-reviewer findings tables, then pre-existing issues, then verdict.
4. **Verdict.** Based only on change-related findings: Ready to merge / Ready with fixes / Not ready.

## Design Principles

**Reviewers report, the skill synthesizes.** Individual reviewers only find and report issues. They never fix code, invoke other skills, or make decisions about what to do with findings. The orchestrating skill owns deduplication, presentation, and next-step decisions.

**Agent teams for cross-validation.** Built-in reviewers can read each other's findings and challenge them, so they run as team members rather than isolated subagents.

**Graceful degradation.** Missing agent teams? Fall back to parallel subagents. The 5 built-in reviewers still provide comprehensive coverage.

**Diff-anchored, not file-anchored.** Reviewers focus on what changed, flag what's caused by the changes, and separately tag what's pre-existing. This keeps reviews actionable for the PR author while not discarding useful observations.

## Standalone Fix Loop

When code-review runs standalone (not invoked from `iterative:implementing`), it owns the full fix-review cycle after presenting findings. When invoked from implementing, it returns findings directly; implementing has its own severity acceptance, subagent fix, and re-review loop.

### Why Two Modes

Implementing orchestrates a multi-phase workflow (task execution, simplification, review, wrapup) and needs to control fix decisions within that broader context. Standalone code-review has no outer orchestrator, so it must handle the cycle itself. Both modes use the same pattern (severity acceptance, subagent fix, re-review) but ownership differs.

### Standalone Flow

After synthesizing findings (Step 4), the standalone flow adds:

1. **Severity acceptance (Step 5).** Same pattern as implementing: Critical/High present, recommend fixing them; Medium/Low only, recommend proceeding. Interactive prompt, never combined with next-step options.
2. **Subagent fix (Step 6).** A single subagent receives the filtered findings, affected files, and instructions to fix, test, and commit. Runs outside the main thread to preserve context for re-review. One agent handles all findings because fixes can interact across files.
3. **Re-review (Step 7).** After fixes land, offer another round. Each round runs the full review flow (fresh team, fresh scope). Continues until clean or the user stops.
4. **Post-fix options (Step 8).** PR creation (if on a feature branch), continue, or exit. Handled inline; no other skills invoked.
