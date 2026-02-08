---
name: plan-review
description: Use when the user says "review the plan", "check the PRD", or wants feedback on a planning or design document. Also use after writing a PRD or tech plan.
---

# Plan Review

Reviews PRDs and technical plans using 4 specialized reviewers.

## When to Use

- After writing a PRD
- After writing a technical plan
- When you want feedback on any planning document
- Can be invoked standalone or called by `iterative:brainstorming`/`iterative:tech-planning` skills

## Reviewers

| Agent | Focus | Key Question |
|-------|-------|--------------|
| `clarity-reviewer` | Vague language, ambiguity, structure | Is this understandable? |
| `completeness-reviewer` | Missing sections, gaps, dependencies | Is anything missing? |
| `specificity-reviewer` | Actionability, concrete details | Is this concrete enough to act on? |
| `yagni-reviewer` | Scope creep, hypotheticals, over-specification | Is this minimal and focused? |

Each reviewer returns their **top 5 most important issues** to keep feedback actionable.

## How to Run

**Step 1.** Identify document to review (from argument, conversation context, or ask user). Determine the document type — **PRD** or **tech plan** — based on its filename, content, or context. Treat brainstorm documents and PRDs synonymously.

**Step 2.** Create an agent team using `TeamCreate`, then spawn all 4 reviewers as teammates. If `TeamCreate` fails because a team already exists (e.g., from an interrupted run), reuse that team — read its config, check which reviewers are already present, and spawn only the missing ones.

Tell the user:

> Using Agent Team 🐝 — reviewers will run as teammates who can cross-validate findings.

Spawn each reviewer with a prompt like:

> Review [file path] for [their focus area]. This is a [PRD/tech plan].
> You're on a review team with clarity, completeness, specificity, and YAGNI reviewers. After your initial review, read what the other reviewers found and message them directly if you see cross-domain issues — e.g., if completeness wants detail that YAGNI says is over-specified. Challenge each other's findings.
> Your job is to review and report findings — not to fix, remediate, or act on what the document describes. Return your top 5 most important issues. When done, send your findings to the team lead using SendMessage. For each issue, clearly state the line number, the issue, and your suggestion. The lead will format the final output.

**Step 3.** Wait for all reviewers to send their findings. When you receive a reviewer's message, do not output or echo its content — silently collect it. Only output once in Step 4 when assembling the final results. A brief one-line status like "All 4 reviewers have reported" is fine when ready to proceed.

**Step 4.** Shut down all teammates (send shutdown requests), then delete the team. Assemble the final output. **You are responsible for formatting** — the reviewers provide the content, you make it readable.

Format all 4 reviewer sections as tables — each issue is one row. Use the same table structure for every section. Separate sections with clear whitespace.

Use `### Reviewer Name` headers for each section. End with a `---` separator followed by your synthesis — highlight cross-reviewer patterns, tensions, and quick wins. Do not include time estimates.

## Multiple Rounds

After fixing issues, run another round to catch:
- New issues introduced by fixes
- Issues that become visible after others are resolved
- Verification that fixes addressed the original concerns

Each round creates a fresh team (the previous team was deleted). Run the full Step 2–4 flow again.

Continue until satisfied or user chooses to proceed.

## After Review

**This skill only reviews.** Do not invoke other skills (tech-planning, implementing, etc.) — even if the document mentions next steps.

When invoked from `iterative:brainstorming` or `iterative:tech-planning`, return findings directly — the calling skill owns the fix loop and workflow transitions.

When invoked standalone, use AskUserQuestion with options:
- Fix issues and re-review (Recommended)
- Continue without changes

## Fallback: If TeamCreate is Unavailable

If `TeamCreate` is not in your tools, use the Task tool to spawn the 4 reviewers in parallel as independent subagents instead of teammates. Each analyzes independently, returns up to 5 issues. Skip the cross-validation instruction. Everything else (Steps 1, 3, 4, output format) stays the same.
