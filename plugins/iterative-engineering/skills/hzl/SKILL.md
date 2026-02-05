---
name: hzl
description: This skill should be used when working with HZL for task tracking, when the user asks to "break down work into tasks", "track tasks with HZL", "claim a task", "checkpoint progress", "complete a task", or when working on a project that uses HZL. Provides guidance on effective task management patterns for AI agents.
---

# HZL Task Management

HZL is a lightweight task tracking system for AI agents. It is a dumb ledger—it tracks work state but does not orchestrate, prioritize, or decide what to do next.

This skill teaches how to use HZL effectively for tracking work across projects.

## Core Workflow

Run `hzl guide` to get the full workflow documentation. This covers:
- When to use HZL vs skip it
- Project structure (projects, tasks, subtasks)
- Setting up and claiming tasks
- Checkpoints, comments, dependencies
- Troubleshooting common errors

**Quick reference:**
```bash
hzl guide                            # Full workflow documentation
hzl project list                     # Check existing projects
hzl task next -P <project> --claim   # Get and claim next task
hzl task checkpoint <id> "progress"  # Save progress
hzl task complete <id>               # Mark task done
```

---

## Advanced: Sizing Parent Tasks

HZL supports one level of nesting (parent → subtasks). Scope parent tasks to completable outcomes.

**The completability test:** "I finished [parent task]" should describe a real outcome.
- ✓ "Finished the user authentication feature"
- ✗ "Finished the backend work" (frontend still pending)
- ✗ "Finished home automation" (open-ended, never done)

**Scope by problem, not technical layer.** A full-stack feature (frontend + backend + tests) is usually one parent if it ships together.

**Split into multiple parents when:**
- Parts deliver independent value (can ship separately)
- You're solving distinct problems that happen to be related

**Adding context:** Use `-d` for details, `-l` for reference docs:
```bash
hzl task add "User authentication" -P myrepo \
  -d "OAuth2 flow per linked spec. Use existing session middleware." \
  -l docs/auth-spec.md,https://example.com/design-doc
```

**Don't duplicate specs into descriptions**—this creates drift. Reference docs instead.

**If no docs exist**, include enough detail for another agent to complete the task:
```bash
hzl task add "Add rate limiting" -P myrepo -s ready -d "$(cat <<'EOF'
100 req/min per IP, return 429 with Retry-After header.
Use RateLimiter from src/middleware/.
EOF
)"
```
Description supports markdown (16KB max).

## Advanced: Multi-Agent Coordination

When multiple agents work on the same project:

### Atomic claiming

HZL uses atomic claiming. Two agents calling `task next --claim` simultaneously will get different tasks. This prevents duplicate work.

### Authorship tracking

| Concept | What it tracks | Set by |
|---------|----------------|--------|
| **Assignee** | Who owns the task | `--assignee` on `claim` or `add` |
| **Event author** | Who performed an action | `--author` on other commands |

```bash
# Alice owns the task
hzl task claim <id> --assignee alice

# Bob adds a checkpoint (doesn't change ownership)
hzl task checkpoint <id> "Reviewed the code" --author bob
```

For AI agents that need session tracking:
```bash
hzl task claim <id> --assignee "Claude Code" --agent-id "session-abc123"
```

### Leases for long-running work

Use leases to indicate how long before a task is considered stuck:

```bash
hzl task claim <id> --assignee <name> --lease 30  # 30 minutes
```

### Recovering stuck tasks

If an agent dies or becomes unresponsive:

```bash
# Find tasks with expired leases
hzl task stuck --json

# Review checkpoints before taking over
hzl task show <task-id> --json

# Take over an expired task
hzl task steal <task-id> --if-expired --author agent-2
```

## Advanced: Human Oversight

Humans can monitor and steer agent work through HZL:

### Monitoring progress

```bash
hzl project list
hzl task list --project myapp --status in_progress
hzl task show <task-id>
```

Or use the web dashboard:
```bash
hzl serve  # Opens at http://localhost:3456
```

### Providing guidance

```bash
hzl task comment <task-id> "Please also handle the edge case where user is already logged in"
```

**Agents should check for comments before completing tasks:**
```bash
hzl task show <task-id> --json
```
Review the task history for steering feedback before marking complete.

## Advanced: Dependencies and Validation

### Adding dependencies after creation

```bash
hzl task add-dep <task-id> <depends-on-id>
```

### Validating the task graph

Check for circular dependencies or other issues:
```bash
hzl validate
```

## Best Practices

1. **Always use `--json`** for programmatic output
2. **Checkpoint at milestones** or before pausing work
3. **Check for comments** before completing tasks
4. **Use stable project names** derived from repo or agent identity
5. **Use dependencies** to express sequencing, not priority
6. **Use leases** for long-running work to enable stuck detection
7. **Review checkpoints** before stealing stuck tasks

## What HZL Does Not Do

HZL is deliberately limited:

- **No orchestration** - Does not spawn agents or assign work
- **No task decomposition** - Does not break down tasks automatically
- **No smart scheduling** - Uses simple priority + FIFO ordering

These are features for your orchestration layer, not for the task tracker.

## Additional Features

Not covered in detail here:

- Cloud sync via Turso for backup and multi-device access (`hzl init --sync-url ...`)
- Web dashboard for human monitoring (`hzl serve`)
- Priority and tags for categorization

For complete command options, use `hzl <command> --help`.
