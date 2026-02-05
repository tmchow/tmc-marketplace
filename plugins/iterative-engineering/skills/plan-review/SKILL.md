---
name: plan-review
description: Use when reviewing brainstorm documents or technical plans for quality. Spawns 4 specialized reviewers (clarity, completeness, specificity, YAGNI) to analyze in parallel and synthesize findings. Uses agent teams when available for richer cross-validation.
allowed-tools: Glob, Grep, Read, Task
model: opus
---

# Plan Review

Reviews brainstorm documents and technical plans using 4 specialized reviewers.

## When to Use

- After writing a brainstorm document
- After writing a technical plan
- When you want feedback on any planning document
- Can be invoked standalone or called by brainstorming/create-technical-plan skills

## Reviewers

| Agent | Focus | Key Question |
|-------|-------|--------------|
| `clarity-reviewer` | Vague language, ambiguity, structure | Is this understandable? |
| `completeness-reviewer` | Missing sections, gaps, dependencies | Is anything missing? |
| `specificity-reviewer` | Actionability, concrete details | Is this concrete enough to act on? |
| `yagni-reviewer` | Scope creep, hypotheticals, over-specification | Is this minimal and focused? |

Each reviewer returns **max 5 issues** to keep feedback actionable.

## Execution Mode

**First, check if agent teams are enabled for this session.**

### Mode A: Agent Team (if enabled)

Create a review team with specialized teammates:

```
1. Identify document to review
   ├── Use document from argument
   ├── Or infer from conversation context
   └── Or ask user to specify

2. Create agent team with 4 reviewer teammates
   Spawn each with a detailed prompt, for example:

   "Review [document path] for clarity issues. Focus on vague language,
   ambiguity, and structural problems. Return up to 5 issues, each with:
   location, problem description, and suggested fix."

3. Wait for all teammates to complete their reviews
   └── Do NOT start synthesizing until all reviewers report back

4. Lead synthesizes findings
   ├── Collect issues from all reviewers
   ├── Deduplicate overlapping issues
   ├── Note where multiple reviewers flagged the same concern (high confidence)
   ├── Note conflicting perspectives (e.g., YAGNI vs Completeness)
   └── Prioritize by impact

5. Present consolidated results to user

6. Clean up the team when done
```

**Benefits of team mode:**
- Reviewers may catch issues others missed
- Conflicting findings surface real tradeoffs
- Multiple reviewers flagging same issue = high confidence

**Note:** Agent teams use more tokens than subagents. For simple documents, subagent mode may be sufficient.

### Mode B: Parallel Subagents (fallback)

When agent teams are not available:

```
1. Identify document to review

2. Spawn 4 reviewer agents via Task tool in parallel
   └── Each analyzes the document independently

3. Collect findings from all agents
   └── Each returns up to 5 issues

4. Synthesize findings
   ├── Deduplicate overlapping issues
   ├── Prioritize by impact
   └── Present consolidated list

5. Present to user
```

## Output Format

```markdown
## Plan Review Results

### Clarity (N issues)
- [Issue description]

### Completeness (N gaps)
- [Gap description]

### Specificity (N issues)
- [Issue description]

### YAGNI (N suggestions)
- [Suggestion to cut/simplify]

---
**Summary:** [X] issues found across [Y] categories.
**Mode:** Agent Team / Parallel Subagents
```

## Multiple Rounds

After fixing issues, run another round to catch:
- New issues introduced by fixes
- Issues that become visible after others are resolved
- Verification that fixes addressed the original concerns

Continue until satisfied or user chooses to proceed.

## After Review

```
Review complete. What next?
├── A) Fix issues now
├── B) Fix issues, then another review round
└── C) Accept as-is and continue
```
