---
name: implementation-wrapup
description: Complete a feature branch with test verification and PR creation. This skill should be used when the user says "finish up", "create a PR", "wrap up the feature", or when invoked by the iterative:implementing skill after all tasks are complete.
---

# Implementation Wrapup

Completes development with verification, optional review, and PR creation.

## When to Use

- After `iterative:implementing` skill completes all tasks
- When you're ready to create a PR
- When you want to finish a feature branch
- Can be invoked standalone on any branch

## Workflow

### Phase 1: Final Verification

1. Run full test suite. If tests fail, stop and report failures.
2. Check for uncommitted changes — commit or stash.

### Phase 2: Optional Code Review

When invoked from `iterative:implementing`, skip this phase — all code reviews are already complete.

When invoked standalone:
1. Present an interactive choice to the user (e.g., `AskUserQuestion` in Claude Code): A) Full code review (recommended), B) Quick review, C) Skip review.
2. If review: invoke `code-review` skill (1+ rounds).
3. Continue when review complete or skipped.

### Phase 3: Context Summary

1. Determine base branch (main/master/develop).
2. Check if in worktree.
3. Report: N commits, files changed, branch info.

### Phase 4: Present Options

Present an interactive choice to the user (e.g., `AskUserQuestion` in Claude Code):
- A) Push + PR (recommended) — creates new PR, or shows existing if one exists
- B) Push only
- C) Keep branch, don't push
- D) Discard work (typed confirmation required)

### Phase 5: Execute

**Option A — Push + PR:** Push branch with `-u`, run `gh pr create`. If PR exists, show existing PR URL. If no PR, create one following repo conventions. Return PR URL.

**Option B — Push only:** Push branch, report remote URL.

**Option C — Keep:** Report branch preserved locally.

**Option D — Discard:** Require typed confirmation ("discard [branch-name]"). Delete branch (and worktree if applicable).

### Phase 6: Cleanup

1. If in worktree and work done, offer removal.
2. Switch to base branch if not in worktree.

## Safeguards

- **Never skip test verification** - tests must pass before any option
- **Never push with failing tests** - stop and report failures
- **Never discard without typed confirmation** - require exact branch name
- **git push prompts user** - not pre-approved, user confirms before pushing

## PR Description

When creating a PR:
- Follow repo conventions from AGENTS.md/CLAUDE.md
- If no conventions: use conventional commits style
- Generate description from commit messages
- Keep title succinct and descriptive
- Do NOT include HZL task IDs in PR description

## Output Format

```markdown
## Implementation Wrapup

### Verification
- Tests: PASS (N tests)
- Uncommitted changes: None / Committed

### Code Review
- Status: Completed / Skipped
- Issues addressed: N

### Summary
- Branch: feature/my-feature
- Base: main
- Commits: N
- Files changed: M

### Options
A) Push + Create PR (recommended)
B) Push only
C) Keep branch locally
D) Discard work

What would you like to do?
```

## After Completion

Returns:
- PR URL (if created)
- Branch status
- Cleanup status (worktree removed if applicable)
