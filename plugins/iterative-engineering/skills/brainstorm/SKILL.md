---
name: iterative:brainstorm
description: Explore ideas and approaches before building. This skill should be used when the user says "brainstorm", "explore approaches", "think through options", or is starting a new feature with unclear direction.
allowed-tools: Glob, Grep, Read, WebSearch, WebFetch, AskUserQuestion, Task
---

# Brainstorming

Clarify **WHAT** to build before diving into **HOW**. Use collaborative dialogue to understand user intent, then explore approaches.

## When to Use

- Before implementing any new feature or significant change
- When requirements are unclear or multiple approaches exist
- When the user hasn't fully articulated what they want

Skip brainstorming when requirements are explicit, detailed, and the user knows exactly what they want.

## Key Principles

1. **Questions before options** - Understand the idea through dialogue BEFORE presenting approaches
2. **One question at a time** - Never ask multiple questions in a single message
3. **Multiple choice preferred** - Easier to answer than open-ended when natural options exist
4. **Incremental validation** - Present ideas in small sections (200-300 words), confirm before continuing
5. **YAGNI** - Resist complexity; choose the simplest approach that solves the stated problem
6. **WHAT not HOW** - Stay focused on requirements and design, not implementation details

## Workflow

```
Phase 0: Detect Resume / Assess Clarity
├── If user references an existing brainstorm document or topic:
│   ├── Load the document, summarize current state
│   └── Offer: user directs what to change, or agent identifies gaps
│   └── Resume note: build on existing content, update in place
├── If requirements are already explicit and detailed:
│   └── Suggest skipping to `iterative:tech-design` skill
└── Otherwise: proceed to Phase 1

Phase 1: Understand the Idea (iterative Q&A)
├── Explore the codebase lightly for relevant context
├── Ask questions ONE AT A TIME using AskUserQuestion
├── Start broad (purpose, users), then narrow (constraints, edge cases)
├── Validate assumptions explicitly ("I'm assuming X. Is that correct?")
├── Topics to cover: Purpose, Users, Constraints, Success Criteria,
│   Edge Cases, Existing Patterns
├── Gate: Continue until the idea is clear OR user says "proceed"
└── Do NOT present approaches until this phase is complete

Phase 2: Explore Approaches
├── Propose 2-3 concrete approaches with pros/cons
├── Lead with a recommendation and explain why
├── Apply YAGNI — prefer simpler approaches
├── Ask user to pick a direction or give feedback
└── Refine through further Q&A if needed

Phase 3: Deep Research (on chosen approach)
├── Explore implementation details for the chosen direction
├── Research libraries, patterns, prior art
├── Identify risks and dependencies
└── Draft detailed design

Phase 4: Document Findings
├── Write brainstorm document (format below)
├── Include: context, chosen approach, design decisions, open questions
└── Save to docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md (ensure directory exists)

Phase 5: Review Cycle
├── Offer: "Plan-review: 4 agents analyze for issues and improve (recommended)"
├── If review: invoke `plan-review` skill
├── Fix issues identified
└── Offer another round or continue

Phase 6: Handoff
└── Continue to `iterative:tech-design` skill when ready
```

## Question Techniques (Phase 1)

**Prefer multiple choice when natural options exist:**
- Good: "Should the notification be: (a) email only, (b) in-app only, or (c) both?"
- Avoid: "How should users be notified?"

**Key topics to explore:**

| Topic | Example Questions |
|-------|-------------------|
| Purpose | What problem does this solve? What's the motivation? |
| Users | Who uses this? What's their context? |
| Constraints | Technical limitations? Timeline? Dependencies? |
| Success | How will you measure success? What's the happy path? |
| Edge Cases | What shouldn't happen? Any error states? |
| Existing Patterns | Similar features in the codebase to follow? |

**Validate assumptions explicitly:**
- "I'm assuming users will be logged in. Is that correct?"
- "It sounds like you want X. Did I understand that right?"

## Approach Comparison Format (Phase 2)

```markdown
### Approach A: [Name]
[2-3 sentence description]

**Pros:** [bullets]
**Cons:** [bullets]
**Best when:** [circumstances]

### Approach B: [Name]
...

**Recommendation:** [Approach X] because [brief rationale].
```

## Brainstorm Document Format (Phase 4)

```markdown
# [Feature/Change] - Brainstorm

**Date:** [date]
**Status:** Brainstorming

## What We're Building
[Concise description — 1-2 paragraphs max]

## Why This Approach
[Approaches considered and why this one was chosen]

## Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Open Questions
- [Question 1]
- [Question 2]

## Next Steps
→ Create technical plan via `iterative:tech-design` skill
```

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Presenting options before understanding the idea | Ask questions first, options come after Phase 1 |
| Asking multiple questions at once | One question per message |
| Jumping to implementation details | Focus on WHAT, not HOW |
| Proposing overly complex solutions | Start simple, add complexity only if needed |
| Making assumptions without validating | State assumptions explicitly and confirm |
| Creating lengthy design documents | Keep concise — details go in the technical plan |

## Transition Points

After brainstorm document is created:
```
Brainstorm document created. What next?
├── A) Plan-review: 4 agents analyze for issues and improve (recommended)
├── B) Continue to `iterative:tech-design` skill
├── C) I'll take it from here (exit)
```

After review + fixes:
```
Review issues addressed. What next?
├── A) Another round of `plan-review` skill (recommended if significant changes)
├── B) Continue to `iterative:tech-design` skill
├── C) I'll take it from here (exit)
```
