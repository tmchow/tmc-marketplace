# Spike Document Template

Use this template when creating spike documents. Update the Progress section as the spike proceeds. Finalize Findings, Decisions, and Impact when the spike concludes.

## Document Structure

```markdown
# Spike: [Topic]

**Date:** [date]
**Status:** In Progress
**Branch:** spike/[topic]
**PRD:** [path, if exists]
**Tech Plan:** [path, if exists]
```

**Valid status values:** `In Progress`, `Complete`, `Paused`, `Abandoned`

## Sections

### Context (always include)

```markdown
## Context
[Why this spike exists. What uncertainty it addresses. Which PRD requirements
or decisions need validation, if applicable.]
```

### Validation Goal (always include)

```markdown
## Validation Goal
[What we're trying to validate. What outcome would change direction.]

Spike is complete when [what understanding/confidence we'll have — describe
the information, not a decision].
```

**Acceptance guidelines:**

The validation goal describes the understanding we'll have, not a conclusion:

- "...we can describe how the drag interaction feels and whether users find it intuitive" (understanding)
- "...we know whether the reduced scope still delivers value to users" (understanding)
- NOT "...we can decide if we should proceed" (that's a decision made after the spike)
- NOT "...we can answer whether this is a blocker" (decision, not information)

The spike gathers information through building and experiencing. Decisions are made afterward based on what was learned.

### Approach (always include)

```markdown
## Approach
[How the spike was built — within existing system or standalone prototype.
Key scoping decisions. What was deliberately left out.]
```

### Progress (update during spike, remove when finalizing)

A working note for resuming the spike if paused. Brief — not a play-by-play log.

```markdown
## Progress
[What's been built so far. Key feedback received. What's next.]
```

When the spike concludes, fold relevant content into Findings and Decisions, then remove this section.

### Findings (finalize when spike concludes)

```markdown
## Findings
[What was learned. What was confirmed. What surprised us. What didn't work.]
```

### Decisions (finalize when spike concludes)

```markdown
## Decisions
- [Decision]: [Rationale]
- [Requirement confirmed/changed]: [Why]
```

### Impact on Upstream Docs (finalize when spike concludes)

```markdown
## Impact on Upstream Docs
[Summary of PRD and/or tech plan changes made based on this spike.
Each change should also be documented in the PRD itself with full rationale —
the PRD should be self-sufficient for downstream stages without needing to
read this spike doc.]
```

### Spike Code (always include)

```markdown
## Spike Code
**Worktree:** [path]
**Branch:** spike/[topic]
**Reusable:** No
```

If any code is genuinely reusable (rare), describe what specifically and where. By default, spike code is throwaway.
