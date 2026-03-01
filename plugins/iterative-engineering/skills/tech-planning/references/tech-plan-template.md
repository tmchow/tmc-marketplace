# Technical Plan Template

Use this template when writing the technical plan document. Every subtask must meet the Plan Quality Bar defined in the skill — file paths, decisions with rationale, concrete test scenarios, existing patterns to follow.

## Document Structure

Every plan follows this structure:

### Header

```markdown
# [Feature] - Technical Plan

**Date:** [date]
**Status:** Planning
**PRD:** [link to PRD, if exists]

## Overview
[1-2 paragraphs: what we're building and why]

## Architecture
[High-level design: key components, data flow, key decisions. ASCII diagram if helpful]
```

### Subtask Format

Every subtask uses the same standardized format so it can be directly converted into tasks in a tracking system. Numbering is `Parent.Subtask` (e.g., 1.1, 1.2, 2.1) — use these numbers for cross-referencing dependencies.

```markdown
#### 1.1 [Action-oriented title]

**Depends on:** none
**Files:** `path/to/file.ts`, `path/to/test.test.ts`

[What this subtask accomplishes — the change, approach, key decisions,
rationale. Free-form but specific enough to act on without clarifying questions.]

**Test scenarios:** (`path/to/test.test.ts`)
- [Input/condition] → [expected output/behavior]
- [Edge case] → [expected handling]
- [Error case] → [expected error]

**Verify:** [How to confirm it works]
```

**Important:** Feature subtasks must include the test file path in both `**Files:**` and `**Test scenarios:**`. The parenthetical after "Test scenarios:" tells the implementer exactly where to write the tests. Without it, test scenarios get skipped.

```markdown
#### 1.2 [Action-oriented title]

**Depends on:** 1.1
**Files:** `path/to/another-file.ts`, `path/to/test.test.ts`

[Description...]

**Test scenarios:**
- ...

**Verify:** ...
```

**Field rules:**
- **Title** — Action-oriented, becomes the task title
- **Depends on** — Always present. Use subtask numbers (e.g., `1.1, 2.3`) or `none`. These become task dependencies during conversion
- **Files** — File paths to create or modify. Become task links during conversion
- **Description** — Everything the implementer needs: what, why, approach, patterns to follow. Reference PRD requirement numbers (e.g., "Satisfies requirement #2") when a subtask directly fulfills a PRD requirement — this enables downstream validation during code review
- **Test scenarios** — Concrete inputs → expected outputs. Parenthetical names the test file (e.g., `**Test scenarios:** (path/to/test.test.ts)`)
- **Verify** — How to confirm the subtask works

### Closing Sections

```markdown
## Testing Strategy
- New coverage: [test scenarios that validate genuinely new behavior — what proves the core change works, as distinct from existing tests updated for new data shapes]
- Unit tests: [what's covered and approach]
- Integration tests: [approach]
- Manual verification: [specific steps to check]

## Risks and Mitigations
| Risk | Mitigation |
|------|------------|
| [Specific risk] | [Concrete mitigation] |

## Open Questions
- [Any remaining unknowns, or "None — all decisions resolved"]
```

## What "Enough Detail" Looks Like

### Not enough (too vague)

```markdown
#### 1.1 Add dependency lookup

**Depends on:** none
**Files:** `src/services/user-service.ts`

Add a method to get blocking dependencies for tasks.

**Test scenarios:**
- Test that it returns correct results
- Test edge cases

**Verify:** Run tests
```

An implementer would need to ask: blocking how? What query strategy? What does the return value look like? What edge cases?

### Enough (decisions are clear, implementer can act)

```markdown
#### 1.1 Add batched blocking dependency lookup to UserService

**Depends on:** none
**Files:** `src/services/user-service.ts`, `src/services/user-service.test.ts`

Add a method that takes an array of user IDs and returns which ones have
incomplete dependencies blocking them. Query `user_dependencies` joined
with `users_current` to find deps where status != 'done'. Use parameterized
IN clause (same pattern as `getTitlesByIds`). Return a map keyed by
user ID — absent keys mean no blockers.

Standalone method rather than extending `getSubItems()` — keeps it
unchanged and composable for other callers. The existing `getBlockedByMap()`
only covers `ready` status which is too narrow — need all non-terminal statuses.

**Test scenarios:** (`src/services/user-service.test.ts`)
- Empty input → empty map
- Tasks with no dependencies → empty map
- Tasks with incomplete dependencies → map of task_id to blocking dep IDs
- Dependencies already `done` → excluded from results
- Mix of blocked and unblocked tasks in single call → only blocked ones in map
- Tasks in `draft` and `ready` status → included (not just `ready`)

**Verify:** Run task-service tests
```

The implementer knows: which files, the query strategy, why this design, the return semantics, every test scenario. They write the actual code.

### Too much (pre-writing the implementation)

A subtask where the description is replaced by complete code — e.g., a 50-line function body with the full query, map construction, and error handling, plus 30 lines of test code with setup, assertions, and teardown. Essentially writing the feature twice (once in the plan, once during implementation). This is brittle because the code was written without running it, and the implementer follows it blindly even if they discover a better approach during actual implementation.

## Quality Checklist

Before the plan is complete, verify every subtask has:

- [ ] Standardized format (title, depends on, files, description, test scenarios, verify)
- [ ] `Depends on` field present (even if "none")
- [ ] File paths for files to create or modify
- [ ] Description specific enough to act on without clarifying questions
- [ ] Key decisions with rationale (approach, query strategy, data flow)
- [ ] Concrete test scenarios with specific inputs and expected outputs
- [ ] Test file path in `Files:` and parenthetical in `Test scenarios:` (feature subtasks)
- [ ] Reference to existing patterns to follow (where applicable)

And the plan overall has:

- [ ] Subtasks numbered as Parent.Subtask (1.1, 1.2, 2.1) for cross-referencing
- [ ] Dependency graph is complete — every subtask's blockers are explicit
- [ ] Architecture section explains the approach and key decisions
- [ ] Testing strategy identifies new coverage and covers unit, integration, and manual verification
- [ ] Risks identified with concrete mitigations

## Subtask Granularity Guidelines

**Right-sized subtask:**
- Scoped to one atomic commit
- Typically touches 2-3 files
- Has clear, testable outcome
- Accomplishes one coherent thing

**Signs a subtask is too big:**
- Touches more than 3-4 files
- Has multiple unrelated changes
- Could be described as two separate things

**Signs a subtask is too small:**
- Single line change with no logic
- No meaningful test scenario
- Just renaming or moving code
