---
name: finishing-work
description: Use when completing development work. Runs final test verification, offers optional code review, then presents options for push/PR/keep/discard. Handles PR creation following repo conventions.
allowed-tools: Glob, Grep, Read, Bash(git status), Bash(git diff *), Bash(git add *), Bash(git commit *), Bash(gh pr create *), Bash(gh pr view *), Task
---

# Finishing Work

Completes development with verification, optional review, and PR creation.

## When to Use

- After executing-work completes all tasks
- When you're ready to create a PR
- When you want to finish a feature branch
- Can be invoked standalone on any branch

## Workflow

```
Phase 1: Final Verification
├── Run full test suite
├── If tests fail → stop, report failures
└── Check for uncommitted changes → commit or stash

Phase 2: Optional Code Review
├── Ask: "Run full code review before finishing?"
│   ├── A) Yes, full review (recommended)
│   ├── B) Quick review
│   └── C) Skip review
├── If review: invoke code-review skill (1+ rounds)
└── Continue when review complete or skipped

Phase 3: Context Summary
├── Determine base branch (main/master/develop)
├── Check if in worktree
└── Report: N commits, files changed, branch info

Phase 4: Present Options
├── A) Push + PR (recommended)
│   └── Creates new PR, or shows existing if one exists
├── B) Push only
├── C) Keep branch, don't push
└── D) Discard work (typed confirmation required)

Phase 5: Execute

Option A - Push + PR:
├── Push branch with -u
├── Run `gh pr create`
│   └── If PR exists: shows existing PR URL
│   └── If no PR: creates one following repo conventions
└── Return PR URL

Option B - Push only:
└── Push branch, report remote URL

Option C - Keep:
└── Report branch preserved locally

Option D - Discard:
├── Require typed confirmation: "discard [branch-name]"
└── Delete branch (and worktree if applicable)

Phase 6: Cleanup
├── If in worktree and work done → offer removal
└── Switch to base branch if not in worktree
```

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
## Finishing Work

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
