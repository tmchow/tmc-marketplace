---
name: git-worktree
description: Internal skill for workspace isolation. Detects current git state and offers worktree/branch options to ensure agent has isolated workspace. Called by iterative:implement, not user-invocable.
user-invocable: false
allowed-tools: Bash(git status), Bash(git branch *), Bash(git worktree *), Bash(git checkout -b *), Bash(git remote *), Task
---

# Git Worktree (Workspace Isolation)

Ensures agent has an isolated workspace to avoid conflicts with human work.

## When Called

- At the start of `iterative:implement` skill
- When workspace isolation is needed
- Not directly invocable by users

## Detection

```bash
# Check if already in worktree
in_worktree = git rev-parse --git-dir contains "/worktrees/"

# Get current branch
current_branch = git branch --show-current

# Get default branch
default_branch = git remote show origin | grep "HEAD branch"
```

## Scenario Handling

| Scenario | Detection | Options |
|----------|-----------|---------|
| Already in worktree | `git_dir` contains `/worktrees/` | Proceed (already isolated) |
| On default branch (main/master) | `current == default` | A) Create worktree (recommended) B) Create branch here C) Continue on main (requires consent) |
| On feature branch | `current != default` | A) Create worktree (if human also working) B) Continue here |

## Why Worktree is Recommended

- Agent gets isolated directory
- Human can continue working in original directory
- No file conflicts between human and agent work
- Clean separation of concerns

## Workflow

```
1. Detect current state
   ├── Check if in worktree
   ├── Get current branch
   └── Get default branch

2. If already in worktree:
   └── Report "Already in isolated worktree" → proceed

3. If on default branch:
   └── Present options:
       A) Create worktree at ../[repo]-[branch] (recommended)
       B) Create branch here and continue
       C) Continue on main (requires explicit consent)

4. If on feature branch:
   └── Present options:
       A) Create worktree (if human may also be working here)
       B) Continue on this branch

5. Execute choice
   ├── If worktree: spawn branch-setup-worker
   ├── If new branch: git checkout -b [branch-name]
   └── If continue: proceed with warning

6. Verify isolation
   └── Report: "Ready on branch [name] in [directory]"
```

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
