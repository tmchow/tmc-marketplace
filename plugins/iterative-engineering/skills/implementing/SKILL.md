---
name: iterative:implementing
description: This skill should be used when the user says "implement the plan", "start building", "start implementing", "execute the plan", or has a technical plan ready to implement.
---

# Executing Work

Read the plan critically, create tasks, and implement with TDD, code review, and continuous testing. The plan is your guide — it contains the decisions, patterns, and test scenarios that drive implementation.

## When to Use

- After `iterative:tech-planning` skill completes a plan
- When a plan document exists and is ready to implement
- When tasks already exist (HZL or built-in tasks) from a prior session
- Can be invoked standalone with a plan document path

## Key Principles

1. **The plan is your guide** — Read referenced files and patterns, use the plan's decisions to drive implementation
2. **Clarify before building** — Ask questions now, not after building the wrong thing
3. **Test as you go** — Run tests after each change, not at the end
4. **Review at the right scope** — Incremental reviews for large plan sections, final review after each section, user chooses which severities to fix
5. **Stop when blocked** — Ask for help rather than guessing

## Workflow

### Phase 0: Detect Resume

1. Check for in-progress HZL tasks or built-in task items related to this plan.
2. If tasks exist and work is in progress: load the plan document, summarize current state, show completed vs remaining subtasks, continue from next incomplete subtask (skip to Phase 2).
3. If no tasks exist: proceed to Phase 1 — **even if you have prior conversation context.** Having discussed the plan in a previous session is not the same as having set up tasks and workspace. Phase 1 setup (task creation, HZL detection, workspace isolation) must run before any implementation begins.

### Phase 1: Understand and Setup

1. **Find and read the plan document completely.** Check conversation context for referenced plans, scan `docs/plans/` for recent plan files. If no plan found, ask user for path. If no plan exists, ask the user: A) Create a tech plan first (recommended), B) I'll provide the plan path. If tech plan: invoke `iterative:tech-planning` skill.
2. **Review critically.** If anything is unclear or ambiguous, ask now. Do not skip this — better to clarify now than build the wrong thing.
3. **Workspace isolation.** See Workspace Setup section.
4. **Create tasks from the plan.** See Task Creation section.
5. **Execution preference.** Ask the user to choose: A) Execute all tasks, report when done (default), B) Pause after each plan section for feedback, C) Pause after each subtask for feedback.

### Phase 2: Execute (repeat per plan section)

1. **Record section baseline.** Before starting each plan section, capture the current commit: `git rev-parse HEAD`. This SHA is the section's baseline — used to scope reviews to only this section's changes.
2. **Analyze dependency graph.** Using the plan's `**Depends on:**` and `**Files:**` fields, group the section's subtasks into execution batches — subtasks with no unmet dependencies form the next batch.
3. **Execute batch.** For each batch, spawn `task-worker` subagents concurrently for all subtasks in the batch. Each subagent receives:
   - Path to the tech plan document
   - Subtask number and title
   - Parent task context
   - Task system (HZL or built-in tasks) and task ID if HZL
4. Worker reads subtask from plan, loads referenced patterns, implements with TDD (tests first), commits, and updates task status (see task-worker agent for details).
5. **Wait for batch completion.** All subagents in the batch must finish before the next batch starts.
6. **Test verification gate.** After each batch completes, verify that feature subtasks produced test files. For each completed feature subtask, check: does the test file listed in the plan's `**Files:**` field exist, and does it contain tests matching the plan's `**Test scenarios:**`? If a feature subtask committed without tests, flag it immediately — do not continue to the next batch until resolved.
7. **Incremental review (large sections only).** If the plan section has more than 5 subtasks, automatically run a quick code review after each batch — this catches issues before subsequent batches build on flawed code. Scope the review to `git diff <section-baseline-sha>..HEAD`. If issues are found, present them with severity acceptance before continuing. If clean, continue to the next batch silently.
8. **Repeat** steps 3-7 for remaining batches.
9. Update plan document progress (mark completed items).
10. Mark section complete in task system.
11. **Section code review.** Run after all subtasks in the plan section are complete, regardless of whether incremental reviews occurred (see When to Review table for trivial exceptions). **Skip if this is the only section in the plan** — Phase 3's final review will cover the same code plus simplification changes, so a section-level review would be redundant. For multi-section plans: scope to `git diff <section-baseline-sha>..HEAD`. Pass the baseline SHA and plan context to the `code-review` skill. **Wait for the review to complete and fixes to land before moving on.** Do not run anything else in parallel with code review — it needs to see the final code.

### Phase 3: Finish

**Phase 3 steps are strictly sequential. Do not parallelize them** — each step depends on the output of the previous one.

1. Verify: all tasks complete, all section-level code reviews passed.
2. **Detect base branch.** `git rev-parse --verify origin/main >/dev/null 2>&1 && echo main || echo master`. Use this for all branch-level scoping in Phase 3.
3. **Simplification pass.** Get changed files with `git diff --name-only $(git merge-base HEAD <base>)..HEAD`. Spawn the `code-simplifier` agent with this file list. The agent applies behavior-preserving simplifications, runs tests, and commits separately. This is a single bounded pass — not a refactor. **Wait for simplification to complete before proceeding** — the final review must see simplified code.
4. **Final review offer.** Ask the user to choose: A) Full code review of complete work (recommended), B) Quick review, C) Skip to finish.
5. If review: invoke `code-review` skill with scope `git diff $(git merge-base HEAD <base>)..HEAD` (all branch changes including simplification).
6. **Severity acceptance (separate prompt).** If the review found issues at any severity, present severity acceptance (see Severity Acceptance section). This is its own prompt — do not combine it with next-step options, and do not skip it even when all issues are Medium/Low. "Clean" means zero findings at any severity. If no findings, skip to step 7.
7. **Next steps (separate prompt, after fixes land or user skipped fixes).** Ask the user to choose: A) Another review round, B) Wrap up and create PR, C) I'll handle PR/merge myself (exit). Do not recommend wrap-up if fixes were just applied — recommend **another round** to verify. Recommend **wrap up** only when zero findings or user chose to skip all fixes.
8. Repeat steps 5-7 if user chooses another round.

## Workspace Setup

Ensure the agent has an isolated workspace before creating tasks or writing code.

**First: sync with remote**
Pull the latest from the default branch before creating any branch or worktree.

**Then: check current state**

| Situation | Action |
|-----------|--------|
| Already in a worktree | Confirm it's for this feature, then proceed |
| On default branch | Ask the user: A) Create worktree (recommended), B) Create branch, C) Continue on main (requires explicit consent) |
| On a feature branch | Ask the user: A) Continue on this branch, B) Create new worktree |

Invoke the `git-worktree` skill if a worktree is needed.

## Task Creation

Task creation happens inside Phase 1, after the plan is read and clarified. This ensures the implementer understands the plan before tasks are locked in.

### Task System Selection

Check whether HZL is installed (e.g., `hzl status`) and the project uses HZL for task tracking (e.g., AGENTS.md/CLAUDE.md).

- **HZL not detected** → Use built-in task tracking automatically, no question needed
- **HZL detected** → Ask the user to choose:
  - HZL tasks (Recommended) — durable tracking with dependencies, persists across sessions
  - Built-in tasks — lightweight, session-scoped

### Parsing the Plan

The plan's standardized subtask format (numbered, with dependencies and files) maps directly to tasks:
- Plan sections → parent tasks
- Numbered subtasks → child tasks
- `Depends on` fields → task dependencies
- `Files` fields → task links (HZL) or description references (built-in tasks)

Show the proposed task structure to the user for approval before creating.

### Parent Task Descriptions

- Always link to the technical plan document
  - HZL: `-l docs/plans/[plan].md`
  - Built-in tasks: include plan file path in description
- **Single parent:** description includes the plan overview — what's being built and why
- **Multiple parents:** each describes its relationship to the feature and what subset of work it covers

### Subtask Descriptions

- Copy relevant plan prose into description
- Include file paths from the plan's `**Files:**` fields
- If very complex: summarize, reference section by name

## Commit Pattern

- 1 commit per completed subtask (default)
- Commit only when tests pass — never commit with failing tests
- Heuristic: can you write a meaningful commit message? If yes, commit. If it would be "WIP", group with the next related subtask.

## Code Review

### When to Review

| Trigger | Review Level |
|---------|-------------|
| **Section review** (after all subtasks in a plan section complete) | Full or Quick — based on scope of changes. **Skip if single-section plan** — Phase 3 final review covers it |
| **Incremental batch review** (sections with 6+ subtasks) | Quick review — lightweight check between batches |
| **Trivial section** (config, single-line, renaming only) | Skip review — note in progress report |

Assess scope to choose between full and quick: substantial feature work (multiple files, new logic) → full review via `code-review` skill. Moderate changes (few files, straightforward) → quick mode.

### Severity Acceptance

**This is its own prompt — do not combine it with next-step options.** Present severity acceptance whenever the review has findings at ANY severity, including Medium/Low-only reviews. Do not interpret "no Critical/High" as "clean" — clean means zero findings.

**When Critical or High issues exist:**

> Review found issues. How would you like to handle them?
> - **Fix Critical + High (Recommended)** — N Critical, N High
> - **Choose which severity levels to fix** — select from all levels
> - **Skip fixes**

If the user accepts the recommendation, fix Critical + High. If they choose, present a multi-select of severity levels that have findings:

> Which severity levels should be fixed? (select one or more)
> - [ ] Critical (N issues)
> - [ ] High (N issues)
> - [ ] Medium (N issues)
> - [ ] Low (N issues)

**When only Medium/Low issues exist (no Critical/High):**

> Review found N Medium and N Low issues. How would you like to handle them?
> - **Choose which severity levels to fix** — select from Medium, Low
> - **Proceed without fixes (Recommended)**

If the user chooses to fix, present the multi-select of severity levels with findings.

Fix only the selected severities. Next-step options come AFTER fixes land, as a separate prompt (Phase 3 step 7).

By the time implementing hands off to `implementation-wrapup`, all code reviews are complete. Wrapup skips its own review offer and handles verification, PR, and cleanup.

## Plan Adjustment

If reality diverges from the plan during implementation:

- **Minor adjustments** (different file path, small API change): update the plan document in place and continue. Note the change in the progress report.
- **Significant divergence** (missing requirement, wrong approach): stop and report the divergence. Ask the user to choose: A) Update the plan and continue, B) Continue as-is, C) Stop execution. If the divergence contradicts the PRD (not just the tech plan), update the PRD as well — it's the requirements source of truth for downstream validation.
- **Blocked by external dependency**: mark the subtask as blocked, skip to next unblocked subtask, and report.

## When Things Go Wrong

**Stop and ask for clarification (plain text, not structured options) when:**
- Subtask instructions are unclear — explain what's ambiguous
- Tests fail and fix isn't obvious — describe the failure and what was tried
- Missing dependency or blocker — report what's missing
- Verification fails repeatedly (3x) — report what was attempted
- Human comment on task requires response

**If a subtask fails:**
1. Report the failure clearly — what was attempted and what went wrong
2. Ask the user to choose: A) Retry with a different approach, B) Skip and continue to next subtask, C) Stop execution

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Jumping to code without reading plan context | Read each subtask's referenced files and patterns first |
| Skipping clarification to start faster | Ask questions now — building the wrong thing is slower |
| Creating tasks before understanding the plan | Read and clarify the plan, then create tasks |
| Committing with failing tests | Only commit when tests pass |
| Committing feature subtask without writing tests | TDD: write tests first from plan's test scenarios, then implement |
| Skipping Phase 1 because of prior conversation context | Prior context ≠ setup complete. If no tasks exist, run Phase 1 — HZL detection, task creation, workspace isolation |
| Pushing through when blocked | Stop and ask for help |
| Running code review in parallel with simplification or other code changes | Code review must see final code. Simplifier → wait → review. Never parallelize steps that change code with steps that review it |
| Full code review on trivial changes | Scale review to complexity — skip for config changes |
| Modifying the plan silently | Report divergence and get user agreement |
| Applying TDD rigidly to config/refactoring subtasks | TDD for feature work, verify for non-feature work |

## Transition Points

**Always present options to the user at transition points** — never just print options as text.

After simplification pass completes (Phase 3 step 4), present options:
- Full code review of complete work (recommended)
- Quick review
- Skip to finish

After review (or skip), present options:
- Another review round (recommended if Critical/High issues were just fixed)
- Wrap up and create PR (recommended otherwise)
- I'll handle PR/merge myself (exit)

## Additional Resources

### Reference Files

For templates and detailed guidelines, consult:
- **`references/progress-template.md`** — Execution progress report format
