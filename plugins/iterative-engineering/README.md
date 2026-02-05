# Iterative Engineering Plugin

Iterative development workflow skills for Claude Code - brainstorming, planning, multi-agent reviews, TDD execution, and PR feedback resolution.

## Installation

```bash
# Add the marketplace (if not already added)
/plugin marketplace add tmchow/tmc-marketplace

# Install the plugin
/plugin install iterative-engineering@tmc-marketplace
```

## Skills

| Skill | Description |
|-------|-------------|
| `brainstorming` | Explore requirements and approaches before planning |
| `create-technical-plan` | Transform brainstorms into structured technical plans |
| `plan-to-tasks` | Convert plans into task hierarchies |
| `executing-work` | TDD-driven task execution with progress tracking |
| `finishing-work` | Complete work with review and PR creation |
| `plan-review` | Multi-agent review of technical plans |
| `code-review` | Multi-agent code review with specialized reviewers |
| `fix-code-review-feedback` | Resolve PR review comments systematically |
| `git-worktree` | Isolated development using git worktrees |
| `agent-browser` | Browser automation using Vercel's agent-browser CLI |
| `hzl` | HZL task tracking integration (optional) |

## Agents

### Workflow Agents
- `task-worker` - Executes subtasks using TDD cycle
- `branch-setup-worker` - Creates git worktrees or branches
- `pr-creator-worker` - Creates pull requests following conventions
- `plan-to-tasks-worker` - Parses plans into task structures

### Review Agents (Plan Review)
- `clarity-reviewer` - Reviews for vague language and ambiguity
- `completeness-reviewer` - Identifies missing sections and gaps
- `specificity-reviewer` - Checks actionability and concrete details
- `yagni-reviewer` - Flags scope creep and over-specification

### Review Agents (Code Review)
- `correctness-reviewer` - Logic errors, edge cases, bugs
- `security-reviewer` - Vulnerabilities, auth, input validation
- `performance-reviewer` - Algorithmic complexity, queries, caching
- `simplicity-reviewer` - YAGNI, over-engineering, abstraction
- `testing-reviewer` - Coverage, test quality, edge cases

## Workflow Example

```
/brainstorming        → Explore the problem space
/create-technical-plan → Structure the approach
/plan-to-tasks        → Break into trackable tasks
/executing-work       → Implement with TDD
/code-review          → Review before finishing
/finishing-work       → Complete with PR
```

## HZL Integration (Optional)

This plugin supports [HZL](https://github.com/tmchow/hzl) for persistent task tracking, but it's not required. Without HZL, the workflow skills use in-session task management.

To install HZL:
```bash
curl -fsSL https://raw.githubusercontent.com/tmchow/hzl/main/scripts/install.sh | bash
```

## License

MIT
