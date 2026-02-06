---
name: brainstorming
description: Use before implementing features or making changes. Explores user intent, presents 2-3 approaches with pros/cons BEFORE deep research, iterates with plan-review. Produces brainstorm document for handoff to create-technical-plan.
allowed-tools: Glob, Grep, Read, WebSearch, WebFetch, AskUserQuestion, Task
model: opus
---

# Brainstorming

Explores intent and approaches before planning implementation.

## When to Use

- Before implementing any new feature
- Before making significant changes
- When requirements are unclear
- When multiple approaches are possible

## Key Pattern: Early Options

**Present 2-3 approaches with pros/cons BEFORE deep research.**

This prevents:
- Over-researching the wrong direction
- Wasted effort on approaches user won't accept
- Analysis paralysis

```
1. Understand request
2. Quickly identify 2-3 possible approaches
3. Present approaches with brief pros/cons
4. User picks direction
5. THEN do deep research on chosen approach
```

## Workflow

```
Phase 0: Detect Resume Intent
├── Check if user indicates continuation:
│   ├── References a file path or document
│   ├── Mentions "continue", "resume", "pick up"
│   └── References a topic matching prior brainstorm in session
├── If resuming:
│   ├── Load the referenced document
│   ├── Summarize current state briefly
│   └── Offer options:
│       ├── "What would you like to explore or change?" (user directs)
│       └── "Want me to identify gaps and suggest next steps?" (Claude proposes)
├── If Claude proposes:
│   ├── Review document for incomplete sections, open questions, weak areas
│   ├── Suggest 2-3 areas to develop further
│   └── User picks direction, then continue from appropriate phase
└── If starting fresh: proceed to Phase 1

Phase 1: Understand Intent
├── Clarify what user wants to achieve (not just what they asked for)
├── Identify constraints, requirements, context
└── Ask clarifying questions if needed

Phase 2: Quick Approach Survey
├── Identify 2-3 viable approaches (don't over-research yet)
├── For each approach:
│   ├── Brief description (1-2 sentences)
│   ├── Key pros (2-3 bullets)
│   └── Key cons (2-3 bullets)
└── Present as comparison table

Phase 3: User Selects Direction
└── User picks approach or provides feedback

Phase 4: Deep Research (on chosen approach)
├── Explore implementation details
├── Research libraries, patterns, prior art
├── Identify risks and dependencies
└── Draft detailed design

Phase 5: Document Findings
├── Write brainstorm document
├── Include: context, approach, design decisions, open questions
└── Save to docs/brainstorms/ or appropriate location

Phase 6: Review Cycle
├── Offer: "Plan-review: 4 agents analyze for issues and improve (recommended)"
├── If review: invoke plan-review skill
├── Fix issues identified
└── Offer another round or continue

Phase 7: Handoff
└── Continue to create-technical-plan when ready
```

## Output Format

### Approach Comparison (Phase 2)

```markdown
## Approaches

| Approach | Description | Pros | Cons |
|----------|-------------|------|------|
| A: [Name] | [Brief description] | + [Pro 1]<br>+ [Pro 2] | - [Con 1]<br>- [Con 2] |
| B: [Name] | [Brief description] | + [Pro 1]<br>+ [Pro 2] | - [Con 1]<br>- [Con 2] |
| C: [Name] | [Brief description] | + [Pro 1]<br>+ [Pro 2] | - [Con 1]<br>- [Con 2] |

**Recommendation:** [Approach X] because [brief rationale].

Which approach would you like to explore?
```

### Brainstorm Document (Phase 5)

```markdown
# [Feature/Change] - Brainstorm

**Date:** [date]
**Status:** Brainstorming

## Context
[What problem are we solving? Why now?]

## Chosen Approach
[Description of selected approach]

## Design Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Open Questions
- [Question 1]
- [Question 2]

## Next Steps
→ Create technical plan
```

## Transition Points

After brainstorm document is created:
```
Brainstorm document created. What next?
├── A) Plan-review: 4 agents analyze for issues and improve (recommended)
├── B) Continue to technical plan
├── C) I'll take it from here (exit)
```

After review + fixes:
```
Review issues addressed. What next?
├── A) Another round of plan-review (recommended if significant changes)
├── B) Continue to technical plan
├── C) I'll take it from here (exit)
```
