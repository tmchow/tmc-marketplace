---
name: iterative:brainstorming
description: Explore ideas and approaches before building — scope assessment (Quick/Standard/Full), collaborative Q&A, PRD or implementation brief. Triggers: "brainstorm", "create a PRD", "write requirements", "explore approaches", "think through options", or starting a new feature with unclear direction.
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
6. **Scale to the scope** - After initial questions, assess scope (Quick/Standard/Full) and adjust ceremony accordingly. A bug fix gets focused Q&A and an inline check; a new subsystem gets the full PRD and 4-agent review
7. **Complexity-aware** - Be skeptical of complexity, not of scope. Simple additions are fine; unnecessary abstraction and indirection are not
8. **PRD is a living document** - The PRD is the requirements source of truth throughout the workflow. Tech planning and implementation may update it as reality reveals new constraints

## Workflow

### Phase 0: Detect Resume / Assess Clarity

1. If user references an existing PRD or brainstorming topic: load the document (check both `docs/prd/` and `docs/brainstorms/` — treat PRDs and brainstorm documents synonymously), summarize current state, and let the user direct what happens next. Build on existing content, update in place.
2. **Check for existing design direction docs.** Scan `docs/design-directions/` for design direction docs. If found, acknowledge the exploration upfront and fold the chosen direction into the conversation. A design direction narrows the exploration space but isn't a final spec — it's strong input about interaction model and visual direction. Build on what it establishes; explore what it doesn't answer (requirements, behaviors, scope, edge cases). Don't ask about technology or implementation — that's for planning. Reference the direction doc in the PRD when written; don't duplicate it.
3. If requirements are already explicit and detailed: ask the user: A) Skip to creating a technical plan (recommended), B) Brainstorm anyway. If skipping: invoke `iterative:tech-planning` skill.
4. Otherwise: proceed to Phase 1.

### Phase 1: Map the Space (2-3 questions)

1. Explore the codebase lightly for relevant context.
2. Ask the 2-3 BEST questions to understand the problem space (one at a time). Pick questions that will most differentiate possible approaches.
3. Don't try to cover everything — just enough to propose broad directions.
4. Move to Phase 2 after 2-3 questions (do not extend).

### Scope Assessment (after Phase 1)

After the initial questions, assess the scope of work and present a recommendation to the user. This determines how much ceremony the rest of the workflow applies.

| Scope | Description | Signals | Downstream behavior |
|-------|-------------|---------|---------------------|
| **Quick** | Bug fix, config change, single-behavior tweak | 1-3 files, no architectural decisions, clear root cause or change | Focused Q&A, no document, inline sanity check, implement directly |
| **Standard** | Small feature, bounded refactor, UI addition | Several files, a few decisions, clear scope | Brief document, full review, option to skip tech planning |
| **Full** | Large feature, cross-cutting change, new subsystem | Many files, architectural choices, multiple stakeholders or flows | Full PRD, 4-agent review, tech planning, structured implementation |

Present the assessment as a recommendation with an interactive choice (e.g., `AskUserQuestion` in Claude Code). The user confirms or overrides. Lead with a brief rationale for the recommendation, then present the three options — marking the assessed scope as `(Recommended)`:

- **Quick** — focused Q&A on edge cases, inline sanity check, then implement directly
- **Standard** — lightweight implementation brief, full review, option to skip tech planning
- **Full** — complete PRD, full review, tech plan, structured implementation

If the user overrides to a larger scope, proceed with that scope's workflow. If they confirm Quick or Standard, proceed with the lighter path. The scope can also be upgraded mid-conversation if hidden complexity emerges — note this possibility but don't belabor it.

### Phase 2: Broad Directions (steering, not detailed)

**Quick scope:** Skip Phase 2. The problem and approach are typically obvious for a bug fix or small tweak. Instead, briefly state your understanding of the approach: "Here's my understanding: [the fix/change]. Does that match?" Then move to Phase 3.

**Standard and Full scope:**

1. Present 2-3 high-level directions (1-2 sentences each). Keep them lightweight — these are steering choices, not final approaches.
2. Include a brief trade-off for each (not full pros/cons yet). Lead with a recommendation.
3. Ask the user to pick a direction. This narrows the search space for deeper exploration.
4. **Validate the direction.** After the user picks, briefly check: does this direction satisfy the core requirements identified so far? If any requirement looks at risk, flag it before going deeper. This is a quick sanity check, not a formal review — a sentence or two is sufficient.

### Phase 3: Deep Exploration (Q&A within chosen direction)

**Quick scope:** Iterative Q&A focused on understanding the specific problem and catching edge cases. Same one-question-at-a-time pattern, but the conversation naturally centers on the fix or change rather than broad goals, UX flows, or feasibility trade-offs. It wraps up faster because there's less to explore — not because of an artificial cap. If the Q&A reveals the problem is more complex than expected, suggest upgrading to Standard or Full scope.

**Standard scope:** Normal Q&A but briefer. Focus on approach decisions and edge cases rather than exhaustive exploration. 3-5 exchanges is typical. Move to Phase 4 once the approach and key edge cases are clear.

**Full scope:**

1. Ask targeted questions within the chosen direction.
2. Bring ideas — don't just ask, suggest and react.
3. Explore: goals, scope, user experience, feasibility, constraints.
4. Challenge assumptions ("Do you actually need X, or would Y work?"). Research prior art and alternatives when useful.
5. Validate assumptions explicitly ("I'm assuming X. Is that correct?"). Identify risks and open questions to carry forward.
6. Continue until the approach is well-scoped.

### Phase 4: Document Findings

**Quick scope:** Skip document creation entirely. The brainstorm conversation itself is the artifact. Instead, move directly to Phase 5 (which runs an inline sanity check for Quick scope). No branch safety gate needed — no commits to make.

**Standard scope:**

1. **Branch safety gate.** Before the first commit, check if on the default branch (`main`/`master`). If so, offer: A) Create a feature branch (recommended), B) Continue on default branch. This is a one-time check — once resolved, all subsequent commits in this session go to the chosen branch.
2. Write a lightweight **implementation brief** — not a full PRD. Include only: Goal (1-2 sentences), Approach (the chosen direction and why), Requirements (simplified table — just the key ones), Edge Cases (what to watch for), and Scope Boundaries (what's deliberately excluded). Skip sections like Alternatives Considered, Key Decisions log, Success Criteria, and Open Questions unless they genuinely apply.
3. Save to `docs/prd/YYYY-MM-DD-<topic>-brief.md` (ensure directory exists).
4. **Commit the brief.** Don't leave it as an uncommitted change.

**Full scope:**

1. **Branch safety gate.** Before the first commit, check if on the default branch (`main`/`master`). If so, offer: A) Create a feature branch (recommended), B) Continue on default branch. This is a one-time check — once resolved, all subsequent commits in this session go to the chosen branch.
2. Write PRD using the template in `references/prd-template.md`. Include sections when their inclusion criteria apply — skip the rest.
3. Group requirements by priority in a single markdown table (columns: ID, Priority, Requirement). Priority values: Core, Must, Nice, Out. Be deliberate about priority — if everything is Must, nothing is.
4. Save to `docs/prd/YYYY-MM-DD-<topic>-prd.md` (ensure directory exists).
5. **Commit the PRD.** Don't leave it as an uncommitted change.

### Phase 5: Review and Handoff

Phase 5 behavior varies by scope. All scopes include at least one review pass — even Quick scope gets a sanity check.

#### Quick Scope

1. **Inline sanity check.** Before presenting options, do a brief self-review of the approach discussed. Present it directly:

   > **Sanity check before proceeding:**
   > - [Edge case X] — covered by [approach detail], or flagged as a concern
   > - [Assumption Y] — validated because [reason], or needs verification
   > - [Adjacent risk Z] — low because [reason], or worth watching
   > - Hidden complexity: [assessment — is this actually as small as it seems?]
   >
   > [Clean: "This looks straightforward." / Concern: "One thing to watch: [X]"]

   This is a thinking pause, not a formal review — a few sentences surfacing anything the conversation might have missed.

2. **Present options.** Interactive choice (e.g., `AskUserQuestion` in Claude Code). AskUserQuestion provides an automatic "Other" option — use that as the exit path:
   - **Implement (Recommended)** — approach is clear, go build it
   - **Upgrade to tech plan** — scope is bigger than expected, create a structured plan

   "Implement" means the skill exits and the user proceeds to build based on the brainstorm conversation. No plan document or structured implementation skill needed. If the sanity check flagged concerns, note them but still let the user choose — they may already be aware.

#### Standard Scope

1. **Classify open questions.** If the brief has open questions, classify them (see classification criteria below).
2. **Surface user decisions.** Same as Full scope step 2 below, applied to the brief.
3. **First time presenting options: recommend Review.** Present an interactive choice (e.g., `AskUserQuestion` in Claude Code). AskUserQuestion provides an automatic "Other" option — use that as the exit path (user can type "I'll take it from here" or similar). Show up to 4 explicit options, selected from this priority order:
   - **Review the brief (Recommended)** — 4 specialized reviewers analyze for issues (always show)
   - **Explore design directions** — generate visual/UX variations to see options before committing (only show when applicable)
   - **Research open questions** — resolve unknowns through investigation (only show when applicable)
   - **Implement directly** — scope is clear enough to start building (always show)
   Only show Design Exploration when the work involves UI/UX. Only show Research when open questions exist that fit the research resolution method. If both Design Exploration and Research apply (rare for Standard scope), drop "Implement directly" to stay within the 4-option limit — if the task has both visual unknowns and open questions, it's complex enough that implementing directly isn't appropriate. When neither conditional applies, show: Review, Tech planning, Implement directly (3 options + Other).

   **Note:** "Continue to technical planning" is available via the automatic "Other" option when not shown explicitly. When it IS shown, it replaces "Implement directly" in the fourth slot — Standard scope always offers at least one forward path (tech planning or implement directly), but not necessarily both. Show "Continue to technical planning" explicitly when the task clearly warrants a plan (e.g., touches multiple files, has architectural decisions). Show "Implement directly" when the brief is simple enough to build from directly.
4. If review: invoke `plan-review` skill. Brainstorming owns the fix loop.
5. Fix issues identified by plan-review. **Commit the updated brief.**
6. **After fixing**, present an interactive choice (e.g., `AskUserQuestion` in Claude Code) — same options as step 3, re-assessed with updated context. **Do not mark any option as recommended.** Do not end the turn without presenting this choice.
7. Repeat steps 4-6 if user chooses another round.
8. If user chooses design exploration: invoke `iterative:design-exploration` skill. After exploration concludes (design direction doc created, brief updated to reference it), **commit the updated brief** and return to step 6.
9. If user chooses research: invoke `iterative:research` skill. After completion, **commit updated brief** and return to step 6.
10. If user chooses tech-planning: invoke `iterative:tech-planning` skill.
11. If user chooses implement directly: exit the skill. The user proceeds to build based on the brief and brainstorm conversation.

#### Full Scope

1. **Classify open questions.** If the PRD has an Open Questions section, read the questions and assess which resolution method fits each (see classification criteria below). Use this to determine which steps and options to surface next.
2. **Surface user decisions.** If any questions were classified as "user decision needed," present them before the main options — the brainstorming context is fresh and it's a good moment to decide. For each question:
   - Assess the question: if natural options exist, present as multiple choice (use interactive tool-based presentation when available). If the question is truly open-ended, ask free-form.
   - Include a "Decide later" option — the user shouldn't be forced to decide now.
   - Answered: update the PRD — remove from Open Questions, apply the decision to the relevant section (requirement, scope, boundary, etc.).
   - Deferred: leave in Open Questions.

   Present one question at a time. Skip this step if no user-decision questions exist.
3. **First time presenting options: always recommend Review.** The PRD has never been reviewed — review is the right default. Present an interactive choice (e.g., `AskUserQuestion` in Claude Code). AskUserQuestion provides an automatic "Other" option — use that as the exit path. Show up to 4 explicit options, selected from this priority order:
   - **Review the PRD (Recommended)** — 4 specialized reviewers analyze for issues (always show)
   - **Explore design directions** — generate visual/UX variations to see options before committing (only show when applicable)
   - **Research open questions** — resolve unknowns through investigation (only show when applicable)
   - **Continue to technical planning** — create a detailed implementation plan (always show)
   Only show Design Exploration when the work involves UI/UX. Only show Research when the PRD has open questions that fit the research resolution method. When all are shown, all 4 slots are used. When neither Design Exploration nor Research applies, only 2 options + Other.
4. If review: invoke `plan-review` skill. Plan-review returns findings — brainstorming owns the fix loop.
5. Fix issues identified by plan-review. **Commit the updated PRD.**
6. **Immediately after fixing**, present an interactive choice to the user (e.g., `AskUserQuestion` in Claude Code) — same options as step 3, re-assessed with updated PRD context. **Do not mark any option as recommended** — the right next step depends on context the skill can't reliably judge. Do not end the turn without presenting this choice.
7. Repeat steps 4-6 if user chooses another round.
8. If user chooses design exploration: invoke `iterative:design-exploration` skill. After exploration concludes (design direction doc created, PRD updated to reference it), **commit the updated PRD** and return to step 6.
9. If user chooses research: invoke `iterative:research` skill with the PRD path. After research completes (findings presented and PRD updated with user-approved changes), **commit the updated PRD** and return to step 6.
10. If user chooses tech-planning: invoke `iterative:tech-planning` skill.

**Open question classification criteria.** When assessing open questions in step 1, apply these criteria to determine which options to surface:

| Resolution method | When | The answer... |
|---|---|---|
| **Research** | Facts, patterns, prior art, external constraints | ...exists somewhere and needs to be found |
| **Design exploration** | Visual design, UX feel, interaction models, "what could this look like?" | ...needs to be seen and experienced across multiple approaches |
| **User decision** | Priorities, preferences, business judgment | ...is a human call, not something research or exploration will reveal |
| **Tech planning** | Implementation details, architecture, codebase mechanics | ...requires deep codebase context that tech planning will explore |

This classification is a judgment call — present it as informed options, not a formal categorization step. The user picks what to do.

**After the first review (step 6), do not recommend a specific option.** Just present the choices and let the user decide. If deferred user decisions remain, note they'll carry forward as open questions into tech planning.

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
- **Requirements are a single table** with columns ID, Priority, Requirement. Priority values: Core, Must, Nice, Out. Each requirement gets a persistent ID (R1, R2...) for cross-referencing.
- **Scope is split into In Scope and Boundaries.** Boundaries are deliberate limits — active decisions that prevent scope creep, not oversights.
- **Open Questions are tagged** with what they affect (specific requirements, scope, direction) so downstream stages know what depends on their resolution.
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
| Proposing overly complex solutions | Start simple, add complexity only when it reduces maintenance burden |
| Full PRD ceremony for a bug fix | Match scope assessment — Quick scope skips documents, Standard scope uses a brief |
| Skipping scope assessment | Always assess scope after Phase 1 — it determines the entire downstream workflow |
| Making assumptions without validating | State assumptions explicitly and confirm |
| Same depth for every PRD | Scale to scope — include sections when their criteria apply |
| Everything is Must | Use priority honestly — if everything is Core, nothing is |
| Leaving open questions unstructured | Tag each question with what it affects (requirement, scope, direction) |

## Transition Points

**Always present options to the user at transition points using the interactive question tool** (e.g., `AskUserQuestion` in Claude Code) — never just print options as text or end the turn without presenting a choice.

Transition options vary by scope (see Phase 5 for detailed options per scope):

- **Quick:** Implement directly (recommended) | Upgrade to tech plan | Other (exit)
- **Standard:** Review brief (recommended first pass) | Design exploration (conditional) | Research (conditional) | Implement directly or Tech planning | Other (exit)
- **Full:** Review PRD (recommended first pass) | Design exploration (conditional) | Research (conditional) | Tech planning | Other (exit)

All scopes respect the 4-option limit for interactive questions. See Phase 5 for the priority rules when more options apply than slots allow.

After the first review round (Standard/Full), do not mark any option as recommended — just present the choices.

**Never skip this step.** Do not proceed to tech-planning, announce "the PRD is ready," or let the conversation drift without presenting these options first.

## Additional Resources

### Reference Files

For templates and detailed guidelines, consult:
- **`references/prd-template.md`** — PRD document template with section descriptions, priority definitions, and inclusion criteria
