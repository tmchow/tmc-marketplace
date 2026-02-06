---
name: plan-review
description: Multi-agent review of plans and brainstorm documents. This skill should be used when the user says "review the plan", "check the brainstorm", or wants feedback on a design document. Four reviewers - clarity, completeness, specificity, YAGNI.
allowed-tools: Glob, Grep, Read, Task
---

# Plan Review

Reviews brainstorm documents and technical plans using 4 specialized reviewers.

## When to Use

- After writing a brainstorm document
- After writing a technical plan
- When you want feedback on any planning document
- Can be invoked standalone or called by `iterative:brainstorm`/`iterative:tech-design` skills

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

**When using Agent Teams, tell the user exactly this:**

> Using Agent Teams 🐝 — reviewers will run as teammates who can cross-validate findings.

### Mode A: Agent Team (if enabled)

**Step 1.** Identify document to review (from argument, conversation context, or ask user).

**Step 2.** Create agent team with 4 reviewer teammates. Spawn each with a prompt that includes their review focus, the document, max 5 issues, and this cross-validation instruction:

> "You are on a review team with other reviewers. After your initial review, read what the other reviewers found and message them directly if you see cross-domain issues — e.g., if completeness wants detail that YAGNI says is over-specified. Challenge each other's findings."

**Step 3.** Let reviewers work and cross-validate. Brief one-line status is fine. Don't repeat status or narrate your thinking. Wait until discussion settles.

**Step 4.** Synthesize and present. Collect final findings from all reviewers. **You must reformat all findings into the exact output format shown below — do NOT pass through raw reviewer text.** Then clean up the team.

### Mode B: Parallel Subagents (fallback)

**Step 1.** Identify document to review.

**Step 2.** Spawn 4 reviewer agents via Task tool in parallel. Each analyzes independently, returns up to 5 issues.

**Step 3.** Collect findings. Deduplicate overlapping issues.

**Step 4.** **You must reformat all findings into the exact output format shown below — do NOT pass through raw agent text.**

### Benefits of team mode

- Reviewers message each other directly — cross-domain insights emerge from debate, not just lead synthesis
- Conflicting findings surface real tradeoffs (e.g., YAGNI vs completeness)
- Multiple reviewers flagging same issue = high confidence

**Note:** Agent teams use more tokens than subagents. For simple documents, subagent mode may be sufficient.

## Output Format

**Your output for Step 4 must look exactly like this example. Copy this structure.**

```markdown
## Plan Review Results

### Clarity

| # | Issue | Suggestion |
|---|-------|------------|
| 1 | "minus comments and checkpoints" is ambiguous | Clarify: "excluding comments and checkpoints for those children" |
| 2 | Approach B conclusion dangles without rationale | Expand reasoning or remove |

### Completeness

| # | Gap | Impact |
|---|-----|--------|
| 1 | `blocked_by` shape undefined | Affects JSON contract |
| 2 | Subtask ordering not specified | Agents may depend on deterministic ordering |

### Specificity

| # | Issue | What's needed |
|---|-------|---------------|
| 1 | Service method signature missing | Concrete interface for new/modified method |

### YAGNI

| # | Over-specification | Simpler alternative |
|---|--------------------|---------------------|
| 1 | Re-listing all 16+ fields | Just say "same as task show minus comments/checkpoints" |

---

**Summary:** 6 issues across 4 categories.

> **High confidence** (multiple reviewers): Field list needs to be explicit or reference existing schema — don't do both.
>
> **Tension** (Completeness vs YAGNI): Completeness wants edge case detail; YAGNI says defer. Resolution: pin down the JSON contract shape, defer implementation specifics.
>
> **Quick wins:** Clarify `--deep` without `--json` behavior, specify subtask sort order.
```

**Rules:**
- Start with `## Plan Review Results` — nothing before it. No "here's what I found" or "let me synthesize."
- One `### Section` per reviewer, each containing **only** a pipe-delimited markdown table.
- Pipe tables use `| col | col |` with `|---|---|` separators. **Never** ASCII box-drawing (`┌─┬─┐`), key-value lists (`#: 1`, `Issue:`), or `────` separators.
- Column headers vary by reviewer (Issue/Suggestion, Gap/Impact, etc.).
- Single summary section after `---` with blockquotes. This is the only place for cross-reviewer insights.
- Skip empty reviewer sections.

## Multiple Rounds

After fixing issues, run another round to catch:
- New issues introduced by fixes
- Issues that become visible after others are resolved
- Verification that fixes addressed the original concerns

Continue until satisfied or user chooses to proceed.

## After Review

Use AskUserQuestion with options:
- Fix issues now
- Fix issues, then another review round
- Accept as-is and continue
