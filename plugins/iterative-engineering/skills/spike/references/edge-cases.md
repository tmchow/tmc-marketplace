# Edge Cases and Special Scenarios

## When the Spike Invalidates the Direction

If the spike reveals that the PRD's chosen direction is fundamentally wrong — not just "R5 needs tweaking" but "Direction A doesn't work, we should go with B" — this is a substantial PRD rewrite that cascades across Chosen Direction, Requirements, Scope, and Boundaries.

Don't try to patch the PRD inline during wrap-up. Instead:

1. Document the findings in the spike doc: what was tried, why the direction failed.
2. Flag it to the user: "This spike suggests the chosen direction may need to change. That's a bigger update than a requirement tweak."
3. If invoked from brainstorming: recommend returning to brainstorming to revisit the direction with the spike findings as input.
4. If standalone: present the finding and let the user decide how to proceed. Don't prescribe a specific workflow — they may want to update the PRD themselves, discuss with their team, or take a different approach entirely.

## Multiple Spikes

When brainstorming identifies several spike-worthy questions:

1. **Scope all spike items upfront.** Present the list. Identify dependencies between spikes (e.g., "we need to validate the interaction model before spiking the detail flow").
2. **Recommend an order** based on dependencies, or ask the user to pick.
3. **Execute one at a time.** Each spike: scope → setup → build → feedback → conclude → update PRD.
4. **Each spike updates the PRD**, so later spikes benefit from earlier findings.
5. **Exit ramp between spikes.** After each concludes: "Spike A complete. PRD updated. Ready to spike B, or return to brainstorming?" The user might learn enough from spike A to skip B entirely.

Each spike gets its own directory, its own doc, and — for in-codebase spikes — its own worktree and branch.

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
