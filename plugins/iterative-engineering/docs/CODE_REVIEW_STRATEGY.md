# Code Review Strategy

## Overview

The code review system uses 8 reviewer personas organized in two tiers (3 always-on, 5 conditional). Reviewers run as parallel sub-agents returning structured JSON. A merge pipeline deduplicates, confidence-gates, and severity-normalizes findings before presenting them.

## Reviewer Personas

### Always-on (every review)

| Persona | Focus |
|---------|-------|
| `correctness` | Logic errors, edge cases, state bugs, error propagation, intent compliance |
| `testing` | Coverage gaps, weak assertions, brittle tests, missing edge case coverage |
| `maintainability` | Coupling, complexity, naming, dead code, premature abstraction |

### Conditional (selected per diff)

| Persona | Select when diff touches... |
|---------|---------------------------|
| `security` | Auth middleware, public endpoints, user input handling, permissions |
| `performance` | Database queries, data transforms, caching, async code |
| `api-contract` | Route definitions, serializers, type signatures, versioning |
| `data-migrations` | Migration files, schema changes, backfill scripts |
| `reliability` | Error handling, retries, timeouts, background jobs, async handlers |

### Dynamic selection

The orchestrator reads the full diff and reasons about which conditional personas are warranted. This is agent judgment — not keyword matching (brittle) or a scoring formula (fragile). The orchestrator announces the selected team with a one-line justification per conditional reviewer, making selection auditable and debuggable.

## Persona Definition Structure

Each persona follows a 4-section structure designed to activate expert reasoning rather than checklist execution:

1. **Identity statement** — 2-sentence expert framing. "You ARE this expert" produces different results than "verify this checklist."
2. **What you're hunting for** — 3-5 concrete failure modes recognizable on sight. Specific enough to pattern-match against code, broad enough to avoid becoming a narrow checklist.
3. **Confidence calibration** — Per-persona guidance on what raises confidence from 0.50 to 0.90. This varies by domain: a security finding at 0.60 is actionable (cost of miss is high); a performance finding at 0.60 is noise (cost of miss is low, easy to measure later).
4. **What you don't flag** — Front-loaded suppress conditions. The biggest quality problem in AI code review is noise. Leading with what NOT to flag trains the persona to self-filter before generating.

## Intent Discovery

Before selecting reviewers, the orchestrator understands what the change is trying to accomplish. Intent shapes *how hard each reviewer looks*, not which reviewers are selected. A 2-3 line summary is derived from commit messages and conversation context, then passed to every reviewer.

## Sub-agent Execution

Reviewers run as parallel sub-agents (not Agent Teams). Each receives a structured prompt assembled from:
- Their persona definition file
- Shared diff-scope rules
- The JSON output contract
- Review context (intent, files, diff)

Sub-agents are read-only: they return structured JSON and do not edit files, run commands, or propose refactors.

## JSON Output and Merge Pipeline

Every reviewer returns JSON matching a shared schema with typed fields: title, severity (P0-P3), file, line, why_it_matters, confidence, evidence, pre_existing, and optional suggested_fix.

The merge pipeline:
1. **Validates** output against the schema, dropping malformed findings
2. **Confidence-gates** at 0.50 (suppresses speculative findings)
3. **Deduplicates** via fingerprint: `normalize(file) + line_bucket(line, ±3) + normalize(title)`. Merges keep highest severity, strongest evidence, and note cross-reviewer agreement.
4. **Separates pre-existing** findings for independent triage
5. **Sorts** by severity → confidence → file → line

## Diff-Anchored Scope

All reviewers follow a three-tier scope model defined in a shared reference file:

| Tier | Rule |
|------|------|
| **Primary** | Issues in the changed lines themselves |
| **Secondary** | Issues in unchanged code directly caused or exposed by the changes |
| **Pre-existing** | Significant issues in unchanged code unrelated to the changes, marked `pre_existing: true` |

Pre-existing findings are separated in the output and excluded from the verdict.

## Review Scope

The always-on/conditional tier model naturally right-sizes reviews. A small config diff triggers 0 conditionals = 3 reviewers. A large feature diff touching auth and migrations triggers security + data-migrations = 5 reviewers. No separate "mode" is needed.

## Output Format

Findings are grouped by severity (P0, P1, P2, P3) rather than by reviewer. Each finding shows file, issue, reviewer(s), and confidence. Cross-reviewer agreement is shown inline. A coverage section reports suppressed findings, residual risks, and testing gaps.

## Standalone Fix Loop

When running standalone (not from `iterative:implementing`), the skill owns the full fix-review cycle: severity acceptance → subagent fixes → re-review offer → post-fix options. When invoked from implementing, findings return directly; implementing has its own severity acceptance flow.

## Design Principles

**Reviewers report, the orchestrator synthesizes.** Individual reviewers find and report issues as structured JSON. They never fix code, invoke other skills, or make decisions about findings. The orchestrator owns deduplication, presentation, and next-step decisions.

**Dynamic selection over fixed roster.** Not every diff needs every reviewer. The orchestrator selects the right reviewers for each diff, reducing noise from irrelevant domains.

**Structured output over prose.** JSON with typed fields enables deterministic dedup, confidence gating, and severity normalization. Prose output requires ad-hoc reconciliation.

**Per-persona confidence calibration.** A uniform "80% confidence threshold" ignores that confidence means different things per domain. Each persona calibrates its own threshold.

**Diff-anchored, not file-anchored.** Reviewers focus on what changed, flag what's caused by the changes, and separately tag what's pre-existing. This keeps reviews actionable.
