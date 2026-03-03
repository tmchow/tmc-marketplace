# Plan Review v2 — Design Document

## Context

PR #79 overhauled the code-review skill from a fixed 5-reviewer agent team into a dynamic 8-persona system with parallel sub-agents and structured JSON output. This document applies the same architectural patterns to the plan-review skill.

## Problems with v1

1. **Agent teams add complexity without proportional benefit.** TeamCreate/SendMessage/shutdown ceremony for 4 reviewers that don't need cross-validation. Plan review findings are independent — one reviewer's output doesn't change based on what another found.
2. **Document-type calibration is too weak.** The completeness reviewer asks for implementation details on PRDs because its "determine document type" conditional logic isn't strong enough. Result: noisy findings that create review friction.
3. **Quality-dimension personas produce generic feedback.** "Clarity reviewer" and "specificity reviewer" think about abstract document properties. The code-review overhaul showed that identity-framed personas ("you ARE a security expert who thinks like an attacker") produce fundamentally different reasoning.
4. **No structured output or merge pipeline.** Free-form text output requires manual reconciliation. No confidence gating, no deduplication, no deterministic merge.
5. **YAGNI skepticism backfires with agents.** The complexity reviewer applied human development heuristics ("you probably won't need this") that ignore agent economics — agents build features cheaply, so build cost is the wrong frame. Only maintenance cost over time matters.

## Architecture

### Execution Model

Replace agent teams with parallel sub-agents returning structured JSON. Same pattern as code-review v2.

### Persona Model

6 personas organized in three tiers:

**Document-type (exactly 1 — selected by document type):**

| Persona | Selected when | Identity |
|---------|--------------|----------|
| `prd-reviewer` | Document is a PRD or brainstorm | Senior product leader evaluating whether the PRD is a strong product document |
| `tech-plan-reviewer` | Document is a tech plan | Implementer who'll turn this plan into working code |

**Always-on (1):**

| Persona | Identity |
|---------|----------|
| `coherence-reviewer` | Editor reading for internal consistency — contradictions, terminology drift, structural issues |

**Conditional (3 — selected by orchestrator judgment):**

| Persona | Select when... |
|---------|---------------|
| `skeptic-reviewer` | Plan proposes abstractions, multi-layer architecture, or infrastructure ahead of need |
| `feasibility-reviewer` | Tech plan proposes architecture, external integrations, or performance constraints |
| `scope-guardian-reviewer` | PRD has priority conflicts, unclear boundaries, or goal-requirement misalignment |

### Selection Model

1. Determine document type → spawn matching doc-type reviewer
2. Always spawn coherence
3. Read the document → select applicable conditionals (agent judgment, not keyword matching)
4. Announce the team with one-line justification per conditional

A simple PRD gets 2 reviewers. A complex tech plan with architecture decisions gets up to 4.

### Structured JSON Output

Each reviewer returns JSON matching a plan-specific findings schema:

```json
{
  "reviewer": "prd-reviewer",
  "findings": [
    {
      "title": "Short issue title (10 words max)",
      "priority": "HIGH | MEDIUM | LOW",
      "section": "Requirements",
      "line": 42,
      "why_it_matters": "Impact — what goes wrong if not addressed",
      "suggestion": "Concrete rewording or structural fix",
      "confidence": 0.85,
      "evidence": ["Quoted text from the document"]
    }
  ],
  "residual_concerns": ["Concerns below confidence threshold"]
}
```

Key differences from code-review schema:
- `priority` (HIGH/MEDIUM/LOW) instead of `severity` (P0-P3)
- `section` instead of `file`
- `suggestion` instead of `suggested_fix`
- No `pre_existing` field (plans don't have diffs)
- `residual_concerns` instead of `residual_risks` + `testing_gaps`

### Merge Pipeline

1. **Validate** — check JSON structure, drop malformed findings
2. **Confidence gate** — suppress findings below 0.50
3. **Deduplicate** — fingerprint: `normalize(section) + line_bucket(line, ±5) + normalize(title)`. Keep highest priority, strongest evidence, note cross-reviewer agreement
4. **Sort** — priority (HIGH first) → confidence (descending) → document order

### Output Format

Findings grouped by priority (not by reviewer). Ends with synthesis (not verdict — plans don't have binary ready/not ready).

### Shared References

```
skills/plan-review/references/
  persona-catalog.md        # All 6 personas, selection criteria
  subagent-template.md      # Template for spawning reviewers
  findings-schema.json      # JSON schema for reviewer output
  review-output-template.md # Final output format
```

## Persona Design Principles

### Identity framing over checklists

Each persona uses a 4-section structure:
1. **Identity statement** — 2-sentence expert framing
2. **What you're hunting for** — 3-5 concrete failure modes
3. **Confidence calibration** — per-persona guidance
4. **What you don't flag** — front-loaded suppress conditions

### Document-type specificity

Instead of one "downstream reader" that adapts per doc type (and fails to calibrate), two explicit personas each do one job perfectly:
- PRD reviewer thinks as a senior product leader — never asks for implementation details
- Tech plan reviewer thinks as an implementer — never asks for product rationale

### Skepticism calibrated to maintenance cost

The skeptic reasons from "what does this cost the team over time?" not "do you really need this?" or "is it worth the effort to build?" Valid: "this abstraction has one consumer — is it earning its keep?" Invalid: "you probably won't need this yet, build it later."

## File Changes

| Action | File |
|--------|------|
| Create | `agents/prd-reviewer.md` |
| Create | `agents/tech-plan-reviewer.md` |
| Rewrite | `agents/coherence-reviewer.md` (was clarity-reviewer) |
| Create | `agents/skeptic-reviewer.md` |
| Create | `agents/feasibility-reviewer.md` |
| Create | `agents/scope-guardian-reviewer.md` |
| Delete | `agents/clarity-reviewer.md` |
| Delete | `agents/completeness-reviewer.md` |
| Delete | `agents/specificity-reviewer.md` |
| Delete | `agents/complexity-reviewer.md` |
| Create | `skills/plan-review/references/persona-catalog.md` |
| Create | `skills/plan-review/references/subagent-template.md` |
| Create | `skills/plan-review/references/findings-schema.json` |
| Create | `skills/plan-review/references/review-output-template.md` |
| Rewrite | `skills/plan-review/SKILL.md` |
| Rewrite | `docs/PLAN_REVIEW_STRATEGY.md` |
| Update | `README.md` |
