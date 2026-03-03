---
name: iterative:brainstorming
description: 'Scope-first brainstorming with intelligent routing — assesses complexity upfront (Quick/Standard/Full), then adapts depth accordingly. Handles simple bug fixes in ~2 exchanges and complex features with full PRD ceremony. Triggers: "brainstorm", "create a PRD", "write requirements", "explore approaches", "think through options", or starting a new feature with unclear direction.'
---

# Brainstorming

Explore the problem space, scope the goal, and make directional choices through collaborative dialogue. Assess scope early and match ceremony to complexity — a bug fix exits in two exchanges, a new subsystem gets a full PRD.

## When to Use

- Before implementing any new feature or significant change
- When requirements are unclear or multiple approaches exist
- When the user hasn't fully articulated what they want
- When exploring an entirely new project or app idea

**When to skip:** Requirements are explicit, detailed, and the user knows exactly what they want. Offer to go straight to `iterative:tech-planning`.

## Key Principles

1. **Scope first** — Assess complexity from the initial message and codebase signals before asking questions. Route to the right path early.
2. **One question at a time** — Never ask multiple questions in a single message
3. **Multiple choice preferred** — Easier to answer than open-ended when natural options exist
4. **Be a thinking partner** — Don't just extract requirements. Bring ideas, suggest alternatives, challenge assumptions, explore what-ifs
5. **Directional, not detailed** — High-level technical direction is welcome. Implementation specifics belong in tech-planning
6. **Complexity-aware** — Be skeptical of unnecessary complexity, not of scope. Simple additions are fine; unnecessary abstraction is not
7. **What, not how** — Brainstorming captures WHAT to build (requirements, scope, decisions). Tech-planning captures HOW (files, architecture, implementation steps). Even in lighter paths, respect this boundary
8. **PRD is a living document** — For Full scope, the PRD is the requirements source of truth throughout the workflow. Tech planning and implementation may update it as reality reveals new constraints

## Step 1: Assess and Route

### Detect Resume

If user references an existing PRD or brainstorming topic: load the document (check both `docs/prd/` and `docs/brainstorms/` — treat PRDs and brainstorm documents synonymously), summarize current state, and let the user direct what happens next. Build on existing content, update in place.

### Check for Existing Context

- **Design direction docs.** Scan `docs/design-directions/` for design direction docs. If found, acknowledge the exploration upfront and fold the chosen direction into the conversation. A design direction narrows the exploration space but isn't a final spec. Build on what it establishes; explore what it doesn't answer. Reference the direction doc in the PRD when written; don't duplicate it.
- **Explicit requirements.** If requirements are already explicit and detailed: ask the user: A) Skip to creating a technical plan (recommended), B) Brainstorm anyway. If skipping: invoke `iterative:tech-planning` skill.

### Assess Scope

Before asking any questions, assess the scope of work from the initial message and a light codebase scan. This determines which path to follow.

1. **Light codebase scan.** Quickly explore relevant files and patterns to ground the assessment.
2. **Assess scope** based on the initial message + codebase signals:

| Scope | Description | Signals |
|-------|-------------|---------|
| **Quick** | Bug fix, config change, single-behavior tweak | 1-3 files, no architectural decisions, clear root cause or change |
| **Standard** | Small feature, bounded refactor, UI addition | Several files, a few decisions, clear scope |
| **Full** | Large feature, cross-cutting change, new subsystem | Many files, architectural choices, multiple stakeholders or flows |

3. **If scope is ambiguous:** Ask one targeted question to disambiguate, then assess.
4. **Present scope recommendation.** Lead with a brief rationale, then present the three options using an interactive choice (e.g., `AskUserQuestion` in Claude Code), marking the assessed scope as `(Recommended)`:
   - **Quick** — focused clarification, confirm understanding, then implement
   - **Standard** — collaborative Q&A, summarize deliverables, option for tech plan
   - **Full** — deep exploration, complete PRD, review and handoff

If the user overrides to a different scope, proceed with that scope's path.

---

## Quick Path

For bug fixes, config changes, and single-behavior tweaks. Gets out of the way fast.

**Question focus:** Inherently technical — questions about root cause, affected behavior, and edge cases are natural for bug fixes and tweaks.

### Clarify (0-2 questions)

Use your judgment. If the initial message plus codebase context gives you enough to understand the fix, ask zero questions. If something is ambiguous, ask one or two — no more.

### Confirm Understanding

State your understanding concisely:
- What the change is
- Which files are likely involved
- Edge cases or risks worth noting

Ask the user to confirm. If they correct something significant, update and re-confirm.

### Multi-step Enumeration

If the fix involves multiple discrete steps, briefly enumerate them at a high level (what to do, not how). These are deliverables, not implementation instructions — no file paths or code specifics.

### Exit

The skill is done. The user proceeds to implement based on the conversation. No documents, no formal review, no transition menu.

**If complexity emerges:** If at any point the problem turns out to be more complex than expected, suggest upgrading to Standard or Full scope. Carry forward everything discussed — don't repeat questions.

---

## Standard Path

For small features, bounded refactors, and UI additions. Enough structure to align on what to build without document ceremony.

**Question focus:** Product decisions + light technical direction. "Should pagination be client-side or server-side?" is fine. "Should we use offset or cursor pagination in the SQL query?" is tech-planning territory.

### Collaborative Q&A

1. Ask targeted questions one at a time. Focus on approach decisions, scope boundaries, and edge cases.
2. Bring ideas — suggest alternatives, challenge assumptions, explore what-ifs.
3. Typically 3-5 exchanges, but use your judgment. Move on when the approach and key decisions are clear, not at an arbitrary count.

### Optional Approach Discussion

Only if the path forward is genuinely ambiguous — present 2-3 lightweight directions (1-2 sentences each with a brief trade-off) and ask the user to pick. Skip this if there's an obvious approach.

### Summarize What We're Building

Capture the key outcomes of the conversation:
- **Goal** — what we're building and why (1-2 sentences)
- **Deliverables** — high-level list of what gets built (e.g., "add pagination to list view", "update UI with page controls", "handle empty state"). These describe WHAT, not HOW — no file paths or implementation steps
- **Key decisions** — choices made during the conversation that constrain the approach
- **Scope boundaries** — what's deliberately excluded
- **Edge cases** — what to watch for

Present this inline in the conversation. Do not create a document or commit anything.

### Exit Options

Present an interactive choice (e.g., `AskUserQuestion` in Claude Code):
- **Implement directly (Recommended)** — scope is clear, go build it
- **Create a tech plan** — want a structured implementation plan before building

The skill exits after this choice. If the user chooses tech-planning, invoke `iterative:tech-planning` skill.

**If complexity emerges:** If Q&A reveals the work is larger than expected, suggest upgrading to Full scope. Carry forward all decisions and context.

---

## Full Path

For large features, cross-cutting changes, and new subsystems. Full ceremony — deep exploration, PRD, review, and structured handoff.

**Question focus:** Product-focused. High-level technical direction ("build vs buy", "real-time vs polling") is the limit. Implementation specifics belong in tech-planning.

### Map the Space (2-3 questions)

1. Explore the codebase lightly for relevant context.
2. Ask the 2-3 best questions to understand the problem space (one at a time). Pick questions that most differentiate possible approaches.
3. Don't try to cover everything — just enough to propose broad directions.

**For design and interaction-heavy tasks** (visual redesigns, marketing pages, UI overhauls, workflow/onboarding redesigns): frame questions around constraints and goals — what should be preserved, what specifically feels stale, who's the audience, what impression or experience they should walk away with. Gather parameters for exploration rather than pushing toward verbal style or interaction choices ("what energy do you want?" forces a text answer for a question the user needs to see or experience to answer well).

### Broad Directions

1. Present 2-3 high-level directions (1-2 sentences each). Keep them lightweight — these are steering choices, not final approaches.
2. Include a brief trade-off for each. Lead with a recommendation.
3. Ask the user to pick a direction.
4. After the user picks, briefly validate: does this direction satisfy the core requirements identified so far? Flag any requirement at risk before going deeper.

**For design and interaction-heavy tasks:** When the task involves visual design, interaction patterns, or user experience (redesigns, marketing pages, onboarding flows, workflow changes), offer the user a choice before presenting text-based directions:
- **Explore design directions** — invoke `iterative:design-exploration` to produce directions the user can see and react to. Use Map the Space answers as constraints and goals to guide the exploration.
- **Discuss approaches first** — present text-based broad directions as above, then optionally explore later. Better when the user already has a direction in mind or wants to narrow conceptually first.

Present this as an interactive choice (e.g., `AskUserQuestion`). The signal to offer this is any task where the user needs to *see or experience* options to meaningfully choose — visual concepts, interaction patterns, flows, or a combination. This choice comes after Map the Space, so the exploration is grounded in the initial scoping, not untethered. If the user picks exploration, the chosen direction feeds into Deep Exploration for remaining requirements and scope decisions. If they pick text-based directions, proceed as normal — design-exploration remains available later in Review and Handoff.

### Deep Exploration

1. Ask targeted questions within the chosen direction.
2. Bring ideas — don't just ask, suggest and react.
3. Explore: goals, scope, user experience, feasibility, constraints.
4. Challenge assumptions ("Do you actually need X, or would Y work?"). Research prior art and alternatives when useful.
5. Validate assumptions explicitly ("I'm assuming X. Is that correct?"). Identify risks and open questions to carry forward.
6. Continue until the approach is well-scoped.

### Document: Write PRD

1. **Branch safety gate.** Before the first commit, check if on the default branch (`main`/`master`). If so, offer: A) Create a feature branch (recommended), B) Continue on default branch. One-time check.
2. Write PRD using the template in `references/prd-template.md`. Include sections when their inclusion criteria apply — skip the rest.
3. Group requirements by priority in a single markdown table (columns: ID, Priority, Requirement). Priority values: Core, Must, Nice, Out. Be deliberate about priority — if everything is Must, nothing is.
4. Save to `docs/prd/YYYY-MM-DD-<topic>-prd.md` (ensure directory exists).
5. **Commit the PRD.** Don't leave it as an uncommitted change.

### Review and Handoff

1. **Classify open questions.** If the PRD has an Open Questions section, assess which resolution method fits each:

   | Resolution method | When | The answer... |
   |---|---|---|
   | **Research** | Facts, patterns, prior art, external constraints | ...exists somewhere and needs to be found |
   | **Design exploration** | Visual design, UX feel, interaction models | ...needs to be seen and experienced across multiple approaches |
   | **User decision** | Priorities, preferences, business judgment | ...is a human call, not something research or exploration will reveal |
   | **Tech planning** | Implementation details, architecture, codebase mechanics | ...requires deep codebase context that tech planning will explore |

2. **Surface user decisions.** If any questions were classified as "user decision needed," present them before the main options — the brainstorming context is fresh. For each: if natural options exist, present as multiple choice; if truly open-ended, ask free-form. Include a "Decide later" option. Answered questions: update the PRD. Deferred: leave in Open Questions. One question at a time.

3. **Present options.** Interactive choice (e.g., `AskUserQuestion` in Claude Code). AskUserQuestion provides an automatic "Other" option — use that as the exit path. Show up to 4 explicit options, selected from this priority order:
   - **Review the PRD (Recommended)** — dynamically selected reviewers analyze for issues (always show)
   - **Explore design directions** — generate visual/UX variations (show when the product has any user-facing surface — web apps, mobile apps, dashboards, CLIs with rich output, landing pages, etc. Only hide for pure backend/infrastructure/library work with no user-facing surface)
   - **Research open questions** — resolve unknowns through investigation (only show when applicable)
   - **Continue to technical planning** — create a detailed implementation plan (always show)

   When all are shown, all 4 slots are used. When neither Design Exploration nor Research applies, only 2 options + Other.

4. **If review:** invoke `plan-review` skill. Brainstorming owns the fix loop.
5. Fix issues identified by plan-review. **Commit the updated PRD.**
6. **After fixing**, present an interactive choice — same options as step 3, re-assessed with updated PRD context. **Do not mark any option as recommended.** Do not end the turn without presenting this choice.
7. Repeat steps 4-6 if user chooses another round.
8. **If design exploration:** invoke `iterative:design-exploration` skill. After exploration concludes, **commit the updated PRD** and return to step 6.
9. **If research:** invoke `iterative:research` skill. After completion, **commit updated PRD** and return to step 6.
10. **If tech-planning:** invoke `iterative:tech-planning` skill.

---

## Scope Upgrades

Scope can be upgraded mid-conversation if hidden complexity emerges. When upgrading:

1. **Explain why** — briefly note what changed (e.g., "This touches more systems than expected").
2. **Carry forward** — everything discussed so far transfers. Don't re-ask questions or repeat analysis.
3. **Resume at the right point** — enter the new path where it makes sense given what's already been covered. If Quick→Standard and you've already clarified the problem, start at the Q&A stage. If Standard→Full and you've already done Q&A, start at Broad Directions or Deep Exploration.

## Question Techniques

**Prefer multiple choice when natural options exist:**
- Good: "Should the notification be: (a) email only, (b) in-app only, or (c) both?"
- Avoid: "How should users be notified?"

**Topics to explore (choose what's relevant, not all):**

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

## Broad Directions Format

Keep these lightweight — 1-2 sentences each with a brief trade-off. These steer the conversation, not finalize the approach.

```markdown
Here are 2-3 broad directions:

**A) [Name]** — [1-2 sentence description]. Trade-off: [brief].
**B) [Name]** — [1-2 sentence description]. Trade-off: [brief].
**C) [Name]** — [1-2 sentence description]. Trade-off: [brief].

I'd lean toward **A** because [one sentence]. Which direction feels right?
```

## PRD Format (Full Path)

See `references/prd-template.md` for the full template with section descriptions and inclusion criteria.

Key structural points:
- **Requirements are a single table** with columns ID, Priority, Requirement. Priority values: Core, Must, Nice, Out. Each requirement gets a persistent ID (R1, R2...) for cross-referencing.
- **Scope is split into In Scope and Boundaries.** Boundaries are deliberate limits — active decisions that prevent scope creep, not oversights.
- **Open Questions are tagged** with what they affect so downstream stages know what depends on their resolution.
- **Sections earn their inclusion.** Goal, Scope, Requirements, and Next Steps are always present. Other sections are included when their criteria apply.

The PRD should give enough context for someone to create a detailed technical plan from it.

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Asking questions before assessing scope | Assess scope from initial message + codebase scan first |
| Same ceremony for every task | Quick exits fast; Standard aligns without docs; Full gets full PRD |
| Rigid question counts ("exactly 2-3") | Use judgment — ask as many as needed, as few as possible |
| Asking implementation questions during brainstorming | "Which database?" is tech-planning. "Real-time vs polling?" is fine |
| Writing documents for Standard scope | An inline summary suffices. Users wanting docs upgrade to Full |
| Multiple questions in one message | One question per message |
| Just extracting requirements passively | Be a thinking partner — bring ideas, challenge assumptions |
| Proposing overly complex solutions | Start simple, add complexity only when it reduces maintenance burden |
| Skipping scope assessment | Always assess scope before questions — it determines the entire path |
| Making assumptions without validating | State assumptions explicitly and confirm |
| Everything is Must priority | Use priority honestly — if everything is Core, nothing is |
| Repeating work after scope upgrade | Carry forward everything; resume the new path where it makes sense |
| Describing HOW instead of WHAT in Standard summary | Deliverables are "add pagination", not "modify api/list.ts to accept page params" |

## Transition Points

**Always present options to the user at transition points using the interactive question tool** (e.g., `AskUserQuestion` in Claude Code) — never just print options as text or end the turn without presenting a choice.

- **Quick:** Confirmation gate only — no transition menu. Skill exits after user confirms understanding.
- **Standard:** Implement directly (recommended) | Create a tech plan | Other (exit)
- **Full:** Review PRD (recommended first pass) | Design exploration (conditional) | Research (conditional) | Tech planning | Other (exit)

After the first review round (Full), do not mark any option as recommended — just present the choices.

**Never skip this step.** Do not proceed to tech-planning, announce "the PRD is ready," or let the conversation drift without presenting these options first.

## Additional Resources

### Reference Files

For templates and detailed guidelines, consult:
- **`references/prd-template.md`** — PRD document template with section descriptions, priority definitions, and inclusion criteria
