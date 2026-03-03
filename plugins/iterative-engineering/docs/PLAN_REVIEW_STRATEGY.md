# Plan Review Strategy

## Overview

The plan review system uses 4 built-in domain experts that run as an agent team, designed for PRDs, brainstorms, and technical plans.

## Built-in Reviewers

Four reviewers run natively on the host platform, each focused on a specific domain:

| Reviewer | Domain | Key Question |
|----------|--------|--------------|
| Clarity | Vague language, ambiguity, structure | Is this understandable? |
| Completeness | Missing sections, gaps, dependencies | Is anything missing? |
| Specificity | Actionability, concrete details | Is this concrete enough? |
| Complexity & Debt | Unjustified complexity, premature abstraction, dead flexibility | Is the complexity justified? |

Built-in reviewers run as an agent team, enabling cross-validation: reviewers can read each other's findings and challenge them. A key cross-validation pattern is the completeness-vs-complexity tension, where completeness wants more detail while the complexity reviewer pushes back on additions that add maintenance burden. When these reviewers disagree, the friction itself is informative.

Quick scope tasks don't invoke plan-review; they use a lightweight confirmation gate during brainstorming (confirm understanding of the fix, flag edge cases) and exit directly. Standard scope also doesn't invoke plan-review — brainstorming captures decisions in an inline summary without creating a document, so there's nothing for reviewers to analyze. Only Full scope invokes plan-review, since it produces a PRD that benefits from structured multi-reviewer analysis.

## Priority Scale

Plan reviews use a 3-level priority scale (vs. code review's 4-level severity scale):

| Level | Meaning | Action |
|-------|---------|--------|
| **High** | Blocks execution; cannot start the next step without resolving | Must fix before proceeding |
| **Medium** | Creates risk; work can start but likely leads to rework or confusion | Should fix |
| **Low** | Improvement opportunity; plan works but could be clearer or tighter | Author's discretion |

The scale is lighter than code review's severity scale because document issues don't crash systems or create security vulnerabilities. "High" in a plan review means "someone will be blocked or confused," not "the system will break in production."

## Synthesis

The skill orchestrator (not the individual reviewers) synthesizes all findings:

1. **Reconciliation.** When multiple reviewers flag the same issue, merge and note agreement.
2. **Structured output.** Per-reviewer findings tables, then synthesis with cross-reviewer patterns, tensions, and quick wins.
3. **No verdict.** Unlike code review (which ends with a merge verdict), plan review ends with a synthesis that highlights patterns and tensions. Plans don't have a binary "ready/not ready"; the synthesis helps the author decide what to address.

## Design Principles

**Reviewers report, the skill synthesizes.** Individual reviewers only find and report issues. They never fix the document, invoke other skills, or make decisions about what to do with findings. The orchestrating skill owns deduplication, presentation, and next-step decisions.

**Agent teams for cross-validation.** Built-in reviewers can read each other's findings and challenge them, so they run as team members rather than isolated subagents.

**Graceful degradation.** Missing agent teams? Fall back to parallel subagents. The 4 built-in reviewers still provide comprehensive coverage.
