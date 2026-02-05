---
name: plan-to-tasks
description: Use when converting a technical plan into trackable tasks. Automatically uses HZL if project uses HZL for task tracking, otherwise uses TodoWrite. Parses plan structure, presents for approval, creates tasks with dependencies.
allowed-tools: Glob, Grep, Read, Bash(hzl *), TodoWrite, Task
model: haiku
---

# Plan to Tasks

Converts technical plans into trackable tasks using HZL or TodoWrite.

## When to Use

- After completing a technical plan
- When you have a structured document to break into tasks
- Called by create-technical-plan skill at handoff
- Can be invoked standalone

## Task System Detection

If project uses HZL for task tracking → use HZL
Otherwise → use TodoWrite

Detection is automatic based on project context (AGENTS.md, CLAUDE.md).

## Workflow

```
Step 1: Identify Plan + Task System
├── Find plan document (argument, conversation, or ask)
├── Detect if project uses HZL for task tracking
└── Report which system will be used

Step 2: Parse Plan → Proposed Structure
├── Spawn plan-to-tasks-worker agent
├── Extract parents, subtasks, dependencies
├── Infer granularity from plan structure (ask if unclear)
└── Include descriptions from plan + link to doc

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
└── Report: "Created [N] parents, [M] subtasks"

Step 7: Handoff → executing-work
```

## Task Descriptions

- Copy relevant plan prose into description (default)
- If very complex: summarize, reference section by name
- HZL: link to plan file via `-l docs/plans/[plan].md`
- TodoWrite: reference plan file path in description

## Output Format

```markdown
## Task Structure

**Task System:** HZL / TodoWrite
**Plan Document:** [path]

### Proposed Structure

Parent 1: [Title]
├── Subtask 1.1: [Title]
├── Subtask 1.2: [Title]
└── Subtask 1.3: [Title]

Parent 2: [Title]
├── Subtask 2.1: [Title] (depends on 1.3)
└── Subtask 2.2: [Title]

---
**Total:** [N] parents, [M] subtasks, [D] dependencies

Create these tasks?
A) Yes, create all (default)
B) Review each parent first
C) Give feedback
```

## If Plan Has No Clear Structure

If the plan document lacks clear sections or actionable items:
1. Point this out to user
2. Offer to help structure it first
3. Then re-run plan-to-tasks

Don't force-create tasks from an ambiguous plan.
