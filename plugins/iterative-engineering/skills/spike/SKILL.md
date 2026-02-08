---
name: iterative:spike
description: This skill should be used when the user says "spike this", "prototype this", "proof of concept", "POC this", "try this out", "let me see what this looks like", "validate this", "explore what this would feel like", "I want to try this before committing", or when PRD requirements need to be experienced before committing to a direction.
---

# Spike

Build something lightweight to validate uncertain requirements before committing to full implementation. Some unknowns can't be resolved through research or dialogue — you need to see it, use it, or experience it. Spiking bridges that gap.

This skill resolves unknowns where the answer **needs to be built and experienced** — interaction feel, UX flow, behavioral validation. For unknowns that can be answered by **gathering information** (prior art, constraints, competitive landscape), use `iterative:research` instead.

## When to Use

- After `iterative:brainstorming` when open questions need to be experienced, not just discussed
- When the user wants to see or try something before committing to a direction
- When requirements seem right on paper but need real-world validation
- Before tech planning, to validate PRD decisions that carry risk
- Can be invoked standalone — no PRD or workflow context required

## Key Principles

1. **Validate, don't implement** — The spike answers a question. It's not a head start on implementation. No tests, no error handling, no edge cases.
2. **Minimum to validate** — Build the least amount needed to answer the question. Resist the urge to flesh things out.
3. **Worktree isolation** — Spike code goes in a separate worktree. Spike docs and PRD updates go on the original branch. This keeps throwaway code separate from durable artifacts.
4. **PRD is the primary output** — The PRD captures conclusions with full rationale — self-sufficient for downstream stages without needing to read the spike doc. The spike doc records the journey for traceability.
5. **User drives iteration** — Build, present, get feedback, iterate. The user decides when they've seen enough.

## Workflow

### Phase 0: Detect Resume

1. Scan `docs/spikes/` for documents with `Status: In Progress`.
2. For each, check if the recorded branch has a worktree (`git worktree list`).
3. If active spikes found, present them:
   - Active spikes with worktrees: name, validation goal, worktree path
   - Spike docs without worktrees (worktree was deleted): flag the inconsistency
4. Ask the user: resume an existing spike, or start new?
5. If resuming: switch to the worktree, read the spike doc's Progress section, continue from Phase 3.
6. If starting fresh or no active spikes: proceed to Phase 1.

### Phase 1: Scope the Spike

1. **Identify what to validate.** If invoked from brainstorming, the open questions provide context. If standalone, ask the user what they want to validate.
2. **Map to requirements.** If a PRD exists, connect the spike to specific requirements or decisions being validated.
3. **Define the validation goal.** What are we trying to learn? What outcome would change direction? Frame it as understanding to gain, not a decision to make (see spike doc template for acceptance guidelines).
4. **Assess system state.** Determine the spike approach:

| System state | Approach |
|---|---|
| Relevant modules exist and work | **Spike within** — add minimal code to existing system. Validates in real context. |
| System exists but relevant parts aren't built yet | **Standalone prototype** — build outside the system. Cheaper than integrating. |
| Greenfield or very early | **Standalone prototype** — HTML, minimal app, whatever fits the question. |

5. **Create the spike doc on the original branch.** Use the template in `references/spike-template.md`. Save to `docs/spikes/YYYY-MM-DD-<topic>-spike.md` (ensure directory exists). Fill in Context, Validation Goal, and Approach. Status: In Progress. Create this before setting up the spike worktree — the spike doc is a durable artifact that belongs on the original branch, not the throwaway spike branch.
6. **Present the scope to the user.** What we're validating, how we'll build it, what we're deliberately leaving out. Get confirmation before setup.

### Phase 2: Setup

1. **Create worktree.** Invoke the `git-worktree` skill with branch name `spike/<topic>`. Spikes should always use a worktree — the code is throwaway and should not mix with feature or main branch work.
2. **Record worktree info** in the spike doc's Spike Code section (worktree path, branch name).
3. **Minimal setup only.** No test infrastructure, no CI config. Just enough to build and demonstrate.

### Phase 3: Build and Validate (repeat)

1. **Build the minimum** to validate the goal. This is deliberately rough — no tests, no error handling, no edge cases. If it validates the question, it's enough.
2. **Present to the user.** How to experience the spike depends on what was built — open a file, run a server, execute a command, walk through the behavior. Be specific about how the user can see or interact with it.
3. **Ask targeted feedback questions.** Not open-ended "what do you think?" — specific questions tied to the validation goal. Examples:
   - "Does this drag interaction feel natural, or does it fight you?"
   - "Is this the information hierarchy you expected on this screen?"
   - "When you [performed action], was the result what you anticipated?"
4. **Update the spike doc's Progress section** with a brief note: what was built, key feedback, what's next.
5. **User chooses:**
   - **Iterate** — refine based on feedback, return to step 1
   - **Conclude** — enough was learned, proceed to Phase 4
   - **Abandon** — the spike isn't helping, proceed to Phase 4 with inconclusive findings
   - **Pause** — ensure Progress section is current, keep the worktree. Resume detection (Phase 0) will find this spike in a future session.

### Phase 4: Wrap Up

1. **Finalize the spike doc:**
   - Write Findings: what was learned, what was confirmed, what surprised, what didn't work
   - Write Decisions: what changed, what was validated, requirement confirmations or changes
   - If the spike was abandoned/inconclusive: document what was tried and why it didn't resolve the uncertainty. Carry the question forward.
   - Remove the Progress section (fold relevant content into Findings)
   - Set Status to Complete

2. **Propose upstream doc updates.** If a PRD exists, propose specific changes. The PRD must be self-sufficient — capture full rationale, not just pointers to the spike doc:

   | What changed | PRD update |
   |---|---|
   | Requirement validated | Note increased confidence, no change needed unless wording should be more specific |
   | Requirement changed | Update wording and priority. Full rationale in the PRD: what was tried, why it changed. Link to spike doc for traceability. |
   | New requirement discovered | Add to Requirements with appropriate priority. Note discovered during spike. |
   | Scope boundary confirmed or shifted | Update Scope / Boundaries with rationale. |
   | New decision made | Add to Key Decisions with rationale. |
   | Direction invalidated | Flag for user — this is a significant PRD change. See "When the spike invalidates the direction" below. |
   | Open question resolved | Remove from Open Questions. Rationale captured in the affected section. |

   If a tech plan exists, propose updates there too.

3. **User approves** changes before they're applied. Present proposed changes clearly — what will change and why.

4. **Apply approved changes** to the PRD (and tech plan if applicable) on the original branch. Each change in the PRD should include enough context that someone reading it understands the decision without reading the spike doc. The spike doc updates (Findings, Decisions, Impact, Status) also go on the original branch.

5. **Write Impact on Upstream Docs section** in spike doc: summarize what was changed in upstream docs.

### Phase 5: Handoff

1. If **multiple spikes were scoped** (e.g., brainstorming identified several spike-worthy questions): "Spike complete. PRD updated. Ready to spike [next item], or done with spiking?"
2. If invoked from **brainstorming**: return to brainstorming's Phase 5 transition (brainstorming presents its own options with updated PRD context).
3. If invoked **standalone**: present options:
   - Continue to technical planning
   - Spike something else
   - I'll take it from here (exit)

## Multiple Spikes

When brainstorming identifies several spike-worthy questions:

1. **Scope all spike items upfront.** Present the list. Identify dependencies between spikes (e.g., "we need to validate the interaction model before spiking the detail flow").
2. **Recommend an order** based on dependencies, or ask the user to pick.
3. **Execute one at a time.** Each spike: scope → worktree → build → feedback → conclude → update PRD.
4. **Each spike updates the PRD**, so later spikes benefit from earlier findings.
5. **Exit ramp between spikes.** After each concludes: "Spike A complete. PRD updated. Ready to spike B, or return to brainstorming?" The user might learn enough from spike A to skip B entirely.

Each spike gets its own doc, its own worktree, its own branch.

## When the Spike Invalidates the Direction

If the spike reveals that the PRD's chosen direction is fundamentally wrong — not just "R5 needs tweaking" but "Direction A doesn't work, we should go with B" — this is a substantial PRD rewrite that cascades across Chosen Direction, Requirements, Scope, and Boundaries.

Don't try to patch the PRD inline during wrap-up. Instead:

1. Document the findings in the spike doc: what was tried, why the direction failed.
2. Flag it to the user: "This spike suggests the chosen direction may need to change. That's a bigger update than a requirement tweak."
3. Recommend returning to brainstorming to revisit the direction with the spike findings as input. Brainstorming can update the PRD's Chosen Direction, cascade the changes to requirements and scope, and re-review if needed.

## When Things Go Wrong

**Stop and ask for clarification when:**
- The validation goal is unclear — what exactly are we trying to learn?
- The system state makes spiking impractical — explain why and suggest alternatives
- The spike isn't converging after 2-3 iterations — the question may be too broad
- Worktree creation fails — check disk space, branch conflicts, or existing worktrees. Don't retry blindly; diagnose the issue first.

**If a spike doesn't help:**
- Document what was tried and why it was inconclusive
- Don't force conclusions — carry the uncertainty forward
- The user may decide to: try a different approach to the spike, defer the question, or proceed with the uncertainty accepted

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Building production-quality code in a spike | Deliberately rough — no tests, no error handling. It's throwaway. |
| Spiking on the main or feature branch | Always use a worktree. Spike code should never mix with real work. |
| Open-ended "what do you think?" feedback | Targeted questions tied to the validation goal |
| Updating PRD with "see spike doc" as rationale | Full reasoning in the PRD — it must be self-sufficient for downstream stages |
| Forcing conclusions from an inconclusive spike | Document what was tried, carry the uncertainty forward |
| Deleting the spike worktree before the spike is complete | Worktree persists until the user is done — the spike skill owns the lifecycle |
| Scope creep — adding features beyond the validation goal | Build the minimum to answer the question. If new questions emerge, scope them as separate spikes. |
| Spiking questions that research could answer | If the answer exists somewhere, use `iterative:research` instead |

## Transition Points

**Always present options to the user at transition points** — never just print options as text.

After each spike concludes, present options:
- Spike next item (if multiple were scoped)
- Return to brainstorming (if invoked from brainstorming)
- Continue to technical planning
- Spike something else
- I'll take it from here (exit)

After each build-feedback round, present options:
- Iterate — refine based on feedback
- Conclude — enough was learned
- Abandon — the spike isn't helping
- Pause — park and come back later

## Additional Resources

### Reference Files

For templates and detailed guidelines, consult:
- **`references/spike-template.md`** — Spike document template with section descriptions and acceptance guidelines
