# Iterative Engineering Plugin

A Claude Code plugin for iterative development workflows — brainstorming, tech planning, multi-agent reviews, TDD implementation, and PR management.

## Philosophy

- **Planning pays off** — Time spent planning yields better implementation. Rushing to code is often slower overall.
- **Iteration improves quality** — Multiple review passes catch issues early. A review after a review can still find improvements.
- **User drives every transition** — The workflow never auto-proceeds. Every stage transition, review acceptance, and decision point uses AskUserQuestion — the user always chooses what happens next.
- **Opinionated defaults, user choice** — Recommend reviews, suggest worktrees, default to full coverage. But the user can skip, customize, or exit at any point.
- **Skills are independently valuable** — Each skill works standalone. Run `/code-review` without the full pipeline, or `/iterative:brainstorming` to revisit requirements mid-implementation.

## Installation

```bash
/plugin marketplace add tmchow/tmc-marketplace
/plugin install iterative-engineering@tmc-marketplace
```

## The Workflow

```
brainstorming
     │ PRD
     ↕ plan-review (1+ rounds)
     │
tech-planning
     │ Tech Plan
     ↕ plan-review (1+ rounds)
     │
implementing
     ├─ execute batch ◄──────────┐
     │   incremental code-review? ┘ (many subtasks)
     │
     ├─ code-review (per plan section)
     │   fix selected severities
     │
     ├─ code-simplifier (cleanup pass)
     │
     ├─ final code-review (all changes)
     │   fix selected severities
     │
     └─ wrapup: verify tests → PR
```

Each stage produces an artifact, offers review, and hands off when the user is ready. Re-entry is supported — run any skill again at any point.

The implementing stage does the heavy lifting: the tech plan is broken into sections, each with dependency-ordered subtasks that execute in batches. Sections with many subtasks get incremental code reviews between batches. Every section gets a code review when complete, and a final review covers all changes before wrapup verifies tests and creates the PR.

### Stage Boundaries

Each stage has a clear scope — what it produces and what it deliberately leaves to the next stage:

| Stage | Produces | Does | Does NOT |
|-------|----------|------|----------|
| **Brainstorming** | PRD | Explore problem space, make directional choices, capture scope and key decisions | Specify libraries, schemas, API endpoints, or implementation details |
| **Tech Planning** | Tech Plan | Structure subtasks with dependencies, file paths, test scenarios, and architecture decisions | Pre-write implementation code — describe what and where, implementer writes the code |
| **Implementing** | Code → PR | Execute plan with dependency-aware batching, TDD, code reviews, test verification, PR creation | Deploy or release — the workflow ends at PR creation |

### Reviews

Reviews are user-driven:

- **Offered, never forced** — Every review is presented via AskUserQuestion. The user can skip.
- **Severity-based acceptance** — Findings grouped by severity (Critical / High / Medium / Low). User selects which levels to fix — not all-or-nothing.
- **User-controlled loop** — After fixes, user chooses to re-review or continue. No automatic re-review.
- **Scaled to scope** — Full review for substantial work, quick review for moderate changes, skip for trivial config edits.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| PRD captures direction, not implementation | High-level technical direction ("real-time via WebSockets") belongs in the PRD. Specific libraries and database schemas don't — that's tech planning's job. |
| Tech plan describes what, not how | Plans capture architecture, query strategies, and test scenarios. They don't pre-write method bodies — that's brittle and gets followed blindly. The implementer writes the actual code. |
| Dependency-aware batch execution | Subtasks are grouped by their dependency graph. Each batch runs concurrently, but batches execute sequentially. Not one-at-a-time (too slow), not all-at-once (ignores ordering). |
| Incremental reviews for large sections | Plan sections with 6+ subtasks get code review offers between batches. Catches issues before later batches build on flawed code. |
| Severity-based fix acceptance | Not all review findings warrant fixing. User picks which severity levels to address. Keeps the user in control of review scope. |

## Skills

### Core Workflow

The core workflow skills use an `iterative:` prefix in their name (e.g., `/iterative:brainstorming`). Claude Code's slash command menu shows skill names from all installed plugins — if another plugin also has a "brainstorming" skill, you'd see duplicate `/brainstorming` entries. The prefix makes ours immediately identifiable. Substring search still works — typing `/brain` finds `/iterative:brainstorming`.

| Skill | Output | Description |
|-------|--------|-------------|
| `iterative:brainstorming` | PRD | Collaborative exploration of problem space, broad directions, deep Q&A |
| `iterative:tech-planning` | Tech Plan | Structure PRD into dependency-ordered subtasks with file paths, test scenarios, architecture decisions |
| `plan-review` | Review Report | 4 specialized reviewers analyze PRDs and tech plans with cross-validation |
| `iterative:implementing` | Code → PR | Dependency-aware batch execution with TDD, incremental and final code reviews, then wrapup |
| `code-review` | Review Report | 5 specialized reviewers with severity ratings, full or quick mode |

### Internal

| Skill | Description |
|-------|-------------|
| `implementation-wrapup` | Test verification, final review, PR creation — invoked by implementing or standalone ("create a PR") |
| `git-worktree` | Workspace isolation — invoked by implementing during setup |

### Supporting

| Skill | Description |
|-------|-------------|
| `fix-code-review-feedback` | Resolve PR review comments systematically |
| `agent-browser` | Browser automation using Vercel's agent-browser CLI |

## Agents

### Review Agents (Plan Review)

4 specialized reviewers analyze documents via [agent team](https://code.claude.com/docs/en/agent-teams):

| Agent | Focus |
|-------|-------|
| `clarity-reviewer` | Vague language, ambiguity, structure |
| `completeness-reviewer` | Missing sections, gaps, dependencies |
| `specificity-reviewer` | Actionability, concrete details |
| `yagni-reviewer` | Scope creep, over-specification |

### Review Agents (Code Review)

5 specialized reviewers analyze code via agent team:

| Agent | Focus |
|-------|-------|
| `correctness-reviewer` | Logic errors, edge cases, bugs, silent failures, plan compliance |
| `security-reviewer` | Vulnerabilities, auth, input validation, project conventions |
| `performance-reviewer` | Algorithmic complexity, queries, memory, caching |
| `simplicity-reviewer` | YAGNI, over-engineering, unnecessary abstraction |
| `testing-reviewer` | Coverage, test quality, edge cases, plan test scenarios |

Review agents run as teammates who can cross-validate findings — a security reviewer can flag missing test coverage, a YAGNI reviewer can push back on completeness suggestions. When agent teams are unavailable, reviews fall back to parallel subagent execution.

### Workflow Agents

| Agent | Purpose |
|-------|---------|
| `task-worker` | Executes subtasks — reads plan context, loads patterns, implements with TDD, commits |
| `code-simplifier` | Behavior-preserving simplification pass on changed files before final review |
| `branch-setup-worker` | Creates git worktrees or branches for isolation |
| `pr-creator-worker` | Creates pull requests following repo conventions |

Workflow agents run as isolated subagents. Each `task-worker` gets its own context window with just its subtask from the plan.

## HZL Integration (Optional)

This plugin supports [HZL](https://github.com/tmchow/hzl) for persistent task tracking across sessions and agents. Implementing detects HZL automatically and offers it as the recommended option. Without HZL, the workflow uses Claude's built-in task management (TaskCreate).

See the [HZL repository](https://github.com/tmchow/hzl) for installation.

## Credits

This plugin draws inspiration from:

- [superpowers](https://github.com/obra/superpowers) by Jesse Vincent — TDD workflows, git worktrees, execution patterns, SHA-based review scoping
- [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by Every — Brainstorming, document review, workflow orchestration, code simplicity analysis
- [pr-review-toolkit](https://github.com/anthropics/claude-code-pr-review) by Anthropic — Confidence filtering, silent failure audit patterns, selective reviewer activation
- [code-simplifier](https://github.com/anthropics/claude-code-code-simplifier) by Anthropic — Over-simplification guardrails, project convention awareness

## License

MIT
