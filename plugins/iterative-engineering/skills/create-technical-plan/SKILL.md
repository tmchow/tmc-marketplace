---
name: create-technical-plan
description: Use when turning a brainstorm or requirements into an implementation plan. Emphasizes TDD approach, creates structured plan with tasks and subtasks, iterates with plan-review, hands off to plan-to-tasks then executing-work.
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, Task
model: opus
---

# Create Technical Plan

Turns design into a structured implementation plan with TDD emphasis.

## When to Use

- After brainstorming is complete
- When you have clear requirements to implement
- When you need a structured implementation approach
- Can be invoked standalone with existing requirements

## Key Principles

1. **TDD First** - Plan tests before implementation
2. **Small Steps** - Break into subtasks that can be completed in one session
3. **Dependencies Clear** - Explicit ordering of what depends on what
4. **Verification Built-in** - Each step has clear success criteria

## Workflow

```
Phase 0: Detect Resume Intent
├── Check if user indicates continuation:
│   ├── References an existing plan document
│   ├── Mentions "continue", "resume", "pick up"
│   └── References a topic matching prior plan in session
├── If resuming:
│   ├── Load the referenced document
│   ├── Summarize current state briefly
│   └── Offer options:
│       ├── "What would you like to change or add?" (user directs)
│       └── "Want me to identify gaps and suggest improvements?" (Claude proposes)
├── If Claude proposes:
│   ├── Review plan for incomplete sections, missing tests, unclear dependencies
│   ├── Suggest 2-3 areas to develop further
│   └── User picks direction, then continue from appropriate phase
└── If starting fresh: proceed to Phase 1

Phase 1: Gather Context
├── Read brainstorm document (if exists)
├── Understand requirements and constraints
├── Identify existing code to integrate with
└── Ask clarifying questions if needed

Phase 2: Structure the Plan
├── Identify major components (become parent tasks)
├── Break each into subtasks (implementable units)
├── For each subtask, define:
│   ├── What test to write first (RED)
│   ├── What implementation makes it pass (GREEN)
│   └── What cleanup/refactoring needed (REFACTOR)
└── Identify dependencies between tasks

Phase 3: Write Technical Plan
├── Create plan document with structure below
├── Include enough detail for another agent to execute
├── Reference relevant files and patterns
└── Save to docs/plans/ or appropriate location

Phase 4: Review Cycle
├── Offer: "Plan-review: 4 agents analyze for issues and improve (recommended)"
├── If review: invoke plan-review skill
├── Fix issues identified
└── Offer another round or continue

Phase 5: Convert to Tasks
├── Offer: "Convert to HZL/TodoWrite tasks" or "Start execution"
├── If convert: invoke plan-to-tasks skill
└── Handoff to executing-work
```

## Plan Document Format

```markdown
# [Feature] - Technical Plan

**Date:** [date]
**Status:** Planning
**Brainstorm:** [link to brainstorm if exists]

## Overview
[Brief description of what we're building]

## Architecture
[High-level design, key components, data flow]

## Implementation Plan

### Parent 1: [Component/Feature Name]

#### 1.1 [Subtask Name]
**Test First:**
- [ ] [Test description - what behavior to verify]

**Implementation:**
- [ ] [Implementation step]
- [ ] [Implementation step]

**Files:** `src/path/to/file.ts`

#### 1.2 [Subtask Name]
**Depends on:** 1.1

**Test First:**
- [ ] [Test description]

**Implementation:**
- [ ] [Implementation step]

### Parent 2: [Component/Feature Name]
...

## Testing Strategy
- Unit tests: [approach]
- Integration tests: [approach]
- Manual verification: [steps]

## Risks and Mitigations
| Risk | Mitigation |
|------|------------|
| [Risk 1] | [How to address] |

## Open Questions
- [Any remaining unknowns]
```

## Transition Points

After technical plan is written:

*If project uses HZL for task tracking:*
```
Technical plan created. What next?
├── A) Plan-review: 4 agents analyze for issues and improve (recommended)
├── B) Convert to HZL tasks
├── C) I'll take it from here (exit)
```

*If project does not use HZL:*
```
Technical plan created. What next?
├── A) Plan-review: 4 agents analyze for issues and improve (recommended)
├── B) Convert to TodoWrite tasks
├── C) I'll take it from here (exit)
```

After review + fixes:
Same options as above, with "Another round of plan-review" as option A.

## TDD Emphasis

Every subtask should have a clear TDD structure:
1. **RED** - Write a failing test that defines the behavior
2. **GREEN** - Write minimal code to make the test pass
3. **REFACTOR** - Clean up while keeping tests green
4. **COMMIT** - One commit per completed subtask

This ensures:
- Requirements are captured as tests
- Implementation is focused and minimal
- Code is clean and well-tested
- Progress is trackable via commits
