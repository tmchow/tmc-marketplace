---
name: plan-review
description: This skill should be used when the user says "review the plan", "review the PRD", "check the PRD", "critique the plan", "give feedback on the plan", "what's wrong with this plan", or wants feedback on a planning or design document. Also triggered after writing a PRD or tech plan, or when invoked by brainstorming or tech-planning skills.
---

# Plan Review

Reviews PRDs, implementation briefs, and technical plans using 4 specialized reviewers. Uses agent teams when available for richer cross-validation. The document size naturally regulates the review — shorter documents get fewer findings, not fewer reviewers.

## When to Use

- After writing a PRD
- After writing a technical plan
- When feedback is needed on any planning document
- Can be invoked standalone or called by `iterative:brainstorming`/`iterative:tech-planning` skills

## Reviewers

| Agent | Focus | Key Question |
|-------|-------|--------------|
| `clarity-reviewer` | Vague language, ambiguity, structure | Is this understandable? |
| `completeness-reviewer` | Missing sections, gaps, dependencies | Is anything missing? |
| `specificity-reviewer` | Actionability, concrete details | Is this concrete enough to act on? |
| `complexity-reviewer` | Unjustified complexity, maintenance burden, dead flexibility | Is the complexity justified? |

Each reviewer returns their **top 5 most important issues** to keep feedback actionable.

## How to Run

**Step 1.** Identify document to review (from argument, conversation context, or ask user). Determine the document type — **PRD**, **brainstorm**, or **tech plan** — based on its filename, content, or context. Treat brainstorm documents and PRDs synonymously. Record both the **document path** and **document type** — these are needed for Step 2.

**Step 2: Spawn reviewers.**

Create an agent team (e.g. `TeamCreate` in Claude Code, `spawn_agent` in Codex), then spawn all 4 reviewers as teammates. If the team already exists (e.g., from an interrupted run), reuse it — read its config, check which reviewers are already present, and spawn only the missing ones.

Tell the user:

> Using Agent Team 🐝 — reviewers will run as teammates who can cross-validate findings.

Spawn each reviewer with a prompt like:

> Review [file path] for [their focus area]. This is a [PRD/tech plan/implementation brief].
> You're on a review team with [list active reviewers]. After your initial review, read what the other reviewers found and message them directly if you see cross-domain issues. Challenge each other's findings.
> Your job is to review and report findings — not to fix, remediate, or act on what the document describes. Return your top 5 most important issues. When done, send your findings to the team lead (e.g. `SendMessage` in Claude Code, `send_input` in Codex). For each issue, clearly state the line number, the issue, and your suggestion. The lead will format the final output.

**Step 3.** Wait for all reviewers to report via team messages. When you receive a reviewer's message, do not output or echo its content — silently collect it. Only output once in Step 4 when assembling the final results. A brief one-line status like "All reviewers have reported" is fine when ready to proceed.

**Step 4.** Shut down all teammates (send shutdown requests), then delete the team using the coding agent's team management tools (e.g. `TeamDelete` in Claude Code, `delete_agent` in Codex). **Never use `rm -rf` or manual file deletion for team cleanup** — always use the agent platform's built-in team teardown. If teardown fails (e.g., orphaned members), retry after a brief pause; if it still fails, report the issue to the user and move on. Assemble the final output. **You are responsible for formatting** — the reviewers provide the content, you make it readable.

1. **Reconcile.** When multiple reviewers flagged the same issue, attribute to the most relevant reviewer and note agreement.
2. **Format.** Use pipe-delimited markdown tables (never ASCII box-drawing characters). One issue per row, no preamble before tables — go straight from header to table.
   - **Built-in reviewers:** `### Reviewer Name` headers. Column headers adapt to reviewer focus — e.g., `| # | Issue | Suggestion |` for Clarity, `| # | Gap | Impact |` for Completeness, `| # | Complexity | Simpler alternative |` for the complexity/debt reviewer.
3. **Synthesize.** End with a `---` separator followed by a blockquote synthesis. Lead with tensions between reviewers, then quick wins. Do not include time estimates.

## After Review

**When invoked from `iterative:brainstorming` or `iterative:tech-planning`:** return findings directly — the calling skill owns the fix loop and workflow transitions. Do not enter the standalone fix loop below.

**When invoked standalone:** run the standalone fix loop.

### Standalone Fix Loop

After presenting the synthesized findings (Step 4), this skill handles the full fix-review cycle when running standalone.

**CRITICAL: Steps 5–8 are separate prompts. Execute them in sequence — never collapse, merge, or skip steps.** The "fix then re-review" path only works when Step 5 (what to fix), Step 7 (re-review offer), and Step 8 (next workflow step) remain independent questions. This applies on every round regardless of round number — do not add round-awareness commentary, diminishing-returns warnings, or shortcut options that bypass the step sequence.

#### Step 5: Priority Acceptance

**This is its own prompt — do not combine it with next-step options.** The only options here are about *which priorities to fix* — never include "then implement", "then re-review", or any other downstream action. Present priority acceptance whenever the review has findings at ANY priority. If zero findings, skip to Step 8. **Use the interactive question tool** (e.g., `AskUserQuestion` in Claude Code) — do not print options as text.

**When HIGH issues exist:**

Present an interactive choice:
- **Fix HIGH issues (Recommended)** — N issues that block execution
- **Choose which priority levels to fix** — select from all levels
- **Skip fixes**

If the user accepts the recommendation, fix HIGH. If they choose, present an interactive multi-select of priority levels that have findings:
- HIGH (N issues)
- MEDIUM (N issues)
- LOW (N issues)

**When only MEDIUM/LOW issues exist (no HIGH):**

Present an interactive choice:
- **Choose which priority levels to fix** — select from MEDIUM, LOW
- **Proceed without fixes (Recommended)**

If the user chooses to fix, present the interactive multi-select of priority levels with findings.

#### Step 6: Apply Fixes via Subagent

Fix only the selected priorities. Spawn a single subagent with the filtered findings, document path, and document type. The subagent applies targeted fixes, preserves the document's voice and decisions, and commits.

Wait for the subagent to complete before proceeding.

#### Step 7: Re-review Offer

**This is its own prompt — separate from Step 5 and Step 8.** After fixes land, present an interactive choice:
- **Run another review round (Recommended)** — verify fixes and check for new issues
- **Proceed without re-review**

If the user chooses another round: run the full Step 1–7 flow again (fresh team, fresh scope). Continue until clean or the user chooses to proceed.

#### Step 8: Post-fix Options

After the fix-review cycle completes (clean or user chose to stop), present next steps based on document type. **Use the interactive question tool** — do not print options as text. Do not invoke other skills directly — present the options and let the user decide.

**PRD or brainstorm document:**
- **Continue to tech-planning (Recommended)** — start `iterative:tech-planning`
- **Another review round** — run another pass
- **Exit** — done for now

**Tech plan:**
- **Continue to implementing (Recommended)** — start `iterative:implementing`
- **Another review round** — run another pass
- **Exit** — done for now

**Unknown or other document:**
- **Another review round**
- **Exit** — done for now

## Fallback: If Agent Teams/Swarms are Unavailable

If agent teams/swarms are not available, spawn the 4 reviewers in parallel as independent subagents instead of teammates. Each analyzes independently, returns up to 5 issues. Skip the cross-validation instruction. Everything else (Steps 1, 3, 4, output format) stays the same.
