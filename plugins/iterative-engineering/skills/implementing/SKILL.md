---
name: iterative:implementing
description: 'Execute a tech plan with dependency-aware batching, TDD, code review, and PR creation. Triggers: "implement the plan", "start building", "start implementing", "execute the plan".'
---

# Executing Work

Read the plan critically, create tasks, and implement with TDD, code review, and continuous testing. The plan is your guide — it contains the decisions, patterns, and test scenarios that drive implementation.

## When to Use

- After `iterative:tech-planning` skill completes a plan
- When a plan document exists and is ready to implement
- When tasks already exist from a prior session
- Can be invoked standalone with a plan document path

## Key Principles

1. **The plan is your guide** — Read referenced files and patterns, use the plan's decisions to drive implementation
2. **Clarify before building** — Ask questions now, not after building the wrong thing
3. **Test as you go** — Run tests after each change, not at the end
4. **Commit as you go** — One commit per completed subtask, never batch commits at the end
5. **Review at the right scope** — Section review after each plan section, final review of all branch changes, user chooses which severities to fix
6. **Stop when blocked** — Ask for help rather than guessing

## Workflow

### Phase 0: Detect Resume

1. Check for in-progress tasks related to this plan.
2. If tasks exist and work is in progress: load the plan document, summarize current state, show completed vs remaining subtasks, continue from next incomplete subtask (skip to Phase 2).
3. If no tasks exist: proceed to Phase 1 — **even if you have prior conversation context.** Having discussed the plan in a previous session is not the same as having set up tasks and workspace. Phase 1 setup (task creation, workspace isolation) must run before any implementation begins.

### Phase 1: Understand and Setup

1. **Find and read the plan document completely.** Check conversation context for referenced plans, scan `docs/plans/` for recent plan files. If no plan found, ask user for path. If no plan exists, ask the user: A) Create a tech plan first (recommended), B) I'll provide the plan path. If tech plan: invoke `iterative:tech-planning` skill.
2. **Review critically.** If anything is unclear or ambiguous, ask now. Do not skip this — better to clarify now than build the wrong thing.
3. **Workspace isolation.** See Workspace Setup section.
4. **Create tasks from the plan.** See Task Creation section.
5. **Execution preference.** Present an interactive choice to the user — `AskUserQuestion` (Claude Code) or `request_user_input` (Codex): A) Execute all tasks, report when done (default), B) Pause after each plan section for feedback, C) Pause after each subtask for feedback.

### Phase 2: Execute (repeat per plan section)

1. **Record section baseline.** Before starting each plan section, capture the current commit: `git rev-parse HEAD`. This SHA is the section's baseline — used to scope reviews to only this section's changes.
2. **Analyze dependency graph.** Using the plan's `**Depends on:**` and `**Files:**` fields, group the section's subtasks into execution batches — subtasks with no unmet dependencies form the next batch.
3. **Execute batch.** For each batch, spawn subagents for all subtasks (concurrently when multiple). Always use subagents, even for single-subtask batches — this keeps implementation detail out of the orchestrator's context, preserving capacity for reviews, phase transitions, and user interaction. Each subagent receives:
   - Path to the tech plan document
   - Subtask number and title
   - Parent task context
   - Task ID
4. Worker reads subtask from plan, loads referenced patterns, implements with TDD (tests first), commits, and updates task status (see task-worker agent for details).
5. **Wait for batch completion.** All subagents in the batch must finish before the next batch starts.
6. **Test verification gate.** After each batch completes, verify that feature subtasks produced test files. For each completed feature subtask, check: does the test file listed in the plan's `**Files:**` field exist, and does it contain tests matching the plan's `**Test scenarios:**`? If a feature subtask committed without tests, flag it immediately — do not continue to the next batch until resolved.
7. **Repeat** steps 3-6 for remaining batches.
8. Update plan document progress (mark completed items).
9. Mark section complete in task system.
10. **Section code review.** Run after all subtasks in the plan section are complete (see When to Review table for trivial exceptions). **Skip if this is the only section in the plan** — Phase 3's final review will cover the same code plus simplification changes, so a section-level review would be redundant. For multi-section plans: scope to `git diff <section-baseline-sha>..HEAD`. Pass the baseline SHA and plan context to the `code-review` skill. **Wait for the review to complete and fixes to land before moving on.** Do not run anything else in parallel with code review — it needs to see the final code. **Placeholder exclusion:** When the review returns findings targeting code that is an acknowledged placeholder for a later plan section, exclude those findings from severity acceptance — they will be addressed in a later section and caught by the final review. Note excluded count and reasons in the review summary (e.g., "Excluded 1 finding — placeholder for section 3").

### Phase 3: Finish

**Phase 3 steps are strictly sequential. Do not parallelize them** — each step depends on the output of the previous one.

1. Verify: all tasks complete, all section-level code reviews passed.
2. **Detect base branch.** `git rev-parse --verify origin/main >/dev/null 2>&1 && echo main || echo master`. Use this for all branch-level scoping in Phase 3.
3. **Simplification pass.** If `/simplify` is available, invoke it to review and clean up changed code. Otherwise, do a manual review of changed files (`git diff --name-only $(git merge-base HEAD <base>)..HEAD`) and apply behavior-preserving simplifications: flatten nesting, remove dead code, simplify expressions, collapse single-use variables. This is a single bounded pass — not a refactor. **Wait for simplification to complete before proceeding** — the final review must see simplified code.
4. **Final review offer.** Present an interactive choice to the user: A) Full code review of complete work (recommended), B) Skip to finish.
5. If review: invoke `code-review` skill with scope `git diff $(git merge-base HEAD <base>)..HEAD` (all branch changes including simplification).
6. **Severity acceptance (separate prompt).** If the review found issues at any severity, present severity acceptance (see Severity Acceptance section). This is its own prompt — do not combine it with next-step options, and do not skip it even when all issues are Medium/Low. "Clean" means zero findings at any severity. If no findings, skip to step 7.
7. **Next steps (separate prompt, after fixes land or user skipped fixes).** Present an interactive choice to the user: A) Another review round, B) Wrap up and create PR, C) I'll handle PR/merge myself (exit). Do not recommend wrap-up if fixes were just applied — recommend **another round** to verify. Recommend **wrap up** only when zero findings or user chose to skip all fixes.
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

### Task Tracking

Use built-in task tracking for all plans. Tasks are lightweight and session-scoped.

**Platform mapping:** Claude Code provides task objects (`TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet`) — use these directly. Codex composes equivalent tracking from `update_plan` (plan steps as task state) + `spawn_agent`/`wait`/`close_agent` (delegation). The workflow is the same: create tasks from the plan, track status, and mark complete — only the tool names differ.

### Parsing the Plan

The plan's standardized subtask format (numbered, with dependencies and files) maps directly to tasks:
- Plan sections → parent tasks
- Numbered subtasks → child tasks
- `Depends on` fields → task dependencies
- `Files` fields → description references in tasks

Show the proposed task structure to the user for approval before creating.

### Parent Task Descriptions

- Always link to the technical plan document — include the plan file path in the description
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
| **Section review** (after all subtasks in a plan section complete) | Full review via `code-review` skill. **Skip if single-section plan** — Phase 3 final review covers it |
| **Trivial section** (config, single-line, renaming only) | Skip review — note in progress report |

### Severity Acceptance

**This is its own prompt — do not combine it with next-step options.** Present severity acceptance whenever the review has findings at ANY severity, including Medium/Low-only reviews. Do not interpret "no Critical/High" as "clean" — clean means zero findings. **Use the platform's interactive question tool** — `AskUserQuestion` (Claude Code) or `request_user_input` (Codex) — for all severity acceptance prompts. Do not print options as text. Both platforms provide an automatic "Other" free-form option — do not add one manually.

Present a **single prompt** listing all severity levels with findings. No intermediate "choose which..." step.

**Claude Code** — use `AskUserQuestion` with `multiSelect: true`:

When Critical or High issues exist, pre-check the Critical+High option:
- ☑ **Critical + High (Recommended)** — N Critical, N High
- ☐ **Medium** — N issues
- ☐ **Low** — N issues

When only Medium/Low issues exist, nothing pre-checked:
- ☐ **Medium** — N issues
- ☐ **Low** — N issues

Only include severity levels that have findings.

**Codex** — use `request_user_input` (single-select, build combined options):

When Critical or High issues exist:
- **Fix Critical + High (Recommended)** — N issues
- **Fix Critical + High + Medium** — N issues
- **Fix all** — N issues
- **Skip fixes**

When only Medium/Low issues exist:
- **Fix Medium only** — N issues
- **Fix Medium + Low** — N issues
- **Skip fixes**

Only include options where findings exist at those levels. Omit options that would duplicate another (e.g., if no Low, omit "Fix all" since it equals the line above).

### Applying Fixes

Fix only the selected severities. Spawn a **single subagent** to apply all selected fixes — do not fix in the main thread (preserves context for subsequent review rounds and wrapup).

The subagent receives:
- The filtered findings list (only selected severities)
- The affected file paths
- Instruction to apply all fixes, run tests, and commit

One subagent (not one per finding) because findings can interact — a security fix and a correctness fix in the same function need to see each other. This mirrors the simplification pattern: one bounded pass, specific scope, commits separately.

Wait for the subagent to complete before proceeding. Next-step options come AFTER fixes land, as a separate prompt (Phase 3 step 7).

By the time implementing hands off to `implementation-wrapup`, all code reviews are complete. Wrapup skips its own review offer and handles verification, PR, and cleanup.

## Plan Adjustment

If reality diverges from the plan during implementation:

- **Minor adjustments** (different file path, small API change): update the plan document in place and continue. Note the change in the progress report.
- **Significant divergence** (missing requirement, wrong approach): stop and report the divergence. Present an interactive choice: A) Update the plan and continue, B) Continue as-is, C) Stop execution. If the divergence contradicts the PRD (not just the tech plan), update the PRD as well — it's the requirements source of truth for downstream validation.
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
2. Present an interactive choice: A) Retry with a different approach, B) Skip and continue to next subtask, C) Stop execution

## Anti-Patterns to Avoid

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| Jumping to code without reading plan context | Read each subtask's referenced files and patterns first |
| Skipping clarification to start faster | Ask questions now — building the wrong thing is slower |
| Creating tasks before understanding the plan | Read and clarify the plan, then create tasks |
| Committing with failing tests | Only commit when tests pass |
| Committing feature subtask without writing tests | TDD: write tests first from plan's test scenarios, then implement |
| Skipping Phase 1 because of prior conversation context | Prior context ≠ setup complete. If no tasks exist, run Phase 1 — task creation, workspace isolation |
| Pushing through when blocked | Stop and ask for help |
| Running code review in parallel with simplification or other code changes | Code review must see final code. Simplify → wait → review. Never parallelize steps that change code with steps that review it |
| Full code review on trivial changes | Scale review to complexity — skip for config changes |
| Modifying the plan silently | Report divergence and get user agreement |
| Applying TDD rigidly to config/refactoring subtasks | TDD for feature work, verify for non-feature work |

## Transition Points

**Always present options to the user at transition points using the platform's interactive question tool** — `AskUserQuestion` (Claude Code) or `request_user_input` (Codex). Never print options as text or end the turn without presenting a choice.

After simplification pass completes (Phase 3 step 4), present options:
- Full code review of complete work (recommended)
- Skip to finish

After review (or skip), present options:
- Another review round (recommended if Critical/High issues were just fixed)
- Wrap up and create PR (recommended otherwise)
- I'll handle PR/merge myself (exit)

## Additional Resources

### Reference Files

For templates and detailed guidelines, consult:
- **`references/progress-template.md`** — Execution progress report format
