---
name: iterative:tech-planning
description: This skill should be used when the user says "create a plan", "tech planning", "write a tech plan", or has requirements ready to formalize into an implementation plan.
---

# Create Technical Plan

Turn a PRD or set of requirements into a structured, executable implementation plan. Write as if the implementer has zero context for the codebase — document the decisions, the reasoning, and enough detail that they can start working without asking clarifying questions.

The plan captures WHAT to build and WHERE. The implementer writes the actual code.

## When to Use

- After `iterative:brainstorming` skill is complete
- When clear requirements exist and need an implementation plan
- Can be invoked standalone with existing requirements

If requirements are vague and no PRD exists, offer to start with `iterative:brainstorming` skill first.

## Key Principles

1. **Understand before structuring** — Explore the codebase and ask questions before writing the plan
2. **Decisions, not code** — Capture architecture choices, query strategies, component boundaries, trade-offs. Leave method names, signatures, and implementation code to the implementer
3. **Concrete test scenarios** — Specific inputs, expected outputs, edge cases to cover. Not full test code, not "test that it works"
4. **Right-sized subtasks** — Scoped to a single atomic commit, typically touching 2-3 files. Not too big (5+ files, multiple unrelated changes), not too small (single line, no meaningful test)
5. **Dependencies clear** — Explicit ordering of what depends on what
6. **Verification built-in** — Each subtask has a way to confirm it works

## Plan Quality Bar

Every plan must contain:

- **File paths** — Which files to create or modify
- **Decisions with rationale** — Architecture choices, query strategies, data flow, what was considered and rejected
- **Test scenarios** — Specific inputs, expected outputs, edge cases — not "verify it works"
- **Existing patterns to follow** — Reference actual code in the codebase that the implementer should use as a model
- **What and why, not how** — Describe what each subtask accomplishes and the key decisions driving it. Don't pre-write the implementation

A plan is ready when an implementer can start working without asking clarifying questions. They know what to build, where to build it, what decisions have been made, and what edge cases to handle. They write the code.

## Workflow

### Phase 0: Detect Resume / Assess Input

1. If user references an existing plan document or topic: load the document, summarize current state, and let the user direct what happens next. Build on existing content, update in place.
2. If no PRD AND requirements are vague: use AskUserQuestion: A) Start with brainstorming first (recommended), B) Proceed with what we have. If brainstorming: invoke `iterative:brainstorming` skill.
3. Otherwise: proceed to Phase 1.

### Phase 1: Gather Context (Q&A + Codebase Exploration)

1. Read PRD (if exists). Check both `docs/prd/` and `docs/brainstorms/` for existing documents.
2. Explore the codebase for: existing patterns and conventions to follow, files and modules that will be affected, test patterns and frameworks in use, related code that informs the design.
3. Ask implementation-focused questions ONE AT A TIME: architecture preferences, highest risk areas, testing approach, constraints not in the PRD, existing code patterns to follow or avoid.
4. Gate: continue until approach is clear OR user says "proceed."
5. Do NOT start writing the plan until this phase is complete.

### Phase 2: Structure the Plan

1. Identify major components (become parent tasks, typically 2-5).
2. Break each into subtasks (2-5 per parent, one commit each).
3. Use the standardized subtask format (see template) — every subtask has the same fields so it can be directly converted into tasks.
4. For each subtask, define: dependencies on other subtasks (always present, even if "none"), files to create or modify, what the subtask accomplishes and key decisions, test scenarios with specific inputs and expected outputs, how to verify it works.
5. Number subtasks as Parent.Subtask (1.1, 1.2, 2.1) for cross-referencing.

### Phase 3: Write Technical Plan

1. Create plan document using template in `references/tech-plan-template.md`.
2. Every subtask must meet the Plan Quality Bar above.
3. Reference actual file paths, existing patterns, and conventions from Phase 1.
4. Save to `docs/plans/YYYY-MM-DD-<topic>-tech-plan.md` (ensure directory exists).

### Phase 4: Review and Handoff

1. Use AskUserQuestion: A) Plan-review (recommended), B) Start implementing, C) I'll take it from here (exit).
2. If review: invoke `plan-review` skill. Plan-review returns findings — tech-planning owns the fix loop.
3. Fix issues identified by plan-review.
4. Use AskUserQuestion: A) Another round of plan-review (recommended if significant changes), B) Start implementing, C) I'll take it from here (exit).
5. Repeat steps 2-4 if user chooses another round.
6. If user chooses implementing: invoke `iterative:implementing` skill (implementing handles task creation internally after reading the plan).

## PRD Alignment

Codebase exploration during Phase 1 may reveal that the PRD's chosen direction, scope, or requirements need to change. Keep the PRD in sync — it's the source of truth for requirements that downstream code review validates against.

- **Minor adjustments** (slightly different scope boundary, refined requirement wording): update the PRD in place and note the change when presenting the plan.
- **Significant divergence** (different approach than chosen direction, requirement added/removed, scope change): stop and discuss with the user before proceeding. Update the PRD's Chosen Direction, Requirements, and/or Scope sections to reflect the new reality. The tech plan should never contradict the PRD.
- **New requirements discovered** (codebase reveals constraints not in PRD): add them to the PRD's Requirements section with a note that they were discovered during tech planning.

The tech plan's `**PRD:**` header links to the PRD document. If the PRD is updated during tech planning, this link ensures reviewers can find the authoritative requirements.

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Writing the plan before exploring the codebase | Explore existing code and patterns first |
| Skipping Q&A when PRD exists | Still ask implementation-focused questions |
| Subtasks that are too large (touch 5+ files) | Break into smaller, atomic units |
| Vague descriptions ("implement the feature") | Specific: what to build, which files, what decisions, what edge cases |
| Pre-writing implementation code in the plan | Describe what to build and the decisions; the implementer writes the code |
| Test descriptions without specifics ("test that it works") | Concrete scenarios: specific inputs, expected outputs, edge cases |
| Planning without referencing existing code patterns | Ground every subtask in actual file paths and existing conventions |
| Over-planning hypothetical scenarios | Plan only what's needed; defer decisions that can wait |
| Diverging from the PRD without updating it | Update the PRD when approach changes — it's the requirements source of truth |

## Transition Points

**Always use AskUserQuestion for transition points** — never just print options as text.

After technical plan is written, and after each review round, use AskUserQuestion with options:
- Plan-review: 4 agents analyze for issues and improve (recommended on first pass)
- Start implementing
- I'll take it from here (exit)

## Additional Resources

### Reference Files

For detailed templates and guidelines, consult:
- **`references/tech-plan-template.md`** — Full plan document template with examples, subtask granularity guidelines, and quality checklist
