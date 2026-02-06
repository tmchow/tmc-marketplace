---
name: implement
description: Use when executing an implementation plan. Handles workspace isolation, spawns task-workers sequentially for TDD cycle, runs code review after parent tasks, and hands off to finishing-work. Works with HZL or TodoWrite tasks.
allowed-tools: Glob, Grep, Read, Bash(hzl *), Bash(git status), Bash(git diff *), Bash(git add *), Bash(git commit *), TodoWrite, AskUserQuestion, Task
---

# Executing Work

Executes implementation plans with TDD cycle, code review, and task tracking.

## When to Use

- After `plan-to-tasks` creates tasks
- When you have tasks ready to execute
- Can work with HZL tasks or TodoWrite tasks

## Task System

If project uses HZL for task tracking → use HZL tasks
Otherwise → use TodoWrite tasks

## Execution Preferences

Ask upfront which mode user prefers:
- **A) Execute all tasks, report when done** (default)
- **B) Pause after each parent task for feedback**
- **C) Pause after each subtask for feedback**

## Workflow

```
Phase 1: Setup
├── Clarify plan (ask questions upfront)
├── Ask execution preference (A/B/C)
├── Workspace isolation check:
│   ├── In worktree already? → proceed (isolated)
│   ├── On default branch? → offer: worktree (recommended), branch, or consent for main
│   └── On feature branch? → offer: worktree (if human also working), or continue here
├── Invoke git-worktree skill if needed
└── Identify task source:
    ├── HZL (if project uses HZL for task tracking)
    └── TodoWrite (otherwise)

Phase 2: Execute (repeat per parent)
├── For each subtask SEQUENTIALLY:
│   ├── Spawn task-worker agent
│   ├── Worker executes TDD cycle:
│   │   ├── RED: Write failing test
│   │   ├── GREEN: Implement to pass
│   │   ├── REFACTOR: Clean up
│   │   └── Commit: "feat(scope): [subtask]"
│   └── Wait for completion before next subtask
├── Mark parent complete
└── Invoke code-review (1+ rounds)

Phase 3: Finish
├── Run full test suite
├── Invoke finishing-work skill
└── Report completion
```

## Sequential Execution

**One task-worker at a time** to avoid file conflicts.

This is safer and simpler than parallel execution:
- No merge conflicts between workers
- Clear ownership of files at any time
- Easier to debug when something fails
- Works correctly in any git state

## Commit Pattern (RGRC)

**R**ed → **G**reen → **R**efactor → **C**ommit

- 1 commit per completed subtask
- Commit only after REFACTOR step, when tests pass
- Never commit with failing tests
- Commits are squashed on merge to main (clean history)

## Stop Conditions

Stop and ask for help when:
- Subtask instructions are unclear
- Tests fail and fix isn't obvious
- Missing dependency or blocker
- Verification fails repeatedly (3x)
- Human comment on task requires response

## Code Review After Parent

After completing all subtasks in a parent:
1. Mark parent complete in task system
2. Invoke code-review skill
3. Fix any issues found
4. Continue to next parent (or finish if done)

## Output Format

```markdown
## Execution Progress

### Setup
- Workspace: [worktree/branch/main]
- Task source: [HZL/TodoWrite]
- Execution mode: [A/B/C]

### Parent 1: [Name]
- [x] Subtask 1.1 - committed abc123
- [x] Subtask 1.2 - committed def456
- [x] Subtask 1.3 - committed ghi789
- Code review: PASS

### Parent 2: [Name]
- [x] Subtask 2.1 - committed jkl012
- [ ] Subtask 2.2 - in progress...

---
**Progress:** 5/8 subtasks complete
```

## Transition Points

After all tasks complete:
```
Implementation complete, tests passing. What next?
├── A) Continue to finishing-work (recommended)
├── B) I'll handle PR/merge myself (exit)
```

## Error Handling

If a subtask fails:
1. Report the failure clearly
2. Show what was attempted
3. Ask user how to proceed:
   - Retry with different approach
   - Skip and continue
   - Stop execution
