# Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Building production-quality code in a spike | Deliberately rough — no tests, no error handling. It's throwaway. |
| Spiking on the main or feature branch | In-codebase spikes always use a worktree. Static HTML prototypes go in `docs/spikes/` on the original branch. |
| Putting HTML prototypes in the worktree | HTML prototypes are durable artifacts — they belong in `docs/spikes/YYYY-MM-DD-<topic>/prototypes/`, not the throwaway worktree. |
| Leaving spike worktrees around after the spike ends | Phase 4 cleanup removes the worktree and branch. All durable artifacts are on the original branch — the worktree is pure throwaway. |
| Open-ended "what do you think?" feedback | Targeted questions tied to the validation goal, followed by open dialogue |
| Treating feedback as a single round | Feedback is a dialogue — ask, listen, follow up. Don't rush to "what's next" after one question. |
| Updating PRD with "see spike doc" as rationale | Full reasoning in the PRD — it must be self-sufficient for downstream stages |
| Forcing conclusions from an inconclusive spike | Document what was tried, carry the uncertainty forward |
| Deleting the spike worktree before the spike is complete | Worktree persists until Phase 4 cleanup — the spike skill owns the lifecycle |
| Scope creep — adding features beyond the validation goal | Build the minimum to answer the question. If new questions emerge, scope them as separate spikes. |
| Spiking questions that research could answer | If the answer exists somewhere, use `iterative:research` instead |
