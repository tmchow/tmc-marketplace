# Iterative Engineering Plugin

A Claude Code plugin for iterative development workflows - brainstorm, design, multi-agent reviews, TDD implementation, and PR management.

## Philosophy

This plugin is built on a few core beliefs:

- **Planning pays off** - Time spent planning yields better implementation. Rushing to code is often slower overall.
- **Iteration improves quality** - Multiple review passes catch issues early. A review after a review can still find improvements.
- **Context protection matters** - Using sub-agents protects the main context window from bloat.
- **Opinionated defaults, user choice** - Guide users toward best practices, but let them move faster if they choose.
- **Skills are independently valuable** - Each skill works standalone. Run just `/code-review` without the full pipeline.

## Installation

```bash
/plugin marketplace add tmchow/tmc-marketplace
/plugin install iterative-engineering@tmc-marketplace
```

## The Workflow

```
brainstorm ──────► tech-design ──────► implement
     ↓↑                 ↓↑                 ↓↑
 plan-review        plan-review        code-review
   (1+)               (1+)               (1+)
```

Each stage: produce artifact → review → fix → repeat until satisfied.

Re-entry is supported - run `/iterative:brainstorm` again after seeing the design, or `/code-review` multiple times.

## Skills

### Core Workflow

| Skill | Description |
|-------|-------------|
| `iterative:brainstorm` | Explore requirements and approaches before planning |
| `iterative:tech-design` | Transform brainstorms into structured technical plans |
| `plan-review` | Multi-agent review of plans (4 reviewers) |
| `iterative:implement` | TDD-driven task execution with progress tracking |
| `code-review` | Multi-agent code review (5 reviewers, full or quick mode) |
| `finishing-work` | Complete work with final review and PR creation |

### Supporting

| Skill | Description |
|-------|-------------|
| `plan-to-tasks` | Convert plans into task hierarchies (auto-runs after `iterative:tech-design`) |
| `fix-code-review-feedback` | Resolve PR review comments systematically |
| `git-worktree` | Isolated development using git worktrees |
| `agent-browser` | Browser automation using Vercel's agent-browser CLI |

## Agents

### Review Agents (Plan Review)

4 specialized reviewers analyze documents in parallel:

| Agent | Focus |
|-------|-------|
| `clarity-reviewer` | Vague language, ambiguity, structure |
| `completeness-reviewer` | Missing sections, gaps, dependencies |
| `specificity-reviewer` | Actionability, concrete details |
| `yagni-reviewer` | Scope creep, over-specification |

### Review Agents (Code Review)

5 specialized reviewers analyze code in parallel:

| Agent | Focus |
|-------|-------|
| `correctness-reviewer` | Logic errors, edge cases, bugs |
| `security-reviewer` | Vulnerabilities, auth, input validation |
| `performance-reviewer` | Algorithmic complexity, queries, caching |
| `simplicity-reviewer` | YAGNI, over-engineering, abstraction |
| `testing-reviewer` | Coverage, test quality, edge cases |

### Workflow Agents

| Agent | Purpose |
|-------|---------|
| `task-worker` | Executes subtasks using TDD cycle (Red-Green-Refactor-Commit) |
| `branch-setup-worker` | Creates git worktrees or branches for isolation |
| `pr-creator-worker` | Creates pull requests following repo conventions |
| `plan-to-tasks-worker` | Parses plans into task structures |

## Agent Teams (Experimental)

The `plan-review` and `code-review` skills support [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams) when enabled. This allows reviewers to cross-validate findings - security issues flagged alongside missing test coverage, performance concerns weighed against simplicity.

When agent teams are not available, the skills fall back to parallel subagent execution.

## HZL Integration (Optional)

This plugin supports [HZL](https://github.com/tmchow/hzl) for persistent task tracking across sessions and agents. Without HZL, the workflow skills use in-session task management.

See the [HZL repository](https://github.com/tmchow/hzl) for installation.

## Credits

This plugin draws inspiration from:

- [superpowers](https://github.com/obra/superpowers) by Jesse Vincent - TDD workflows, git worktrees, execution patterns
- [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) by Every - Brainstorming, document review, workflow orchestration

## License

MIT
