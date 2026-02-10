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
3. **Throwaway code, durable docs** — In-codebase spike code goes in a separate worktree and is deleted when the spike ends. Spike docs and PRD updates go on the original branch and persist. Static HTML prototypes are preserved in the spike directory by default.
4. **Spike doc captures the journey; PRD captures conclusions** — If a PRD exists, it gets updated with full rationale — self-sufficient for downstream stages without needing to read the spike doc. For standalone spikes, the spike doc itself is the primary output.
5. **User drives iteration** — Build, present, get feedback, iterate. The user decides when they've seen enough.

## Workflow

### Phase 0: Detect Resume

1. Scan `docs/spikes/*/spike.md` for documents with `Status: In Progress`.
2. For each, check if the spike doc records a branch. If so, check if that branch has a worktree (`git worktree list`).
3. If active spikes found, present them:
   - Active spikes with worktrees: name, validation goal, worktree path
   - Static HTML spikes (no worktree expected): name, validation goal, prototypes path
   - Spike docs that reference a worktree but none exists: flag the inconsistency
4. Ask the user: resume an existing spike, or start new?
5. If resuming: read the spike doc's Progress section. If the spike has a worktree, switch to it. Continue from Phase 3.
6. If starting fresh or no active spikes: proceed to Phase 1.

### Phase 1: Scope the Spike

**What to validate**

1. **Identify what to validate.** If invoked from brainstorming, the open questions provide context. If standalone, ask the user what they want to validate.
2. **Map to requirements.** If a PRD exists, connect the spike to specific requirements or decisions being validated.
3. **Define the validation goal.** What are we trying to learn? What outcome would change direction? Frame it as understanding to gain, not a decision to make (see spike doc template for acceptance guidelines).

**How to build it**

4. **Determine spike medium.** First assess: can we spike within the existing system? (Relevant modules exist and work.)

   - **If no** (greenfield, or relevant parts aren't built yet): default to **static HTML** and proceed. In-codebase isn't viable, so no need to ask.
   - **If yes**: ask the user which medium fits:

   | Medium | When it fits |
   |---|---|
   | **In-codebase** | Validating behavior that depends on real data, system integration, or existing UI. Uses a worktree. Code is throwaway. |
   | **Static HTML** | Validating visual design, UX flow, interaction feel, or comparing multiple variants side-by-side. Self-contained HTML files in the spike directory. |
   | **Both** | Some questions need real system context, others need rapid visual exploration. Worktree for integration, static HTML for visual variants. |

   Default recommendation: if the validation goal is primarily visual/UX and doesn't need live data, suggest static HTML.

5. **Discuss approaches.** Ask whether the user wants to explore multiple approaches upfront or start with one. If multiple, note the planned variants. Either way, additional approaches can always be added later during Phase 3 — this sets initial intent, not a rigid plan.

**Document and confirm**

6. **Create the spike doc on the original branch.** Use the template in `references/spike-template.md`. Save to `docs/spikes/YYYY-MM-DD-<topic>/spike.md` (ensure directory exists). Fill in Context, Validation Goal, and Approach. Status: In Progress. Create this before Phase 2 setup — the spike doc is a durable artifact that belongs on the original branch, not a throwaway spike branch.
7. **Present the scope to the user.** What we're validating, how we'll build it, what we're deliberately leaving out. Get confirmation before setup.

### Phase 2: Setup

1. **If the spike includes in-codebase work:** Invoke the `git-worktree` skill with branch name `spike/<topic>`. In-codebase spike code is throwaway and should not mix with feature or main branch work. Record worktree info in the spike doc's Spike Code section. A single worktree can hold multiple approach variants — use separate files, components, or routes so variants coexist and are independently runnable.
2. **If the spike includes static HTML prototypes:** Create `docs/spikes/YYYY-MM-DD-<topic>/prototypes/` on the original branch. HTML prototypes live alongside the spike doc, not in a worktree.
3. **Commit durable artifacts as they're written.** Spike doc, HTML prototypes, and upstream doc updates live on the original branch — commit them incrementally, don't leave them as uncommitted changes. This protects against accidental loss from stash, reset, or checkout operations on the original branch. Small, frequent commits are fine; the "In Progress" status makes it clear the spike is still in flight.
4. **Minimal setup only.** No test infrastructure, no CI config. Just enough to build and demonstrate.

### Phase 3: Build and Validate (repeat)

1. **Build the minimum** to validate the goal. This is deliberately rough — no tests, no error handling, no edge cases. If it validates the question, it's enough.
   - **For static HTML prototypes:** Each file should be self-contained (inline styles and scripts). Name files descriptively: `v1-sidebar-nav.html`, `v2-top-nav.html`. Create multiple variants when comparing approaches — this is a key advantage of the static HTML medium.
   - **For in-codebase variants:** Build each approach as separate files, components, or routes within the same worktree so the user can compare them side-by-side in the running app (e.g., `/nav-v1` and `/nav-v2`, or toggling between components).
2. **Present to the user.** How to experience the spike depends on what was built — open a file in a browser, run a server, execute a command, walk through the behavior. Be specific about how the user can see or interact with it.
3. **Gather feedback.** This is a dialogue, not a single round of questions.
   - Start with 1-2 targeted questions tied to the validation goal. Not open-ended "what do you think?" — specific questions. Examples:
     - "Does this drag interaction feel natural, or does it fight you?"
     - "Is this the information hierarchy you expected on this screen?"
     - "When you [performed action], was the result what you anticipated?"
   - Let the user respond freely — they may raise points you didn't ask about.
   - Follow up on their responses. Dig into what's working and what isn't.
   - Continue until the user's reaction is clear. Don't rush to the "what's next" options.
4. **Update the spike doc's Progress section** with a brief note: what was built, key feedback, what's next. Write this to the original branch path, not the worktree — the spike doc's canonical location is on the original branch.
5. **User chooses:**
   - **Iterate** — refine the current approach based on feedback, return to step 1
   - **Try a different approach** — keep the current variant, build an alternative alongside it. For static HTML, add a new file in `prototypes/`. For in-codebase, add new files/routes in the same worktree.
   - **Conclude** — enough was learned, proceed to Phase 4
   - **Abandon** — the spike isn't helping, proceed to Phase 4 with inconclusive findings
   - **Pause** — ensure Progress section is current. If a worktree exists, keep it. Resume detection (Phase 0) will find this spike in a future session.

### Phase 4: Wrap Up

1. **Finalize the spike doc:**
   - Write Findings: what was learned, what was confirmed, what surprised, what didn't work
   - Write Decisions: what changed, what was validated, requirement confirmations or changes
   - If the spike was abandoned/inconclusive: document what was tried and why it didn't resolve the uncertainty. Carry the question forward.
   - Remove the Progress section (fold relevant content into Findings)
   - Set Status to `Complete` or `Abandoned` based on how the spike concluded

2. **Propose upstream doc updates.** If a PRD exists, propose specific changes using the mapping in `references/prd-update-guide.md`. If no PRD or tech plan exists (standalone spike), skip to step 5.

3. **User approves** changes before they're applied. Present proposed changes clearly — what will change and why.

4. **Apply approved changes** to the PRD (and tech plan if applicable) on the original branch. Each change in the PRD should include enough context that someone reading it understands the decision without reading the spike doc. The spike doc updates (Findings, Decisions, Impact, Status) also go on the original branch.

5. **Write Impact on Upstream Docs section** in spike doc: summarize what was changed in upstream docs, or note "Standalone spike — no upstream docs."

6. **Clean up throwaway artifacts.**
   - **In-codebase spikes:** Remove the spike worktree and delete the spike branch. All durable artifacts (spike doc, PRD updates) are already on the original branch — nothing is lost. Use the `git-worktree` skill or `git worktree remove` directly.
   - **Static HTML prototypes:** Preserved in `docs/spikes/` alongside the spike doc. No cleanup needed.

### Phase 5: Handoff

1. If **multiple spikes were scoped** (e.g., brainstorming identified several spike-worthy questions): "Spike complete. PRD updated. Ready to spike [next item], or done with spiking?"
2. If invoked from **brainstorming**: return to brainstorming's Phase 5 transition (brainstorming presents its own options with updated PRD context).
3. If invoked **standalone**: present an interactive choice (e.g., `AskUserQuestion` in Claude Code):
   - Continue to technical planning
   - Spike something else
   - I'll take it from here (exit)

## Edge Cases

For handling unusual situations during spikes, consult `references/edge-cases.md`:
- When the spike invalidates the PRD direction
- Coordinating multiple spikes from brainstorming
- When things go wrong (unclear goals, non-converging spikes, worktree failures)
- Cleanup issues (uncommitted worktree changes, missing worktrees)

## Anti-Patterns

Consult `references/anti-patterns.md` for common mistakes. Key ones: don't build production-quality code in a spike, don't spike on the main branch, don't put HTML prototypes in the worktree, and don't leave spike worktrees around after the spike ends.

## Transition Points

**Always present options to the user at transition points using the interactive question tool** (e.g., `AskUserQuestion` in Claude Code) — never just print options as text or end the turn without presenting a choice. Present the options defined in Phase 3 step 5 (build-feedback rounds) and Phase 5 (handoff).

## Additional Resources

### Reference Files

For templates, detailed guidelines, and edge cases, consult:
- **`references/spike-template.md`** — Spike document template with section descriptions and acceptance guidelines
- **`references/prd-update-guide.md`** — Mapping of spike findings to PRD updates
- **`references/anti-patterns.md`** — Common anti-patterns to avoid during spikes
- **`references/edge-cases.md`** — Direction invalidation, multiple spikes, and error handling
