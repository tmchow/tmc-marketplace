---
name: iterative:implement
description: Execute an implementation plan with TDD and code review. This skill should be used when the user says "implement the plan", "start building", or has tasks ready to execute.
allowed-tools: Glob, Grep, Read, Bash(hzl *), Task
---

# Executing Work

Execute implementation plans with TDD cycle, code review, and task tracking.

## When to Use

- After `plan-to-tasks` skill creates tasks
- When tasks are ready to execute (HZL or TodoWrite)
- Can be invoked standalone if a plan document exists

## Key Principles

1. **Read the plan first** - Load and understand the technical plan before executing anything
2. **One commit per subtask** - Atomic commits after each RED/GREEN/REFACTOR cycle
3. **Review after each parent** - Invoke `code-review` skill before moving to next parent
4. **Stop when blocked** - Ask for help rather than guessing when stuck

## Workflow

```
Phase 0: Detect Resume
├── Check for in-progress HZL tasks or TodoWrite items
├── If resuming:
│   ├── Load the plan document, summarize current state
│   ├── Show completed vs remaining subtasks
│   └── Continue from next incomplete subtask
└── If starting fresh: proceed to Phase 1

Phase 1: Setup
├── Read the technical plan document
├── Explore the codebase for relevant context:
│   ├── Files and modules referenced in the plan
│   ├── Test patterns and frameworks in use
│   └── Existing conventions to follow
├── Use AskUserQuestion for execution preference:
│   ├── A) Execute all tasks, report when done (default)
│   ├── B) Pause after each parent task for feedback
│   └── C) Pause after each subtask for feedback
├── Choose execution strategy (see section below):
│   └── Analyze plan for file overlap, recommend strategy, user confirms
├── Workspace isolation check:
│   ├── In worktree already? → proceed (isolated)
│   ├── On default branch? → offer: worktree (recommended), branch, or consent for main
│   └── On feature branch? → offer: worktree (if human also working), or continue here
├── Invoke `git-worktree` skill if needed
└── Identify task source:
    ├── Check if HZL tasks exist (run `hzl task list`)
    ├── Otherwise, check for TodoWrite tasks
    └── If no tasks in either system:
        ├── Look for a tech plan: check conversation context for referenced plans,
        │   then scan docs/plans/ for recent plan files
        ├── If plan found → invoke `plan-to-tasks` skill to create tasks, then continue
        ├── If no plan found → ask user for a plan document path
        └── If no plan exists at all → redirect to `iterative:tech-design` skill

Phase 2: Execute (repeat per parent)
├── For each subtask:
│   ├── Spawn `task-worker` agent (sequential) or teammate (Agent Teams)
│   ├── Worker executes TDD cycle:
│   │   ├── RED: Write failing test
│   │   ├── GREEN: Implement to pass
│   │   ├── REFACTOR: Clean up
│   │   └── Commit: "feat(scope): [subtask]"
│   └── Wait for completion before dependent subtasks
├── Mark parent complete in task system
└── Invoke `code-review` skill (1+ rounds, fix issues found)

Phase 3: Finish
├── Run full test suite
├── Invoke `finishing-work` skill
└── Report completion (see references/progress-template.md)
```

## Execution Strategy

If Agent Teams is not enabled for the session, use sequential execution with `task-worker` agents — no choice needed.

If Agent Teams is enabled, offer it as an option. **When the user chooses Agent Teams, tell them exactly this:**

> Using Agent Teams 🐝 — subtasks will be assigned to teammates with dependency-based coordination.

Agent Teams uses a shared task list with automatic dependency management — teammates can only claim tasks whose dependencies are resolved. This makes it safe even when subtasks touch overlapping files, as long as the dependency graph is set up correctly.

**How to set up the dependency graph:**
1. Extract file paths per subtask from the tech plan document (the `**Files:**` fields) — this is the most efficient source since Phase 1 already reads the plan. If no plan document exists, fall back to querying task descriptions from HZL or TodoWrite.
2. Where subtasks touch overlapping files, add a dependency between them (so they run sequentially via the task list)
3. Where subtasks have no file overlap and no logical dependency, leave them independent (teammates can claim them in parallel)
4. If file paths are missing, add dependencies conservatively (default to sequential for those subtasks)

**Present the analysis to the user:** Show which subtasks can run in parallel vs which are sequenced due to file overlap or dependencies. Let the user confirm or adjust before proceeding.

### Sequential (default)

Execute one `task-worker` agent at a time. Always available, no special setup required.

- No file conflict risk — clear ownership at any time
- Easier to debug when something fails
- Lower token cost
- Works correctly in any git state

### Agent Teams

Assign subtasks to teammates via a shared task list. Dependencies between overlapping subtasks are enforced automatically — teammates cannot claim a task until its dependencies are resolved.

- Independent subtasks run in parallel, overlapping subtasks run sequentially
- Higher token cost — each teammate is a separate Claude instance
- Dependency graph must be set up correctly before starting
- Faster overall when the plan has independent modules

## Commit Pattern (RGRC)

**R**ed → **G**reen → **R**efactor → **C**ommit

- 1 commit per completed subtask
- Commit only after REFACTOR step, when tests pass
- Never commit with failing tests

## Code Review After Parent

After completing all subtasks in a parent:
1. Mark parent complete in task system
2. Invoke `code-review` skill
3. Fix any issues found
4. Continue to next parent (or finish if done)

## Plan Adjustment

If reality diverges from the plan during implementation:

- **Minor adjustments** (different file path, small API change): update the plan document in place and continue
- **Significant divergence** (missing requirement, wrong approach): stop, report the divergence, and ask the user whether to update the plan or continue as-is
- **Blocked by external dependency**: mark the subtask as blocked, skip to next unblocked subtask, and report

## Stop Conditions

Stop and ask for help when:
- Subtask instructions are unclear
- Tests fail and fix isn't obvious
- Missing dependency or blocker
- Verification fails repeatedly (3x)
- Human comment on task requires response

## Error Handling

If a subtask fails:
1. Report the failure clearly
2. Show what was attempted
3. Ask user how to proceed:
   - Retry with different approach
   - Skip and continue
   - Stop execution

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Starting implementation without reading the plan | Read and understand the plan document first |
| Parallelizing subtasks that touch the same files | Only parallelize tasks with clear file boundaries |
| Committing with failing tests | Only commit after REFACTOR step, all tests green |
| Pushing through when blocked or confused | Stop and ask for help |
| Skipping code review to save time | Review after every parent — catching issues early saves time overall |
| Modifying the plan silently | Report divergence and get user agreement before changing direction |

## Transition Points

**Always use AskUserQuestion for transition points** — never just print options as text.

After all tasks complete, use AskUserQuestion with options:
- Continue to `finishing-work` skill (recommended)
- I'll handle PR/merge myself (exit)

## Additional Resources

### Reference Files

For templates and detailed guidelines, consult:
- **`references/progress-template.md`** - Execution progress report format
