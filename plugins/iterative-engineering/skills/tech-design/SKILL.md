---
name: iterative:tech-design
description: Turn requirements into a structured implementation plan. This skill should be used when the user says "create a plan", "design the implementation", or has a brainstorm document ready to formalize.
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, Task
---

# Create Technical Plan

Turn a brainstorm or set of requirements into a structured, executable implementation plan with TDD emphasis.

## When to Use

- After `iterative:brainstorm` skill is complete
- When clear requirements exist and need an implementation plan
- Can be invoked standalone with existing requirements

If requirements are vague and no brainstorm document exists, redirect to `iterative:brainstorm` skill first.

## Key Principles

1. **Understand before structuring** - Explore the codebase and ask questions before writing the plan
2. **TDD First** - Plan tests before implementation for every subtask
3. **Small steps** - Break into subtasks completable in one session (~30-60 min)
4. **Dependencies clear** - Explicit ordering of what depends on what
5. **Verification built-in** - Each step has clear success criteria

## Workflow

```
Phase 0: Detect Resume / Assess Input
├── If user references an existing plan document or topic:
│   ├── Load the document, summarize current state
│   └── Offer: user directs what to change, or agent identifies gaps
│   └── Resume note: build on existing content, update in place
├── If no brainstorm AND requirements are vague:
│   └── Redirect to `iterative:brainstorm` skill
└── Otherwise: proceed to Phase 1

Phase 1: Gather Context (Q&A + Codebase Exploration)
├── Read brainstorm document (if exists)
├── Explore the codebase for:
│   ├── Existing patterns and conventions to follow
│   ├── Files and modules that will be affected
│   ├── Test patterns and frameworks in use
│   └── Related code that informs the design
├── Ask implementation-focused questions ONE AT A TIME:
│   ├── Architecture preferences (e.g., new module vs extend existing?)
│   ├── Which parts are highest risk or uncertainty?
│   ├── Testing approach preferences
│   ├── Any constraints not in the brainstorm?
│   └── Existing code patterns to follow or avoid?
├── Gate: Continue until approach is clear OR user says "proceed"
└── Do NOT start writing the plan until this phase is complete

Phase 2: Structure the Plan
├── Identify major components (become parent tasks, typically 2-5)
├── Break each into subtasks (2-5 per parent, implementable units)
├── For each subtask, define:
│   ├── What test to write first (RED)
│   ├── What implementation makes it pass (GREEN)
│   └── What cleanup/refactoring needed (REFACTOR)
└── Identify dependencies between tasks

Phase 3: Write Technical Plan
├── Create plan document using template in references/tech-plan-template.md
├── Include enough detail for another agent to execute each subtask
├── Reference relevant files, patterns, and conventions
└── Save to docs/plans/YYYY-MM-DD-<topic>-plan.md (ensure directory exists)

Phase 4: Review Cycle
├── Use AskUserQuestion to offer plan-review (recommended) or skip
├── If review: invoke `plan-review` skill
├── Fix issues identified
└── Use AskUserQuestion to offer another round or continue

Phase 5: Convert to Tasks
├── Use AskUserQuestion to offer: convert to tasks, or exit
├── If convert: invoke `plan-to-tasks` skill
└── Handoff to `iterative:implement` skill
```

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Writing the plan before exploring the codebase | Explore existing code and patterns first |
| Skipping Q&A when brainstorm exists | Still ask implementation-focused questions |
| Subtasks that are too large (touch 5+ files) | Break into smaller, atomic units |
| Vague subtask descriptions ("implement the feature") | Specify exact test and implementation steps |
| Planning without referencing existing code patterns | Ground every subtask in actual file paths and conventions |
| Over-planning hypothetical scenarios | Plan only what's needed; defer decisions that can wait |

## Transition Points

**Always use AskUserQuestion for transition points** — never just print options as text.

After technical plan is written, use AskUserQuestion with options:
- Plan-review: 4 agents analyze for issues and improve (recommended)
- Convert to HZL/TodoWrite tasks
- I'll take it from here (exit)

After review + fixes, use AskUserQuestion with options:
- Another round of `plan-review` skill (recommended if significant changes)
- Convert to tasks
- I'll take it from here (exit)

## Additional Resources

### Reference Files

For detailed templates and guidelines, consult:
- **`references/tech-plan-template.md`** - Full plan document template, subtask granularity guidelines, and TDD structure per subtask
