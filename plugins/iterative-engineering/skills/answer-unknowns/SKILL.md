---
name: iterative:answer-unknowns
description: This skill should be used when the user says "answer unknowns", "answer these questions", "investigate questions", "resolve open questions", "research these questions", "address open questions", "look into the unknowns", or when a PRD has unresolved questions that should be investigated before technical planning.
---

# Answer Unknowns

Investigate open questions from a PRD or a user-provided set of questions. Categorize each question, spawn parallel research subagents for investigatable items, synthesize findings, and update the PRD.

## When to Use

- After `iterative:brainstorming` produces a PRD with open questions
- When the user has specific questions to investigate before planning
- When scope, requirements, or direction questions need answers before tech planning can proceed
- Can be invoked standalone with a list of questions (no PRD required)

## Key Principles

1. **Categorize before investigating** — Not all questions belong here. Technical implementation questions (how to query X, which API to use) belong in tech planning's codebase exploration. This skill handles scope, requirements, external research, and prior art questions.
2. **Parallel research** — Spawn independent research subagents for each question. Questions are typically unrelated and benefit from concurrent investigation.
3. **Update the source of truth** — When a PRD exists, findings should update it directly. Answered questions move out of Open Questions; new constraints become requirements.
4. **Present before committing** — Show findings and proposed PRD changes to the user for approval before updating the document.

## Workflow

### Phase 1: Gather Questions

1. **If invoked with a PRD path:** Read the PRD's Open Questions section. Extract all tagged questions.
2. **If invoked with user-provided questions:** Use the questions as provided.
3. **If no input:** Ask the user for either a PRD path or a set of questions.

### Phase 2: Categorize

For each question, assess whether it can be investigated now or should be deferred:

| Category | Action | Examples |
|----------|--------|----------|
| **Scope / Requirements** | Investigate now | "Do users need offline support?" / "Should this handle bulk operations?" |
| **External research** | Investigate now | "What do competitors do for this?" / "Are there regulatory constraints?" |
| **Prior art / Patterns** | Investigate now | "How do similar tools handle this?" / "What's the standard approach?" |
| **Technical implementation** | Defer to tech planning | "Which database index strategy?" / "How does the existing auth middleware work?" |
| **User decision needed** | Flag for user | "Should we support both formats?" / "What's the priority between X and Y?" |

Present the categorization to the user. They may recategorize or add questions.

### Phase 3: Investigate

1. For each investigatable question, spawn an independent general-purpose subagent. Each subagent receives:
   - The question
   - Relevant context from the PRD (if exists)
   - Research scope (web search, codebase exploration, documentation review — as appropriate)
   - Instruction to return findings as: what was learned, confidence level, and how it affects the PRD (if applicable)
2. Run subagents in parallel — questions are independent and do not need cross-validation (unlike review agents, which use agent teams). Independent subagents are the right pattern here.
3. Collect findings from all subagents.
4. If a subagent finds nothing useful: note it as unresolved and carry the question forward.

### Phase 4: Synthesize and Update

1. **Present findings** to the user, organized by question:
   - What was found
   - How it affects the PRD (new requirement, scope change, question resolved, question remains open)
2. **If a PRD exists, propose updates:**
   - Questions answered → remove from Open Questions
   - New constraints discovered → add to Requirements (note they were discovered during investigation)
   - Scope implications → update Scope / Boundaries
3. **Get user approval** before making any PRD changes.
4. **Apply approved changes** to the PRD document.

### Phase 5: Handoff

1. Summarize: what was resolved, what remains open, what was deferred to tech planning.
2. If invoked from brainstorming workflow: return to brainstorming's Phase 5 transition (brainstorming presents the next set of options).
3. If invoked standalone: ask the user what's next.

## When Things Go Wrong

- **No results found for a question:** Mark it as unresolved. Carry it forward to tech planning or flag it for the user as needing a decision.
- **All questions are "User decision needed":** Nothing to investigate. Present the decisions to the user directly and skip Phase 3.
- **PRD has no Open Questions section:** If invoked with a PRD path but no Open Questions, report this and ask the user if they have questions to investigate or if the PRD is ready for tech planning.
- **User rejects all proposed PRD changes:** Findings are still valuable context. Summarize what was learned even if the PRD isn't updated.

## Transition Points

**Always present options to the user at transition points** — never just print options as text.

After investigation completes, when invoked standalone, present options:
- Continue to technical planning
- Investigate more questions
- I'll take it from here (exit)

When invoked from brainstorming: return to brainstorming's transition (brainstorming presents its own options).

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Investigating technical implementation questions | Defer to tech planning — those need codebase context |
| Making PRD changes without user approval | Present findings and proposed changes first |
| Sequential research when questions are independent | Spawn parallel subagents |
| Leaving answered questions in Open Questions | Clean up — move resolved items out, update affected sections |
| Investigating when the answer requires a user decision | Flag it — present the decision to the user instead of researching |
