# HZL Workflow Skills - Brainstorm

**Date:** 2026-02-04
**Status:** Design phase (not yet implementation-ready)

## Goals and Assumptions

The overall workflow is based on these core beliefs:

1. **Planning pays off** - More time spent in planning yields better implementation results. Rushing to code is often slower overall.

2. **Iteration improves quality** - Multiple passes on brainstorm documents and technical plans catch issues early. A review after a review can still find improvements.

3. **Context protection matters** - Using sub-agents protects the main context window from compaction. This requires extra work to ensure agents are correctly designed with skills so context passes correctly, but the tradeoff is worth it.

4. **Opinionated defaults with user choice** - Offer users good choices when transitioning between workflows. Steer them toward what we think is best, but allow them to go faster if they explicitly choose to. Don't force; guide.

5. **Non-linear workflow support** - Users should be able to invoke most skills manually to re-run any part of the workflow. Sometimes work is non-linear - a user might want to re-run brainstorming after seeing the technical plan, or do another code review after fixes. Support this flexibility.

6. **HZL is beneficial but optional** - HZL makes task tracking easier and better, but not everyone will use it. The workflow should work without HZL, but if HZL is available, use it. No false choices - don't block users who don't have HZL, but reward those who do.

7. **Skills are independently valuable** - Each skill should be useful on its own, not just as part of the full workflow. A user should be able to run just `code-review` or just `plan-review` without going through the entire pipeline.

---

## Problem Statement

Users combining HZL with existing skill ecosystems (superpowers, compound-engineering) face:

1. **Broken workflows** - Existing skills use TodoWrite, conflict with HZL as source of truth
2. **Friction in transitions** - No clean handoff from "plan" → "HZL tasks" → "execution"
3. **Discovery** - Users don't know how to integrate HZL into their workflow

### Root Cause

Existing skills (superpowers, compound-engineering) are self-contained workflows that:
- Use TodoWrite for task tracking (competes with HZL)
- Write to specific markdown formats (docs/plans/, checkboxes)
- Have no "import to external system" hook

Users either skip HZL entirely or try both systems and get confused about source of truth.

## Solution

Build an HZL-native workflow skill set that:
- Forks/adapts best parts of existing skills (with attribution)
- Makes HZL the task backbone throughout
- Uses skill/agent architecture for context efficiency

### Design Principles

1. **Don't assume referenced skills and agents are perfect** - External skills may have outdated patterns or could benefit from improvement. Use them as inspiration, not gospel.

2. **HZL is optional** - Skills (especially executing-work) must work with AND without HZL. Some users have smaller projects or choose not to use task tracking.

3. **Iterate on quality** - Support multiple rounds of review (plan-review, code-review), not just one pass.

---

## Architecture

### Pattern: Skills as Context Bridges

Skills orchestrate in main context, agents do isolated work:

```
SKILL (main context)
├── Has conversation history
├── Infers context (paths, project, etc.)
├── Spawns AGENT with explicit parameters
└── Agent returns concise summary
```

**Why this pattern:**
- Skills run in main context → can see conversation, infer parameters
- Agents run isolated → verbose work doesn't bloat main context
- Agents have tight output constraints → return summaries only
- No user friction → `/plan-to-tasks` just works, no need to specify paths

### Key Constraints (from Claude Code docs)

1. **Skills cannot invoke other skills directly** - but can tell Claude to use other skills
2. **Subagents cannot spawn other subagents** - main context must orchestrate parallel work
3. **`context: fork` currently broken** (GitHub #17283) - skills run in main context regardless
4. **Subagent output is NOT automatically summarized** - must design tight output constraints

### Skill Preloading

Agents can have skills injected at startup via the `skills` field:
```yaml
---
name: task-worker
skills:
  - hzl
---
```

The full skill content is injected, giving the agent domain knowledge without discovery.

---

## Main Workflow

**With HZL:**
```
brainstorming ──► create-technical-plan ──► plan-to-tasks ──► executing-work ──► finishing-work
     │                    │                                         │
     ▼                    ▼                                         ▼
 plan-review          plan-review                              git-worktree
 (1+ iterations)      (1+ iterations)                          code-review
```

**Without HZL:**
```
brainstorming ──► create-technical-plan ──► plan-to-tasks ──► executing-work ──► finishing-work
     │                    │                 (TodoWrite)            │
     ▼                    ▼                                        ▼
 plan-review          plan-review                             git-worktree
 (1+ iterations)      (1+ iterations)                         code-review
```

**Core skills (3):** brainstorming, create-technical-plan, executing-work
**Supporting skills (5):** plan-review, plan-to-tasks, git-worktree, code-review, finishing-work

### Workflow Transitions

User choice points between stages. Pattern: produce artifact → offer review → fix issues → offer again or continue.

**T1: After brainstorming document written**
```
Brainstorm document created. What next?
├── A) Plan-review: 4 agents analyze for issues and improve (recommended)
├── B) Continue to technical plan
├── C) I'll take it from here (exit)
```

**T1b: After brainstorm review + fixes applied**
```
Review issues addressed. What next?
├── A) Another round of plan-review (recommended if significant changes)
├── B) Continue to technical plan
├── C) I'll take it from here (exit)
```

**T2: After technical plan written**

*If project uses HZL for task tracking:*
```
Technical plan created. What next?
├── A) Plan-review: 4 agents analyze for issues and improve (recommended)
├── B) Convert to HZL tasks
├── C) I'll take it from here (exit)
```

*If project does not use HZL:*
```
Technical plan created. What next?
├── A) Plan-review: 4 agents analyze for issues and improve (recommended)
├── B) Convert to TodoWrite tasks
├── C) I'll take it from here (exit)
```

**T2b: After plan review + fixes applied**

Same options as T2, just with "Another round of plan-review" as option A.

**T3: After tasks created**

*If HZL:*
```
Tasks created in HZL. What next?
├── A) Start executing (recommended)
├── B) Let me review/adjust tasks first (exit)
```

*If TodoWrite:*
```
Tasks created in TodoWrite. What next?
├── A) Start executing (recommended)
├── B) Let me review/adjust tasks first (exit)
```

**T4: After executing-work completes**
```
Implementation complete, tests passing. What next?
├── A) Continue to finishing-work (recommended)
├── B) I'll handle PR/merge myself (exit)
```

**T5: After finishing-work completes**
```
PR created / Branch pushed. What next?
├── A) Clean up worktree (if applicable)
├── B) Keep worktree for more work
```

**Design principles:**
- Recommended option is always A)
- Always offer exit ("I'll take it from here")
- Support going back for more iterations
- Don't force HZL - offer "skip HZL" path

**Non-linear re-entry:**
Users can invoke any skill directly at any time:
- `/brainstorming` - start fresh or iterate
- `/plan-review` - review any document
- `/code-review` - review any code
- `/finishing-work` - finish any branch

---

## Skills (8)

### Core Skills

#### `brainstorming`
- **Purpose:** Explore intent before planning
- **Source:** Fork compound-engineering brainstorming (user authored)
- **Key change:** Early options pattern - present 2-3 approaches with pros/cons table BEFORE deep research
- **Calls:** plan-review (1+ iterations)
- **Handoff:** To create-technical-plan

#### `create-technical-plan`
- **Purpose:** Turn design into implementation plan with TDD
- **Source:** Fork superpowers writing-plans (TDD emphasis)
- **Calls:** plan-review (1+ iterations), then plan-to-tasks at end
- **Handoff:** To executing-work (via plan-to-tasks creating tasks in HZL or TodoWrite)

#### `executing-work`
- **Purpose:** Execute implementation work
- **Source:** Fork superpowers executing-plans + compound-engineering work
- **HZL optional:** Works with OR without HZL. Uses HZL tasks if project uses HZL for task tracking, otherwise TodoWrite tasks.

**Execution preference (asked upfront):**
- A) Execute all tasks, report when done (default)
- B) Pause after each parent task for feedback
- C) Pause after each subtask for feedback

**Phases:**
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
├── Invoke finishing-work skill (option to squash on merge)
└── Report completion
```

**Sequential execution (not parallel):**
- One task-worker at a time to avoid file conflicts
- Safer and simpler (follows superpowers guidance)
- Works fine in existing worktrees

**Commit pattern (RGRC - Red-Green-Refactor-Commit):**
- 1 commit per completed subtask (after REFACTOR, tests passing)
- Never commit with failing tests
- Squash commits on merge to main (clean history)

**Stop conditions:**
- Subtask instructions unclear
- Tests fail and fix isn't obvious
- Missing dependency or blocker
- Verification fails repeatedly (3x)
- Human comment on task requires response (HZL or conversation)

**Calls:** git-worktree (setup), code-review (1+ rounds after parent), finishing-work (at end)

### Supporting Skills

#### `plan-review`
- **Purpose:** Refine brainstorm or technical plan documents
- **Source:** Fork compound-engineering document-review (user authored)
- **Behavior:** Spawns 4 reviewer agents in parallel (clarity, completeness, specificity, yagni), synthesizes findings
- **Called by:** brainstorming, create-technical-plan
- **Also:** Standalone invocable

#### `plan-to-tasks`
- **Purpose:** Convert technical plan to trackable tasks
- **Adapts to project:** Uses HZL if project uses HZL for task tracking, otherwise TodoWrite
- **Spawns:** plan-to-tasks-worker agent

**Detection:** If project uses HZL for task tracking → use HZL. Otherwise → use TodoWrite.

**Flow:**
```
Step 1: Identify Plan + Task System
├── Find plan document (argument, conversation, or ask)
├── Detect if project uses HZL for task tracking → use HZL, otherwise TodoWrite
└── Report which system will be used

Step 2: Parse Plan → Proposed Structure
├── Spawn plan-to-tasks-worker agent
├── Extract parents, subtasks, dependencies
├── Infer granularity from plan structure (ask if unclear)
└── Include descriptions from plan + always link to doc

Step 3: QA the Parsing (BEFORE creating tasks)
├── Compare proposed structure against plan sections
├── Flag any plan content not captured
├── If issues: fix parsing, re-verify
└── If clean: proceed

Step 4: Present Structure for Approval
├── Show summary + tree view
└── Ask:
    A) Create all tasks (default)
    B) Review each parent individually
    C) Give feedback first

Step 5: Create Tasks
├── If HZL:
│   ├── Create parents and subtasks via `hzl task add`
│   ├── Set dependencies
│   └── Add links to plan document
└── If TodoWrite:
    ├── Create tasks via TodoWrite tool
    └── Include plan references in descriptions

Step 6: Sanity Check
├── Verify counts match expected
└── Report: "Created [N] parents, [M] subtasks ✓"

Step 7: Handoff → executing-work
```

**Task descriptions:**
- Copy relevant plan prose into description (default)
- If very complex: summarize, reference section by name
- HZL: link to plan file via `-l docs/plans/[plan].md`
- TodoWrite: reference plan file path in description

**If plan has no clear structure:**
- Offer to help structure it before converting

#### `git-worktree` (workspace isolation)
- **Purpose:** Ensure agent has isolated workspace, avoid conflicts with human work
- **Detection:**
  ```
  in_worktree = git_dir contains "/worktrees/"
  current_branch = git branch --show-current
  default_branch = git remote show origin | grep "HEAD branch"
  ```

**Scenario handling:**

| Scenario | Detection | Options |
|----------|-----------|---------|
| Already in worktree | `git_dir` contains `/worktrees/` | Proceed (already isolated) |
| On default branch (main/master) | `current == default` | A) Create worktree (recommended) B) Create branch here C) Continue on main (requires consent) |
| On feature branch | `current != default` | A) Create worktree (if human also working here) B) Continue here (if human not using this dir) |

**Worktree is recommended default** because:
- Agent gets isolated directory
- Human can continue working in original directory
- No file conflicts between human and agent work

- **Spawns:** branch-setup-worker agent

#### `code-review`
- **Purpose:** Review code with multiple perspectives
- **Modes:** Full (default) or Quick (when explicitly requested)
- **Behavior:**
  - Full mode: Spawns 5 reviewer agents in parallel (correctness, security, performance, simplicity, testing)
  - Quick mode: Spawns 2-3 agents based on change type (e.g., security + correctness for auth changes)
- **Iterations:** Can run multiple rounds until issues are addressed
- **Triggered:** After parent task completion (1+ rounds), or on-demand
- **Language-agnostic:** Detect project context, adapt criteria (no Rails-specific agents)

#### `finishing-work`
- **Purpose:** Complete development with verification, optional review, and PR creation
- **Source:** Fork superpowers finishing-a-development-branch + Anthropic commit-push-pr patterns
- **Spawns:** pr-creator-worker agent (or executes directly for simplicity)
- **Returns:** PR URL or completion status

**Flow:**
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

**Safeguards:**
- Never skip test verification
- Never push with failing tests
- Never discard without typed confirmation
- `git push` prompts (user confirms before pushing)

---

## Agents (13)

All agents designed with **tight output constraints** - return summaries, not verbose analysis.

### Plan Review Agents (4)

| Agent | Focus | Key Question | Output |
|-------|-------|--------------|--------|
| `clarity-reviewer` | Vague language, ambiguity, structure | Is this document understandable? | Max 5 issues |
| `completeness-reviewer` | Missing sections, gaps, dependencies | Is anything missing? | Max 5 gaps |
| `specificity-reviewer` | Actionability, concrete details | Is this concrete enough to act on? | Max 5 issues |
| `yagni-reviewer` | Scope creep, hypotheticals, over-specification | Is this minimal and focused? | Max 5 cuts |

### Code Review Agents (5)

| Agent | Focus | Key Questions | Output |
|-------|-------|---------------|--------|
| `correctness-reviewer` | Logic, edge cases, bugs, error handling | Does this code work correctly? | Max 5 issues |
| `security-reviewer` | Vulnerabilities, auth, input validation, secrets | Is this code safe? | Max 5 issues |
| `performance-reviewer` | Algorithmic complexity, DB queries, memory, caching | Is this code fast enough? | Max 5 issues |
| `simplicity-reviewer` | YAGNI, over-engineering, unnecessary abstraction | Is this code minimal? | Max 5 suggestions |
| `testing-reviewer` | Test coverage, test quality, edge cases, integration | Is this code well-tested? | Max 5 issues |

### Worker Agents (4)

| Agent | Purpose | Preloaded Skills | Output |
|-------|---------|------------------|--------|
| `plan-to-tasks-worker` | Parse plan, extract task structure | `hzl` (if HZL used) | JSON task structure |
| `task-worker` | Execute single subtask (TDD cycle + commit) | `hzl` (if HZL used) | "Completed [task], committed [sha]" |
| `branch-setup-worker` | Ensure on feature branch (not main) | - | "Ready on branch [name]" |
| `pr-creator-worker` | Create PR following repo conventions | - | "PR created: [URL]" |

**Notes:**
- Workers execute sequentially, not in parallel, to avoid file conflicts
- `hzl` skill only preloaded when project uses HZL for task tracking

---

## Model Specifications

Different skills/agents have different complexity needs. Use appropriate models for cost/performance balance.

### Skills

| Skill | Model | Rationale |
|-------|-------|-----------|
| `brainstorming` | (inherit) | Interactive, uses main conversation |
| `create-technical-plan` | (inherit) | Interactive, uses main conversation |
| `plan-review` | **opus-4.5** | Needs deep reasoning for document analysis |
| `plan-to-tasks` | **haiku-4.5** | Structured extraction, not complex reasoning |
| `git-worktree` | **haiku-4.5** | Straightforward git operations |
| `executing-work` | (inherit) | Orchestration, uses main conversation |
| `code-review` | **opus-4.5** | Needs deep reasoning for code analysis |
| `finishing-work` | (inherit) | Simple orchestration |

### Agents

| Agent Type | Model | Rationale |
|------------|-------|-----------|
| Plan review agents | `inherit` | Inherit opus-4.5 from plan-review skill |
| Code review agents | **sonnet-4.5** | Good balance of speed and quality for code analysis |
| Worker agents (plan-to-tasks, task, worktree, pr) | **haiku-4.5** | Execution-focused, not complex reasoning |

---

## Tool Access (allowed-tools)

The `allowed-tools` frontmatter field grants tools without per-use approval when the skill is active. Tools can be pattern-restricted using prefix matching syntax like `Bash(hzl )`.

**Pattern matching:** Prefix-based. `Bash(git checkout -b )` matches `git checkout -b feature` but NOT `git checkout .`. Be specific to avoid over-permissioning.

### Safe Tool Tiers

**Tier 1: Always safe (read-only)**
```
Glob, Grep, Read
```

**Tier 2: Research (for planning/research skills)**
```
WebSearch, WebFetch
```

**Tier 3: HZL (our tool, trusted)**
```
Bash(hzl )
```

**Tier 4: Safe git patterns**
```
Bash(git status)
Bash(git diff )
Bash(git log )
Bash(git branch )
Bash(git worktree )
Bash(git add )
Bash(git commit )
Bash(git checkout -b )   # -b required to avoid dangerous checkout
Bash(git remote )
```

**Tier 5: Safe gh patterns**
```
Bash(gh pr create )
Bash(gh pr view )
Bash(gh pr list )
Bash(gh issue )
```

**Prompt for (don't pre-approve):**
- `git push` - could --force, wrong branch
- `git checkout` without -b - discards changes
- `git reset`, `git clean` - destructive
- `npm`, `pnpm`, `node`, `python` - arbitrary execution
- `gh pr merge` - consequential action

### User-invocable Classification

| Skill | User-invocable | Rationale |
|-------|----------------|-----------|
| `brainstorming` | Yes | Entry point |
| `create-technical-plan` | Yes | Entry point |
| `plan-review` | Yes | Can run standalone |
| `plan-to-tasks` | Yes | Can run standalone |
| `git-worktree` | No | Internal, called by executing-work |
| `executing-work` | Yes | Entry point |
| `code-review` | Yes | Can run standalone |
| `finishing-work` | Yes | Can run standalone |

### Skill Tool Allocations

| Skill | allowed-tools |
|-------|---------------|
| `brainstorming` | Glob, Grep, Read, WebSearch, WebFetch, AskUserQuestion, Task |
| `create-technical-plan` | Glob, Grep, Read, Write, Edit, AskUserQuestion, Task |
| `plan-review` | Glob, Grep, Read, Task |
| `plan-to-tasks` | Glob, Grep, Read, Bash(hzl ), TodoWrite, Task |
| `git-worktree` | Bash(git status), Bash(git branch ), Bash(git worktree ), Bash(git checkout -b ), Bash(git remote ), Task |
| `executing-work` | Glob, Grep, Read, Bash(hzl ), Bash(git status), Bash(git diff ), Bash(git add ), Bash(git commit ), TodoWrite, AskUserQuestion, Task |
| `code-review` | Glob, Grep, Read, Task |
| `finishing-work` | Glob, Grep, Read, Bash(git status), Bash(git diff ), Bash(git add ), Bash(git commit ), Bash(gh pr create ), Bash(gh pr view ), Task |

**Notes:**
- `git push` prompts (in finishing-work) - user confirms before pushing
- Test running (`pnpm test`) prompts at skill level, but pre-approved for task-worker agent

### Agent Tool Allocations

Agents have their own tool access, independent of the spawning skill.

**Reviewer agents (read-only):**

All 9 reviewer agents (4 plan + 5 code) use the same tools:
```
Glob, Grep, Read
```
- Analyze only, never modify
- Return max 5 findings

**Worker agents:**

| Agent | allowed-tools |
|-------|---------------|
| `plan-to-tasks-worker` | Glob, Grep, Read, Bash(hzl ), TodoWrite |
| `task-worker` | Glob, Grep, Read, Write, Edit, Bash(git status), Bash(git diff ), Bash(git add ), Bash(git commit ), Bash(pnpm test), Bash(npm test) |
| `branch-setup-worker` | Bash(git status), Bash(git branch ), Bash(git worktree ), Bash(git checkout -b ), Bash(git remote ) |
| `pr-creator-worker` | Glob, Grep, Read, Bash(git status), Bash(git diff ), Bash(gh pr create ), Bash(gh pr view ) |

**Notes:**
- `task-worker` has broad access for TDD cycle (read, write, test, commit)
- `git push` stays with skill (prompts user), not delegated to agents
- Test commands (`pnpm test`, `npm test`) pre-approved for task-worker

---

## Key Design Decisions

1. **Skills as context bridges** - Run in main context, infer parameters, spawn isolated agents

2. **Early options in brainstorming** - Present 2-3 approaches with pros/cons table before deep research (avoid over-researching wrong direction)

3. **Incremental commits** - Commit after each subtask completion, not just "when feels complete" (superpowers pattern, compound-engineering doesn't do this)

4. **Sequential execution** - executing-work runs one task-worker at a time to avoid file conflicts (follows superpowers guidance)

5. **Code review after parent completion** - Not after each subtask (tasks are small)

6. **Single code-review skill with modes** - Full (default) or quick, not separate skills. Mode determined by explicit request ("quick review") or could infer from change size.

7. **Language-agnostic** - No Rails/Python-specific reviewer agents. Detect project context from CLAUDE.md, package.json, Gemfile, etc. and adapt criteria.

8. **`hzl` skill preloaded** - Agents that interact with HZL (plan-to-tasks-worker, task-worker) get the skill injected at startup

9. **No standalone simplifier skill** - Simplification handled by:
   - plan-review (YAGNI lens for documents)
   - code-review (simplicity-reviewer agent for code)

10. **HZL is optional** - executing-work works with or without HZL. Uses HZL tasks if project uses HZL, otherwise TodoWrite. Always uses a task system, never works from plan document directly.

11. **Multiple review rounds** - Both plan-review and code-review support iterating until quality is acceptable, not just one pass.

12. **Referenced skills and agents are inspiration, not gospel** - External skills may have outdated patterns. Improve where beneficial.

13. **Justify design choices** - When creating each skill/agent, carefully reason over what to include/exclude from referenced sources. Document justification for adaptations. Use latest Claude Code documentation for best practices.

---

## Source Attribution

| Skill | Primary Source | Repository |
|-------|---------------|------------|
| `brainstorming` | compound-engineering brainstorming (user authored) | EveryInc/compound-engineering-plugin |
| `create-technical-plan` | superpowers writing-plans | obra/superpowers |
| `plan-review` | compound-engineering document-review (user authored) | EveryInc/compound-engineering-plugin |
| `git-worktree` | Both repos combined | Both |
| `executing-work` | superpowers executing-plans | obra/superpowers |
| `code-review` | Combine multiple sources | Multiple |
| `finishing-work` | superpowers finishing-a-development-branch | obra/superpowers |

---

## Open Questions

### For Detail Phase

1. **Specific reviewer agent perspectives** - What exactly does each reviewer focus on? What criteria/checklist?

2. **plan-to-tasks QA pass** - How do we verify nothing was missed? Compare task count to plan sections? Parse plan structure?

3. **Skill frontmatter triggers** - Exact wording for description field to enable appropriate auto-invocation

4. **Error handling** - What happens when agents fail? Retry? Report and continue? Stop workflow?

5. **Mode selection for code-review** - How does quick vs full get determined? Explicit only, or infer from change size?

6. ~~**Parallel agent count**~~ - RESOLVED: Using sequential execution (one task-worker at a time) to avoid file conflicts

7. ~~**HZL project determination**~~ - RESOLVED: Detect if project uses HZL for task tracking. If yes, infer project from repo or ask. If no, use TodoWrite.

8. ~~**Tool access for skills**~~ - RESOLVED: See "Tool Access" section with tiered patterns

9. ~~**Tool access for agents**~~ - RESOLVED: See "Agent Tool Allocations" section. Reviewers are read-only; workers have task-specific access.

### Technical Validation Needed

1. **`context: fork` bug status** - Monitor GitHub #17283 for resolution
2. **Agent output constraints** - Validate that tight prompts actually produce tight output
3. ~~**Parallel agent spawning**~~ - N/A: Using sequential execution for task-workers (parallel still used for reviewer agents)

---

## References

### External Skills (for forking)

- superpowers brainstorming: https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md
- superpowers writing-plans: https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md
- superpowers executing-plans: https://github.com/obra/superpowers/blob/main/skills/executing-plans/SKILL.md
- superpowers git-worktrees: https://github.com/obra/superpowers/blob/main/skills/using-git-worktrees/SKILL.md
- superpowers finishing-branch: https://github.com/obra/superpowers/blob/main/skills/finishing-a-development-branch/SKILL.md
- compound-engineering brainstorming: https://raw.githubusercontent.com/tmchow/compound-engineering-plugin/a17ff11741621fec3d7c58f494f2d232f7238055/plugins/compound-engineering/commands/workflows/brainstorm.md
- compound-engineering document-review (PR): https://github.com/EveryInc/compound-engineering-plugin/pull/112
- compound-engineering git-worktree: https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/git-worktree/SKILL.md
- compound-engineering workflows:work: https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/commands/workflows/work.md
- wshobson full-review: https://github.com/wshobson/agents/blob/main/plugins/comprehensive-review/commands/full-review.md
- wshobson ai-review: https://github.com/wshobson/agents/blob/main/plugins/code-review-ai/commands/ai-review.md

### External Agents (for inspiration)

- compound-engineering performance-oracle: https://raw.githubusercontent.com/EveryInc/compound-engineering-plugin/refs/heads/main/plugins/compound-engineering/agents/review/performance-oracle.md
- compound-engineering security-sentinel: https://raw.githubusercontent.com/EveryInc/compound-engineering-plugin/refs/heads/main/plugins/compound-engineering/agents/review/security-sentinel.md
- compound-engineering code-simplicity-reviewer: https://raw.githubusercontent.com/EveryInc/compound-engineering-plugin/refs/heads/main/plugins/compound-engineering/agents/review/code-simplicity-reviewer.md

### Claude Code Documentation

- Skills: https://code.claude.com/docs/en/skills
- Subagents: https://code.claude.com/docs/en/sub-agents

---

## Next Steps

1. Dive into specifics on each skill/agent to fortify the plan
2. Create detailed specs for each skill's behavior and prompts
3. Create detailed specs for each agent's focus and output format
4. Move to implementation plan (create-technical-plan) when design is complete

### Process for Each Skill/Agent

When detailing each skill or agent:

1. **Fetch referenced sources** - Read the external skill/agent files listed in References
2. **Analyze what works** - Identify patterns, structures, and content worth keeping
3. **Identify what to change** - Note outdated patterns, missing features, or improvements needed
4. **Document justification** - For each major inclusion/exclusion, explain why
5. **Apply latest best practices** - Use current Claude Code documentation for skill/agent structure
6. **Design for our context** - Ensure it fits HZL workflow, supports optional HZL, uses correct model tier
