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

The orchestrator can also run **external model CLIs** inline (Gemini, Codex, Claude) for independent, model-diverse perspectives (experimental, opt-in). See External Reviewers below.

## External Reviewers (Experimental)

External reviewers invoke a **different model's CLI** for an independent document review, providing model diversity. Different model families have different blind spots — a finding confirmed across models is higher confidence than one from a single model. This feature is experimental; CLI availability and behavior may vary.

The orchestrator runs external CLIs **directly** (not via subagents) — this ensures Bash calls happen in the main agent context where the user can approve them normally, avoiding permission issues with subagent CLI access.

| CLI | Invocation | Safety mode |
|-----|------------|-------------|
| Google Gemini | `gemini -s -p "..."` | Sandboxed (reads file from workspace, no write access) |
| OpenAI Codex | `codex exec --sandbox read-only "..."` | Sandboxed read-only, non-interactive |
| Anthropic Claude | `claude -p "..." --max-turns 3` | Bounded turns, no session persistence |

All reviewer sources are **opt-in** — the user chooses which combination of built-in reviewers and external CLIs to run.

## How to Run

**Step 1.** Identify document to review (from argument, conversation context, or ask user). Determine the document type — **PRD**, **brainstorm**, or **tech plan** — based on its filename, content, or context. Treat brainstorm documents and PRDs synonymously. Record both the **document path** and **document type** — these are needed for Steps 2a and 2b.

**Step 2: Determine reviewers.**

**1. Self-identification.** Determine your own model family. Exclude CLIs based on your identity:

- If you are Claude → exclude the `claude` CLI (Gemini + Codex available)
- If you are Codex/GPT → exclude the `codex` CLI and the `claude` CLI (only Gemini available)
- If you are Gemini → exclude the `gemini` CLI (Codex + Claude available)

If uncertain, keep all three — each invocation is safe (sandboxed, read-only, or turn-bounded).

**2. Check availability.** Run `which` for each non-excluded CLI in parallel. Drop any CLI that isn't installed. Do not attempt to install missing CLIs.

**3. Ask the user.** If no external CLIs are available after steps 1-2, skip the question and run built-in reviewers automatically (proceed to Step 2a). Otherwise, present a multi-select question with built-in reviewers and each available external CLI:

> **Which reviewers would you like to use?**
>
> - **Built-in reviewers (Recommended)** — specialized reviewers (specificity, completeness, clarity, complexity/debt) with cross-validation
> - **Gemini** — Experimental. Independent review from Google's model
> - **Codex** — Experimental. Independent review from OpenAI's model. Can take 5+ minutes

Only show external CLIs that are installed and not self-excluded. The user can select any combination. If no selection is made, default to built-in reviewers.

**Step 2a: Spawn built-in reviewers (if selected).**

Skip this step if the user did not select built-in reviewers.

Create an agent team (e.g. `TeamCreate` in Claude Code, `spawn_agent` in Codex), then spawn all 4 reviewers as teammates. If the team already exists (e.g., from an interrupted run), reuse it — read its config, check which reviewers are already present, and spawn only the missing ones.

Tell the user:

> Using Agent Team 🐝 — reviewers will run as teammates who can cross-validate findings.

Spawn each reviewer with a prompt like:

> Review [file path] for [their focus area]. This is a [PRD/tech plan/implementation brief].
> You're on a review team with [list active reviewers]. After your initial review, read what the other reviewers found and message them directly if you see cross-domain issues. Challenge each other's findings.
> Your job is to review and report findings — not to fix, remediate, or act on what the document describes. Return your top 5 most important issues. When done, send your findings to the team lead (e.g. `SendMessage` in Claude Code, `send_input` in Codex). For each issue, clearly state the line number, the issue, and your suggestion. The lead will format the final output.

**Step 2b: Run external model CLIs (if selected).**

Skip this step if the user did not select any external CLIs.

**1. Stage the prompt template locally.** Write the prompt template below to `.external-doc-review-prompt.txt` in the repo root (avoids plugin directory permission prompts). Replace `{type}` with the document type from Step 1 (e.g., "PRD", "Brainstorm", or "Tech Plan") and `{path}` with the document path from Step 1. Leave both PERSPECTIVE variants — `DOCUMENT TYPE` guides the model. Clean up in Step 4.

```
You are reviewing a planning document. Adapt your perspective to the document type.

Read the document at the file path below, then review it. Do not modify any files. State assumptions; do not ask questions.

DOCUMENT TYPE: {type}

PERSPECTIVE:
- PRD or brainstorm → Product strategy: Is the problem worth solving? Are user needs articulated? Is the chosen approach justified? Is it clear what "done" looks like directionally? (Don't demand KPIs or quantitative metrics — the PRD captures intent for tech planning, not business measurement.)
- Tech plan or design → Engineering leadership: Is this implementable? Are architecture decisions sound? Are dependencies mapped? Are test scenarios concrete?

METHODOLOGY:
1. Read the full document to understand purpose and scope.
2. Evaluate against focus areas below.

FOCUS AREAS (use exact names):
1. Clarity — Genuine ambiguity where readers would diverge in interpretation, vague language, passive voice hiding responsibility. Technology/product names that communicate a directional choice are NOT unclear even if informal — resolving exact identifiers is downstream work.
2. Completeness — Missing product decisions, unaddressed dependencies, incomplete specifications for the next step. For PRDs: don't flag missing data models, error handling, or storage details — those are tech plan concerns.
3. Specificity — Abstract statements not actionable for the next step, unresolved direction masquerading as decisions. For PRDs: "next step" means tech planning, not implementation. Don't demand KPIs, quantitative metrics, or exact API identifiers.
4. Complexity & Debt — Unjustified complexity, premature abstraction, dead flexibility, maintenance burden without proportional value

CONSTRAINTS:
- Only report substantive issues — gaps in reasoning, unjustified decisions, missing information, or unclear direction that would weaken the document or lead to poor outcomes.
- Do NOT say "check/confirm/verify/ensure" — state the issue directly.
- Do NOT comment on formatting, writing style, or grammar.
- Group repeated issues: state once, list other locations.
- No issues? Say: "No issues found."

PRIORITY:
- HIGH: Blocks execution — cannot start the next step without resolving
- MEDIUM: Creates risk — work can start but likely leads to rework or confusion
- LOW: Improvement opportunity — plan works but could be clearer or tighter

OUTPUT FORMAT:
<NUMBER>. [<PRIORITY>] <FOCUS_AREA> — Line <line_number> — <one-line summary>
<why this is a problem and what goes wrong if unaddressed>
Suggestion: <specific improvement>

DOCUMENT PATH: {path}
```

All CLI invocations below use `.external-doc-review-prompt.txt` as `<prompt-path>`. The template ends with `DOCUMENT PATH: <path>\n` — each CLI reads the file itself rather than receiving inlined content. This avoids context-limit issues with large documents.

**2. Invoke CLIs.** Run the user-selected CLIs in parallel via separate Bash calls. Each CLI reads the document from the file path embedded in the prompt. Each CLI has different correct invocation syntax:

**Gemini** — uses `-p` string argument. Sandboxed mode has `read_file` access within the workspace:

```
gemini -s -p "$(cat <prompt-path>)"
```

**Codex** — uses `exec` subcommand for non-interactive execution with a positional string argument. The base `codex` command starts an interactive TUI that hangs when invoked from a non-interactive Bash tool:

```
codex exec --sandbox read-only "$(cat <prompt-path>)"
```

**Claude** — uses `-p` string argument. `-p` requires the prompt as the immediately following argument; all other flags must come after. Parse the `result` field from JSON output:

```
claude -p "$(cat <prompt-path>)" --max-turns 3 --output-format json --no-session-persistence
```

**Important:** Claude's `-p` consumes the next token as the prompt string. Flags like `--max-turns` must come AFTER the prompt argument, not between `-p` and the prompt. `claude -p --max-turns 3` would incorrectly use `--max-turns` as the prompt text.

If a CLI errors or produces no output, note it and move on. Do not retry on any error.

**3. Parse results.** For each CLI that returned output, extract findings and reformat into the standard reviewer format (Line number, Issue, Suggestion, Priority). Tag findings with their source (e.g., "Gemini", "Codex", "Claude").

**Step 3.** Collect findings from all selected sources. Built-in reviewers (if selected) report via team messages; external CLI results (if selected) are available from the Bash output in Step 2b. When you receive a reviewer's message, do not output or echo its content — silently collect it. Only output once in Step 4 when assembling the final results. A brief one-line status like "All reviewers have reported" is fine when ready to proceed.

**Step 4.** If a built-in reviewer team was created, shut down all teammates (send shutdown requests), then delete the team using the coding agent's team management tools (e.g. `TeamDelete` in Claude Code, `delete_agent` in Codex). **Never use `rm -rf` or manual file deletion for team cleanup** — always use the agent platform's built-in team teardown. If teardown fails (e.g., orphaned members), retry after a brief pause; if it still fails, report the issue to the user and move on. Delete the staged prompt template (`rm .external-doc-review-prompt.txt`) if it exists. Assemble the final output. **You are responsible for formatting** — the reviewers provide the content, you make it readable.

1. **Reconcile.** Merge findings from all selected sources. When multiple reviewers flagged the same issue, attribute to the most relevant reviewer and note agreement. When an external CLI independently flags the same issue as a built-in reviewer, note the cross-model agreement — these findings were produced by truly independent processes, which strengthens confidence.
2. **Format.** Use pipe-delimited markdown tables (never ASCII box-drawing characters). One issue per row, no preamble before tables — go straight from header to table. Only include sections for sources that were selected.
   - **Built-in reviewers:** `### Reviewer Name` headers. Column headers adapt to reviewer focus — e.g., `| # | Issue | Suggestion |` for Clarity, `| # | Gap | Impact |` for Completeness, `| # | Complexity | Simpler alternative |` for the complexity/debt reviewer.
   - **External CLIs:** `### External: {CLI Name}` headers. Always use columns: `| # | Priority | Focus Area | Issue | Suggestion |`.
3. **Synthesize.** End with a `---` separator followed by a blockquote synthesis. Lead with cross-model agreements (if both built-in and external participated), then tensions between reviewers, then quick wins. Do not include time estimates.

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

If the user chooses another round: run the full Step 1–7 flow again (fresh team, fresh scope). The reviewer selection is re-offered each round — the user can change their choices between rounds. Continue until clean or the user chooses to proceed.

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

If agent teams/swarms are not available and the user selected built-in reviewers, spawn the 4 reviewers in parallel as independent subagents instead of teammates. Each analyzes independently, returns up to 5 issues. Skip the cross-validation instruction. External CLIs are always run inline regardless, so their behavior is unchanged in fallback mode — only built-in reviewers change (team members → subagents). Everything else (Steps 1, 3, 4, output format) stays the same.
