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
8. **PRD is a living document** - The PRD is the requirements source of truth throughout the workflow. Tech planning and implementation may update it as reality reveals new constraints

## Workflow

### Phase 0: Detect Resume / Assess Clarity

1. If user references an existing PRD or brainstorming topic: load the document (check both `docs/prd/` and `docs/brainstorms/` — treat PRDs and brainstorm documents synonymously), summarize current state, and let the user direct what happens next. Build on existing content, update in place.
2. If requirements are already explicit and detailed: ask the user: A) Skip to creating a technical plan (recommended), B) Brainstorm anyway. If skipping: invoke `iterative:tech-planning` skill.
3. Otherwise: proceed to Phase 1.

### Phase 1: Map the Space (2-3 questions)

1. Explore the codebase lightly for relevant context.
2. Ask the 2-3 BEST questions to understand the problem space (one at a time). Pick questions that will most differentiate possible approaches.
3. Don't try to cover everything — just enough to propose broad directions.
4. Move to Phase 2 after 2-3 questions (do not extend).

### Phase 2: Broad Directions (steering, not detailed)

1. Present 2-3 high-level directions (1-2 sentences each). Keep them lightweight — these are steering choices, not final approaches.
2. Include a brief trade-off for each (not full pros/cons yet). Lead with a recommendation.
3. Ask the user to pick a direction. This narrows the search space for deeper exploration.
4. **Validate the direction.** After the user picks, briefly check: does this direction satisfy the core requirements identified so far? If any requirement looks at risk, flag it before going deeper. This is a quick sanity check, not a formal review — a sentence or two is sufficient.

### Phase 3: Deep Exploration (Q&A within chosen direction)

1. Ask targeted questions within the chosen direction.
2. Bring ideas — don't just ask, suggest and react.
3. Explore: goals, scope, user experience, feasibility, constraints.
4. Challenge assumptions ("Do you actually need X, or would Y work?"). Research prior art and alternatives when useful.
5. Validate assumptions explicitly ("I'm assuming X. Is that correct?"). Identify risks and open questions to carry forward.
6. Continue until the approach is well-scoped.

### Phase 4: Document Findings

1. Write PRD using the template in `references/prd-template.md`. Include sections when their inclusion criteria apply — skip the rest.
2. Group requirements by priority (Core, Must-Have, Nice-to-Have, Out). Be deliberate about priority — if everything is Must-Have, nothing is.
3. Save to `docs/prd/YYYY-MM-DD-<topic>-prd.md` (ensure directory exists).

### Phase 5: Review and Handoff

1. Ask the user to choose: A) Review the PRD (recommended), B) Investigate open questions (if PRD has open questions), C) Continue to technical planning, D) I'll take it from here (exit). Only show option B when the PRD has an Open Questions section with unresolved items.
2. If review: invoke `plan-review` skill. Plan-review returns findings — brainstorming owns the fix loop.
3. Fix issues identified by plan-review.
4. Ask the user to choose (see recommendation logic below): A) Another review round, B) Investigate open questions (if applicable), C) Continue to technical planning, D) I'll take it from here (exit).
5. Repeat steps 2-4 if user chooses another round.
6. If user chooses investigate: invoke `iterative:answer-unknowns` skill with the PRD path. After investigation completes (findings presented and PRD updated with user-approved changes), return to step 4.
7. If user chooses tech-planning: invoke `iterative:tech-planning` skill.

**Recommendation logic for step 4.** Shift the recommended option based on what the review found:
- Review found Critical or High issues (now fixed) → recommend **another review round** to verify the fixes landed well
- Review found only Medium/Low issues, or a round came back clean → recommend **continue to technical planning** — further rounds will have diminishing returns
- After 3+ rounds → recommend **continue to technical planning** regardless, and note that additional passes are unlikely to surface significant issues

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
| Scope | What's in v1 vs later? What are the deliberate boundaries? |
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

See `references/prd-template.md` for the full template with section descriptions and inclusion criteria.

Key structural points:
- **Requirements are grouped by priority:** Core (the whole point), Must-Have (required for v1), Nice-to-Have (include if straightforward), Out (explicitly excluded). Each requirement gets a persistent number (R1, R2...) for cross-referencing.
- **Scope is split into In Scope and Boundaries.** Boundaries are deliberate limits — active decisions that prevent scope creep, not oversights.
- **Open Questions are tagged** with what they affect (specific requirements, scope, direction, or research needed) so downstream stages know what depends on their resolution.
- **Sections earn their inclusion.** Goal, Scope, Requirements, and Next Steps are always present. Other sections (Chosen Direction, Alternatives Considered, Key Decisions, Open Questions) are included when their criteria apply.

The PRD should give enough context for someone to create a detailed technical plan from it. High-level technical direction belongs here. Implementation specifics do not.

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
| Same depth for every PRD | Scale to scope — include sections when their criteria apply |
| Everything is Must-Have | Use priority grouping honestly — if everything is Core, nothing is |
| Leaving open questions unstructured | Tag each question with what it affects (requirement, scope, direction) |

## Transition Points

**Always present options to the user at transition points** — never just print options as text.

After PRD is created, and after each review round, present options:
- Review the PRD — 4 agents analyze for issues (recommended on first pass)
- Investigate open questions — resolve unknowns before planning (only when PRD has open questions)
- Continue to technical planning (recommended when prior review found only Medium/Low issues or after 3+ rounds)
- I'll take it from here (exit)

**Never skip this step.** Do not proceed to tech-planning or announce "the PRD is ready" without presenting these options first.

## Additional Resources

### Reference Files

For templates and detailed guidelines, consult:
- **`references/prd-template.md`** — PRD document template with section descriptions, priority definitions, and inclusion criteria
