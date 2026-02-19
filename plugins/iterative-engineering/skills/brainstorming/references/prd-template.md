# PRD Template

Use this template when writing the PRD document. Scale to scope — include sections when their inclusion criteria apply, skip the rest. Requirements should always be included because they are referenced downstream by tech planning and code review.

## Document Structure

```markdown
# [Feature/Change] - PRD

**Date:** [date]
**Status:** Brainstorming
```

## Sections

### Goal (always include)

```markdown
## Goal
[What problem are we solving and for whom? 1-3 sentences.]
```

### Scope (always include)

Split into what's included and what's deliberately excluded.

```markdown
## Scope

### In Scope
[What v1 includes — specific deliverables.]

### Boundaries
Deliberate limits on what this work will NOT do. These aren't oversights — they're
active decisions that prevent scope creep and set expectations.

- [Boundary — what's excluded and why]
- [Boundary]
```

Boundaries are especially valuable when the feature could easily grow. If stakeholders or future sessions might reasonably ask "why didn't you also do X?" — that's a boundary worth documenting.

### Requirements (always include)

Group requirements by priority in a single table. Each requirement gets a number (R1, R2...) that persists for cross-referencing by tech planning and code review, even if the requirement changes priority.

```markdown
## Requirements

| ID | Priority | Requirement |
|----|----------|-------------|
| R1 | Core | [Requirement — specific and verifiable] |
| R2 | Must | [Requirement] |
| R3 | Must | [Requirement] |
| R4 | Nice | [Requirement] |
| R5 | Out | [Requirement — brief rationale for exclusion] |
```

**Priority definitions:**

| Priority | Meaning | Implementation impact |
|----------|---------|----------------------|
| **Core** | The whole point of this work | Must be satisfied by the chosen direction |
| **Must** | Required for v1 completeness | Tech plan must cover these |
| **Nice** | Valuable but not essential | Include if straightforward, defer if not |
| **Out** | Explicitly excluded | Do not implement — documented to prevent scope creep |

**Guidelines:**
- Core should be 1-2 requirements, rarely more. If everything is Core, nothing is.
- "Out" items document decisions, not oversights. Include brief rationale.
- Requirements state WHAT is needed, not HOW to satisfy it.
- Make requirements verifiable — "fast search" is vague, "search returns results in under 500ms" is verifiable.

### Chosen Direction (include when meaningful alternatives were considered)

```markdown
## Chosen Direction
[Which direction was picked and why. Can include high-level technical direction
(e.g., "real-time via WebSockets", "CLI-first with optional web dashboard").
Implementation specifics (libraries, schemas, endpoints) do not belong here.]
```

Skip if there was only one reasonable approach. Include when Phase 2 presented multiple directions and the choice has implications worth documenting.

### Alternatives Considered (include when documenting rejected directions prevents relitigating)

```markdown
## Alternatives Considered
- **[Direction B]** — [1 sentence description]. Rejected because [reason].
- **[Direction C]** — [1 sentence description]. Rejected because [reason].
```

Skip for small features. Include when the rejected alternatives were plausible enough that someone might suggest them later.

### Key Decisions (include when decisions were made that aren't obvious from requirements)

```markdown
## Key Decisions
- [Decision]: [Rationale]
- [Decision]: [Rationale]
```

### Open Questions (include when unresolved questions remain)

Tag each question with what it affects so downstream stages know which questions need resolving before they can proceed.

```markdown
## Open Questions
- **[Affects R3]** [Question about a specific requirement]
- **[Affects Scope]** [Question that could change what's in/out of scope]
- **[Affects Direction]** [Question that could change the chosen approach]
```

Questions tagged with specific requirements or scope signal that those areas aren't fully locked in. Tech planning should resolve technical questions during codebase exploration. Non-technical questions may be resolved through research (see `iterative:research`) or through design exploration (see `iterative:design-exploration`). Resolution method is determined when you go to resolve them, not when writing the PRD.

### Next Steps (always include)

```markdown
## Next Steps
→ [What happens next — typically "Create technical plan" or "Investigate open questions"]
```

## Section Inclusion Criteria

| Section | When to Include |
|---------|----------------|
| **Goal** | Always |
| **Scope** (In Scope + Boundaries) | Always |
| **Requirements** (single table with priority column) | Always |
| **Chosen Direction** | When meaningful alternatives were considered |
| **Alternatives Considered** | When documenting rejected directions prevents relitigating |
| **Key Decisions** | When decisions were made that aren't obvious from requirements |
| **Open Questions** | When unresolved questions remain after brainstorming |
| **Next Steps** | Always |

## PRD as Living Document

The PRD is the requirements source of truth throughout the workflow. It may be updated by:
- **Tech planning** — codebase exploration reveals new constraints, approach changes, or new requirements
- **Implementation** — reality diverges from assumptions, requirements need adjustment

When updated downstream, the change and rationale should be noted in the document (e.g., "R6 added during tech planning — codebase requires backward compatibility with v2 API"). This keeps the history visible and prevents confusion about when and why requirements changed.

## Quality Guidance

The PRD should give enough context for someone to create a detailed technical plan from it. The test: could an implementer with no prior context read this PRD and understand what needs to be built, what's excluded, and what decisions have been made?

**Belongs in the PRD:** High-level technical direction ("real-time via WebSockets", "CLI-first with optional web dashboard"), scope boundaries, requirement priorities, directional choices.

**Does NOT belong in the PRD:** Specific libraries, database schemas, API endpoints, implementation code — that's tech planning's domain.
