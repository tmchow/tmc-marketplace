---
name: iterative:brainstorm
description: Explore ideas and approaches before building. This skill should be used when the user says "brainstorm", "explore approaches", "think through options", or is starting a new feature with unclear direction.
allowed-tools: Glob, Grep, Read, WebSearch, WebFetch, Task
---

# Brainstorming

Clarify **WHAT** to build before diving into **HOW**. Use collaborative dialogue to understand user intent, then explore approaches.

## When to Use

- Before implementing any new feature or significant change
- When requirements are unclear or multiple approaches exist
- When the user hasn't fully articulated what they want

Skip brainstorming when requirements are explicit, detailed, and the user knows exactly what they want.

## Key Principles

1. **Quick questions, then broad options** - Ask 2-3 questions to map the space, then present lightweight directions to steer deeper exploration
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

Phase 1: Map the Space (2-3 questions)
├── Explore the codebase lightly for relevant context
├── Ask the 2-3 BEST questions to understand the problem space
│   (use AskUserQuestion, one at a time)
├── Pick questions that will most differentiate possible approaches
├── Don't try to cover everything — just enough to propose broad directions
└── Move to Phase 2 after 2-3 questions (do not extend)

Phase 2: Broad Directions (steering, not detailed)
├── Present 2-3 high-level directions (1-2 sentences each)
├── Keep them lightweight — these are steering choices, not final approaches
├── Include a brief trade-off for each (not full pros/cons yet)
├── Lead with a recommendation
├── Use AskUserQuestion to let user pick a direction
└── This narrows the search space for deeper exploration

Phase 3: Deep Exploration (Q&A within chosen direction)
├── Now ask targeted questions within the chosen direction
├── Cover: constraints, edge cases, success criteria, existing patterns
├── Research libraries, patterns, prior art as relevant
├── Validate assumptions explicitly ("I'm assuming X. Is that correct?")
├── Identify risks and dependencies
└── Continue until the approach is well-understood

Phase 4: Document Findings
├── Write brainstorm document (format below)
├── Include: context, chosen approach, design decisions, open questions
└── Save to docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md (ensure directory exists)

Phase 5: Review Cycle
├── Use AskUserQuestion to offer plan-review (recommended) or skip
├── If review: invoke `plan-review` skill
├── Fix issues identified
└── Use AskUserQuestion to offer another round or continue

Phase 6: Handoff
└── Continue to `iterative:tech-design` skill when ready
```

## Question Techniques

**Phase 1 questions (2-3 max) — pick the ones that differentiate approaches:**
- What's the core problem? (purpose)
- Who's the primary user/audience? (scope)
- Are there hard constraints? (boundaries)

**Prefer multiple choice when natural options exist:**
- Good: "Should the notification be: (a) email only, (b) in-app only, or (c) both?"
- Avoid: "How should users be notified?"

**Phase 3 questions — go deeper within the chosen direction:**

| Topic | Example Questions |
|-------|-------------------|
| Constraints | Technical limitations? Timeline? Dependencies? |
| Success | How will you measure success? What's the happy path? |
| Edge Cases | What shouldn't happen? Any error states? |
| Existing Patterns | Similar features in the codebase to follow? |

**Validate assumptions explicitly:**
- "I'm assuming users will be logged in. Is that correct?"
- "It sounds like you want X. Did I understand that right?"

## Broad Directions Format (Phase 2)

Keep these lightweight — 1-2 sentences each with a brief trade-off. These steer the conversation, not finalize the approach.

```markdown
Here are 2-3 broad directions:

**A) [Name]** — [1-2 sentence description]. Trade-off: [brief].
**B) [Name]** — [1-2 sentence description]. Trade-off: [brief].
**C) [Name]** — [1-2 sentence description]. Trade-off: [brief].

I'd lean toward **A** because [one sentence]. Which direction feels right?
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
| Exhaustive Q&A before presenting any options | Ask 2-3 questions, then present broad directions to steer |
| Detailed approach comparison too early | Phase 2 directions are lightweight; detail comes in Phase 3 |
| Asking multiple questions at once | One question per message |
| Jumping to implementation details | Focus on WHAT, not HOW |
| Proposing overly complex solutions | Start simple, add complexity only if needed |
| Making assumptions without validating | State assumptions explicitly and confirm |
| Creating lengthy design documents | Keep concise — details go in the technical plan |

## Transition Points

**Always use AskUserQuestion for transition points** — never just print options as text.

After brainstorm document is created, use AskUserQuestion with options:
- Plan-review: 4 agents analyze for issues and improve (recommended)
- Continue to `iterative:tech-design` skill
- I'll take it from here (exit)

After review + fixes, use AskUserQuestion with options:
- Another round of `plan-review` skill (recommended if significant changes)
- Continue to `iterative:tech-design` skill
- I'll take it from here (exit)
