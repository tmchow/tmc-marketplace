# Technical Plan Template

Use this template when writing the technical plan document.

## Full Template

```markdown
# [Feature] - Technical Plan

**Date:** [date]
**Status:** Planning
**Brainstorm:** [link to brainstorm doc, if exists]

## Overview
[Brief description of what we're building — 1-2 paragraphs max]

## Architecture
[High-level design, key components, data flow]

## Implementation Plan

### Parent 1: [Component/Feature Name]

#### 1.1 [Subtask Name]
**Test First:**
- [ ] [Test description - what behavior to verify]

**Implementation:**
- [ ] [Implementation step]
- [ ] [Implementation step]

**Files:** `src/path/to/file.ts`

#### 1.2 [Subtask Name]
**Depends on:** 1.1

**Test First:**
- [ ] [Test description]

**Implementation:**
- [ ] [Implementation step]

### Parent 2: [Component/Feature Name]
...

## Testing Strategy
- Unit tests: [approach]
- Integration tests: [approach]
- Manual verification: [steps]

## Risks and Mitigations
| Risk | Mitigation |
|------|------------|
| [Risk 1] | [How to address] |

## Open Questions
- [Any remaining unknowns]
```

## Subtask Granularity Guidelines

**Each subtask should be:**
- Completable in a single focused session (~30-60 min of agent work)
- Small enough for one atomic commit
- Testable independently (has its own RED/GREEN/REFACTOR cycle)

**A typical plan has:**
- 2-5 parent tasks (major components or features)
- 2-5 subtasks per parent
- Clear dependencies between subtasks (not everything depends on everything)

**Signs a subtask is too big:**
- Touches more than 3-4 files
- Has multiple distinct test scenarios
- Could be described as two separate changes

**Signs a subtask is too small:**
- Just renaming or moving code with no logic change
- Only modifying a single line
- No meaningful test to write

## TDD Structure Per Subtask

Every subtask follows the RGRC cycle:
1. **RED** - Write a failing test that defines the expected behavior
2. **GREEN** - Write minimal code to make the test pass
3. **REFACTOR** - Clean up while keeping tests green
4. **COMMIT** - One atomic commit per completed subtask

The plan document should define the RED step (what test to write) and the GREEN step (what implementation makes it pass) for each subtask. The REFACTOR step is left to the implementer's judgment.
