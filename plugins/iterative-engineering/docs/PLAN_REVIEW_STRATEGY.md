# Plan Review Strategy

## Overview

The plan review system uses 6 reviewer personas organized in three tiers (1 document-type, 1 always-on, 3 conditional). Reviewers run as parallel sub-agents returning structured JSON. A merge pipeline deduplicates, confidence-gates, and priority-normalizes findings before presenting them.

The system is calibrated for an agentic workflow — the primary consumers of PRDs and tech plans are AI agents, not humans. Agents build exactly what's specified, don't exercise judgment about ambiguity, and won't ask clarifying questions. This changes what "good" looks like for both document types.

## Reviewer Personas

### Document-type (exactly 1)

Exactly one is spawned based on document type. These are the most important reviewers — they embody the perspective of the person who will use this document next.

| Persona | Selected when | Identity |
|---------|--------------|----------|
| `prd-reviewer` | PRD or brainstorm | Senior product leader evaluating whether the PRD properly frames a problem, makes the right decisions at the right level, and gives a tech planner everything it needs |
| `tech-plan-reviewer` | Tech plan | Senior developer implementing this plan with AI worker agents, mentally walking through each subtask to find where agents would stall |

Having two explicit personas instead of one "adaptive" persona solves a calibration problem: a single reviewer carrying logic for both doc types inevitably bleeds concerns across boundaries (e.g., asking a PRD for error handling details, or asking a tech plan about business justification). Separate identities mean each persona has a sharp, singular focus with explicit suppress conditions for the other domain.

#### PRD reviewer — what it hunts for

The PRD reviewer evaluates PRDs as a class of document, not checking boxes:

- **Weak problem framing** — problem statements that don't constrain the solution space (too broad or too narrow)
- **Coverage-scope mismatch** — PRD depth doesn't match what it's proposing. This includes questioning whether a PRD is even warranted — a bug fix, config change, or single-behavior tweak doesn't need one. Flags PRDs too thin for complex work and too ceremonial for simple work
- **Requirements that don't inform implementation** — requirements vague enough that a tech planner would have to make product decisions. Agents build exactly what you specify; ambiguous requirements produce ambiguous implementations
- **Decisions deferred that should be made here** — product decisions punted to the tech planner. Tech planners resolve technical questions; they shouldn't resolve product questions. Every deferred product decision is a coin flip an agent will make arbitrarily
- **Missing or porous scope boundaries** — exclusions not stated, or claimed but contradicted by requirements. Agents don't exercise judgment about "obviously out of scope"

The PRD reviewer explicitly does NOT flag: implementation details, file paths, business frameworks (KPIs, OKRs), measurement methodology, or style preferences.

#### Tech plan reviewer — what it hunts for

The tech plan reviewer reads by mentally walking through the implementation:

- **Subtasks that aren't independently executable** — each subtask needs: what to build, where in the codebase, what the interfaces look like, and how to verify it works. Self-contained subtasks execute reliably whether run serially or in parallel. Parallel execution is a bonus when the dependency structure supports it, not a requirement
- **Missing file paths and interfaces** — without explicit locations, agents create new files when they should modify existing ones
- **Architecture decisions without rationale** — agents need the "why" to know when to adapt vs. follow blindly
- **Test scenarios too vague to execute** — agents need concrete inputs and expected outputs, not "verify error handling"
- **Coverage-scope mismatch** — plan granularity should match complexity. Over-decomposed simple work adds coordination overhead; under-specified complex work forces agents to make architectural decisions

The tech plan reviewer explicitly does NOT flag: product rationale, priority/scope decisions, alternative approaches (unless the chosen one won't work), or over-specification of simple subtasks.

### Always-on (1)

| Persona | Focus |
|---------|-------|
| `coherence-reviewer` | Internal consistency, contradictions, terminology drift, structural issues |

The coherence reviewer is valuable for every document type. It catches when the document disagrees with itself — a different concern from whether the content is good or complete (which the doc-type reviewer handles). It does NOT flag missing content, only content that contradicts other content.

### Conditional (3)

| Persona | Select when... | Doc-type constraint |
|---------|---------------|---------------------|
| `skeptic-reviewer` | Plan proposes abstractions, multi-layer architecture, plugin systems, generic frameworks, or infrastructure ahead of need | Any |
| `feasibility-reviewer` | Tech plan proposes architecture decisions, external system integrations, performance requirements, or migration strategies | Tech plans only |
| `scope-guardian-reviewer` | PRD has multiple priority levels with potential conflicts, unclear scope boundaries, or goals that don't connect to requirements | PRDs only |

Because `feasibility-reviewer` applies only to tech plans and `scope-guardian-reviewer` applies only to PRDs, they are mutually exclusive. The maximum reviewer count for any single document is 4 (1 doc-type + 1 always-on + 2 applicable conditionals).

### Dynamic selection

The orchestrator reads the document and reasons about which conditional personas are warranted. This is agent judgment — not keyword matching. The orchestrator announces the selected team with a one-line justification per conditional reviewer, making selection auditable.

## Persona Definition Structure

Each persona follows a 4-section structure designed to activate expert reasoning:

1. **Identity statement** — 2-sentence expert framing. Establishes who the reviewer IS, not what checklist they follow.
2. **What you're hunting for** — 3-5 concrete failure modes recognizable on sight. Specific enough to pattern-match against document content.
3. **Confidence calibration** — per-persona guidance on what raises confidence from 0.50 to 0.90.
4. **What you don't flag** — front-loaded suppress conditions. The biggest quality problem in plan review is noise — flagging issues that belong to a different document type or a different reviewer. Leading with what NOT to flag trains the persona to self-filter.

### Skeptic calibration

The skeptic reasons from maintenance cost over time, not build cost or effort. Valid: "this abstraction has one consumer — is it earning its keep?" Invalid: "you probably won't need this yet, build it later."

The skeptic CAN question features and scope — but only through the lens of ongoing maintenance burden, not crude YAGNI heuristics. The agent file's suppress condition ("don't second-guess scope decisions") means the skeptic won't say "you don't need this feature." But it can say "this feature adds ongoing maintenance burden through X, Y, Z." The distinction: questioning the *structural approach* to building a feature is valid; questioning *whether to build it* is not.

Agents build cheaply; the cost that matters is what the team pays to maintain, understand, and modify over time.

### Coverage-scope mismatch (cross-cutting)

Both doc-type reviewers share a "coverage-scope mismatch" failure mode, but calibrated differently:

- **PRD reviewer**: questions whether the PRD's depth matches its scope, including whether a PRD was even needed. Flags thin PRDs on complex topics and ceremonial PRDs on simple ones.
- **Tech plan reviewer**: questions whether the plan's granularity matches its complexity. Flags over-decomposed simple plans and under-specified complex ones.

This is one of the most important failure modes — it prevents document ceremony from scaling linearly with every task regardless of actual complexity.

## Sub-agent Execution

Reviewers run as parallel sub-agents (not agent teams). Each receives a structured prompt assembled from:
- Their persona definition file
- The JSON output contract
- Review context (document type, path, content)

Sub-agents are read-only: they return structured JSON and do not edit files or propose fixes.

## JSON Output and Merge Pipeline

Every reviewer returns JSON matching a shared schema with typed fields: title, priority (HIGH/MEDIUM/LOW), section, line, why_it_matters, confidence, evidence, and optional suggestion.

The merge pipeline:
1. **Validates** output against the schema, dropping malformed findings
2. **Confidence-gates** at 0.50 (suppresses speculative findings). Personas self-suppress below 0.60 as a first line of defense; the 0.50 gate is a safety net.
3. **Deduplicates** via fingerprint: `normalize(section) + line_bucket(line, ±5) + normalize(title)`. Merges keep highest priority, strongest evidence, and note cross-reviewer agreement.
4. **Sorts** by priority → confidence → document order

## Priority Scale

Plan reviews use a 3-level priority scale (vs. code review's 4-level severity scale):

| Level | Meaning | Action |
|-------|---------|--------|
| **HIGH** | Blocks execution; cannot start the next step without resolving | Must fix before proceeding |
| **MEDIUM** | Creates risk; work can start but likely leads to rework or confusion | Should fix |
| **LOW** | Improvement opportunity; plan works but could be clearer or tighter | Author's discretion |

The scale is lighter than code review's P0-P3 because document issues don't crash systems or create security vulnerabilities. "HIGH" in a plan review means "someone will be blocked or confused," not "the system will break in production."

## Output Format

Findings are grouped by priority (not by reviewer). Each finding shows section, issue, reviewer(s), and confidence. Cross-reviewer agreement is shown inline. A coverage section reports suppressed findings and residual concerns.

The report ends with a synthesis — patterns, tensions, quick wins — not a binary verdict. Plans don't have "ready/not ready." The synthesis helps the author decide what to address.

## Invocation Modes

Plan review operates in two modes depending on how it's called:

**When invoked from `iterative:brainstorming` or `iterative:tech-planning`:** returns findings directly. The calling skill owns the fix loop and workflow transitions.

**When invoked standalone:** owns the full fix-review cycle:
1. **Priority acceptance** — user selects which priority levels to fix (HIGH recommended when present; skip recommended when only MEDIUM/LOW)
2. **Subagent fixes** — a single subagent applies targeted fixes, preserving the document's voice
3. **Re-review offer** — verify fixes and check for new issues
4. **Post-fix options** — next workflow step based on document type (PRD → tech planning, tech plan → implementing)

Steps are strictly sequential — never collapsed or merged. The fix-review loop continues until the user chooses to proceed. There is no binary "clean" state; exit is always user-driven.

## Design Principles

**Reviewers report, the orchestrator synthesizes.** Individual reviewers find and report issues as structured JSON. They never fix the document, invoke other skills, or make decisions about findings. The orchestrator owns deduplication, presentation, and next-step decisions.

**Document-type specificity over adaptive personas.** Two explicit doc-type reviewers (PRD reviewer, tech plan reviewer) instead of one reviewer that switches behavior. Each persona has a sharp identity and never bleeds concerns across document types.

**Agentic calibration throughout.** These documents feed AI agents, not human teams. Agents build exactly what's specified, don't exercise judgment about ambiguity, and won't ask clarifying questions. Every persona is calibrated for this reality — from the PRD reviewer's emphasis on explicit scope boundaries to the tech plan reviewer's focus on self-contained subtasks.

**Coverage-scope mismatch as a first-class concern.** Both doc-type reviewers flag when document ceremony doesn't match actual scope. This prevents the system from generating full PRDs for config changes or thin plans for complex integrations.

**Structured output over prose.** JSON with typed fields enables deterministic dedup, confidence gating, and priority normalization. Prose output requires ad-hoc reconciliation.

**Maintenance-cost skepticism, not build-cost skepticism.** The skeptic evaluates ongoing structural burden, not whether something is worth building. Agents make build cost cheap; only maintenance cost over time matters.

**Dynamic selection over fixed roster.** Not every document needs every reviewer. The orchestrator selects the right reviewers for each document, reducing noise from irrelevant domains.
