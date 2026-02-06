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

Create a review team with specialized teammates:

```
1. Identify document to review
   ├── Use document from argument
   ├── Or infer from conversation context
   └── Or ask user to specify

2. Create agent team with 4 reviewer teammates
   Spawn each with a detailed prompt that includes:
   ├── Their review focus and the document to review
   ├── Max 5 issues, each with: location, problem, and suggested fix
   └── Cross-validation instruction (see below)

   Include this in every reviewer's spawn prompt:
   "You are on a review team with other reviewers. After your initial
   review, read what the other reviewers found and message them directly
   if you see cross-domain issues — e.g., if completeness wants detail
   that YAGNI says is over-specified, or if multiple reviewers flagged
   the same concern. Challenge each other's findings."

3. Let reviewers work and cross-validate
   ├── Reviewers do their initial review, then discuss with each other
   ├── Brief one-line status is fine (e.g., "Clarity and YAGNI done, waiting on 2 more")
   ├── Don't repeat status, narrate your thinking, or fill the wait with commentary
   └── Wait until discussion settles before synthesizing

4. Synthesize, present, and clean up
   ├── Collect final findings from all reviewers (post-discussion)
   ├── REFORMAT into the Output Structure below
   │   ### [Reviewer] header → pipe table (| # | Col | Col |) → repeat → --- → Summary
   │   Do NOT pass through reviewer output as-is
   ├── Put synthesis insights (including cross-reviewer debates) in summary blockquotes
   └── Then clean up the team
```

**Benefits of team mode:**
- Reviewers message each other directly — cross-domain insights emerge from debate, not just lead synthesis
- Conflicting findings surface real tradeoffs (e.g., YAGNI vs completeness)
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

4. Synthesize and reformat into the Output Structure below
   ├── Deduplicate overlapping issues
   ├── REFORMAT all findings into:
   │   ### [Reviewer] header → pipe table (| # | Col | Col |) → repeat → --- → Summary
   │   Do NOT pass through agent output as-is
   └── Put synthesis insights in the summary blockquotes at the end
```

## Output Structure

**The output must follow this exact structure, in this order. Nothing else.**

```
## Plan Review Results

### [Reviewer Name]              ← one section per reviewer
| # | Col A | Col B |            ← pipe-delimited table, immediately after header
|---|-------|-------|
| 1 | ...   | ...   |

### [Next Reviewer]
| # | Col A | Col B |
|---|-------|-------|
| 1 | ...   | ...   |

[...repeat for each reviewer...]

---

**Summary:** N issues across M categories.

> **High confidence** (multiple reviewers): ...
>
> **Tension** (X vs Y): ...
>
> **Quick wins:** ...
```

**Rules:**
- **This structure is the entire output.** Do not add anything before `## Plan Review Results` — no introductory paragraphs, no "here's what I found" narrative.
- **One `###` section per reviewer**, each containing only a pipe-delimited table. No prose between the header and the table.
- **Pipe-delimited markdown tables only** (`| col | col |` with `|---|---|`). Do NOT use ASCII box-drawing characters (`┌─┬─┐`, `│`, `└─┴─┘`).
- **One summary section at the end**, after the `---` rule. This is the only place for cross-reviewer insights, tensions, and quick wins. Do not put summary content anywhere else.
- **Skip empty reviewer sections.** If a reviewer found no issues, omit that section entirely.

See `references/review-output-template.md` for a complete example.

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
