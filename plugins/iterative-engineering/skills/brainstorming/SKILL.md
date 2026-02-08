---
name: iterative:brainstorming
description: Explore ideas and approaches before building. This skill should be used when the user says "brainstorm", "brainstorming", "create a PRD", "write requirements", "define scenarios", "explore approaches", "think through options", or is starting a new feature with unclear direction.
---

# Brainstorming

Explore the problem space, scope the goal, and make directional choices through collaborative dialogue. Be a thinking partner — bring ideas, challenge assumptions, and help the user see options they haven't considered.

## When to Use

- Before implementing any new feature or significant change
- When requirements are unclear or multiple approaches exist
- When the user hasn't fully articulated what they want
- When exploring an entirely new project or app idea

Skip brainstorming when requirements are explicit, detailed, and the user knows exactly what they want.

## Key Principles

1. **Quick questions, then broad options** - Ask 2-3 questions to map the space, then present lightweight directions to steer deeper exploration
2. **One question at a time** - Never ask multiple questions in a single message
3. **Multiple choice preferred** - Easier to answer than open-ended when natural options exist
4. **Be a thinking partner** - Don't just extract requirements. Bring ideas, suggest alternatives, challenge assumptions, explore what-ifs
5. **Directional, not detailed** - High-level technical direction is welcome ("real-time vs polling", "build vs buy"). Implementation specifics are not ("use Socket.io with Redis", "add a notifications table with columns X, Y, Z")
6. **Scale to the scope** - An entire app idea needs deeper exploration than a small feature. Match the depth to what's being brainstormed
7. **YAGNI** - Resist complexity; choose the simplest approach that solves the stated problem

## Workflow

### Phase 0: Detect Resume / Assess Clarity

1. If user references an existing PRD or brainstorming topic: load the document (check both `docs/prd/` and `docs/brainstorms/` — treat PRDs and brainstorm documents synonymously), summarize current state, and let the user direct what happens next. Build on existing content, update in place.
2. If requirements are already explicit and detailed: use AskUserQuestion: A) Skip to `iterative:tech-planning` (recommended), B) Brainstorm anyway.
3. Otherwise: proceed to Phase 1.

### Phase 1: Map the Space (2-3 questions)

1. Explore the codebase lightly for relevant context.
2. Ask the 2-3 BEST questions to understand the problem space (use AskUserQuestion, one at a time). Pick questions that will most differentiate possible approaches.
3. Don't try to cover everything — just enough to propose broad directions.
4. Move to Phase 2 after 2-3 questions (do not extend).

### Phase 2: Broad Directions (steering, not detailed)

1. Present 2-3 high-level directions (1-2 sentences each). Keep them lightweight — these are steering choices, not final approaches.
2. Include a brief trade-off for each (not full pros/cons yet). Lead with a recommendation.
3. Use AskUserQuestion to let user pick a direction. This narrows the search space for deeper exploration.

### Phase 3: Deep Exploration (Q&A within chosen direction)

1. Ask targeted questions within the chosen direction.
2. Bring ideas — don't just ask, suggest and react.
3. Explore: goals, scope, user experience, feasibility, constraints.
4. Challenge assumptions ("Do you actually need X, or would Y work?"). Research prior art and alternatives when useful.
5. Validate assumptions explicitly ("I'm assuming X. Is that correct?"). Identify risks and open questions to carry forward.
6. Continue until the approach is well-scoped.

### Phase 4: Document Findings

1. Write PRD (format below).
2. Scale the document to the scope.
3. Save to `docs/prd/YYYY-MM-DD-<topic>-prd.md` (ensure directory exists).

### Phase 5: Review and Handoff

1. Use AskUserQuestion: A) Plan-review (recommended), B) Continue to `iterative:tech-planning`, C) I'll take it from here (exit).
2. If review: invoke `plan-review` skill. Plan-review returns findings — brainstorming owns the fix loop.
3. Fix issues identified by plan-review.
4. Use AskUserQuestion: A) Another round of plan-review (recommended if significant changes), B) Continue to `iterative:tech-planning`, C) I'll take it from here (exit).
5. Repeat steps 2-4 if user chooses another round.
6. If user chooses tech-planning: invoke `iterative:tech-planning` skill.

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
| Goals | What does success look like? What's the happy path? |
| Scope | What's in v1 vs later? What's explicitly out of scope? |
| User experience | Who uses this? What's the workflow? What do they see? |
| Feasibility | Is this technically viable? Build vs buy? Any hard constraints? |
| Prior art | How do others solve this? What can we learn from? |
| Constraints | Timeline? Must integrate with existing things? |
| Risks | What could go wrong? What's the riskiest assumption? |

**Be a thinking partner, not just an interviewer:**
- Suggest alternatives: "Have you considered X instead?"
- Challenge assumptions: "Do you actually need real-time, or would near-real-time work?"
- Explore what-ifs: "What if we started with just Y and added Z later?"

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

## PRD Format (Phase 4)

Scale the document to the scope. A small feature might only need Goal, Scope, Requirements, and Key Decisions. An app idea might need all sections. Use the sections that are relevant — skip the rest. Requirements should always be included (even if brief) because they are referenced downstream by tech planning and code review.

```markdown
# [Feature/Change] - PRD

**Date:** [date]
**Status:** Brainstorming

## Goal
[What problem are we solving and for whom?]

## Scope
[What's in v1. What's explicitly out of scope or deferred.]

## Requirements
[Verifiable criteria that the implementation must satisfy. These are referenced downstream by tech planning (to design the solution) and code review (to validate correctness). Number them for cross-referencing.]

1. [Requirement — specific and verifiable, not vague]
2. [Requirement]
3. [Requirement]

## Chosen Direction
[Which direction we picked and why — can include high-level technical direction]

## Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Open Questions
- [Question 1]
- [Question 2]

## Next Steps
→ Create technical plan
```

The PRD should give enough context for someone to create a detailed technical plan from it. High-level technical direction (e.g., "real-time via WebSockets", "CLI-first with optional web dashboard") belongs here. Implementation specifics (e.g., specific libraries, database schema, API endpoints) do not.

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Exhaustive Q&A before presenting any options | Ask 2-3 questions, then present broad directions to steer |
| Detailed approach comparison too early | Phase 2 directions are lightweight; detail comes in Phase 3 |
| Asking multiple questions at once | One question per message |
| Just extracting requirements passively | Be a thinking partner — bring ideas, challenge assumptions |
| Going too deep into implementation specifics | High-level direction is fine; specific libraries, schema, and code design are not |
| Proposing overly complex solutions | Start simple, add complexity only if needed |
| Making assumptions without validating | State assumptions explicitly and confirm |
| Same depth for every PRD | Scale to scope — brief for small features, thorough for app ideas |

## Transition Points

**Always use AskUserQuestion for transition points** — never just print options as text.

After PRD is created, and after each review round, use AskUserQuestion with options:
- Plan-review: 4 agents analyze for issues and improve (recommended on first pass)
- Continue to `iterative:tech-planning` skill
- I'll take it from here (exit)

**Never skip this step.** Do not proceed to tech-planning or announce "the PRD is ready" without presenting these options first.
