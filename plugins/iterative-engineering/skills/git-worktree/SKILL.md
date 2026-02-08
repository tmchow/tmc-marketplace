---
name: git-worktree
description: Internal skill for workspace isolation. Detects current git state and offers worktree/branch options. Called by iterative:implementing, not user-invocable.
user-invocable: false
---

# Git Worktree (Workspace Isolation)

Ensures agent has an isolated workspace to avoid conflicts with human work.

## When Called

- At the start of `iterative:implementing` skill
- At the start of `iterative:spike` skill (branch convention: `spike/<topic>`)
- When workspace isolation is needed
- Not directly invocable by users

## Workflow

1. **Sync with remote.** Pull latest from default branch.
2. **Detect current state.** Check if in worktree (`git rev-parse --git-dir` contains `/worktrees/`), get current branch (`git branch --show-current`), get default branch (`git remote show origin | grep "HEAD branch"`).
3. **Choose workspace** based on current state:
   - Already in worktree: confirm it's for this feature, then proceed
   - On default branch: ask the user — A) Create worktree (recommended), B) Create branch, C) Continue on main (requires explicit consent)
   - On feature branch: ask the user — A) Continue on this branch, B) Create new worktree
4. **Execute choice.** If worktree: `git worktree add ../[repo]-[branch] -b [branch]`. If new branch: `git checkout -b [branch-name]`. If continue: proceed.
5. **Verify.** Report: "Ready on branch [name] in [directory]"

## Worktree Creation

When creating a worktree:
1. Generate branch name from feature/task context
2. Create worktree: `git worktree add ../[repo]-[branch] -b [branch]`
3. Copy necessary files (.env, etc.) if they exist
4. Verify worktree is functional

## Output

Returns to calling skill:
- Branch name
- Directory path (if worktree created)
- Isolation status confirmed
